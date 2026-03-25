<script lang="ts">
	import { getBridge } from '$lib/wasm/bridge.js';
	import { wasmEvent } from '$lib/wasm/events.js';
	import Icon from '$lib/icons/Icon.svelte';
	import { capitalize, statusTone, formatDate, formatCurrency } from '$lib/utils/format.js';

	const bridge = getBridge();
	let entities = $state<Record<string, Record<string, Record<string, unknown>>> | null>(null);

	bridge.entities.subscribe((e) => (entities = e));

	let estimates = $derived(entities?.estimates ? Object.values(entities.estimates) : []);
	let drawerOpen = $state(false);
	let selectedEst = $state<Record<string, unknown> | null>(null);

	async function selectEst(id: string) {
		await bridge.dispatch(wasmEvent.click(`estimate_${id}`));
		selectedEst = entities?.estimates?.[id] ?? null;
		drawerOpen = true;
	}
</script>

<div class="page">
	<div class="page-header"><h1>Estimates</h1><span class="muted">{estimates.length} estimates</span></div>

	<div class="card">
		<table class="table">
			<thead><tr><th>Estimate</th><th>Customer</th><th>Amount</th><th>Status</th><th>Created</th></tr></thead>
			<tbody>
				{#each estimates as est}
					<tr onclick={() => selectEst(est['id'] as string)}>
						<td><code>{est['id']}</code></td>
						<td>{est['customer_name'] ?? est['customer_id'] ?? '—'}</td>
						<td>{formatCurrency((est['total_cents'] as number) ?? 0)}</td>
						<td><span class="badge" data-tone={statusTone(est['status'] as string)}>{capitalize((est['status'] as string) ?? '')}</span></td>
						<td>{formatDate(est['created_at'] as string)}</td>
					</tr>
				{/each}
			</tbody>
		</table>
	</div>

	{#if drawerOpen && selectedEst}
		<button class="drawer-backdrop" aria-label="Close drawer" onclick={() => (drawerOpen = false)}></button>
		<div class="drawer">
			<div class="drawer-header">
				<h2>Estimate {selectedEst['id']}</h2>
				<button class="btn btn--ghost btn--sm" onclick={() => (drawerOpen = false)}><Icon name="x" size={16} /></button>
			</div>
			<dl class="kv">
				<dt>Customer</dt><dd>{selectedEst['customer_name'] ?? selectedEst['customer_id']}</dd>
				<dt>Amount</dt><dd>{formatCurrency((selectedEst['total_cents'] as number) ?? 0)}</dd>
				<dt>Status</dt><dd><span class="badge" data-tone={statusTone(selectedEst['status'] as string)}>{capitalize((selectedEst['status'] as string) ?? '')}</span></dd>
				<dt>Version</dt><dd>{selectedEst['version'] ?? 1}</dd>
				<dt>Description</dt><dd>{selectedEst['description'] ?? '—'}</dd>
			</dl>
		</div>
	{/if}
</div>
