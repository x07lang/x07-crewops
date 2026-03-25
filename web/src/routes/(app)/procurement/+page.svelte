<script lang="ts">
	import { getBridge } from '$lib/wasm/bridge.js';
	import { wasmEvent } from '$lib/wasm/events.js';
	import Icon from '$lib/icons/Icon.svelte';
	import { capitalize, statusTone, formatDate, formatCurrency } from '$lib/utils/format.js';

	const bridge = getBridge();
	let entities = $state<Record<string, Record<string, Record<string, unknown>>> | null>(null);

	bridge.entities.subscribe((e) => (entities = e));

	let tab = $state<'orders' | 'receiving' | 'reorder'>('orders');

	let purchaseOrders = $derived(
		entities?.purchase_orders ? Object.values(entities.purchase_orders) : []
	);
	let receivingRecords = $derived(
		entities?.receiving_records ? Object.values(entities.receiving_records) : []
	);
	let reorderSuggestions = $derived(
		entities?.reorder_suggestions ? Object.values(entities.reorder_suggestions) : []
	);

	let drawerOpen = $state(false);
	let selectedPo = $state<Record<string, unknown> | null>(null);

	async function selectPo(id: string) {
		await bridge.dispatch(wasmEvent.click(`po_${id}`));
		selectedPo = entities?.purchase_orders?.[id] ?? null;
		drawerOpen = true;
	}

	async function receiveOrder(id: string) {
		await bridge.dispatch(wasmEvent.click(`receive_po_${id}`));
	}
</script>

<div class="page">
	<div class="page-header"><h1>Procurement</h1></div>

	<div class="page-tabs">
		<button data-active={tab === 'orders'} onclick={() => (tab = 'orders')}>Purchase Orders</button>
		<button data-active={tab === 'receiving'} onclick={() => (tab = 'receiving')}>Receiving</button>
		<button data-active={tab === 'reorder'} onclick={() => (tab = 'reorder')}>Reorder Suggestions</button>
	</div>

	{#if tab === 'orders'}
		<div class="card">
			<table class="table">
				<thead><tr><th>PO</th><th>Vendor</th><th>Amount</th><th>Status</th><th>Date</th><th></th></tr></thead>
				<tbody>
					{#each purchaseOrders as po}
						<tr onclick={() => selectPo(po['id'] as string)}>
							<td><code>{po['id']}</code></td>
							<td>{po['vendor_name'] ?? po['vendor_id'] ?? '—'}</td>
							<td>{formatCurrency((po['total_cents'] as number) ?? 0)}</td>
							<td><span class="badge" data-tone={statusTone(po['status'] as string)}>{capitalize((po['status'] as string) ?? '')}</span></td>
							<td>{formatDate(po['order_date'] as string)}</td>
							<td>
								{#if po['status'] === 'ordered'}
									<button class="btn btn--primary btn--sm" onclick={(e) => { e.stopPropagation(); receiveOrder(po['id'] as string); }}>Receive</button>
								{/if}
							</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	{:else if tab === 'receiving'}
		<div class="card">
			<table class="table">
				<thead><tr><th>ID</th><th>PO</th><th>Status</th><th>Items Received</th></tr></thead>
				<tbody>
					{#each receivingRecords as rr}
						<tr>
							<td><code>{rr['id']}</code></td>
							<td><code>{rr['purchase_order_id']}</code></td>
							<td><span class="badge" data-tone={statusTone(rr['status'] as string)}>{capitalize((rr['status'] as string) ?? '')}</span></td>
							<td>{rr['items_received'] ?? '—'}</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	{:else}
		<div class="card">
			<table class="table">
				<thead><tr><th>Item</th><th>Current Stock</th><th>Suggested Qty</th><th>Vendor</th></tr></thead>
				<tbody>
					{#each reorderSuggestions as rs}
						<tr>
							<td>{rs['item_name'] ?? rs['item_id']}</td>
							<td>{rs['current_stock']}</td>
							<td><strong>{rs['suggested_quantity']}</strong></td>
							<td>{rs['preferred_vendor'] ?? '—'}</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	{/if}

	{#if drawerOpen && selectedPo}
		<button class="drawer-backdrop" aria-label="Close drawer" onclick={() => (drawerOpen = false)}></button>
		<div class="drawer">
			<div class="drawer-header">
				<h2>PO {selectedPo['id']}</h2>
				<button class="btn btn--ghost btn--sm" onclick={() => (drawerOpen = false)}><Icon name="x" size={16} /></button>
			</div>
			<dl class="kv">
				<dt>Vendor</dt><dd>{selectedPo['vendor_name'] ?? selectedPo['vendor_id']}</dd>
				<dt>Amount</dt><dd>{formatCurrency((selectedPo['total_cents'] as number) ?? 0)}</dd>
				<dt>Status</dt><dd><span class="badge" data-tone={statusTone(selectedPo['status'] as string)}>{capitalize((selectedPo['status'] as string) ?? '')}</span></dd>
				<dt>Order Date</dt><dd>{formatDate(selectedPo['order_date'] as string)}</dd>
			</dl>
		</div>
	{/if}
</div>
