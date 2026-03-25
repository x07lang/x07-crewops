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

	let tab = $state<'invoices' | 'history' | 'estimates' | 'requests'>('invoices');

	let invoices = $derived(entities?.invoices ? Object.values(entities.invoices) : []);
	let estimates = $derived(entities?.estimates ? Object.values(entities.estimates) : []);
	let serviceRequests = $derived(
		entities?.service_requests ? Object.values(entities.service_requests) : []
	);
	let visits = $derived(entities?.visits ? Object.values(entities.visits) : []);

	async function approveEstimate(id: string) {
		await bridge.dispatch(wasmEvent.click(`portal_approve_${id}`));
	}

	async function submitRequest() {
		await bridge.dispatch(wasmEvent.submit('portal_new_request'));
	}
</script>

<div class="page">
	<div class="page-header">
		<h1>Customer Portal</h1>
	</div>

	<div class="page-tabs">
		<button data-active={tab === 'invoices'} onclick={() => (tab = 'invoices')}>Invoices</button>
		<button data-active={tab === 'history'} onclick={() => (tab = 'history')}>Service History</button>
		<button data-active={tab === 'estimates'} onclick={() => (tab = 'estimates')}>Estimates</button>
		<button data-active={tab === 'requests'} onclick={() => (tab = 'requests')}>Requests</button>
	</div>

	{#if tab === 'invoices'}
		<div class="card">
			<table class="table">
				<thead><tr><th>Invoice</th><th>Date</th><th>Amount</th><th>Status</th></tr></thead>
				<tbody>
					{#each invoices as inv}
						<tr>
							<td><code>{inv['id']}</code></td>
							<td>{formatDate(inv['issued_date'] as string)}</td>
							<td>{formatCurrency((inv['total_cents'] as number) ?? 0)}</td>
							<td><span class="badge" data-tone={statusTone(inv['status'] as string)}>{capitalize((inv['status'] as string) ?? '')}</span></td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	{:else if tab === 'history'}
		<div class="card">
			<table class="table">
				<thead><tr><th>Visit</th><th>Date</th><th>Technician</th><th>Status</th></tr></thead>
				<tbody>
					{#each visits as v}
						<tr>
							<td><code>{v['id']}</code></td>
							<td>{formatDate(v['date'] as string)}</td>
							<td>{v['technician_name'] ?? v['technician_id'] ?? '—'}</td>
							<td><span class="badge" data-tone={statusTone(v['status'] as string)}>{capitalize((v['status'] as string) ?? '')}</span></td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	{:else if tab === 'estimates'}
		<div class="card">
			<table class="table">
				<thead><tr><th>Estimate</th><th>Amount</th><th>Status</th><th></th></tr></thead>
				<tbody>
					{#each estimates as est}
						<tr>
							<td><code>{est['id']}</code></td>
							<td>{formatCurrency((est['total_cents'] as number) ?? 0)}</td>
							<td><span class="badge" data-tone={statusTone(est['status'] as string)}>{capitalize((est['status'] as string) ?? '')}</span></td>
							<td>
								{#if est['status'] === 'awaiting_approval'}
									<button class="btn btn--primary btn--sm" onclick={() => approveEstimate(est['id'] as string)}>Approve</button>
								{/if}
							</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	{:else}
		<div style="margin-bottom: var(--space-4)">
			<button class="btn btn--primary" onclick={submitRequest}>
				<Icon name="plus" size={16} /> New Request
			</button>
		</div>
		<div class="card">
			<table class="table">
				<thead><tr><th>Request</th><th>Subject</th><th>Status</th><th>Created</th></tr></thead>
				<tbody>
					{#each serviceRequests as req}
						<tr>
							<td><code>{req['id']}</code></td>
							<td>{req['subject'] ?? '—'}</td>
							<td><span class="badge" data-tone={statusTone(req['status'] as string)}>{capitalize((req['status'] as string) ?? '')}</span></td>
							<td>{formatDate(req['created_at'] as string)}</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	{/if}
</div>
