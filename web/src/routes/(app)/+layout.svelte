<script lang="ts">
	import type { Snippet } from 'svelte';
	import AppShell from '$lib/components/shell/AppShell.svelte';
	import { getBridge } from '$lib/wasm/bridge.js';
	import { wasmEvent, pathnameToWasmRoute } from '$lib/wasm/events.js';
	import { ROLE_DEFAULT_ROUTE } from '$lib/types/roles.js';
	import { goto } from '$app/navigation';
	import { page } from '$app/stores';
	import type { Role } from '$lib/wasm/types.js';

	type Props = { children: Snippet };
	let { children }: Props = $props();

	const bridge = getBridge();
	let role = $derived.by(() => {
		let s: Role = 'technician';
		bridge.session.subscribe((v) => {
			if (v) s = v.role;
		})();
		return s;
	});

	// Sync SvelteKit route → WASM route state
	$effect(() => {
		const wasmRoute = pathnameToWasmRoute($page.url.pathname);
		if (wasmRoute) {
			bridge.ui.subscribe((u) => {
				if (u && u.route !== wasmRoute) {
					bridge.dispatch(wasmEvent.click(`nav_${wasmRoute}`));
				}
			})();
		}
	});

	async function handleRoleSwitch(newRole: Role) {
		await bridge.dispatch(wasmEvent.click(`dev_login_${newRole}`));
		goto(ROLE_DEFAULT_ROUTE[newRole] ?? '/today');
	}
</script>

<AppShell {role} onroleswitch={handleRoleSwitch}>
	{@render children()}
</AppShell>
