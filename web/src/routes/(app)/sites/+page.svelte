<script lang="ts">
	import { getBridge } from '$lib/wasm/bridge.js';
	import { wasmEvent } from '$lib/wasm/events.js';
	import Icon from '$lib/icons/Icon.svelte';

	const bridge = getBridge();
	let entities = $state<Record<string, Record<string, Record<string, unknown>>> | null>(null);

	bridge.entities.subscribe((e) => (entities = e));

	let sites = $derived(entities?.sites ? Object.values(entities.sites) : []);
	let drawerOpen = $state(false);
	let selectedSite = $state<Record<string, unknown> | null>(null);

	async function selectSite(id: string) {
		await bridge.dispatch(wasmEvent.click(`site_${id}`));
		selectedSite = entities?.sites?.[id] ?? null;
		drawerOpen = true;
	}
</script>

<div class="page">
	<div class="page-header"><h1>Sites</h1><span class="muted">{sites.length} sites</span></div>

	<div class="card">
		<table class="table">
			<thead><tr><th>ID</th><th>Name</th><th>Address</th><th>Customer</th></tr></thead>
			<tbody>
				{#each sites as s}
					<tr onclick={() => selectSite(s['id'] as string)}>
						<td><code>{s['id']}</code></td>
						<td>{s['name'] ?? '—'}</td>
						<td>{s['address'] ?? '—'}</td>
						<td>{s['customer_name'] ?? s['customer_id'] ?? '—'}</td>
					</tr>
				{/each}
			</tbody>
		</table>
	</div>

	{#if drawerOpen && selectedSite}
		<button class="drawer-backdrop" aria-label="Close drawer" onclick={() => (drawerOpen = false)}></button>
		<div class="drawer">
			<div class="drawer-header">
				<h2>{selectedSite['name'] ?? selectedSite['id']}</h2>
				<button class="btn btn--ghost btn--sm" onclick={() => (drawerOpen = false)}><Icon name="x" size={16} /></button>
			</div>
			<dl class="kv">
				<dt>ID</dt><dd><code>{selectedSite['id']}</code></dd>
				<dt>Name</dt><dd>{selectedSite['name']}</dd>
				<dt>Address</dt><dd>{selectedSite['address'] ?? '—'}</dd>
				<dt>Customer</dt><dd>{selectedSite['customer_name'] ?? selectedSite['customer_id']}</dd>
				<dt>Assets</dt><dd>{selectedSite['asset_count'] ?? '—'}</dd>
			</dl>
		</div>
	{/if}
</div>
