<script lang="ts">
	import type { Snippet } from 'svelte';

	type Props = {
		actions?: Snippet;
	};

	let { actions }: Props = $props();
</script>

<header class="topbar" data-testid="topbar">
	<div class="topbar__brand">
		<span class="topbar__logo">CrewOps</span>
	</div>
	<div class="topbar__spacer"></div>
	{#if actions}
		<div class="topbar__actions">
			{@render actions()}
		</div>
	{/if}
</header>

<style>
	.topbar {
		display: flex;
		align-items: center;
		height: var(--topbar-height);
		padding: 0 var(--space-5);
		background: var(--c-surface);
		border-bottom: 1px solid var(--c-border);
		gap: var(--space-4);
	}

	.topbar__brand {
		display: flex;
		align-items: center;
		gap: var(--space-3);
	}

	.topbar__logo {
		font-size: var(--text-lg);
		font-weight: var(--weight-semibold);
		letter-spacing: -0.02em;
		color: var(--c-primary);
	}

	.topbar__spacer {
		flex: 1;
	}

	.topbar__actions {
		display: flex;
		align-items: center;
		gap: var(--space-3);
	}
</style>
