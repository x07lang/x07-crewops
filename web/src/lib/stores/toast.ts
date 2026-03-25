import { writable } from 'svelte/store';

export interface Toast {
	id: string;
	message: string;
	tone: 'success' | 'warning' | 'danger' | 'info';
}

let nextId = 0;

const { subscribe, update } = writable<Toast[]>([]);

export const toasts = { subscribe };

export function pushToast(message: string, tone: Toast['tone'] = 'info', duration = 4000) {
	const id = String(++nextId);
	update((t) => [...t, { id, message, tone }]);
	if (duration > 0) {
		setTimeout(() => dismissToast(id), duration);
	}
	return id;
}

export function dismissToast(id: string) {
	update((t) => t.filter((x) => x.id !== id));
}
