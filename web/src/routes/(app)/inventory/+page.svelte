<script lang="ts">
	import { getBridge } from '$lib/wasm/bridge.js';
	import { wasmEvent } from '$lib/wasm/events.js';
	import Icon from '$lib/icons/Icon.svelte';
	import { capitalize, statusTone } from '$lib/utils/format.js';

	const bridge = getBridge();
	let entities = $state<Record<string, Record<string, Record<string, unknown>>> | null>(null);
	let ui = $state<import('$lib/wasm/types.js').UiState | null>(null);

	bridge.entities.subscribe((e) => (entities = e));
	bridge.ui.subscribe((u) => (ui = u));

	let tab = $state<'stock' | 'movements' | 'counts'>('stock');

	let inventoryItems = $derived(
		entities?.inventory_items ? Object.values(entities.inventory_items) : []
	);
	let stockLocations = $derived(
		entities?.stock_locations ? Object.values(entities.stock_locations) : []
	);
	let movements = $derived(
		entities?.inventory_movements ? Object.values(entities.inventory_movements) : []
	);
	let cycleCounts = $derived(
		entities?.cycle_counts ? Object.values(entities.cycle_counts) : []
	);

	let lowStockItems = $derived(
		inventoryItems.filter(
			(i) => ((i['quantity_on_hand'] as number) ?? 0) <= ((i['reorder_point'] as number) ?? 0)
		)
	);

	async function recordMovement(itemId: string) {
		await bridge.dispatch(wasmEvent.click(`record_movement_${itemId}`));
	}
</script>

<div class="page">
	<div class="page-header"><h1>Inventory</h1></div>

	{#if lowStockItems.length > 0}
		<div class="card card--padded" style="margin-bottom: var(--space-5); border-left: 3px solid var(--c-warning)">
			<strong>Low Stock Alert:</strong> {lowStockItems.length} items below reorder point
		</div>
	{/if}

	<div class="page-tabs">
		<button data-active={tab === 'stock'} onclick={() => (tab = 'stock')}>Stock Levels</button>
		<button data-active={tab === 'movements'} onclick={() => (tab = 'movements')}>Movements</button>
		<button data-active={tab === 'counts'} onclick={() => (tab = 'counts')}>Cycle Counts</button>
	</div>

	{#if tab === 'stock'}
		<div class="card">
			<table class="table">
				<thead><tr><th>Item</th><th>Name</th><th>On Hand</th><th>Reorder Point</th><th>Location</th><th></th></tr></thead>
				<tbody>
					{#each inventoryItems as item}
						{@const qty = (item['quantity_on_hand'] as number) ?? 0}
						{@const rp = (item['reorder_point'] as number) ?? 0}
						<tr>
							<td><code>{item['id']}</code></td>
							<td>{item['name'] ?? '—'}</td>
							<td><span class:low-stock={qty <= rp}>{qty}</span></td>
							<td>{rp}</td>
							<td>{item['stock_location_id'] ?? '—'}</td>
							<td><button class="btn btn--ghost btn--sm" onclick={() => recordMovement(item['id'] as string)}>Move</button></td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	{:else if tab === 'movements'}
		<div class="card">
			<table class="table">
				<thead><tr><th>ID</th><th>Item</th><th>Type</th><th>Quantity</th><th>From</th><th>To</th></tr></thead>
				<tbody>
					{#each movements as m}
						<tr>
							<td><code>{m['id']}</code></td>
							<td>{m['item_id']}</td>
							<td>{capitalize((m['movement_type'] as string) ?? '')}</td>
							<td>{m['quantity']}</td>
							<td>{m['from_location'] ?? '—'}</td>
							<td>{m['to_location'] ?? '—'}</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	{:else}
		<div class="card">
			<table class="table">
				<thead><tr><th>Count</th><th>Location</th><th>Status</th><th>Discrepancies</th></tr></thead>
				<tbody>
					{#each cycleCounts as cc}
						<tr>
							<td><code>{cc['id']}</code></td>
							<td>{cc['location_id'] ?? '—'}</td>
							<td><span class="badge" data-tone={statusTone(cc['status'] as string)}>{capitalize((cc['status'] as string) ?? '')}</span></td>
							<td>{cc['discrepancy_count'] ?? 0}</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	{/if}
</div>

<style>
	.low-stock {
		color: var(--c-danger);
		font-weight: var(--weight-semibold);
	}
</style>
