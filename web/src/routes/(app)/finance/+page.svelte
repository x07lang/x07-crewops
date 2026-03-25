<script lang="ts">
	import { getBridge } from '$lib/wasm/bridge.js';
	import { formatCurrency } from '$lib/utils/format.js';

	const bridge = getBridge();
	let entities = $state<Record<string, Record<string, Record<string, unknown>>> | null>(null);

	bridge.entities.subscribe((e) => (entities = e));

	let invoices = $derived(entities?.invoices ? Object.values(entities.invoices) : []);

	let totalRevenue = $derived(
		invoices.reduce((sum, inv) => sum + ((inv['total_cents'] as number) ?? 0), 0)
	);
	let paidTotal = $derived(
		invoices
			.filter((i) => i['status'] === 'paid')
			.reduce((sum, inv) => sum + ((inv['total_cents'] as number) ?? 0), 0)
	);
	let outstandingTotal = $derived(
		invoices
			.filter((i) => i['status'] !== 'paid' && i['status'] !== 'cancelled')
			.reduce((sum, inv) => sum + ((inv['total_cents'] as number) ?? 0), 0)
	);
	let overdueTotal = $derived(
		invoices
			.filter((i) => i['status'] === 'overdue')
			.reduce((sum, inv) => sum + ((inv['total_cents'] as number) ?? 0), 0)
	);
</script>

<div class="page">
	<div class="page-header">
		<h1>Finance Overview</h1>
	</div>

	<div class="kpi-grid">
		<div class="kpi" data-tone="primary">
			<div class="kpi__label">Total Invoiced</div>
			<div class="kpi__value">{formatCurrency(totalRevenue)}</div>
			<div class="kpi__hint">{invoices.length} invoices</div>
		</div>
		<div class="kpi" data-tone="success">
			<div class="kpi__label">Collected</div>
			<div class="kpi__value">{formatCurrency(paidTotal)}</div>
		</div>
		<div class="kpi" data-tone="warning">
			<div class="kpi__label">Outstanding</div>
			<div class="kpi__value">{formatCurrency(outstandingTotal)}</div>
		</div>
		<div class="kpi" data-tone="danger">
			<div class="kpi__label">Overdue</div>
			<div class="kpi__value">{formatCurrency(overdueTotal)}</div>
		</div>
	</div>
</div>
