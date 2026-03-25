<script lang="ts">
	import type { Role } from '$lib/wasm/types.js';
	import { NAV_BY_ROLE } from '$lib/types/roles.js';
	import Icon from '$lib/icons/Icon.svelte';
	import { page } from '$app/stores';

	type Props = {
		role: Role;
	};

	let { role }: Props = $props();

	let sections = $derived(NAV_BY_ROLE[role] ?? []);
	let currentPath = $derived($page.url.pathname);
</script>

<nav class="sidenav" data-testid="sidenav">
	{#each sections as section}
		<div class="sidenav__section">
			<div class="sidenav__title">{section.title}</div>
			{#each section.items as item}
				<a
					class="sidenav__link"
					href={item.href}
					data-active={currentPath === item.href}
					data-testid="nav-{item.id}"
				>
					<Icon name={item.icon} size={18} />
					<span>{item.label}</span>
				</a>
			{/each}
		</div>
	{/each}
</nav>

<style>
	.sidenav {
		width: var(--sidebar-width);
		min-width: var(--sidebar-width);
		height: 100%;
		overflow-y: auto;
		padding: var(--space-4) var(--space-3);
		background: var(--c-surface);
		border-right: 1px solid var(--c-border);
	}

	.sidenav__section {
		margin-bottom: var(--space-4);
	}

	.sidenav__title {
		padding: var(--space-1) var(--space-3);
		font-size: var(--text-xs);
		font-weight: var(--weight-semibold);
		text-transform: uppercase;
		letter-spacing: 0.06em;
		color: var(--c-text-faint);
		margin-bottom: var(--space-1);
	}

	.sidenav__link {
		display: flex;
		align-items: center;
		gap: var(--space-3);
		padding: var(--space-2) var(--space-3);
		border-radius: var(--radius-md);
		color: var(--c-text-muted);
		font-size: var(--text-sm);
		font-weight: var(--weight-medium);
		transition: background 0.12s, color 0.12s;
	}

	.sidenav__link:hover {
		background: var(--c-surface-2);
		color: var(--c-text);
	}

	.sidenav__link[data-active='true'] {
		background: var(--c-primary-wash);
		color: var(--c-primary);
	}

	@media (max-width: 960px) {
		.sidenav {
			display: none;
		}
	}
</style>
