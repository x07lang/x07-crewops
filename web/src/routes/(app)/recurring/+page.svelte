<script lang="ts">
	import { getBridge } from '$lib/wasm/bridge.js';
	import { wasmEvent } from '$lib/wasm/events.js';
	import { capitalize, statusTone, formatDate } from '$lib/utils/format.js';

	const bridge = getBridge();
	let entities = $state<Record<string, Record<string, Record<string, unknown>>> | null>(null);

	bridge.entities.subscribe((e) => (entities = e));

	let recurringPlans = $derived(
		entities?.recurring_plans ? Object.values(entities.recurring_plans) : []
	);

	async function skipPlan(id: string) {
		await bridge.dispatch(wasmEvent.click(`skip_recurring_${id}`));
	}

	async function generateWork(id: string) {
		await bridge.dispatch(wasmEvent.click(`generate_recurring_${id}`));
	}
</script>

<div class="page">
	<div class="page-header"><h1>Recurring Work</h1><span class="muted">{recurringPlans.length} plans</span></div>

	<div class="card">
		<table class="table">
			<thead><tr><th>Plan</th><th>Agreement</th><th>Frequency</th><th>Status</th><th>Next Date</th><th></th></tr></thead>
			<tbody>
				{#each recurringPlans as rp}
					<tr>
						<td><code>{rp['id']}</code></td>
						<td><code>{rp['agreement_id'] ?? '—'}</code></td>
						<td>{capitalize((rp['frequency'] as string) ?? '')}</td>
						<td><span class="badge" data-tone={statusTone(rp['status'] as string)}>{capitalize((rp['status'] as string) ?? '')}</span></td>
						<td>{formatDate(rp['next_date'] as string)}</td>
						<td style="display: flex; gap: var(--space-2)">
							<button class="btn btn--primary btn--sm" onclick={() => generateWork(rp['id'] as string)}>Generate</button>
							<button class="btn btn--ghost btn--sm" onclick={() => skipPlan(rp['id'] as string)}>Skip</button>
						</td>
					</tr>
				{/each}
			</tbody>
		</table>
	</div>
</div>
