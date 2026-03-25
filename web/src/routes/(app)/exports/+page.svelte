<script lang="ts">
	import { getBridge } from '$lib/wasm/bridge.js';
	import { wasmEvent } from '$lib/wasm/events.js';
	import Icon from '$lib/icons/Icon.svelte';
	import { capitalize, statusTone, formatDateTime } from '$lib/utils/format.js';

	const bridge = getBridge();
	let entities = $state<Record<string, Record<string, Record<string, unknown>>> | null>(null);
	let ui = $state<import('$lib/wasm/types.js').UiState | null>(null);

	bridge.entities.subscribe((e) => (entities = e));
	bridge.ui.subscribe((u) => (ui = u));

	let exportJobs = $derived(entities?.export_jobs ? Object.values(entities.export_jobs) : []);
	let exportKind = $derived((ui?.export_kind as string) ?? 'invoices');
	let exportFormat = $derived((ui?.export_format as string) ?? 'csv');

	async function createExport() {
		await bridge.dispatch(wasmEvent.submit('create_export'));
	}

	async function retryExport(id: string) {
		await bridge.dispatch(wasmEvent.click(`retry_export_${id}`));
	}

	async function setKind(val: string) {
		await bridge.dispatch(wasmEvent.change('export_kind', val));
	}

	async function setFormat(val: string) {
		await bridge.dispatch(wasmEvent.change('export_format', val));
	}
</script>

<div class="page">
	<div class="page-header"><h1>Exports</h1></div>

	<div class="card card--padded" style="margin-bottom: var(--space-5)">
		<h3 style="margin: 0 0 var(--space-3)">New Export</h3>
		<div class="toolbar">
			<select class="select" value={exportKind} onchange={(e) => setKind(e.currentTarget.value)}>
				<option value="invoices">Invoices</option>
				<option value="work_orders">Work Orders</option>
				<option value="customers">Customers</option>
			</select>
			<select class="select" value={exportFormat} onchange={(e) => setFormat(e.currentTarget.value)}>
				<option value="csv">CSV</option>
				<option value="json">JSON</option>
			</select>
			<button class="btn btn--primary" onclick={createExport}>
				<Icon name="download" size={16} /> Export
			</button>
		</div>
	</div>

	<div class="card">
		<table class="table">
			<thead><tr><th>Job</th><th>Kind</th><th>Format</th><th>Status</th><th>Created</th><th></th></tr></thead>
			<tbody>
				{#each exportJobs as ej}
					<tr>
						<td><code>{ej['id']}</code></td>
						<td>{capitalize((ej['kind'] as string) ?? '')}</td>
						<td>{((ej['format'] as string) ?? '').toUpperCase()}</td>
						<td><span class="badge" data-tone={statusTone(ej['status'] as string)}>{capitalize((ej['status'] as string) ?? '')}</span></td>
						<td>{formatDateTime(ej['created_at'] as string)}</td>
						<td>
							{#if ej['status'] === 'failed'}
								<button class="btn btn--ghost btn--sm" onclick={() => retryExport(ej['id'] as string)}>Retry</button>
							{/if}
						</td>
					</tr>
				{/each}
			</tbody>
		</table>
	</div>
</div>
