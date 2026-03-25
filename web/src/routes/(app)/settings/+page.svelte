<script lang="ts">
	import { getBridge } from '$lib/wasm/bridge.js';
	import { wasmEvent } from '$lib/wasm/events.js';

	const bridge = getBridge();
	let settings = $state<import('$lib/wasm/types.js').SettingsState | null>(null);
	let meta = $state<import('$lib/wasm/types.js').MetaState | null>(null);

	bridge.state.subscribe((s) => {
		if (s) {
			settings = s.settings;
			meta = s.meta;
		}
	});

	async function setTheme(val: string) {
		await bridge.dispatch(wasmEvent.change('settings_theme', val));
	}

	async function setDensity(val: string) {
		await bridge.dispatch(wasmEvent.change('settings_density', val));
	}
</script>

<div class="page">
	<div class="page-header"><h1>Settings</h1></div>

	<div class="card card--padded" style="max-width: 560px">
		<div class="field-group">
			<label>
				Theme
				<select class="select" value={(settings?.theme as string) ?? 'system'} onchange={(e) => setTheme(e.currentTarget.value)}>
					<option value="system">System</option>
					<option value="light">Light</option>
					<option value="dark">Dark</option>
				</select>
			</label>

			<label>
				Density
				<select class="select" value={(settings?.density as string) ?? 'comfortable'} onchange={(e) => setDensity(e.currentTarget.value)}>
					<option value="comfortable">Comfortable</option>
					<option value="compact">Compact</option>
				</select>
			</label>
		</div>
	</div>

	{#if meta}
		<div class="card card--padded" style="max-width: 560px; margin-top: var(--space-5)">
			<h3 style="margin: 0 0 var(--space-3)">App Info</h3>
			<dl class="kv">
				<dt>Version</dt><dd>{meta.app_version}</dd>
				<dt>Target</dt><dd>{meta.target_kind}</dd>
				<dt>Profile</dt><dd>{meta.build_profile}</dd>
			</dl>
		</div>
	{/if}
</div>
