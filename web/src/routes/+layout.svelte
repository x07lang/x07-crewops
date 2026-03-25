<script lang="ts">
	import type { Snippet } from 'svelte';
	import '../app.css';
	import ToastHost from '$lib/components/ui/ToastHost.svelte';
	import { initBridge } from '$lib/wasm/bridge.js';
	import { onMount } from 'svelte';

	type Props = { children: Snippet };
	let { children }: Props = $props();

	onMount(() => {
		initBridge();
	});
</script>

{@render children()}
<ToastHost />
