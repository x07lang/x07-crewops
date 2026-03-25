<script lang="ts">
	import { getBridge } from '$lib/wasm/bridge.js';
	import { wasmEvent } from '$lib/wasm/events.js';
	import Icon from '$lib/icons/Icon.svelte';
	import { capitalize, statusTone, formatDate, formatCurrency } from '$lib/utils/format.js';

	const bridge = getBridge();
	let entities = $state<Record<string, Record<string, Record<string, unknown>>> | null>(null);
	let ui = $state<import('$lib/wasm/types.js').UiState | null>(null);

	bridge.entities.subscribe((e) => (entities = e));
	bridge.ui.subscribe((u) => (ui = u));

	let invoices = $derived(entities?.invoices ? Object.values(entities.invoices) : []);
	let statusFilter = $derived((ui?.invoice_status_filter as string) ?? 'all');

	let filtered = $derived(
		statusFilter === 'all' ? invoices : invoices.filter((i) => i['status'] === statusFilter)
	);

	let selectedId = $derived((ui?.selected_invoice_id as string) ?? null);
	let selectedInv = $derived(
		selectedId && entities?.invoices ? entities.invoices[selectedId] ?? null : null
	);
	let drawerOpen = $state(false);

	async function selectInv(id: string) {
		await bridge.dispatch(wasmEvent.click(`invoice_${id}`));
		drawerOpen = true;
	}

	async function recordPayment(id: string) {
		await bridge.dispatch(wasmEvent.click(`record_payment_${id}`));
	}

	async function setFilter(val: string) {
		await bridge.dispatch(wasmEvent.change('invoice_status_filter', val));
	}
</script>

<div class="page">
	<div class="page-header">
		<h1>Invoices</h1>
		<span class="muted">{filtered.length} invoices</span>
	</div>

	<div class="toolbar">
		<select class="select" value={statusFilter} onchange={(e) => setFilter(e.currentTarget.value)}>
			<option value="all">All Statuses</option>
			<option value="draft">Draft</option>
			<option value="issued">Issued</option>
			<option value="paid">Paid</option>
			<option value="overdue">Overdue</option>
		</select>
	</div>

	<div class="card">
		<table class="table">
			<thead><tr><th>Invoice</th><th>Customer</th><th>Amount</th><th>Status</th><th>Date</th><th></th></tr></thead>
			<tbody>
				{#each filtered as inv}
					<tr data-selected={inv['id'] === selectedId} onclick={() => selectInv(inv['id'] as string)}>
						<td><code>{inv['id']}</code></td>
						<td>{inv['customer_name'] ?? inv['customer_id'] ?? '—'}</td>
						<td>{formatCurrency((inv['total_cents'] as number) ?? 0)}</td>
						<td><span class="badge" data-tone={statusTone(inv['status'] as string)}>{capitalize((inv['status'] as string) ?? '')}</span></td>
						<td>{formatDate(inv['issued_date'] as string)}</td>
						<td>
							{#if inv['status'] === 'issued'}
								<button class="btn btn--primary btn--sm" onclick={(e) => { e.stopPropagation(); recordPayment(inv['id'] as string); }}>Pay</button>
							{/if}
						</td>
					</tr>
				{/each}
			</tbody>
		</table>
	</div>

	{#if drawerOpen && selectedInv}
		<button class="drawer-backdrop" aria-label="Close drawer" onclick={() => (drawerOpen = false)}></button>
		<div class="drawer">
			<div class="drawer-header">
				<h2>Invoice {selectedInv['id']}</h2>
				<button class="btn btn--ghost btn--sm" onclick={() => (drawerOpen = false)}><Icon name="x" size={16} /></button>
			</div>
			<dl class="kv">
				<dt>Customer</dt><dd>{selectedInv['customer_name'] ?? selectedInv['customer_id']}</dd>
				<dt>Amount</dt><dd>{formatCurrency((selectedInv['total_cents'] as number) ?? 0)}</dd>
				<dt>Status</dt><dd><span class="badge" data-tone={statusTone(selectedInv['status'] as string)}>{capitalize((selectedInv['status'] as string) ?? '')}</span></dd>
				<dt>Issued</dt><dd>{formatDate(selectedInv['issued_date'] as string)}</dd>
				<dt>Due</dt><dd>{formatDate(selectedInv['due_date'] as string)}</dd>
			</dl>
		</div>
	{/if}
</div>
