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

	let tab = $state<'tenants' | 'roles' | 'health'>('tenants');

	let tenants = $derived(entities?.tenants ? Object.values(entities.tenants) : []);
	let roleDefinitions = $derived(
		entities?.role_definitions ? Object.values(entities.role_definitions) : []
	);
	let selectedTenantId = $derived((ui?.selected_tenant_id as string) ?? null);
	let selectedTenant = $derived(
		selectedTenantId && entities?.tenants ? entities.tenants[selectedTenantId] ?? null : null
	);
	let drawerOpen = $state(false);

	async function selectTenant(id: string) {
		await bridge.dispatch(wasmEvent.click(`tenant_${id}`));
		drawerOpen = true;
	}
</script>

<div class="page">
	<div class="page-header">
		<h1>Enterprise Administration</h1>
	</div>

	<div class="page-tabs">
		<button data-active={tab === 'tenants'} onclick={() => (tab = 'tenants')}>Tenants</button>
		<button data-active={tab === 'roles'} onclick={() => (tab = 'roles')}>Roles</button>
		<button data-active={tab === 'health'} onclick={() => (tab = 'health')}>Health</button>
	</div>

	{#if tab === 'tenants'}
		<div class="card">
			<table class="table">
				<thead><tr><th>Tenant</th><th>Name</th><th>Status</th><th>Workspaces</th></tr></thead>
				<tbody>
					{#each tenants as t}
						<tr data-selected={t['id'] === selectedTenantId} onclick={() => selectTenant(t['id'] as string)}>
							<td><code>{t['id']}</code></td>
							<td>{t['name'] ?? '—'}</td>
							<td><span class="badge" data-tone={statusTone(t['status'] as string)}>{capitalize((t['status'] as string) ?? '')}</span></td>
							<td>{t['workspace_count'] ?? '—'}</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	{:else if tab === 'roles'}
		<div class="card">
			<table class="table">
				<thead><tr><th>Role</th><th>Permissions</th><th>Users</th></tr></thead>
				<tbody>
					{#each roleDefinitions as rd}
						<tr>
							<td>{rd['name'] ?? rd['id']}</td>
							<td>{(rd['permissions'] as string[])?.length ?? 0}</td>
							<td>{rd['user_count'] ?? '—'}</td>
						</tr>
					{/each}
				</tbody>
			</table>
		</div>
	{:else}
		<div class="kpi-grid">
			{#each tenants as t}
				<div class="kpi" data-tone={statusTone((t['health_status'] as string) ?? 'active')}>
					<div class="kpi__label">{t['name'] ?? t['id']}</div>
					<div class="kpi__value">{capitalize((t['health_status'] as string) ?? 'Healthy')}</div>
					<div class="kpi__hint">{t['workspace_count'] ?? 0} workspaces</div>
				</div>
			{/each}
		</div>
	{/if}

	{#if drawerOpen && selectedTenant}
		<button class="drawer-backdrop" aria-label="Close drawer" onclick={() => (drawerOpen = false)}></button>
		<div class="drawer" data-testid="tenant-detail-drawer">
			<div class="drawer-header">
				<h2>{selectedTenant['name'] ?? selectedTenant['id']}</h2>
				<button class="btn btn--ghost btn--sm" onclick={() => (drawerOpen = false)}>
					<Icon name="x" size={16} />
				</button>
			</div>
			<dl class="kv">
				<dt>ID</dt><dd><code>{selectedTenant['id']}</code></dd>
				<dt>Status</dt><dd><span class="badge" data-tone={statusTone(selectedTenant['status'] as string)}>{capitalize((selectedTenant['status'] as string) ?? '')}</span></dd>
				<dt>Workspaces</dt><dd>{selectedTenant['workspace_count'] ?? '—'}</dd>
				<dt>Branding</dt><dd>{selectedTenant['branding_theme'] ?? 'Default'}</dd>
			</dl>
		</div>
	{/if}
</div>
