<script lang="ts">
	import { goto } from '$app/navigation';
	import { getBridge } from '$lib/wasm/bridge.js';
	import { ROLE_DEFAULT_ROUTE } from '$lib/types/roles.js';
	import { onMount } from 'svelte';

	onMount(() => {
		const bridge = getBridge();
		const unsub = bridge.session.subscribe((s) => {
			if (s) {
				goto(ROLE_DEFAULT_ROUTE[s.role] ?? '/today');
				unsub();
			}
		});
		return unsub;
	});
</script>

<div class="empty-state">
	<p>Loading CrewOps...</p>
</div>
