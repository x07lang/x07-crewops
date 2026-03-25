<script lang="ts">
	import type { Snippet } from 'svelte';
	import type { Role } from '$lib/wasm/types.js';
	import TopBar from './TopBar.svelte';
	import SideNav from './SideNav.svelte';
	import RoleSwitcher from './RoleSwitcher.svelte';

	type Props = {
		role: Role;
		onroleswitch: (role: Role) => void;
		children: Snippet;
	};

	let { role, onroleswitch, children }: Props = $props();
</script>

<div class="shell" data-testid="app-shell">
	<TopBar>
		{#snippet actions()}
			<RoleSwitcher currentRole={role} onswitch={onroleswitch} />
		{/snippet}
	</TopBar>

	<div class="shell__body">
		<SideNav {role} />
		<main class="shell__content">
			{@render children()}
		</main>
	</div>
</div>

<style>
	.shell {
		display: flex;
		flex-direction: column;
		height: 100vh;
	}

	.shell__body {
		display: flex;
		flex: 1;
		overflow: hidden;
	}

	.shell__content {
		flex: 1;
		overflow-y: auto;
		background: var(--c-bg);
	}
</style>
