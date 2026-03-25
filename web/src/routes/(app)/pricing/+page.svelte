<script lang="ts">
	import { getBridge } from '$lib/wasm/bridge.js';
	import { wasmEvent } from '$lib/wasm/events.js';
	import { capitalize, formatCurrency } from '$lib/utils/format.js';

	const bridge = getBridge();
	let entities = $state<Record<string, Record<string, Record<string, unknown>>> | null>(null);

	bridge.entities.subscribe((e) => (entities = e));

	let tab = $state<'price_books' | 'billing' | 'labor' | 'tax'>('price_books');

	let priceBooks = $derived(entities?.price_books ? Object.values(entities.price_books) : []);
	let billingPolicies = $derived(entities?.billing_policies ? Object.values(entities.billing_policies) : []);
	let laborRatePolicies = $derived(entities?.labor_rate_policies ? Object.values(entities.labor_rate_policies) : []);
	let taxRules = $derived(entities?.tax_rules ? Object.values(entities.tax_rules) : []);
</script>

<div class="page">
	<div class="page-header"><h1>Pricing</h1></div>

	<div class="page-tabs">
		<button data-active={tab === 'price_books'} onclick={() => (tab = 'price_books')}>Price Books</button>
		<button data-active={tab === 'billing'} onclick={() => (tab = 'billing')}>Billing Policies</button>
		<button data-active={tab === 'labor'} onclick={() => (tab = 'labor')}>Labor Rates</button>
		<button data-active={tab === 'tax'} onclick={() => (tab = 'tax')}>Tax Rules</button>
	</div>

	{#if tab === 'price_books'}
		<div class="card">
			<table class="table">
				<thead><tr><th>ID</th><th>Name</th><th>Branch</th><th>Items</th></tr></thead>
				<tbody>
					{#each priceBooks as pb}
						<tr><td><code>{pb['id']}</code></td><td>{pb['name'] ?? '—'}</td><td>{pb['branch_id'] ?? '—'}</td><td>{pb['item_count'] ?? '—'}</td></tr>
					{/each}
				</tbody>
			</table>
		</div>
	{:else if tab === 'billing'}
		<div class="card">
			<table class="table">
				<thead><tr><th>Policy</th><th>Branch</th><th>Terms</th></tr></thead>
				<tbody>
					{#each billingPolicies as bp}
						<tr><td><code>{bp['id']}</code></td><td>{bp['branch_id'] ?? '—'}</td><td>{bp['payment_terms'] ?? '—'}</td></tr>
					{/each}
				</tbody>
			</table>
		</div>
	{:else if tab === 'labor'}
		<div class="card">
			<table class="table">
				<thead><tr><th>Policy</th><th>Branch</th><th>Rate</th></tr></thead>
				<tbody>
					{#each laborRatePolicies as lr}
						<tr><td><code>{lr['id']}</code></td><td>{lr['branch_id'] ?? '—'}</td><td>{lr['hourly_rate_cents'] ? formatCurrency(lr['hourly_rate_cents'] as number) + '/hr' : '—'}</td></tr>
					{/each}
				</tbody>
			</table>
		</div>
	{:else}
		<div class="card">
			<table class="table">
				<thead><tr><th>Rule</th><th>Rate</th><th>Jurisdiction</th></tr></thead>
				<tbody>
					{#each taxRules as tr}
						<tr><td><code>{tr['id']}</code></td><td>{tr['rate_percent'] ? `${tr['rate_percent']}%` : '—'}</td><td>{tr['jurisdiction'] ?? '—'}</td></tr>
					{/each}
				</tbody>
			</table>
		</div>
	{/if}
</div>
