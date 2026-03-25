<script lang="ts">
	import { iconPaths } from './paths.js';

	type Props = {
		name: string;
		size?: number;
	};

	let { name, size = 18 }: Props = $props();

	let d = $derived(iconPaths[name] ?? '');
</script>

<svg
	width={size}
	height={size}
	viewBox="0 0 24 24"
	fill="none"
	stroke="currentColor"
	stroke-width="2"
	stroke-linecap="round"
	stroke-linejoin="round"
	data-testid="icon-{name}"
>
	{#each d.split(/(?<=z|Z)\s*(?=M)/) as segment}
		<path d={segment} />
	{/each}
</svg>
