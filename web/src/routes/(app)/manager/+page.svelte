<script lang="ts">
	import { getBridge } from '$lib/wasm/bridge.js';
	import { capitalize, statusTone } from '$lib/utils/format.js';

	const bridge = getBridge();
	let entities = $state<Record<string, Record<string, Record<string, unknown>>> | null>(null);
	let summary = $state<Record<string, unknown> | null>(null);

	bridge.entities.subscribe((e) => (entities = e));
	bridge.state.subscribe((s) => {
		if (s) summary = s.summary as Record<string, unknown>;
	});

	let workOrders = $derived(
		entities?.work_orders ? Object.values(entities.work_orders) : []
	);

	let totalWo = $derived(workOrders.length);
	let completedWo = $derived(workOrders.filter((w) => w['status'] === 'completed').length);
	let inProgressWo = $derived(workOrders.filter((w) => w['status'] === 'in_progress').length);
	let overdueWo = $derived(workOrders.filter((w) => w['status'] === 'overdue').length);
	let newWo = $derived(workOrders.filter((w) => w['status'] === 'new').length);

	let statusBreakdown = $derived(() => {
		const counts: Record<string, number> = {};
		workOrders.forEach((wo) => {
			const s = (wo['status'] as string) ?? 'unknown';
			counts[s] = (counts[s] ?? 0) + 1;
		});
		return Object.entries(counts).sort(([, a], [, b]) => b - a);
	});
</script>

<div class="page">
	<div class="page-header">
		<h1>Operations Dashboard</h1>
	</div>

	<div class="kpi-grid">
		<div class="kpi" data-tone="primary">
			<div class="kpi__label">Total Work Orders</div>
			<div class="kpi__value">{totalWo}</div>
		</div>
		<div class="kpi" data-tone="success">
			<div class="kpi__label">Completed</div>
			<div class="kpi__value">{completedWo}</div>
			<div class="kpi__hint">{totalWo > 0 ? Math.round((completedWo / totalWo) * 100) : 0}% completion rate</div>
		</div>
		<div class="kpi" data-tone="warning">
			<div class="kpi__label">In Progress</div>
			<div class="kpi__value">{inProgressWo}</div>
		</div>
		<div class="kpi" data-tone="danger">
			<div class="kpi__label">Overdue</div>
			<div class="kpi__value">{overdueWo}</div>
		</div>
		<div class="kpi" data-tone="info">
			<div class="kpi__label">New / Unassigned</div>
			<div class="kpi__value">{newWo}</div>
		</div>
	</div>

	<div class="card card--padded" style="margin-top: var(--space-5)">
		<h3 style="margin: 0 0 var(--space-4)">Status Breakdown</h3>
		<table class="table">
			<thead>
				<tr><th>Status</th><th>Count</th></tr>
			</thead>
			<tbody>
				{#each statusBreakdown() as [status, count]}
					<tr>
						<td><span class="badge" data-tone={statusTone(status)}>{capitalize(status)}</span></td>
						<td>{count}</td>
					</tr>
				{/each}
			</tbody>
		</table>
	</div>
</div>
