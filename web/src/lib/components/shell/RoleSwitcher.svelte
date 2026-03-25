<script lang="ts">
	import type { Role } from '$lib/wasm/types.js';
	import { ROLE_LABELS } from '$lib/types/roles.js';
	import Icon from '$lib/icons/Icon.svelte';

	type Props = {
		currentRole: Role;
		onswitch: (role: Role) => void;
	};

	let { currentRole, onswitch }: Props = $props();
	let open = $state(false);

	const roles: Role[] = [
		'technician',
		'dispatcher',
		'supervisor',
		'manager',
		'portal_user',
		'enterprise_admin'
	];

	function select(role: Role) {
		open = false;
		if (role !== currentRole) onswitch(role);
	}
</script>

<div class="role-switcher" data-testid="role-switcher">
	<button class="role-switcher__trigger btn btn--ghost btn--sm" onclick={() => (open = !open)}>
		<Icon name="user" size={16} />
		{ROLE_LABELS[currentRole]}
		<Icon name="chevron-down" size={14} />
	</button>

	{#if open}
		<button class="role-switcher__backdrop" aria-label="Close menu" onclick={() => (open = false)}></button>
		<div class="role-switcher__menu">
			{#each roles as role}
				<button
					class="role-switcher__item"
					data-active={role === currentRole}
					onclick={() => select(role)}
					data-testid="role-{role}"
				>
					{ROLE_LABELS[role]}
				</button>
			{/each}
		</div>
	{/if}
</div>

<style>
	.role-switcher {
		position: relative;
	}

	.role-switcher__backdrop {
		position: fixed;
		inset: 0;
		background: transparent;
		border: none;
		z-index: 50;
		cursor: default;
	}

	.role-switcher__menu {
		position: absolute;
		top: 100%;
		right: 0;
		margin-top: var(--space-1);
		min-width: 180px;
		background: var(--c-surface);
		border: 1px solid var(--c-border);
		border-radius: var(--radius-md);
		box-shadow: var(--shadow-2);
		z-index: 51;
		overflow: hidden;
	}

	.role-switcher__item {
		display: block;
		width: 100%;
		padding: var(--space-2) var(--space-4);
		border: none;
		background: none;
		text-align: left;
		font-size: var(--text-sm);
		color: var(--c-text);
		cursor: pointer;
	}

	.role-switcher__item:hover {
		background: var(--c-surface-2);
	}

	.role-switcher__item[data-active='true'] {
		color: var(--c-primary);
		font-weight: var(--weight-medium);
	}
</style>
