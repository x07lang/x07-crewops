<script lang="ts">
	import { getBridge } from '$lib/wasm/bridge.js';
	import { wasmEvent } from '$lib/wasm/events.js';
	import Icon from '$lib/icons/Icon.svelte';
	import { formatDate, statusTone, capitalize } from '$lib/utils/format.js';

	const bridge = getBridge();
	let entities = $state<Record<string, Record<string, Record<string, unknown>>> | null>(null);
	let ui = $state<import('$lib/wasm/types.js').UiState | null>(null);

	bridge.entities.subscribe((e) => (entities = e));
	bridge.ui.subscribe((u) => (ui = u));

	let workOrders = $derived(
		entities?.work_orders ? Object.values(entities.work_orders) : []
	);
	let selectedId = $derived((ui?.selected_work_order_id as string) ?? null);
	let selectedWo = $derived(
		selectedId && entities?.work_orders
			? (entities.work_orders[selectedId] ?? null)
			: null
	);
	let drawerOpen = $state(false);

	async function selectWo(id: string) {
		await bridge.dispatch(wasmEvent.click(`wo_${id}`));
		drawerOpen = true;
	}

	async function startVisit() {
		await bridge.dispatch(wasmEvent.click('visit_checkin'));
	}
</script>

<div class="page">
	<div class="page-header">
		<h1>Today</h1>
		<span class="muted">{workOrders.length} work orders</span>
	</div>

	{#if workOrders.length === 0}
		<div class="empty-state">
			<Icon name="calendar" size={48} />
			<p>No work orders assigned for today</p>
		</div>
	{:else}
		<div class="card">
			<table class="table">
				<thead>
					<tr>
						<th>ID</th>
						<th>Customer</th>
						<th>Status</th>
						<th>Priority</th>
						<th>Scheduled</th>
					</tr>
				</thead>
				<tbody>
					{#each workOrders as wo}
						<tr
							data-selected={wo['id'] === selectedId}
							onclick={() => selectWo(wo['id'] as string)}
							data-testid="wo-row-{wo['id']}"
						>
							<td><code>{wo['id']}</code></td>
							<td>{wo['customer_name'] ?? wo['customer_id'] ?? '—'}</td>
							<td>
								<span class="badge" data-tone={statusTone(wo['status'] as string)}>
									{capitalize((wo['status'] as string) ?? 'unknown')}
								</span>
							</td>
							<td>{capitalize((wo['priority'] as string) ?? 'normal')}</td>
							<td>{formatDate(wo['scheduled_date'] as string)}</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	{/if}

	{#if drawerOpen && selectedWo}
		<button class="drawer-backdrop" aria-label="Close drawer" onclick={() => (drawerOpen = false)}></button>
		<div class="drawer" data-testid="wo-detail-drawer">
			<div class="drawer-header">
				<h2>Work Order {selectedWo['id']}</h2>
				<button class="btn btn--ghost btn--sm" onclick={() => (drawerOpen = false)}>
					<Icon name="x" size={16} />
				</button>
			</div>
			<dl class="kv">
				<dt>Status</dt>
				<dd>
					<span class="badge" data-tone={statusTone(selectedWo['status'] as string)}>
						{capitalize((selectedWo['status'] as string) ?? '')}
					</span>
				</dd>
				<dt>Customer</dt>
				<dd>{selectedWo['customer_name'] ?? selectedWo['customer_id'] ?? '—'}</dd>
				<dt>Site</dt>
				<dd>{selectedWo['site_id'] ?? '—'}</dd>
				<dt>Priority</dt>
				<dd>{capitalize((selectedWo['priority'] as string) ?? '')}</dd>
				<dt>Scheduled</dt>
				<dd>{formatDate(selectedWo['scheduled_date'] as string)}</dd>
				<dt>Description</dt>
				<dd>{selectedWo['description'] ?? '—'}</dd>
			</dl>
			<div style="margin-top: var(--space-5); display: flex; gap: var(--space-3)">
				<button class="btn btn--primary" onclick={startVisit}>
					<Icon name="truck" size={16} />
					Start Visit
				</button>
			</div>
		</div>
	{/if}
</div>
