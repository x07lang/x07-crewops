<script lang="ts">
	import { getBridge } from '$lib/wasm/bridge.js';
	import { wasmEvent } from '$lib/wasm/events.js';
	import Icon from '$lib/icons/Icon.svelte';
	import { capitalize, statusTone, formatDate } from '$lib/utils/format.js';

	const bridge = getBridge();
	let entities = $state<Record<string, Record<string, Record<string, unknown>>> | null>(null);

	bridge.entities.subscribe((e) => (entities = e));

	let agreements = $derived(entities?.agreements ? Object.values(entities.agreements) : []);
	let drawerOpen = $state(false);
	let selectedAg = $state<Record<string, unknown> | null>(null);

	async function selectAg(id: string) {
		await bridge.dispatch(wasmEvent.click(`contract_${id}`));
		selectedAg = entities?.agreements?.[id] ?? null;
		drawerOpen = true;
	}

	async function pauseContract(id: string) {
		await bridge.dispatch(wasmEvent.click(`pause_contract_${id}`));
	}

	async function renewContract(id: string) {
		await bridge.dispatch(wasmEvent.click(`renew_contract_${id}`));
	}
</script>

<div class="page">
	<div class="page-header"><h1>Contracts</h1><span class="muted">{agreements.length} agreements</span></div>

	<div class="card">
		<table class="table">
			<thead><tr><th>Agreement</th><th>Customer</th><th>Status</th><th>Start</th><th>End</th><th></th></tr></thead>
			<tbody>
				{#each agreements as ag}
					<tr onclick={() => selectAg(ag['id'] as string)}>
						<td><code>{ag['id']}</code></td>
						<td>{ag['customer_name'] ?? ag['customer_id'] ?? '—'}</td>
						<td><span class="badge" data-tone={statusTone(ag['status'] as string)}>{capitalize((ag['status'] as string) ?? '')}</span></td>
						<td>{formatDate(ag['start_date'] as string)}</td>
						<td>{formatDate(ag['end_date'] as string)}</td>
						<td>
							{#if ag['status'] === 'active'}
								<button class="btn btn--ghost btn--sm" onclick={(e) => { e.stopPropagation(); pauseContract(ag['id'] as string); }}>Pause</button>
							{/if}
						</td>
					</tr>
				{/each}
			</tbody>
		</table>
	</div>

	{#if drawerOpen && selectedAg}
		<button class="drawer-backdrop" aria-label="Close drawer" onclick={() => (drawerOpen = false)}></button>
		<div class="drawer">
			<div class="drawer-header">
				<h2>Agreement {selectedAg['id']}</h2>
				<button class="btn btn--ghost btn--sm" onclick={() => (drawerOpen = false)}><Icon name="x" size={16} /></button>
			</div>
			<dl class="kv">
				<dt>Customer</dt><dd>{selectedAg['customer_name'] ?? selectedAg['customer_id']}</dd>
				<dt>Status</dt><dd><span class="badge" data-tone={statusTone(selectedAg['status'] as string)}>{capitalize((selectedAg['status'] as string) ?? '')}</span></dd>
				<dt>Period</dt><dd>{formatDate(selectedAg['start_date'] as string)} — {formatDate(selectedAg['end_date'] as string)}</dd>
				<dt>Description</dt><dd>{selectedAg['description'] ?? '—'}</dd>
			</dl>
			<div style="margin-top: var(--space-5); display: flex; gap: var(--space-3)">
				<button class="btn btn--primary" onclick={() => renewContract(selectedAg!['id'] as string)}>
					<Icon name="repeat" size={16} /> Renew
				</button>
			</div>
		</div>
	{/if}
</div>
