import type { WasmEvent } from './types.js';

export const wasmEvent = {
	click: (target: string): WasmEvent => ({ type: 'click', target }),
	input: (target: string, value: string): WasmEvent => ({ type: 'input', target, value }),
	change: (target: string, value: string): WasmEvent => ({ type: 'change', target, value }),
	submit: (target: string): WasmEvent => ({ type: 'submit', target }),
	init: (): WasmEvent => ({ type: 'init' })
};

/** Map SvelteKit pathnames to WASM route names */
const PATHNAME_TO_ROUTE: Record<string, string> = {
	'/today': 'today',
	'/dispatch': 'dispatch',
	'/review': 'review',
	'/manager': 'manager',
	'/finance': 'finance',
	'/pricing': 'pricing',
	'/invoices': 'invoices',
	'/activity': 'activity',
	'/customers': 'customers',
	'/receivables': 'receivables',
	'/exports': 'exports',
	'/sites': 'sites',
	'/assets': 'assets',
	'/settings': 'settings',
	'/estimates': 'estimates',
	'/contracts': 'contracts',
	'/recurring': 'recurring',
	'/integrations': 'integrations',
	'/portal': 'portal',
	'/enterprise': 'enterprise',
	'/inventory': 'inventory',
	'/procurement': 'procurement',
	'/integration-dashboard': 'integration_dashboard'
};

export function pathnameToWasmRoute(pathname: string): string | null {
	return PATHNAME_TO_ROUTE[pathname] ?? null;
}

/** Map WASM route names to SvelteKit pathnames */
const ROUTE_TO_PATHNAME: Record<string, string> = Object.fromEntries(
	Object.entries(PATHNAME_TO_ROUTE).map(([k, v]) => [v, k])
);

export function wasmRouteToPathname(route: string): string {
	return ROUTE_TO_PATHNAME[route] ?? '/today';
}
