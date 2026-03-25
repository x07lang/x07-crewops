<script lang="ts">
	import { getBridge } from '$lib/wasm/bridge.js';
	import { wasmEvent } from '$lib/wasm/events.js';
	import Icon from '$lib/icons/Icon.svelte';
	import { capitalize, statusTone, formatDate } from '$lib/utils/format.js';

	const bridge = getBridge();
	let entities = $state<Record<string, Record<string, Record<string, unknown>>> | null>(null);
	let ui = $state<import('$lib/wasm/types.js').UiState | null>(null);

	bridge.entities.subscribe((e) => (entities = e));
	bridge.ui.subscribe((u) => (ui = u));

	let workOrders = $derived(
		entities?.work_orders ? Object.values(entities.work_orders) : []
	);
	let statusFilter = $derived((ui?.dispatch_status_filter as string) ?? 'all');
	let branchFilter = $derived((ui?.dispatch_branch_filter as string) ?? 'all');

	let filtered = $derived(
		workOrders.filter((wo) => {
			if (statusFilter !== 'all' && wo['status'] !== statusFilter) return false;
			if (branchFilter !== 'all' && wo['branch_id'] !== branchFilter) return false;
			return true;
		})
	);

	let branches = $derived([
		...new Set(workOrders.map((wo) => wo['branch_id'] as string).filter(Boolean))
	]);

	async function setStatusFilter(val: string) {
		await bridge.dispatch(wasmEvent.change('dispatch_status_filter', val));
	}

	async function setBranchFilter(val: string) {
		await bridge.dispatch(wasmEvent.change('dispatch_branch_filter', val));
	}

	let selectedId = $derived((ui?.selected_work_order_id as string) ?? null);
	let drawerOpen = $state(false);
	let selectedWo = $derived(
		selectedId && entities?.work_orders ? entities.work_orders[selectedId] ?? null : null
	);

	async function selectWo(id: string) {
		await bridge.dispatch(wasmEvent.click(`wo_${id}`));
		drawerOpen = true;
	}

	async function assignWo(woId: string) {
		await bridge.dispatch(wasmEvent.click(`assign_${woId}`));
	}
</script>

<div class="page">
	<div class="page-header">
		<h1>Dispatch Board</h1>
		<span class="muted">{filtered.length} of {workOrders.length} orders</span>
	</div>

	<div class="toolbar">
		<select
			class="select"
			value={statusFilter}
			onchange={(e) => setStatusFilter(e.currentTarget.value)}
			data-testid="filter-status"
		>
			<option value="all">All Statuses</option>
			<option value="new">New</option>
			<option value="assigned">Assigned</option>
			<option value="in_progress">In Progress</option>
			<option value="completed">Completed</option>
		</select>
		<select
			class="select"
			value={branchFilter}
			onchange={(e) => setBranchFilter(e.currentTarget.value)}
			data-testid="filter-branch"
		>
			<option value="all">All Branches</option>
			{#each branches as b}
				<option value={b}>{b}</option>
			{/each}
		</select>
	</div>

	<div class="card">
		<table class="table">
			<thead>
				<tr>
					<th>ID</th>
					<th>Customer</th>
					<th>Status</th>
					<th>Priority</th>
					<th>Assigned To</th>
					<th>Date</th>
					<th></th>
				</tr>
			</thead>
			<tbody>
				{#each filtered as wo}
					<tr
						data-selected={wo['id'] === selectedId}
						onclick={() => selectWo(wo['id'] as string)}
						data-testid="dispatch-row-{wo['id']}"
					>
						<td><code>{wo['id']}</code></td>
						<td>{wo['customer_name'] ?? wo['customer_id'] ?? '—'}</td>
						<td>
							<span class="badge" data-tone={statusTone(wo['status'] as string)}>
								{capitalize((wo['status'] as string) ?? '')}
							</span>
						</td>
						<td>{capitalize((wo['priority'] as string) ?? 'normal')}</td>
						<td>{wo['assigned_to'] ?? '—'}</td>
						<td>{formatDate(wo['scheduled_date'] as string)}</td>
						<td>
							{#if !wo['assigned_to']}
								<button
									class="btn btn--primary btn--sm"
									onclick={(e) => { e.stopPropagation(); assignWo(wo['id'] as string); }}
								>
									Assign
								</button>
							{/if}
						</td>
					</tr>
				{/each}
			</tbody>
		</table>
	</div>

	{#if drawerOpen && selectedWo}
		<button class="drawer-backdrop" aria-label="Close drawer" onclick={() => (drawerOpen = false)}></button>
		<div class="drawer" data-testid="dispatch-detail-drawer">
			<div class="drawer-header">
				<h2>Work Order {selectedWo['id']}</h2>
				<button class="btn btn--ghost btn--sm" onclick={() => (drawerOpen = false)}>
					<Icon name="x" size={16} />
				</button>
			</div>
			<dl class="kv">
				<dt>Status</dt>
				<dd><span class="badge" data-tone={statusTone(selectedWo['status'] as string)}>{capitalize((selectedWo['status'] as string) ?? '')}</span></dd>
				<dt>Customer</dt>
				<dd>{selectedWo['customer_name'] ?? selectedWo['customer_id']}</dd>
				<dt>Site</dt>
				<dd>{selectedWo['site_id'] ?? '—'}</dd>
				<dt>Assigned To</dt>
				<dd>{selectedWo['assigned_to'] ?? 'Unassigned'}</dd>
				<dt>SLA Deadline</dt>
				<dd>{formatDate(selectedWo['sla_deadline'] as string)}</dd>
				<dt>Description</dt>
				<dd>{selectedWo['description'] ?? '—'}</dd>
			</dl>
		</div>
	{/if}
</div>
