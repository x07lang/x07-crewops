<script lang="ts">
	import { getBridge } from '$lib/wasm/bridge.js';
	import { wasmEvent } from '$lib/wasm/events.js';
	import { capitalize, statusTone } from '$lib/utils/format.js';

	const bridge = getBridge();
	let entities = $state<Record<string, Record<string, Record<string, unknown>>> | null>(null);

	bridge.entities.subscribe((e) => (entities = e));

	let endpoints = $derived(
		entities?.integration_endpoints ? Object.values(entities.integration_endpoints) : []
	);
	let webhooks = $derived(
		entities?.webhook_subscriptions ? Object.values(entities.webhook_subscriptions) : []
	);

	let tab = $state<'endpoints' | 'webhooks'>('endpoints');
</script>

<div class="page">
	<div class="page-header"><h1>Integrations</h1></div>

	<div class="page-tabs">
		<button data-active={tab === 'endpoints'} onclick={() => (tab = 'endpoints')}>API Endpoints</button>
		<button data-active={tab === 'webhooks'} onclick={() => (tab = 'webhooks')}>Webhooks</button>
	</div>

	{#if tab === 'endpoints'}
		<div class="card">
			<table class="table">
				<thead><tr><th>Endpoint</th><th>URL</th><th>Status</th></tr></thead>
				<tbody>
					{#each endpoints as ep}
						<tr>
							<td><code>{ep['id']}</code></td>
							<td>{ep['url'] ?? ep['base_url'] ?? '—'}</td>
							<td><span class="badge" data-tone={statusTone(ep['status'] as string)}>{capitalize((ep['status'] as string) ?? 'active')}</span></td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	{:else}
		<div class="card">
			<table class="table">
				<thead><tr><th>Subscription</th><th>Event</th><th>URL</th><th>Status</th></tr></thead>
				<tbody>
					{#each webhooks as wh}
						<tr>
							<td><code>{wh['id']}</code></td>
							<td>{wh['event_type'] ?? '—'}</td>
							<td>{wh['target_url'] ?? '—'}</td>
							<td><span class="badge" data-tone={statusTone(wh['status'] as string)}>{capitalize((wh['status'] as string) ?? '')}</span></td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	{/if}
</div>
