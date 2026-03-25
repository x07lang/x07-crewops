<script lang="ts">
	import { getBridge } from '$lib/wasm/bridge.js';
	import { wasmEvent } from '$lib/wasm/events.js';
	import { capitalize, statusTone, formatDateTime } from '$lib/utils/format.js';

	const bridge = getBridge();
	let entities = $state<Record<string, Record<string, Record<string, unknown>>> | null>(null);
	let ui = $state<import('$lib/wasm/types.js').UiState | null>(null);

	bridge.entities.subscribe((e) => (entities = e));
	bridge.ui.subscribe((u) => (ui = u));

	let activities = $derived(
		entities?.activity_events ? Object.values(entities.activity_events) : []
	);
	let filterVal = $derived((ui?.activity_filter as string) ?? 'all');

	let filtered = $derived(
		filterVal === 'all' ? activities : activities.filter((a) => a['event_type'] === filterVal)
	);

	let eventTypes = $derived([
		...new Set(activities.map((a) => a['event_type'] as string).filter(Boolean))
	]);

	async function setFilter(val: string) {
		await bridge.dispatch(wasmEvent.change('activity_filter', val));
	}
</script>

<div class="page">
	<div class="page-header">
		<h1>Activity</h1>
		<span class="muted">{filtered.length} events</span>
	</div>

	<div class="toolbar">
		<select class="select" value={filterVal} onchange={(e) => setFilter(e.currentTarget.value)}>
			<option value="all">All Events</option>
			{#each eventTypes as et}
				<option value={et}>{capitalize(et)}</option>
			{/each}
		</select>
	</div>

	<div class="timeline">
		{#each filtered as event}
			<div class="timeline-item" data-tone={statusTone((event['event_type'] as string) ?? '')}>
				<div style="font-weight: var(--weight-medium)">{capitalize((event['event_type'] as string) ?? '')}</div>
				<div class="muted" style="font-size: var(--text-sm)">{event['description'] ?? event['summary'] ?? '—'}</div>
				<div class="faint" style="font-size: var(--text-xs)">{formatDateTime(event['timestamp'] as string)} &middot; {event['actor_name'] ?? event['actor_id'] ?? ''}</div>
			</div>
		{/each}
		{#if filtered.length === 0}
			<div class="empty-state"><p>No activity events</p></div>
		{/if}
	</div>
</div>
