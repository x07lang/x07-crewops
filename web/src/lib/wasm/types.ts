export type Role =
	| 'technician'
	| 'dispatcher'
	| 'supervisor'
	| 'manager'
	| 'portal_user'
	| 'enterprise_admin';

export interface SessionState {
	role: Role;
	user_id: string;
	branch_id: string;
	team_id: string;
	status: string;
}

export interface UiState {
	route: string;
	selected_work_order_id: string | null;
	selected_visit_id: string | null;
	selected_customer_id: string | null;
	selected_site_id: string | null;
	selected_asset_id: string | null;
	selected_review_visit_id: string | null;
	selected_correction_id: string | null;
	selected_activity_id: string | null;
	selected_alert_id: string | null;
	selected_invoice_id: string | null;
	selected_payment_id: string | null;
	selected_invoice_artifact_id: string | null;
	selected_service_summary_artifact_id: string | null;
	selected_customer_statement_id: string | null;
	selected_receivable_summary_id: string | null;
	selected_price_book_id: string | null;
	selected_price_book_item_id: string | null;
	selected_billing_policy_id: string | null;
	selected_labor_rate_policy_id: string | null;
	selected_part_rate_policy_id: string | null;
	selected_tax_rule_id: string | null;
	selected_discount_rule_id: string | null;
	selected_export_job_id: string | null;
	selected_finance_rollup_id: string | null;
	selected_profitability_snapshot_id: string | null;
	selected_estimate_id: string | null;
	selected_contract_id: string | null;
	selected_recurring_plan_id: string | null;
	selected_integration_endpoint_id: string | null;
	selected_tenant_id: string | null;
	selected_portal_account_id: string | null;
	selected_inventory_item_id: string | null;
	selected_stock_location_id: string | null;
	selected_purchase_order_id: string | null;
	selected_connector_instance_id: string | null;
	selected_branch_id: string | null;
	selected_team_id: string | null;
	network_status: 'online' | 'offline';
	dispatch_day: string;
	dispatch_status_filter: string;
	dispatch_team_filter: string;
	dispatch_branch_filter: string;
	review_filter: string;
	activity_filter: string;
	manager_scope: string;
	summary_scope: string;
	intake_kind: string;
	pricing_scope: string;
	invoice_status_filter: string;
	invoice_branch_filter: string;
	invoice_customer_filter: string;
	invoice_aging_filter: string;
	customer_branch_filter: string;
	customer_invoice_status_filter: string;
	customer_balance_filter: string;
	customer_statement_filter: string;
	receivables_scope: string;
	receivables_branch_filter: string;
	receivables_aging_filter: string;
	finance_scope: string;
	finance_branch_filter: string;
	export_kind: string;
	export_format: string;
	export_status_filter: string;
	portal_request_filter: string;
	enterprise_workspace_filter: string;
	inventory_status_filter: string;
	inventory_location_filter: string;
	procurement_status_filter: string;
	connector_status_filter: string;
	connector_provider_filter: string;
}

export interface SettingsState {
	theme: 'system' | 'light' | 'dark';
	density: 'comfortable' | 'compact';
	pinned_views: string[];
	dev_flags: Record<string, boolean>;
}

export interface MetaState {
	app_version: string;
	target_kind: string;
	build_profile: string;
	last_event: string;
}

export interface ExecutionState {
	active_visit_state: Record<string, unknown> | null;
}

export interface CrewOpsState {
	session: SessionState;
	bootstrap: unknown;
	ui: UiState;
	entities: Record<string, Record<string, Record<string, unknown>>>;
	indexes: Record<string, unknown>;
	sync: Record<string, unknown>;
	settings: SettingsState;
	diagnostics: unknown;
	summary: Record<string, unknown>;
	drafts: Record<string, unknown>;
	template: unknown;
	execution: ExecutionState;
	meta: MetaState;
}

export interface WasmEvent {
	type: string;
	target?: string;
	value?: string;
}

export interface WasmFrame {
	state: CrewOpsState;
	ui: unknown;
	effects: unknown[];
	patches: unknown[];
}
