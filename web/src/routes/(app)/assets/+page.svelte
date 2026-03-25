<script lang="ts">
	import { getBridge } from '$lib/wasm/bridge.js';
	import { wasmEvent } from '$lib/wasm/events.js';
	import Icon from '$lib/icons/Icon.svelte';
	import { capitalize, statusTone } from '$lib/utils/format.js';

	const bridge = getBridge();
	let entities = $state<Record<string, Record<string, Record<string, unknown>>> | null>(null);

	bridge.entities.subscribe((e) => (entities = e));

	let assets = $derived(entities?.assets ? Object.values(entities.assets) : []);
	let drawerOpen = $state(false);
	let selectedAsset = $state<Record<string, unknown> | null>(null);

	async function selectAsset(id: string) {
		await bridge.dispatch(wasmEvent.click(`asset_${id}`));
		selectedAsset = entities?.assets?.[id] ?? null;
		drawerOpen = true;
	}
</script>

<div class="page">
	<div class="page-header"><h1>Assets</h1><span class="muted">{assets.length} assets</span></div>

	<div class="card">
		<table class="table">
			<thead><tr><th>ID</th><th>Name</th><th>Type</th><th>Site</th><th>Status</th></tr></thead>
			<tbody>
				{#each assets as a}
					<tr onclick={() => selectAsset(a['id'] as string)}>
						<td><code>{a['id']}</code></td>
						<td>{a['name'] ?? '—'}</td>
						<td>{capitalize((a['asset_type'] as string) ?? '')}</td>
						<td>{a['site_id'] ?? '—'}</td>
						<td><span class="badge" data-tone={statusTone(a['status'] as string)}>{capitalize((a['status'] as string) ?? 'active')}</span></td>
					</tr>
				{/each}
			</tbody>
		</table>
	</div>

	{#if drawerOpen && selectedAsset}
		<button class="drawer-backdrop" aria-label="Close drawer" onclick={() => (drawerOpen = false)}></button>
		<div class="drawer">
			<div class="drawer-header">
				<h2>{selectedAsset['name'] ?? selectedAsset['id']}</h2>
				<button class="btn btn--ghost btn--sm" onclick={() => (drawerOpen = false)}><Icon name="x" size={16} /></button>
			</div>
			<dl class="kv">
				<dt>ID</dt><dd><code>{selectedAsset['id']}</code></dd>
				<dt>Type</dt><dd>{capitalize((selectedAsset['asset_type'] as string) ?? '')}</dd>
				<dt>Site</dt><dd>{selectedAsset['site_id']}</dd>
				<dt>Model</dt><dd>{selectedAsset['model'] ?? '—'}</dd>
				<dt>Serial</dt><dd>{selectedAsset['serial_number'] ?? '—'}</dd>
				<dt>Status</dt><dd><span class="badge" data-tone={statusTone(selectedAsset['status'] as string)}>{capitalize((selectedAsset['status'] as string) ?? '')}</span></dd>
			</dl>
		</div>
	{/if}
</div>
