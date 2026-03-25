import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';
import { resolve } from 'node:path';

const SVELTE_CLIENT_ENTRY = resolve('./node_modules/svelte/src/index-client.js');

export default defineConfig(({ mode }) => ({
	plugins: [sveltekit()],
	resolve:
		mode === 'test'
			? {
					alias: [{ find: /^svelte$/, replacement: SVELTE_CLIENT_ENTRY }]
				}
			: undefined,
	server: {
		proxy: {
			'/api': 'http://127.0.0.1:17081'
		}
	},
	test: {
		environment: 'jsdom',
		setupFiles: ['./src/tests/setup.ts'],
		include: ['src/**/*.test.ts'],
		clearMocks: true
	}
}));
