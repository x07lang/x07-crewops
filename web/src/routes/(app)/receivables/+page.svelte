<script lang="ts">
	import { getBridge } from '$lib/wasm/bridge.js';
	import { wasmEvent } from '$lib/wasm/events.js';
	import { formatCurrency, capitalize, statusTone } from '$lib/utils/format.js';

	const bridge = getBridge();
	let entities = $state<Record<string, Record<string, Record<string, unknown>>> | null>(null);

	bridge.entities.subscribe((e) => (entities = e));

	let receivableSummaries = $derived(
		entities?.receivable_summaries ? Object.values(entities.receivable_summaries) : []
	);
	let customerStatements = $derived(
		entities?.customer_statements ? Object.values(entities.customer_statements) : []
	);

	let tab = $state<'aging' | 'statements'>('aging');
</script>

<div class="page">
	<div class="page-header"><h1>Receivables</h1></div>

	<div class="page-tabs">
		<button data-active={tab === 'aging'} onclick={() => (tab = 'aging')}>Aging Analysis</button>
		<button data-active={tab === 'statements'} onclick={() => (tab = 'statements')}>Customer Statements</button>
	</div>

	{#if tab === 'aging'}
		<div class="kpi-grid" style="margin-bottom: var(--space-5)">
			{#each receivableSummaries as rs}
				<div class="kpi" data-tone={rs['overdue_cents'] ? 'danger' : 'success'}>
					<div class="kpi__label">{rs['branch_id'] ?? rs['scope'] ?? rs['id']}</div>
					<div class="kpi__value">{formatCurrency((rs['total_outstanding_cents'] as number) ?? 0)}</div>
					<div class="kpi__hint">
						{formatCurrency((rs['overdue_cents'] as number) ?? 0)} overdue
					</div>
				</div>
			{/each}
		</div>
	{:else}
		<div class="card">
			<table class="table">
				<thead><tr><th>Customer</th><th>Balance</th><th>Status</th></tr></thead>
				<tbody>
					{#each customerStatements as cs}
						<tr>
							<td>{cs['customer_name'] ?? cs['customer_id'] ?? cs['id']}</td>
							<td>{formatCurrency((cs['balance_cents'] as number) ?? 0)}</td>
							<td><span class="badge" data-tone={statusTone(cs['status'] as string)}>{capitalize((cs['status'] as string) ?? 'open')}</span></td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	{/if}
</div>
