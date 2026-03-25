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

	let reviewItems = $derived(
		entities?.review_queue_items ? Object.values(entities.review_queue_items) : []
	);
	let filterVal = $derived((ui?.review_filter as string) ?? 'awaiting_review');

	let filtered = $derived(
		filterVal === 'all'
			? reviewItems
			: reviewItems.filter((r) => r['status'] === filterVal)
	);

	let selectedId = $derived((ui?.selected_review_visit_id as string) ?? null);
	let drawerOpen = $state(false);
	let selectedItem = $derived(
		selectedId && entities?.review_queue_items
			? entities.review_queue_items[selectedId] ?? null
			: null
	);

	async function selectItem(id: string) {
		await bridge.dispatch(wasmEvent.click(`review_${id}`));
		drawerOpen = true;
	}

	async function approve(id: string) {
		await bridge.dispatch(wasmEvent.click(`approve_${id}`));
		drawerOpen = false;
	}

	async function reject(id: string) {
		await bridge.dispatch(wasmEvent.click(`reject_${id}`));
		drawerOpen = false;
	}

	async function setFilter(val: string) {
		await bridge.dispatch(wasmEvent.change('review_filter', val));
	}
</script>

<div class="page">
	<div class="page-header">
		<h1>Review Queue</h1>
		<span class="muted">{filtered.length} items</span>
	</div>

	<div class="toolbar">
		<select
			class="select"
			value={filterVal}
			onchange={(e) => setFilter(e.currentTarget.value)}
			data-testid="filter-review"
		>
			<option value="all">All</option>
			<option value="awaiting_review">Awaiting Review</option>
			<option value="approved">Approved</option>
			<option value="rejected">Rejected</option>
		</select>
	</div>

	<div class="card">
		<table class="table">
			<thead>
				<tr>
					<th>Visit</th>
					<th>Technician</th>
					<th>Work Order</th>
					<th>Status</th>
					<th>Submitted</th>
				</tr>
			</thead>
			<tbody>
				{#each filtered as item}
					<tr
						data-selected={item['id'] === selectedId}
						onclick={() => selectItem(item['id'] as string)}
						data-testid="review-row-{item['id']}"
					>
						<td><code>{item['visit_id'] ?? item['id']}</code></td>
						<td>{item['technician_name'] ?? item['technician_id'] ?? '—'}</td>
						<td><code>{item['work_order_id'] ?? '—'}</code></td>
						<td>
							<span class="badge" data-tone={statusTone(item['status'] as string)}>
								{capitalize((item['status'] as string) ?? '')}
							</span>
						</td>
						<td>{formatDateTime(item['submitted_at'] as string)}</td>
					</tr>
				{/each}
			</tbody>
		</table>
	</div>

	{#if drawerOpen && selectedItem}
		<button class="drawer-backdrop" aria-label="Close drawer" onclick={() => (drawerOpen = false)}></button>
		<div class="drawer" data-testid="review-detail-drawer">
			<div class="drawer-header">
				<h2>Review: {selectedItem['visit_id'] ?? selectedItem['id']}</h2>
				<button class="btn btn--ghost btn--sm" onclick={() => (drawerOpen = false)}>
					<Icon name="x" size={16} />
				</button>
			</div>
			<dl class="kv">
				<dt>Technician</dt>
				<dd>{selectedItem['technician_name'] ?? selectedItem['technician_id']}</dd>
				<dt>Work Order</dt>
				<dd>{selectedItem['work_order_id']}</dd>
				<dt>Status</dt>
				<dd><span class="badge" data-tone={statusTone(selectedItem['status'] as string)}>{capitalize((selectedItem['status'] as string) ?? '')}</span></dd>
				<dt>Notes</dt>
				<dd>{selectedItem['notes'] ?? '—'}</dd>
			</dl>
			{#if selectedItem['status'] === 'awaiting_review'}
				<div style="margin-top: var(--space-5); display: flex; gap: var(--space-3)">
					<button class="btn btn--primary" onclick={() => approve(selectedItem!['id'] as string)}>
						<Icon name="check" size={16} /> Approve
					</button>
					<button class="btn btn--danger" onclick={() => reject(selectedItem!['id'] as string)}>
						<Icon name="x" size={16} /> Reject
					</button>
				</div>
			{/if}
		</div>
	{/if}
</div>
