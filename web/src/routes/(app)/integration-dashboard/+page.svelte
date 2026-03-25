<script lang="ts">
	import { getBridge } from '$lib/wasm/bridge.js';
	import { wasmEvent } from '$lib/wasm/events.js';
	import Icon from '$lib/icons/Icon.svelte';
	import { capitalize, statusTone, formatDateTime } from '$lib/utils/format.js';

	const bridge = getBridge();
	let entities = $state<Record<string, Record<string, Record<string, unknown>>> | null>(null);

	bridge.entities.subscribe((e) => (entities = e));

	let tab = $state<'connectors' | 'sync' | 'deliveries'>('connectors');

	let connectorInstances = $derived(
		entities?.connector_instances ? Object.values(entities.connector_instances) : []
	);
	let syncJobs = $derived(entities?.sync_jobs ? Object.values(entities.sync_jobs) : []);
	let deliveryRecords = $derived(
		entities?.delivery_records ? Object.values(entities.delivery_records) : []
	);

	let healthyCount = $derived(
		connectorInstances.filter((c) => c['health_status'] === 'healthy').length
	);

	async function retryDelivery(id: string) {
		await bridge.dispatch(wasmEvent.click(`retry_delivery_${id}`));
	}

	async function syncConnector(id: string) {
		await bridge.dispatch(wasmEvent.click(`sync_connector_${id}`));
	}
</script>

<div class="page">
	<div class="page-header"><h1>Connector Dashboard</h1></div>

	<div class="kpi-grid" style="margin-bottom: var(--space-5)">
		<div class="kpi" data-tone="primary">
			<div class="kpi__label">Connectors</div>
			<div class="kpi__value">{connectorInstances.length}</div>
		</div>
		<div class="kpi" data-tone="success">
			<div class="kpi__label">Healthy</div>
			<div class="kpi__value">{healthyCount}</div>
		</div>
		<div class="kpi" data-tone="danger">
			<div class="kpi__label">Unhealthy</div>
			<div class="kpi__value">{connectorInstances.length - healthyCount}</div>
		</div>
	</div>

	<div class="page-tabs">
		<button data-active={tab === 'connectors'} onclick={() => (tab = 'connectors')}>Connectors</button>
		<button data-active={tab === 'sync'} onclick={() => (tab = 'sync')}>Sync Jobs</button>
		<button data-active={tab === 'deliveries'} onclick={() => (tab = 'deliveries')}>Deliveries</button>
	</div>

	{#if tab === 'connectors'}
		<div class="card">
			<table class="table">
				<thead><tr><th>Instance</th><th>Provider</th><th>Health</th><th></th></tr></thead>
				<tbody>
					{#each connectorInstances as ci}
						<tr>
							<td><code>{ci['id']}</code></td>
							<td>{ci['provider'] ?? '—'}</td>
							<td>
								<span class="status-dot" data-tone={statusTone((ci['health_status'] as string) ?? '')}></span>
								{capitalize((ci['health_status'] as string) ?? '')}
							</td>
							<td>
								<button class="btn btn--ghost btn--sm" onclick={() => syncConnector(ci['id'] as string)}>
									<Icon name="repeat" size={14} /> Sync
								</button>
							</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	{:else if tab === 'sync'}
		<div class="card">
			<table class="table">
				<thead><tr><th>Job</th><th>Connector</th><th>Status</th><th>Started</th></tr></thead>
				<tbody>
					{#each syncJobs as sj}
						<tr>
							<td><code>{sj['id']}</code></td>
							<td>{sj['connector_instance_id']}</td>
							<td><span class="badge" data-tone={statusTone(sj['status'] as string)}>{capitalize((sj['status'] as string) ?? '')}</span></td>
							<td>{formatDateTime(sj['started_at'] as string)}</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	{:else}
		<div class="card">
			<table class="table">
				<thead><tr><th>Delivery</th><th>Connector</th><th>Status</th><th>Timestamp</th><th></th></tr></thead>
				<tbody>
					{#each deliveryRecords as dr}
						<tr>
							<td><code>{dr['id']}</code></td>
							<td>{dr['connector_instance_id']}</td>
							<td><span class="badge" data-tone={statusTone(dr['status'] as string)}>{capitalize((dr['status'] as string) ?? '')}</span></td>
							<td>{formatDateTime(dr['timestamp'] as string)}</td>
							<td>
								{#if dr['status'] === 'failed'}
									<button class="btn btn--ghost btn--sm" onclick={() => retryDelivery(dr['id'] as string)}>Retry</button>
								{/if}
							</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	{/if}
</div>
