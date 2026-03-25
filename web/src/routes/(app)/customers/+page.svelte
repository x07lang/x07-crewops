<script lang="ts">
	import { getBridge } from '$lib/wasm/bridge.js';
	import { wasmEvent } from '$lib/wasm/events.js';
	import Icon from '$lib/icons/Icon.svelte';
	import { capitalize, statusTone } from '$lib/utils/format.js';

	const bridge = getBridge();
	let entities = $state<Record<string, Record<string, Record<string, unknown>>> | null>(null);
	let ui = $state<import('$lib/wasm/types.js').UiState | null>(null);

	bridge.entities.subscribe((e) => (entities = e));
	bridge.ui.subscribe((u) => (ui = u));

	let customers = $derived(entities?.customers ? Object.values(entities.customers) : []);
	let searchTerm = $state('');

	let filtered = $derived(
		searchTerm
			? customers.filter(
					(c) =>
						((c['name'] as string) ?? '').toLowerCase().includes(searchTerm.toLowerCase()) ||
						((c['id'] as string) ?? '').toLowerCase().includes(searchTerm.toLowerCase())
				)
			: customers
	);

	let selectedId = $derived((ui?.selected_customer_id as string) ?? null);
	let selectedCustomer = $derived(
		selectedId && entities?.customers ? entities.customers[selectedId] ?? null : null
	);
	let drawerOpen = $state(false);

	async function selectCustomer(id: string) {
		await bridge.dispatch(wasmEvent.click(`customer_${id}`));
		drawerOpen = true;
	}
</script>

<div class="page">
	<div class="page-header">
		<h1>Customers</h1>
		<span class="muted">{filtered.length} of {customers.length}</span>
	</div>

	<div class="toolbar">
		<input
			class="input"
			type="search"
			placeholder="Search customers..."
			bind:value={searchTerm}
			data-testid="customer-search"
		/>
	</div>

	<div class="card">
		<table class="table">
			<thead><tr><th>ID</th><th>Name</th><th>Branch</th><th>Status</th></tr></thead>
			<tbody>
				{#each filtered as c}
					<tr data-selected={c['id'] === selectedId} onclick={() => selectCustomer(c['id'] as string)}>
						<td><code>{c['id']}</code></td>
						<td>{c['name'] ?? '—'}</td>
						<td>{c['branch_id'] ?? '—'}</td>
						<td><span class="badge" data-tone={statusTone(c['status'] as string)}>{capitalize((c['status'] as string) ?? 'active')}</span></td>
					</tr>
				{/each}
			</tbody>
		</table>
	</div>

	{#if drawerOpen && selectedCustomer}
		<button class="drawer-backdrop" aria-label="Close drawer" onclick={() => (drawerOpen = false)}></button>
		<div class="drawer" data-testid="customer-detail-drawer">
			<div class="drawer-header">
				<h2>{selectedCustomer['name'] ?? selectedCustomer['id']}</h2>
				<button class="btn btn--ghost btn--sm" onclick={() => (drawerOpen = false)}>
					<Icon name="x" size={16} />
				</button>
			</div>
			<dl class="kv">
				<dt>ID</dt><dd><code>{selectedCustomer['id']}</code></dd>
				<dt>Name</dt><dd>{selectedCustomer['name']}</dd>
				<dt>Branch</dt><dd>{selectedCustomer['branch_id']}</dd>
				<dt>Email</dt><dd>{selectedCustomer['email'] ?? '—'}</dd>
				<dt>Phone</dt><dd>{selectedCustomer['phone'] ?? '—'}</dd>
				<dt>Address</dt><dd>{selectedCustomer['address'] ?? '—'}</dd>
			</dl>
		</div>
	{/if}
</div>
