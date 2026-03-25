import { writable, derived, type Readable } from 'svelte/store';
import { browser } from '$app/environment';
import type { CrewOpsState, SessionState, UiState, WasmEvent, WasmFrame } from './types.js';

export interface WasmBridge {
	dispatch(event: WasmEvent): Promise<void>;
	state: Readable<CrewOpsState | null>;
	session: Readable<SessionState | null>;
	entities: Readable<Record<string, Record<string, Record<string, unknown>>> | null>;
	ui: Readable<UiState | null>;
	ready: Readable<boolean>;
}

const ARENA_CAP = 50_331_648; // 50 MB
const MAX_EFFECTS_LOOPS = 16;

const _state = writable<CrewOpsState | null>(null);
const _ready = writable(false);

let _wasmExports: {
	memory: WebAssembly.Memory;
	x07_solve_v2: (...args: number[]) => void;
	__heap_base: WebAssembly.Global;
} | null = null;

let _currentState: CrewOpsState | null = null;

const textEncoder = new TextEncoder();
const textDecoder = new TextDecoder();

async function loadWasm(): Promise<void> {
	const resp = await fetch('/app.wasm');
	const { instance } = await WebAssembly.instantiateStreaming(resp);
	_wasmExports = {
		memory: instance.exports.memory as WebAssembly.Memory,
		x07_solve_v2: instance.exports.x07_solve_v2 as (...args: number[]) => void,
		__heap_base: instance.exports.__heap_base as WebAssembly.Global
	};
}

function callReducer(state: CrewOpsState | null, event: WasmEvent): WasmFrame {
	if (!_wasmExports) throw new Error('WASM not loaded');
	const { memory, x07_solve_v2, __heap_base } = _wasmExports;

	const envelope = JSON.stringify({
		v: 1,
		kind: 'x07.web_ui.dispatch',
		state,
		event
	});
	const inputBytes = textEncoder.encode(envelope);

	const mem = new Uint8Array(memory.buffer);
	const heapBase = __heap_base.value as number;

	// Layout: [retptr (8 bytes)] [arena (ARENA_CAP)] [input]
	const retptrAddr = heapBase;
	const arenaAddr = retptrAddr + 8;
	const inputAddr = arenaAddr + ARENA_CAP;

	mem.set(inputBytes, inputAddr);

	x07_solve_v2(retptrAddr, arenaAddr, ARENA_CAP, inputAddr, inputBytes.length);

	const view = new DataView(memory.buffer);
	const outPtr = view.getUint32(retptrAddr, true);
	const outLen = view.getUint32(retptrAddr + 4, true);

	const outBytes = new Uint8Array(memory.buffer, outPtr, outLen);
	const outJson = textDecoder.decode(outBytes);
	return JSON.parse(outJson) as WasmFrame;
}

async function runEffects(
	frame: WasmFrame,
	originalEvent: WasmEvent
): Promise<CrewOpsState> {
	let currentFrameState = frame.state;

	for (let i = 0; i < MAX_EFFECTS_LOOPS; i++) {
		const effects = frame.effects ?? [];
		if (effects.length === 0) break;

		// Clone current state as the base for injections (matches host behavior)
		const injectedState: Record<string, unknown> = {
			...(currentFrameState as unknown as Record<string, unknown>)
		};
		let handled = false;

		for (const eff of effects) {
			const effObj = eff as Record<string, unknown>;
			const kind = (effObj['kind'] as string) ?? '';

			if (kind === 'x07.web_ui.effect.storage.get') {
				const key = effObj['key'] as string;
				const raw =
					typeof globalThis.localStorage !== 'undefined'
						? globalThis.localStorage.getItem(key)
						: null;
				const value = raw == null ? null : String(raw);
				const inj = { get: { key, value } };
				// Merge with existing __x07_storage (host merges multiple storage ops)
				const prev = injectedState['__x07_storage'] as Record<string, unknown> | undefined;
				injectedState['__x07_storage'] =
					prev && typeof prev === 'object' ? { ...prev, ...inj } : inj;
				handled = true;
			} else if (kind === 'x07.web_ui.effect.storage.set') {
				const key = effObj['key'] as string;
				const value = effObj['value'] as string;
				if (typeof globalThis.localStorage !== 'undefined') {
					globalThis.localStorage.setItem(key, value);
				}
				const inj = { set: { ok: true } };
				const prev = injectedState['__x07_storage'] as Record<string, unknown> | undefined;
				injectedState['__x07_storage'] =
					prev && typeof prev === 'object' ? { ...prev, ...inj } : inj;
				handled = true;
			} else if (kind === 'x07.web_ui.effect.http.request') {
				const req = effObj['request'] as Record<string, unknown>;
				if (!req) continue;

				const reqId = (req['id'] as string) ?? '';
				const method = (req['method'] as string) ?? 'GET';
				const path = (req['path'] as string) ?? '/';
				const query = (req['query'] as string) ?? '';
				const bodyField = req['body'] as Record<string, unknown> | undefined;

				let fetchBody: BodyInit | undefined;
				if (bodyField?.['text']) {
					fetchBody = bodyField['text'] as string;
				}

				try {
					const headers: Record<string, string> = {};
					const reqHeaders = req['headers'] as Array<{ k: string; v: string }> | undefined;
					if (reqHeaders) {
						for (const h of reqHeaders) {
							if (h.k) headers[h.k] = h.v;
						}
					}

					const url = path.startsWith('/') ? `${path}${query}` : `/${path}${query}`;
					const fetchResp = await fetch(url, {
						method,
						headers,
						body: fetchBody
					});

					const respBuf = new Uint8Array(await fetchResp.arrayBuffer());
					// Match host's bytesToStreamPayload: { bytes_len, text }
					let bodyPayload: Record<string, unknown>;
					try {
						const text = new TextDecoder('utf-8', { fatal: true }).decode(respBuf);
						bodyPayload = { bytes_len: respBuf.length, text };
					} catch {
						bodyPayload = {
							bytes_len: respBuf.length,
							base64: btoa(String.fromCharCode(...respBuf))
						};
					}

					// Match host's response envelope (includes request_id)
					const respHeaders = [...fetchResp.headers.entries()].map(([k, v]) => ({
						k,
						v
					}));
					injectedState['__x07_http'] = {
						response: {
							schema_version: 'x07.http.response.envelope@0.1.0',
							request_id: reqId,
							status: fetchResp.status,
							headers: respHeaders,
							body: bodyPayload
						}
					};
				} catch {
					injectedState['__x07_http'] = {
						response: {
							schema_version: 'x07.http.response.envelope@0.1.0',
							request_id: reqId,
							status: 0,
							headers: [],
							body: { bytes_len: 0 }
						}
					};
				}
				handled = true;
			} else if (kind.includes('timer')) {
				const prev = injectedState['__x07_timer'] as Record<string, unknown> | undefined;
				const inj = { set: { ok: true } };
				injectedState['__x07_timer'] =
					prev && typeof prev === 'object' ? { ...prev, ...inj } : inj;
				handled = true;
			}
			// nav effects: ignored — SvelteKit owns routing
		}

		if (!handled) break;

		// Re-dispatch with the ORIGINAL event and injected state (matches host behavior)
		frame = callReducer(injectedState as unknown as CrewOpsState, originalEvent);
		currentFrameState = frame.state;

		// If entities are populated, settle early to avoid bootstrap re-fetch cycle
		const entities = (currentFrameState as unknown as Record<string, unknown>)?.entities;
		if (entities && typeof entities === 'object') {
			const woCount = Object.keys(
				(entities as Record<string, unknown>)['work_orders'] ?? {}
			).length;
			if (woCount > 0 && i >= 1) {
				// Data loaded — run one more loop for any final storage.set, then stop
				const finalEffects = frame.effects ?? [];
				if (finalEffects.length > 0) {
					const finalInjected: Record<string, unknown> = {
						...(currentFrameState as unknown as Record<string, unknown>)
					};
					for (const eff of finalEffects) {
						const ek = ((eff as Record<string, unknown>)['kind'] as string) ?? '';
						if (ek === 'x07.web_ui.effect.storage.set') {
							const key = (eff as Record<string, unknown>)['key'] as string;
							const value = (eff as Record<string, unknown>)['value'] as string;
							if (typeof globalThis.localStorage !== 'undefined') {
								globalThis.localStorage.setItem(key, value);
							}
							const prev = finalInjected['__x07_storage'] as Record<string, unknown> | undefined;
							finalInjected['__x07_storage'] =
								prev && typeof prev === 'object'
									? { ...prev, set: { ok: true } }
									: { set: { ok: true } };
						}
					}
					frame = callReducer(finalInjected as unknown as CrewOpsState, originalEvent);
					currentFrameState = frame.state;
				}
				break;
			}
		}
	}

	return currentFrameState;
}

async function dispatchEvent(event: WasmEvent): Promise<void> {
	const frame = callReducer(_currentState, event);
	_currentState = await runEffects(frame, event);
	_state.set(_currentState);
}

export async function initBridge(): Promise<WasmBridge> {
	if (!browser) return buildBridge();
	if (_wasmExports) return buildBridge();

	await loadWasm();

	const initEvent: WasmEvent = { type: 'init' };
	const initFrame = callReducer(null, initEvent);
	_currentState = await runEffects(initFrame, initEvent);
	_state.set(_currentState);
	_ready.set(true);

	return buildBridge();
}

function buildBridge(): WasmBridge {
	const session = derived(_state, ($s) => $s?.session ?? null);
	const entities = derived(_state, ($s) => $s?.entities ?? null);
	const ui = derived(_state, ($s) => $s?.ui ?? null);

	return {
		dispatch: dispatchEvent,
		state: _state,
		session,
		entities,
		ui,
		ready: _ready
	};
}

export function getBridge(): WasmBridge {
	return buildBridge();
}
