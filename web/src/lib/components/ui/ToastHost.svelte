<script lang="ts">
	import { toasts, dismissToast } from '$lib/stores/toast.js';
	import Icon from '$lib/icons/Icon.svelte';
</script>

{#if $toasts.length > 0}
	<div class="toast-host" data-testid="toast-host">
		{#each $toasts as toast (toast.id)}
			<div class="toast" data-tone={toast.tone}>
				<span class="toast__msg">{toast.message}</span>
				<button class="toast__close" onclick={() => dismissToast(toast.id)}>
					<Icon name="x" size={14} />
				</button>
			</div>
		{/each}
	</div>
{/if}

<style>
	.toast-host {
		position: fixed;
		bottom: var(--space-5);
		right: var(--space-5);
		display: flex;
		flex-direction: column;
		gap: var(--space-2);
		z-index: 200;
		max-width: 380px;
	}

	.toast {
		display: flex;
		align-items: center;
		gap: var(--space-3);
		padding: var(--space-3) var(--space-4);
		border-radius: var(--radius-md);
		background: var(--c-surface);
		border: 1px solid var(--c-border);
		box-shadow: var(--shadow-2);
		font-size: var(--text-sm);
		animation: slide-in 0.2s ease;
	}

	.toast[data-tone='success'] {
		border-left: 3px solid var(--c-success);
	}
	.toast[data-tone='warning'] {
		border-left: 3px solid var(--c-warning);
	}
	.toast[data-tone='danger'] {
		border-left: 3px solid var(--c-danger);
	}
	.toast[data-tone='info'] {
		border-left: 3px solid var(--c-info);
	}

	.toast__msg {
		flex: 1;
	}

	.toast__close {
		background: none;
		border: none;
		padding: 2px;
		color: var(--c-text-faint);
		cursor: pointer;
	}

	@keyframes slide-in {
		from {
			transform: translateX(20px);
			opacity: 0;
		}
		to {
			transform: translateX(0);
			opacity: 1;
		}
	}
</style>
