import fs from 'fs';
import path from 'path';
import { execFileSync } from 'child_process';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT = path.resolve(__dirname, '..');
const FIXTURE_PATH = path.join(ROOT, 'tests/fixtures/demo_org.json');
const DEMO_SEED_AST_PATH = path.join(ROOT, 'backend/src/demo_seed.x07.json');
const REPORT_DIR = path.join(ROOT, 'build/reports');
const APP_DIR = path.join(ROOT, 'dist/crewops_gate/app.crewops_dev');
const X07_WASM = path.join(ROOT, '../x07-wasm-backend/target/debug/x07-wasm');
const CREATED_UTC = '2026-03-11T00:00:00Z';
const APP_VERSION = '0.5.0';
const TOOL_VERSION = '0.2.4';
const NOW = '2026-03-11T00:00:00Z';

const argv = process.argv.slice(2);
const updateGoldenEnabled = argv.includes('--update-golden');
const authoredOnly = argv.includes('--authored-only');
const appDirArg = argv.find((value) => value.startsWith('--app-dir='));
const x07WasmArg = argv.find((value) => value.startsWith('--x07-wasm='));
const traceFilterArg = argv.find((value) => value.startsWith('--filter='));
const appDir = appDirArg ? appDirArg.slice('--app-dir='.length) : APP_DIR;
const x07Wasm = x07WasmArg ? x07WasmArg.slice('--x07-wasm='.length) : X07_WASM;
const traceFilter = traceFilterArg ? traceFilterArg.slice('--filter='.length) : null;

const fixture = JSON.parse(fs.readFileSync(FIXTURE_PATH, 'utf8'));
const demoSeedAst = JSON.parse(fs.readFileSync(DEMO_SEED_AST_PATH, 'utf8'));
const baseEntities = {
  org: { [fixture.organization.id]: fixture.organization },
  branches: fixture.branches,
  teams: fixture.teams,
  users: fixture.users,
  customers: fixture.customers,
  sites: fixture.sites,
  assets: fixture.assets,
  work_orders: fixture.work_orders,
  visits: fixture.visits,
  templates: fixture.templates,
  parts_catalog: fixture.parts_catalog,
  assignments: fixture.assignments,
  schedule_windows: fixture.schedule_windows,
  review_queue_items: fixture.review_queue_items,
  review_decisions: fixture.review_decisions,
  correction_tasks: fixture.correction_tasks,
  correction_responses: fixture.correction_responses,
  activity_events: fixture.activity_events,
  alerts: fixture.alerts,
  sla_policies: fixture.sla_policies,
  dashboard_rollups: fixture.dashboard_rollups,
  branch_summaries: fixture.branch_summaries,
  team_summaries: fixture.team_summaries,
  workload_snapshots: fixture.workload_snapshots,
  dispatch_filters: fixture.dispatch_filters,
  price_books: fixture.price_books,
  price_book_items: fixture.price_book_items,
  labor_rate_policies: fixture.labor_rate_policies,
  part_rate_policies: fixture.part_rate_policies,
  billing_policies: fixture.billing_policies,
  tax_rules: fixture.tax_rules,
  discount_rules: fixture.discount_rules,
  invoices: fixture.invoices,
  invoice_lines: fixture.invoice_lines,
  invoice_adjustments: fixture.invoice_adjustments,
  invoice_artifacts: fixture.invoice_artifacts,
  service_summary_artifacts: fixture.service_summary_artifacts,
  payment_records: fixture.payment_records,
  payment_allocations: fixture.payment_allocations,
  customer_statements: fixture.customer_statements,
  receivable_summaries: fixture.receivable_summaries,
  export_jobs: fixture.export_jobs,
  finance_rollups: fixture.finance_rollups,
  profitability_snapshots: fixture.profitability_snapshots,
  estimates: fixture.estimates,
  estimate_versions: fixture.estimate_versions,
  estimate_approvals: fixture.estimate_approvals,
  proposal_artifacts: fixture.proposal_artifacts,
  service_agreements: fixture.service_agreements,
  agreement_lines: fixture.agreement_lines,
  recurring_plans: fixture.recurring_plans,
  recurrence_rules: fixture.recurrence_rules,
  generated_schedule_items: fixture.generated_schedule_items,
  renewal_records: fixture.renewal_records,
  contract_health_snapshots: fixture.contract_health_snapshots,
  integration_endpoints: fixture.integration_endpoints,
  api_key_records: fixture.api_key_records,
  webhook_subscriptions: fixture.webhook_subscriptions,
  webhook_deliveries: fixture.webhook_deliveries,
  connector_mappings: fixture.connector_mappings,
  import_or_sync_jobs: fixture.import_or_sync_jobs,
  recurring_revenue_rollups: fixture.recurring_revenue_rollups,
};
const bootstrapWorkOrderIds = ['wo_001', 'wo_002', 'wo_003', 'wo_004', 'wo_005', 'wo_006'];
const bootstrapTemplateIds = ['tmpl_arrival', 'tmpl_pm', 'tmpl_closeout'];
const reviewSnapshotWorkOrderIds = ['wo_016', 'wo_017', 'wo_025'];
const baseIndexes = fixture.indexes;
const baseSummary = fixture.summary;
const priceBooks = fixture.price_books;
const billingPolicies = fixture.billing_policies;
const taxRules = fixture.tax_rules;
const discountRules = fixture.discount_rules;
const invoices = fixture.invoices;
const invoiceLines = fixture.invoice_lines;
const invoiceAdjustments = fixture.invoice_adjustments;
const invoiceArtifacts = fixture.invoice_artifacts;
const serviceSummaryArtifacts = fixture.service_summary_artifacts;
const paymentRecords = fixture.payment_records;
const customerStatements = fixture.customer_statements;
const receivableSummaries = fixture.receivable_summaries;
const exportJobs = fixture.export_jobs;
const financeRollups = fixture.finance_rollups;
const profitabilitySnapshots = fixture.profitability_snapshots;
const sessionDefaults = {
  technician: {
    user_id: 'user_tech_ava',
    branch_id: 'branch_north',
    team_id: 'team_north_alpha',
  },
  dispatcher: {
    user_id: 'user_dispatch_rhea',
    branch_id: 'branch_north',
    team_id: 'team_north_alpha',
  },
  supervisor: {
    user_id: 'user_supervisor_nadia',
    branch_id: 'branch_north',
    team_id: 'team_north_alpha',
  },
  manager: {
    user_id: 'user_manager_jonas',
    branch_id: 'branch_north',
    team_id: 'team_north_alpha',
  },
};
const metaDoc = {
  app_name: 'CrewOps',
  app_version: APP_VERSION,
  build_profile: 'dev',
  environment: 'local',
  generated_at: NOW,
};
const bootstrapEntities = {
  work_orders: Object.fromEntries(
    bootstrapWorkOrderIds
      .filter((id) => fixture.work_orders[id] != null)
      .map((id) => [id, compactWorkOrder(fixture.work_orders[id])]),
  ),
  templates: Object.fromEntries(
    bootstrapTemplateIds
      .filter((id) => fixture.templates[id] != null)
      .map((id) => [id, compactTemplate(fixture.templates[id])]),
  ),
  parts_catalog: fixture.parts_catalog,
};
const bootstrapDoc = {
  meta: metaDoc,
  session_defaults: sessionDefaults,
  bootstrap: {
    status: 'ready',
    source: 'http',
    last_loaded_at: NOW,
    sync_cursor: 'sync_cursor_2026_03_11_101',
  },
  entities: bootstrapEntities,
  indexes: baseIndexes,
  summary: baseSummary,
  sync: syncDoc('sync_cursor_2026_03_11_101', 'idle'),
  diagnostics: {
    app_version: APP_VERSION,
    target_kind: 'web',
    build_profile: 'dev',
  },
};

function compactWorkOrder(workOrder) {
  return {
    id: workOrder.id,
    number: workOrder.number,
    title: workOrder.title,
    priority: workOrder.priority,
    scheduled_day: workOrder.scheduled_day,
    window: workOrder.window,
    allowed_part_ids: Array.isArray(workOrder.allowed_part_ids) ? [...workOrder.allowed_part_ids] : [],
  };
}

function compactTemplate(template) {
  const sections = [];
  const firstLabel = template.sections?.[0]?.fields?.[0]?.label;
  if (firstLabel != null) {
    sections.push({
      fields: [
        {
          label: firstLabel,
        },
      ],
    });
  }
  const secondFields = (template.sections?.[1]?.fields ?? [])
    .slice(0, 3)
    .map((field) => ({ label: field.label }));
  if (secondFields.length > 0) {
    sections.push({ fields: secondFields });
  }
  return {
    id: template.id,
    name: template.name,
    sections,
  };
}

function clone(value) {
  return JSON.parse(JSON.stringify(value));
}

const demoSeedLiteralCache = new Map();

function demoSeedDoc(name) {
  if (demoSeedLiteralCache.has(name)) {
    return clone(demoSeedLiteralCache.get(name));
  }
  const decl = (demoSeedAst.decls ?? []).find((item) => item.kind === 'defn' && item.name === name);
  if (decl == null || !Array.isArray(decl.body) || decl.body[0] !== 'bytes.lit' || typeof decl.body[1] !== 'string') {
    throw new Error(`demo seed literal not found: ${name}`);
  }
  const doc = JSON.parse(decl.body[1]);
  demoSeedLiteralCache.set(name, doc);
  return clone(doc);
}

function demoSeedMapEntry(name, key) {
  const map = demoSeedDoc(name);
  if (map[key] == null) {
    throw new Error(`demo seed map entry not found: ${name} -> ${key}`);
  }
  return map[key];
}

function suffixFromId(id) {
  return id.split('_').pop();
}

function visitIdForWorkOrder(workOrderId) {
  return `visit_${suffixFromId(workOrderId)}`;
}

function workOrderIdForVisit(visitId) {
  return `wo_${suffixFromId(visitId)}`;
}

function correctionIdForVisit(visitId) {
  return `correction_${suffixFromId(visitId)}`;
}

function defaultUi() {
  return {
    route: 'today',
    selected_work_order_id: 'wo_001',
    selected_visit_id: 'visit_001',
    selected_customer_id: 'cust_013',
    selected_site_id: 'site_013',
    selected_asset_id: 'asset_013',
    selected_review_visit_id: 'visit_001',
    selected_correction_id: null,
    selected_activity_id: null,
    selected_alert_id: null,
    selected_invoice_id: 'inv_001',
    selected_payment_id: null,
    selected_invoice_artifact_id: 'invoice_artifact_inv_001',
    selected_service_summary_artifact_id: 'service_summary_inv_001',
    selected_customer_statement_id: 'statement_cust_013',
    selected_receivable_summary_id: 'receivable_branch_north',
    selected_price_book_id: 'price_book_branch_north',
    selected_price_book_item_id: 'price_item_service_call_north',
    selected_billing_policy_id: 'billing_policy_branch_north',
    selected_labor_rate_policy_id: 'labor_policy_branch_north',
    selected_part_rate_policy_id: 'part_rate_north_filter',
    selected_tax_rule_id: 'tax_rule_wa',
    selected_discount_rule_id: 'discount_rule_loyalty',
    selected_export_job_id: 'export_job_003',
    selected_finance_rollup_id: 'finance_global',
    selected_profitability_snapshot_id: 'finance_global',
    selected_estimate_id: 'est_001',
    selected_contract_id: 'agreement_001',
    selected_recurring_plan_id: 'recurring_plan_001',
    selected_integration_endpoint_id: 'integration_endpoint_crm',
    selected_branch_id: 'branch_north',
    selected_team_id: 'team_north_alpha',
    network_status: 'online',
    dispatch_day: '2026-03-11',
    dispatch_status_filter: 'all',
    dispatch_team_filter: 'all',
    dispatch_branch_filter: 'all',
    review_filter: 'awaiting_review',
    activity_filter: 'all',
    manager_scope: 'branch_north',
    summary_scope: 'branch',
    intake_kind: 'work_order',
    pricing_scope: 'branch',
    invoice_status_filter: 'all',
    invoice_branch_filter: 'all',
    invoice_customer_filter: 'all',
    invoice_aging_filter: 'all',
    customer_branch_filter: 'all',
    customer_invoice_status_filter: 'all',
    customer_balance_filter: 'open',
    customer_statement_filter: 'open',
    receivables_scope: 'branch',
    receivables_branch_filter: 'all',
    receivables_aging_filter: 'all',
    finance_scope: 'global',
    finance_branch_filter: 'all',
    export_kind: 'invoices',
    export_format: 'csv',
    export_status_filter: 'all',
  };
}

function defaultDrafts() {
  return {
    customer_name: '',
    site_name: '',
    asset_name: '',
    work_order_title: '',
    dispatch_note: '',
    review_note: '',
    response_note: '',
    schedule_window: '10:00-12:00',
    priority: 'medium',
    location_policy: 'optional',
    signature_policy: 'required',
    review_policy: 'required',
    expected_duration: '90',
    branch_id: 'branch_north',
    team_id: 'team_north_alpha',
    activity_scope: 'all',
    price_book_name: 'North Commercial Standard',
    labor_rate_hourly: '96.00',
    travel_fee: '28.00',
    tax_rule_label: 'WA sales tax',
    discount_rule_label: 'Loyalty discount',
    invoice_memo: 'Drafted from approved work.',
    invoice_issue_date: '2026-03-15',
    invoice_due_date: '2026-03-30',
    invoice_line_description: 'Standard service call',
    invoice_line_quantity: '1',
    invoice_line_rate: '145.00',
    payment_amount: '220.00',
    payment_method: 'ach',
    payment_reference: 'ACH-55201',
    customer_statement_date: '2026-03-11',
    customer_branch_id: 'branch_north',
    customer_balance_filter: 'open',
    receivable_scope: 'branch',
    receivable_aging_bucket: 'all',
    export_date_from: '2026-03-01',
    export_date_to: '2026-03-31',
    export_branch_id: 'branch_north',
    export_status_filter: 'open',
    export_kind: 'invoices',
    export_format: 'csv',
    commercial_ops: {
      estimate_selected_id: 'est_001',
      estimate_status_filter: 'all',
      estimate_branch_filter: 'all',
      estimate_customer_filter: 'all',
      estimate_expiration_date: '2026-04-12',
      estimate_terms: 'Net 15.',
      estimate_note: 'Follow up within seven days.',
      estimate_line_description: 'Preventive maintenance visit',
      estimate_line_quantity: '1',
      estimate_line_unit_price: '185.00',
      estimate_discount_rate: '0.03',
      estimate_tax_rate: '0.101',
      estimate_signature_name: 'Morgan Hale',
      estimate_signature_note: 'Approved as quoted.',
      contract_selected_id: 'agreement_001',
      contract_status_filter: 'all',
      contract_branch_filter: 'all',
      contract_start_date: '2026-04-01',
      contract_end_date: '2027-03-31',
      contract_renewal_date: '2027-02-15',
      contract_service_window: '08:00-10:00',
      contract_sla_tier: 'gold',
      contract_response_commitment: 'same_day',
      recurring_selected_id: 'recurring_plan_001',
      recurring_status_filter: 'all',
      recurring_team_filter: 'all',
      recurring_next_date: '2026-03-21',
      recurring_service_window: '08:00-10:00',
      recurring_skip_reason: 'Customer blackout week.',
      integration_selected_id: 'integration_endpoint_crm',
      integration_status_filter: 'all',
      integration_scope_filter: 'all',
      api_key_label: 'CrewOps ERP sync',
      api_key_expires_at: '2026-12-31',
      api_key_scope_csv: 'integrations.read,deliveries.read',
      webhook_label: 'Estimate lifecycle mirror',
      webhook_url: 'https://example.test/hooks/estimates',
      webhook_events_csv: 'estimate.approved,estimate.converted',
      mapping_source_key: 'customer.external_code',
      mapping_target_key: 'crm.account_id',
    },
  };
}

function defaultSettings() {
  return {
    theme: 'system',
    density: 'comfortable',
    pinned_views: [],
    dev_flags: {},
  };
}

function defaultMeta() {
  return {
    app_version: APP_VERSION,
    target_kind: 'web',
    build_profile: 'dev',
    last_event: 'init',
  };
}

function defaultDiagnostics(lastEvent = 'init') {
  return {
    app_version: APP_VERSION,
    target_kind: 'web',
    build_profile: 'dev',
    last_event: lastEvent,
  };
}

function defaultExecution() {
  return {
    status: 'planned',
    draft_status: 'idle',
    completion_mode: 'complete',
    template_id: 'tmpl_pm',
    arrival_ready: false,
    temperature: '',
    filter_condition: '',
    findings: '',
    note: '',
    labor_minutes: '0',
    labor_running: false,
    labor_cycles: '0',
    parts_qty: '0',
    block_reason: '',
    signature_name: '',
    signature_role: '',
    signature_strokes: '0',
    signature_required: true,
    signature_status: 'missing',
    capture_status: 'idle',
    capture_attachment: null,
    import_status: 'idle',
    import_attachment: null,
    blob_status: 'idle',
    permission_status: 'idle',
    permission_state: 'unknown',
    location_status: 'idle',
    checkin_location: null,
    checkout_location_status: 'idle',
    checkout_location: null,
    autosave_status: 'idle',
    unsaved: false,
    validation_error: '',
    last_action: 'ready',
  };
}

function defaultSession(role = 'technician') {
  const defaults = sessionDefaults[role];
  return {
    user_id: defaults.user_id,
    role,
    branch_id: defaults.branch_id,
    team_id: defaults.team_id,
    token: `dev_${role}_token`,
    status: 'ready',
  };
}

function runtimeState(mutator = null) {
  const state = {
    session: defaultSession('technician'),
    bootstrap: clone(bootstrapDoc.bootstrap),
    ui: defaultUi(),
    entities: clone(bootstrapEntities),
    indexes: clone(baseIndexes),
    sync: syncDoc('sync_cursor_2026_03_11_101', 'idle'),
    settings: defaultSettings(),
    diagnostics: defaultDiagnostics(),
    summary: clone(baseSummary),
    drafts: defaultDrafts(),
    template: null,
    execution: defaultExecution(),
    meta: defaultMeta(),
  };
  if (mutator) {
    mutator(state);
  }
  return state;
}

function bootstrapFrameState() {
  return runtimeState((state) => {
    state.session = {
      user_id: null,
      role: 'technician',
      branch_id: 'branch_north',
      team_id: 'team_north_alpha',
      token: '',
      status: 'idle',
    };
    state.ui = { ...(state.ui ?? {}), ...defaultUi() };
    state.sync = syncDoc('sync_cursor_2026_03_11_101', 'idle', {
      last_push_at: null,
    });
    state.diagnostics = defaultDiagnostics('init');
    state.execution = defaultExecution();
    state.execution.last_action = 'bootstrap loaded';
    state.meta = defaultMeta();
    state.meta.last_event = 'init';
  });
}

function runtimeStateForRole(role, options = {}, mutator = null) {
  return runtimeState((state) => {
    const defaults = sessionDefaults[role];
    const workOrderId = options.workOrderId ?? state.ui.selected_work_order_id ?? 'wo_001';
    const visitId = visitIdForWorkOrder(workOrderId);
    state.session = {
      ...(state.session ?? {}),
      user_id: defaults.user_id,
      role,
      branch_id: defaults.branch_id,
      team_id: defaults.team_id,
      token: `dev_${role}_token`,
      status: 'ready',
    };
    state.ui.route = options.route ?? routeForRole(role);
    state.ui.selected_work_order_id = workOrderId;
    state.ui.selected_visit_id = visitId;
    state.ui.selected_review_visit_id = visitId;
    state.ui.network_status = options.networkStatus ?? state.ui.network_status ?? 'online';
    if (Object.hasOwn(options, 'reviewFilter')) {
      state.ui.review_filter = options.reviewFilter;
    }
    if (Object.hasOwn(options, 'managerScope')) {
      state.ui.manager_scope = options.managerScope;
    }
    if (Object.hasOwn(options, 'summaryScope')) {
      state.ui.summary_scope = options.summaryScope;
    }
    if (mutator) {
      mutator(state);
    }
  });
}

function routeForRole(role) {
  if (role === 'dispatcher') {
    return 'dispatch';
  }
  if (role === 'supervisor') {
    return 'review';
  }
  if (role === 'manager') {
    return 'manager';
  }
  return 'today';
}

function syncDoc(cursor, status, overrides = {}) {
  return {
    cursor,
    pending_ops: [],
    last_pull_at: NOW,
    last_push_at: status === 'accepted' || status === 'conflict' ? NOW : null,
    last_server_event_at: NOW,
    status,
    last_error: null,
    conflict_status: 'idle',
    conflict_message: '',
    conflict_code: null,
    conflict_entity_id: null,
    invoice_lock_status: 'idle',
    invoice_lock_message: '',
    stale_invoice_id: null,
    estimate_revision_status: 'idle',
    stale_estimate_id: null,
    agreement_revision_status: 'idle',
    stale_agreement_id: null,
    payment_revision_status: 'idle',
    pricing_revision_status: 'idle',
    stale_price_book_id: null,
    export_status: 'idle',
    finance_revision: 'finance_rev_2026_03_11_001',
    unread_alerts: 4,
    unread_activity: 6,
    commercial_ops: {
      estimate_revision_status: 'idle',
      stale_estimate_id: null,
      agreement_revision_status: 'idle',
      stale_agreement_id: null,
      recurring_generation_status: 'idle',
      stale_recurring_plan_id: null,
      delivery_retry_status: 'idle',
      stale_delivery_id: null,
    },
    ...overrides,
  };
}

function compactEntitySnapshot(sourceEntities, extraWorkOrderIds = []) {
  const workOrderIds = [...new Set([...bootstrapWorkOrderIds, ...extraWorkOrderIds])];
  return {
    work_orders: Object.fromEntries(
      workOrderIds
        .filter((id) => sourceEntities.work_orders?.[id] != null)
        .map((id) => [id, compactWorkOrder(sourceEntities.work_orders[id])]),
    ),
    templates: Object.fromEntries(
      bootstrapTemplateIds
        .filter((id) => sourceEntities.templates?.[id] != null)
        .map((id) => [id, compactTemplate(sourceEntities.templates[id])]),
    ),
    parts_catalog: sourceEntities.parts_catalog ?? fixture.parts_catalog,
  };
}

function payloadWithSnapshot(extra, snapshot = null, extraWorkOrderIds = []) {
  const current = snapshot ?? {
    entities: clone(bootstrapEntities),
    indexes: clone(baseIndexes),
    summary: clone(baseSummary),
  };
  return {
    ...extra,
    entities: compactEntitySnapshot(current.entities, extraWorkOrderIds),
    indexes: current.indexes,
    summary: current.summary,
    sync: extra.sync ?? syncDoc('sync_cursor_2026_03_11_103', 'accepted'),
  };
}

function payloadWithFullSnapshot(extra, snapshot = null) {
  const current = snapshot ?? {
    entities: clone(baseEntities),
    indexes: clone(baseIndexes),
    summary: clone(baseSummary),
  };
  return {
    ...extra,
    entities: current.entities,
    indexes: current.indexes,
    summary: current.summary,
    sync: extra.sync ?? syncDoc('sync_cursor_2026_03_11_103', 'accepted'),
  };
}

function payloadWithOperationalSnapshot(extra, snapshot = null) {
  const current = snapshot ?? {
    entities: clone(baseEntities),
    indexes: clone(baseIndexes),
    summary: clone(baseSummary),
  };
  return {
    ...extra,
    entities: {
      work_orders: current.entities.work_orders,
      templates: current.entities.templates,
      parts_catalog: current.entities.parts_catalog,
    },
    indexes: current.indexes,
    summary: current.summary,
    sync: extra.sync ?? syncDoc('sync_cursor_2026_03_11_103', 'accepted'),
  };
}

function loginDoc(role) {
  const session = defaultSession(role);
  return {
    session: {
      token: session.token,
      role: session.role,
      user_id: session.user_id,
      branch_id: session.branch_id,
      team_id: session.team_id,
      status: session.status,
    },
  };
}

function dispatchBoardDoc(snapshot = null) {
  return payloadWithSnapshot(
    {
      board: {
        day: '2026-03-11',
        branch_id: 'branch_north',
        team_id: 'all',
        filters: fixture.dispatch_filters.dispatch_default,
        focus_work_orders: baseSummary.dispatcher_focus,
      },
      workload: fixture.workload_snapshots,
      alerts: ['alert_dispatcher_overdue'],
      sync: syncDoc('sync_cursor_2026_03_11_101', 'idle'),
    },
    snapshot,
  );
}

function reviewQueueDoc(snapshot = null) {
  return payloadWithSnapshot(
    {
      queue: Object.keys((snapshot ?? { entities: baseEntities }).entities.review_queue_items ?? fixture.review_queue_items),
      items: (snapshot ?? { entities: baseEntities }).entities.review_queue_items ?? fixture.review_queue_items,
      corrections: (snapshot ?? { entities: baseEntities }).entities.correction_tasks ?? fixture.correction_tasks,
      alerts: ['alert_supervisor_review'],
      sync: syncDoc('sync_cursor_2026_03_11_101', 'idle'),
    },
    snapshot,
    reviewSnapshotWorkOrderIds,
  );
}

function managerSummaryDoc(snapshot = null) {
  return payloadWithSnapshot(
    {
      dashboard_rollup: fixture.dashboard_rollups.dashboard_default,
      branch_summaries: fixture.branch_summaries,
      team_summaries: fixture.team_summaries,
      workload_snapshots: fixture.workload_snapshots,
      sync: syncDoc('sync_cursor_2026_03_11_101', 'idle'),
    },
    snapshot,
  );
}

function activityFeedDoc(snapshot = null) {
  const current = snapshot ?? {
    entities: clone(baseEntities),
    indexes: clone(baseIndexes),
    summary: clone(baseSummary),
  };
  return payloadWithSnapshot(
    {
      items: Object.keys(current.entities.activity_events),
      events: current.entities.activity_events,
      alerts: current.entities.alerts,
      sync: syncDoc('sync_cursor_2026_03_11_101', 'idle', {
        unread_alerts: current.summary.activity_unread?.technician ?? 4,
      }),
    },
    current,
  );
}

function pricingConfigDoc(snapshot = null) {
  return payloadWithSnapshot(
    {
      pricing: {
        price_book_ids: Object.keys(priceBooks),
        billing_policy_ids: Object.keys(billingPolicies),
        tax_rule_ids: Object.keys(taxRules),
        discount_rule_ids: Object.keys(discountRules),
        revision: 'pricing_rev_2026_03_11_001',
        default_branch_price_books: {
          branch_north: 'price_book_branch_north',
          branch_south: 'price_book_branch_south',
        },
      },
      sync: syncDoc('sync_cursor_2026_03_11_101', 'idle'),
    },
    snapshot,
  );
}

function pricingUpdateDoc(snapshot = null) {
  return payloadWithSnapshot(
    {
      status: 'updated',
      message: 'Saved pricing and billing policy changes.',
      price_book_id: 'price_book_branch_north',
      billing_policy_id: 'billing_policy_branch_north',
      sync: syncDoc('sync_cursor_2026_03_11_103', 'accepted', {
        finance_revision: 'finance_rev_2026_03_11_002',
      }),
    },
    snapshot,
  );
}

function pricingUpdateConflictDoc(snapshot = null) {
  return payloadWithSnapshot(
    {
      status: 'conflict',
      message: 'Pricing revision changed while the draft invoice was open.',
      price_book_id: 'price_book_customer_cust_018',
      sync: syncDoc('sync_cursor_2026_03_11_103', 'conflict', {
        conflict_status: 'stale',
        conflict_message: 'Pricing revision mismatch; refresh before saving.',
        conflict_code: 'pricing_revision_mismatch',
        conflict_entity_id: 'price_book_customer_cust_018',
        pricing_revision_status: 'mismatch',
        stale_price_book_id: 'price_book_customer_cust_018',
        finance_revision: 'finance_rev_2026_03_11_003',
      }),
    },
    snapshot,
  );
}

function invoiceListDoc(snapshot = null) {
  return payloadWithSnapshot(
    {
      invoice_ids: Object.keys(invoices),
      open_invoice_ids: Object.entries(invoices)
        .filter(([, invoice]) => !['paid', 'voided', 'written_off'].includes(invoice.status))
        .map(([invoiceId]) => invoiceId),
      receivable_summary_ids: Object.keys(receivableSummaries),
      sync: syncDoc('sync_cursor_2026_03_11_101', 'idle'),
    },
    snapshot,
  );
}

const invoiceDetailMap = Object.fromEntries(
  Object.entries(invoices).map(([invoiceId, invoice]) => [
    invoiceId,
    payloadWithSnapshot({
      invoice_id: invoiceId,
      invoice,
      line_items: Object.fromEntries(
        invoice.line_ids.map((lineId) => [lineId, invoiceLines[lineId]]),
      ),
      adjustments: Object.fromEntries(
        invoice.adjustment_ids.map((adjustmentId) => [adjustmentId, invoiceAdjustments[adjustmentId]]),
      ),
      payments: Object.fromEntries(
        invoice.payment_ids.map((paymentId) => [paymentId, paymentRecords[paymentId]]),
      ),
      statement: customerStatements[`statement_${invoice.customer_id}`],
      artifacts: {
        [invoice.invoice_artifact_id]: invoiceArtifacts[invoice.invoice_artifact_id],
        [invoice.service_summary_artifact_id]: serviceSummaryArtifacts[invoice.service_summary_artifact_id],
      },
      sync: syncDoc('sync_cursor_2026_03_11_101', 'idle'),
    }),
  ]),
);

function invoiceGenerateDoc(snapshot = null) {
  return payloadWithSnapshot(
    {
      status: 'generated',
      message: 'Generated an invoice draft from approved work.',
      invoice_id: 'inv_001',
      source_work_order_ids: invoices.inv_001.source_work_order_ids,
      sync: syncDoc('sync_cursor_2026_03_11_103', 'accepted', {
        finance_revision: 'finance_rev_2026_03_11_002',
      }),
    },
    snapshot,
  );
}

function invoicePatchDoc(snapshot = null) {
  return payloadWithSnapshot(
    {
      status: 'updated',
      message: 'Updated invoice draft totals and memo.',
      invoice_id: 'inv_001',
      revision: 2,
      sync: syncDoc('sync_cursor_2026_03_11_103', 'accepted', {
        finance_revision: 'finance_rev_2026_03_11_002',
      }),
    },
    snapshot,
  );
}

const invoiceIssueMap = Object.fromEntries(
  Object.keys(invoices).map((invoiceId) => [
    invoiceId,
    payloadWithSnapshot({
      status: 'issued',
      message: 'Issued invoice and locked revision-sensitive fields.',
      invoice_id: invoiceId,
      sync: syncDoc('sync_cursor_2026_03_11_103', 'accepted', {
        invoice_lock_status: 'revision_sensitive',
        finance_revision: 'finance_rev_2026_03_11_002',
      }),
    }),
  ]),
);

function invoiceLockConflictDoc(snapshot = null) {
  return payloadWithSnapshot(
    {
      status: 'conflict',
      message: 'Invoice is locked because a newer issued revision already exists.',
      invoice_id: 'inv_007',
      sync: syncDoc('sync_cursor_2026_03_11_103', 'conflict', {
        conflict_status: 'locked',
        conflict_message: 'Refresh invoice data before editing or issuing.',
        conflict_code: 'invoice_locked',
        conflict_entity_id: 'inv_007',
        invoice_lock_status: 'locked',
        invoice_lock_message: 'Invoice is already overdue and locked to receivables controls.',
        stale_invoice_id: 'inv_007',
        finance_revision: 'finance_rev_2026_03_11_003',
      }),
    },
    snapshot,
  );
}

const invoiceVoidMap = Object.fromEntries(
  Object.keys(invoices).map((invoiceId) => [
    invoiceId,
    payloadWithSnapshot({
      status: 'voided',
      message: 'Voided invoice and recorded a credit note.',
      invoice_id: invoiceId,
      sync: syncDoc('sync_cursor_2026_03_11_103', 'accepted', {
        invoice_lock_status: 'locked',
        finance_revision: 'finance_rev_2026_03_11_002',
      }),
    }),
  ]),
);

const invoicePaymentMap = Object.fromEntries(
  Object.keys(invoices).map((invoiceId) => [
    invoiceId,
    payloadWithSnapshot({
      status: 'recorded',
      message: 'Recorded payment allocation against invoice.',
      invoice_id: invoiceId,
      payment_id: `payment_recorded_${invoiceId}`,
      sync: syncDoc('sync_cursor_2026_03_11_103', 'accepted', {
        payment_revision_status: 'accepted',
        finance_revision: 'finance_rev_2026_03_11_002',
      }),
    }),
  ]),
);

function paymentRevisionConflictDoc(snapshot = null) {
  return payloadWithSnapshot(
    {
      status: 'conflict',
      message: 'Payment revision mismatched the latest invoice balance.',
      invoice_id: 'inv_005',
      sync: syncDoc('sync_cursor_2026_03_11_103', 'conflict', {
        conflict_status: 'stale',
        conflict_message: 'Payment allocation was based on a stale invoice balance.',
        conflict_code: 'payment_revision_mismatch',
        conflict_entity_id: 'inv_005',
        payment_revision_status: 'mismatch',
        stale_invoice_id: 'inv_005',
        finance_revision: 'finance_rev_2026_03_11_003',
      }),
    },
    snapshot,
  );
}

function financeSummaryDoc(snapshot = null) {
  return payloadWithSnapshot(
    {
      rollup: financeRollups.finance_global,
      branch_rollups: Object.fromEntries(
        Object.entries(financeRollups).filter(([, rollup]) => rollup.scope === 'branch'),
      ),
      team_rollups: Object.fromEntries(
        Object.entries(financeRollups).filter(([, rollup]) => rollup.scope === 'team'),
      ),
      profitability: profitabilitySnapshots,
      sync: syncDoc('sync_cursor_2026_03_11_101', 'idle'),
    },
    snapshot,
  );
}

function financeReceivablesDoc(snapshot = null) {
  return payloadWithSnapshot(
    {
      receivable_ids: Object.keys(receivableSummaries),
      receivables: receivableSummaries,
      statements: customerStatements,
      overdue_invoice_ids: [
        ...baseIndexes.invoices_by_aging_bucket['31_60'],
        ...baseIndexes.invoices_by_aging_bucket['61_plus'],
      ],
      sync: syncDoc('sync_cursor_2026_03_11_101', 'idle'),
    },
    snapshot,
  );
}

const customerAccountMap = Object.fromEntries(
  Object.values(customerStatements).map((statement) => {
    const customerId = statement.customer_id;
    return [
      customerId,
      payloadWithSnapshot({
        customer_id: customerId,
        customer: baseEntities.customers[customerId],
        statement,
        invoice_ids: baseIndexes.invoices_by_customer[customerId] ?? [],
        payment_ids: baseIndexes.payments_by_customer[customerId] ?? [],
        receivable_summary: receivableSummaries[`receivable_${customerId}`],
        sync: syncDoc('sync_cursor_2026_03_11_101', 'idle'),
      }),
    ];
  }),
);

function exportCenterDoc(snapshot = null) {
  return payloadWithSnapshot(
    {
      export_job_ids: Object.keys(exportJobs),
      jobs: exportJobs,
      filters: {
        formats: ['csv', 'json'],
        kinds: ['invoices', 'receivables', 'profitability'],
        branch_ids: Object.keys(baseEntities.branches),
      },
      sync: syncDoc('sync_cursor_2026_03_11_101', 'idle', {
        export_status: 'idle',
      }),
    },
    snapshot,
  );
}

function exportCreateDoc(snapshot = null) {
  return payloadWithSnapshot(
    {
      status: 'queued',
      message: 'Queued export job and snapshotted finance revision.',
      export_job_id: 'export_job_003',
      sync: syncDoc('sync_cursor_2026_03_11_103', 'accepted', {
        export_status: 'running',
        finance_revision: 'finance_rev_2026_03_11_002',
      }),
    },
    snapshot,
  );
}

const exportRetryMap = Object.fromEntries(
  Object.keys(exportJobs).map((exportJobId) => [
    exportJobId,
    payloadWithSnapshot({
      status: 'retried',
      message: 'Retried export job with a fresh finance snapshot.',
      export_job_id: exportJobId,
      sync: syncDoc('sync_cursor_2026_03_11_103', 'accepted', {
        export_status: 'running',
        finance_revision: 'finance_rev_2026_03_11_002',
      }),
    }),
  ]),
);

const invoiceArtifactMap = Object.fromEntries(
  Object.entries(invoices).map(([invoiceId, invoice]) => [
    invoiceId,
    payloadWithSnapshot({
      invoice_id: invoiceId,
      artifact: invoiceArtifacts[invoice.invoice_artifact_id],
      sync: syncDoc('sync_cursor_2026_03_11_101', 'idle', {
        export_status: invoiceArtifacts[invoice.invoice_artifact_id].status,
      }),
    }),
  ]),
);

const serviceSummaryMap = Object.fromEntries(
  Object.entries(invoices).map(([invoiceId, invoice]) => [
    invoiceId,
    payloadWithSnapshot({
      invoice_id: invoiceId,
      artifact: serviceSummaryArtifacts[invoice.service_summary_artifact_id],
      sync: syncDoc('sync_cursor_2026_03_11_101', 'idle'),
    }),
  ]),
);

function estimateListDoc() {
  return demoSeedDoc('demo_seed.estimate_list_body_v1');
}

const estimateDetailMap = demoSeedDoc('demo_seed.estimate_detail_map_body_v1');
const estimateCreateDoc = demoSeedDoc('demo_seed.estimate_create_body_v1');
const estimatePatchMap = demoSeedDoc('demo_seed.estimate_patch_map_body_v1');
const estimateSendMap = demoSeedDoc('demo_seed.estimate_send_map_body_v1');
const estimateApproveMap = demoSeedDoc('demo_seed.estimate_approve_map_body_v1');
const estimateConvertMap = demoSeedDoc('demo_seed.estimate_convert_map_body_v1');
const estimateApprovalConflictDoc = demoSeedDoc('demo_seed.estimate_approval_conflict_body_v1');
const estimateConversionConflictDoc = demoSeedDoc('demo_seed.estimate_conversion_conflict_body_v1');

function contractListDoc() {
  return demoSeedDoc('demo_seed.contract_list_body_v1');
}

const contractCreateDoc = demoSeedDoc('demo_seed.contract_create_body_v1');
const contractResumeMap = demoSeedDoc('demo_seed.contract_resume_map_body_v1');
const contractRenewMap = demoSeedDoc('demo_seed.contract_renew_map_body_v1');
const contractRenewConflictDoc = demoSeedDoc('demo_seed.contract_renewal_conflict_body_v1');

function recurringBoardDoc() {
  return demoSeedDoc('demo_seed.recurring_board_body_v1');
}

const recurringGenerateMap = demoSeedDoc('demo_seed.recurring_generate_map_body_v1');
const recurringSkipMap = demoSeedDoc('demo_seed.recurring_skip_map_body_v1');
const recurringGenerationConflictDoc = demoSeedDoc('demo_seed.recurring_generation_conflict_body_v1');

function integrationsCenterDoc() {
  return demoSeedDoc('demo_seed.integrations_center_body_v1');
}

function integrationsDeliveriesDoc() {
  return demoSeedDoc('demo_seed.integrations_deliveries_body_v1');
}

const integrationsApiKeyCreateDoc = demoSeedDoc('demo_seed.integrations_api_key_create_body_v1');
const integrationsWebhookCreateDoc = demoSeedDoc('demo_seed.integrations_webhook_create_body_v1');
const integrationsDeliveryRetryDoc = demoSeedDoc('demo_seed.integrations_delivery_retry_body_v1');

function workOrderAssignDoc(workOrderId) {
  const workOrder = baseEntities.work_orders[workOrderId];
  return payloadWithOperationalSnapshot(
    {
      status: 'assigned',
      message: 'Assigned work order to technician.',
      work_order_id: workOrderId,
      assignment_id: workOrder.latest_assignment_id,
      sync: syncDoc('sync_cursor_2026_03_11_103', 'accepted'),
    },
  );
}

function workOrderReassignDoc(workOrderId) {
  const workOrder = baseEntities.work_orders[workOrderId];
  return payloadWithOperationalSnapshot(
    {
      status: 'reassigned',
      message: 'Reassigned work order and published activity event.',
      work_order_id: workOrderId,
      assignment_id: workOrder.latest_assignment_id,
      sync: syncDoc('sync_cursor_2026_03_11_103', 'accepted'),
    },
  );
}

function reviewRequestCorrectionDoc(visitId) {
  return payloadWithOperationalSnapshot(
    {
      status: 'correction_requested',
      message: 'Supervisor requested correction.',
      visit_id: visitId,
      correction_task_id: correctionIdForVisit(visitId),
      sync: syncDoc('sync_cursor_2026_03_11_103', 'accepted'),
    },
  );
}

function correctionResubmitDoc(correctionId) {
  const task = baseEntities.correction_tasks[correctionId];
  return payloadWithOperationalSnapshot(
    {
      status: 'resubmitted',
      message: 'Technician resubmitted the correction task.',
      visit_id: task.visit_id,
      correction_task_id: correctionId,
      sync: syncDoc('sync_cursor_2026_03_11_103', 'accepted'),
    },
  );
}

function saveDraftDoc(visitId) {
  return {
    visit_id: visitId,
    status: 'saved',
    server_draft_version: `draft_${suffixFromId(visitId)}_v1`,
    saved_at: NOW,
  };
}

function reassignmentSnapshot(workOrderId, nextAssigneeUserId) {
  const snapshot = {
    entities: clone(baseEntities),
    indexes: clone(baseIndexes),
    summary: clone(baseSummary),
  };
  const workOrder = snapshot.entities.work_orders[workOrderId];
  const visitId = visitIdForWorkOrder(workOrderId);
  const assignmentId = workOrder.latest_assignment_id;
  const previousAssigneeUserId = workOrder.assignee_user_id;
  const previousTeamId = workOrder.team_id;
  const previousBranchId = workOrder.branch_id;
  const nextUser = snapshot.entities.users[nextAssigneeUserId];
  const nextTeamId = nextUser.team_ids[0];
  const nextBranchId = nextUser.branch_id;

  workOrder.assignee_user_id = nextAssigneeUserId;
  workOrder.team_id = nextTeamId;
  workOrder.branch_id = nextBranchId;
  workOrder.assignment_revision = Number(workOrder.assignment_revision ?? 1) + 1;
  snapshot.entities.assignments[assignmentId].assignee_user_id = nextAssigneeUserId;
  snapshot.entities.assignments[assignmentId].team_id = nextTeamId;
  snapshot.entities.assignments[assignmentId].branch_id = nextBranchId;
  snapshot.entities.assignments[assignmentId].revision = workOrder.assignment_revision;
  snapshot.entities.assignments[assignmentId].changed_at = NOW;
  snapshot.entities.visits[visitId].user_id = nextAssigneeUserId;
  snapshot.entities.visits[visitId].team_id = nextTeamId;
  snapshot.entities.visits[visitId].branch_id = nextBranchId;

  removeValue(snapshot.indexes.work_orders_by_assignee[previousAssigneeUserId], workOrderId);
  ensureList(snapshot.indexes.work_orders_by_assignee, nextAssigneeUserId).push(workOrderId);
  removeValue(snapshot.indexes.work_orders_by_team[previousTeamId], workOrderId);
  ensureList(snapshot.indexes.work_orders_by_team, nextTeamId).push(workOrderId);
  removeValue(snapshot.indexes.work_orders_by_branch[previousBranchId], workOrderId);
  ensureList(snapshot.indexes.work_orders_by_branch, nextBranchId).push(workOrderId);

  const alertId = 'alert_technician_reassign';
  snapshot.entities.alerts[alertId] = {
    id: alertId,
    role: 'technician',
    severity: 'medium',
    work_order_id: workOrderId,
    message: `${workOrder.number} was reassigned while the local plan was in progress.`,
  };
  const activityId = `activity_reassign_${suffixFromId(workOrderId)}`;
  snapshot.entities.activity_events[activityId] = {
    id: activityId,
    kind: 'assignment',
    work_order_id: workOrderId,
    visit_id: visitId,
    role: 'technician',
    message: `${workOrder.number} reassigned to ${nextUser.name}.`,
    created_at: NOW,
    unread: true,
  };
  ensureList(snapshot.indexes.activity_by_role, 'technician').push(activityId);
  if (!ensureList(snapshot.indexes.alerts_by_role, 'technician').includes(alertId)) {
    snapshot.indexes.alerts_by_role.technician.push(alertId);
  }
  if (snapshot.summary.activity_unread) {
    snapshot.summary.activity_unread.technician = (snapshot.summary.activity_unread.technician ?? 0) + 1;
  }
  return snapshot;
}

function syncPullReassignmentDoc(workOrderId, nextAssigneeUserId) {
  const snapshot = reassignmentSnapshot(workOrderId, nextAssigneeUserId);
  return {
    cursor: 'sync_cursor_2026_03_11_102',
    changes: [
      {
        kind: 'assignment',
        entity_id: snapshot.entities.work_orders[workOrderId].latest_assignment_id,
        work_order_id: workOrderId,
      },
      {
        kind: 'alert',
        entity_id: 'alert_technician_reassign',
        work_order_id: workOrderId,
      },
    ],
    status: 'idle',
    received_at: NOW,
    server_policies: {
      signature_required_on_complete: true,
      location_capture_optional: true,
      offline_queue_mode: 'client_ops_v1',
    },
    entities: {
      assignments: snapshot.entities.assignments,
      review_queue_items: snapshot.entities.review_queue_items,
      correction_tasks: snapshot.entities.correction_tasks,
      activity_events: snapshot.entities.activity_events,
      alerts: snapshot.entities.alerts,
    },
    indexes: snapshot.indexes,
    summary: snapshot.summary,
    sync: syncDoc('sync_cursor_2026_03_11_102', 'idle', {
      unread_alerts: 4,
      unread_activity: snapshot.summary.activity_unread?.technician ?? 2,
    }),
  };
}

function activityFeedReassignmentDoc(workOrderId, nextAssigneeUserId) {
  const snapshot = reassignmentSnapshot(workOrderId, nextAssigneeUserId);
  return payloadWithSnapshot(
    {
      items: Object.keys(snapshot.entities.activity_events),
      events: snapshot.entities.activity_events,
      alerts: snapshot.entities.alerts,
      sync: syncDoc('sync_cursor_2026_03_11_101', 'idle', {
        unread_alerts: snapshot.summary.activity_unread?.technician ?? 4,
      }),
    },
    snapshot,
    [workOrderId],
  );
}

function syncPushConflictDoc(workOrderId, nextAssigneeUserId) {
  const snapshot = reassignmentSnapshot(workOrderId, nextAssigneeUserId);
  const message = 'Work order was reassigned while the local submit was pending.';
  return {
    cursor: 'sync_cursor_2026_03_11_103',
    accepted_ops: [],
    conflicts: [
      {
        code: 'assignment_revision_mismatch',
        message,
        entity_id: workOrderId,
      },
    ],
    status: 'conflict',
    received_at: NOW,
    entities: {
      assignments: snapshot.entities.assignments,
      review_queue_items: snapshot.entities.review_queue_items,
      correction_tasks: snapshot.entities.correction_tasks,
      activity_events: snapshot.entities.activity_events,
      alerts: snapshot.entities.alerts,
    },
    indexes: snapshot.indexes,
    summary: snapshot.summary,
    sync: syncDoc('sync_cursor_2026_03_11_103', 'conflict', {
      conflict_status: 'conflict',
      conflict_message: message,
      conflict_code: 'assignment_revision_mismatch',
      conflict_entity_id: workOrderId,
      unread_alerts: 4,
      unread_activity: snapshot.summary.activity_unread?.technician ?? 2,
    }),
  };
}

function ensureList(doc, key) {
  if (!Array.isArray(doc[key])) {
    doc[key] = [];
  }
  return doc[key];
}

function removeValue(list, value) {
  if (!Array.isArray(list)) {
    return;
  }
  const index = list.indexOf(value);
  if (index >= 0) {
    list.splice(index, 1);
  }
}

function jsonText(doc) {
  return JSON.stringify(doc);
}

function bytesDoc(text) {
  const buffer = Buffer.from(text, 'utf8');
  return {
    bytes_len: buffer.length,
    text,
  };
}

function requestEnvelope(id, method, targetPath, body = '', headers = []) {
  return {
    schema_version: 'x07.http.request.envelope@0.1.0',
    id,
    method,
    path: targetPath,
    headers,
    body: body ? bytesDoc(body) : { bytes_len: 0, text: '' },
  };
}

function responseEnvelope(requestId, status, doc, headers = []) {
  const text = typeof doc === 'string' ? doc : jsonText(doc);
  return {
    schema_version: 'x07.http.response.envelope@0.1.0',
    request_id: requestId,
    status,
    headers,
    body: bytesDoc(text),
  };
}

function jsonHeaders() {
  return [
    {
      k: 'Content-Type',
      v: 'application/json',
    },
  ];
}

function exchange(requestId, method, targetPath, status, responseDoc, requestBody = '') {
  return {
    request: requestEnvelope(requestId, method, targetPath, requestBody, requestBody ? jsonHeaders() : []),
    response: responseEnvelope(requestId, status, responseDoc),
  };
}

function emptyUiTree() {
  return {
    v: 1,
    kind: 'x07.web_ui.tree',
    root: {
      k: 'el',
      tag: 'div',
      key: 'root',
      props: {
        attrs: {},
        class: ['app'],
        style: {},
      },
      on: [],
      children: [],
    },
  };
}

function emptyFrame(state = null) {
  return {
    v: 1,
    kind: 'x07.web_ui.frame',
    state: state == null ? null : clone(state),
    ui: emptyUiTree(),
    effects: [],
    patches: [],
    telemetry: {},
  };
}

function step(event, { state = null, http = [] } = {}) {
  return {
    i: 0,
    ui_dispatch: {
      v: 1,
      kind: 'x07.web_ui.dispatch',
      state: state == null ? null : clone(state),
      event,
    },
    ui_frame: emptyFrame(state),
    http,
    timing: { ui_ms: 0, http_ms: 0, total_ms: 0 },
  };
}

function click(target, options = {}) {
  return step({ type: 'click', target }, options);
}

function input(target, value, options = {}) {
  return step({ type: 'input', target, value }, options);
}

function traceDoc() {
  return {
    schema_version: 'x07.app.trace@0.1.0',
    meta: {
      tool: { name: 'x07-wasm', version: TOOL_VERSION },
      app: { name: 'x07_crewops', version: APP_VERSION },
      created_utc: CREATED_UTC,
    },
    steps: [
      {
        i: 0,
        ui_dispatch: {
          v: 1,
          kind: 'x07.web_ui.dispatch',
          state: null,
          event: { type: 'init' },
        },
        ui_frame: emptyFrame(bootstrapFrameState()),
        http: [
          exchange('req_bootstrap', 'GET', '/api/bootstrap', 200, bootstrapDoc),
        ],
        timing: { ui_ms: 0, http_ms: 0, total_ms: 0 },
      },
    ],
  };
}

function normalizeTraceStates(doc) {
  const steps = Array.isArray(doc.steps) ? doc.steps : [];
  let previousState = null;
  for (const item of steps) {
    const nextDispatchState = item?.ui_dispatch?.state == null ? previousState : item.ui_dispatch.state;
    const nextFrameState = item?.ui_frame?.state == null ? nextDispatchState : item.ui_frame.state;
    item.ui_dispatch = {
      ...(item.ui_dispatch ?? {}),
      v: 1,
      kind: 'x07.web_ui.dispatch',
      state: nextDispatchState == null ? null : clone(nextDispatchState),
    };
    const nextUiTree =
      item?.ui_frame?.ui != null && item.ui_frame.ui.root != null
        ? clone(item.ui_frame.ui)
        : emptyUiTree();
    item.ui_frame = {
      v: 1,
      kind: 'x07.web_ui.frame',
      state: nextFrameState == null ? null : clone(nextFrameState),
      ui: nextUiTree,
      effects: Array.isArray(item?.ui_frame?.effects) ? item.ui_frame.effects : [],
      patches: Array.isArray(item?.ui_frame?.patches) ? item.ui_frame.patches : [],
      telemetry: item?.ui_frame?.telemetry != null ? clone(item.ui_frame.telemetry) : {},
    };
    previousState = nextFrameState == null ? previousState : clone(nextFrameState);
  }
  return doc;
}

function clearStepStateAfter(doc, lastStepWithState) {
  const steps = Array.isArray(doc.steps) ? doc.steps : [];
  steps.forEach((item, index) => {
    if (index <= lastStepWithState) {
      return;
    }
    if (item?.ui_dispatch && typeof item.ui_dispatch === 'object') {
      item.ui_dispatch.state = null;
    }
    if (item?.ui_frame && typeof item.ui_frame === 'object') {
      item.ui_frame.state = null;
    }
  });
  return doc;
}

function mergeExistingGoldenFrames(doc, existingDoc) {
  const existingSteps = Array.isArray(existingDoc?.steps) ? existingDoc.steps : [];
  doc.steps.forEach((item, index) => {
    const existingStep = existingSteps[index];
    if (!existingStep || typeof existingStep !== 'object') {
      return;
    }
    if (existingStep.ui_dispatch && typeof existingStep.ui_dispatch === 'object') {
      item.ui_dispatch = {
        ...clone(item.ui_dispatch ?? {}),
        ...clone(existingStep.ui_dispatch),
        event: clone(item.ui_dispatch?.event ?? existingStep.ui_dispatch?.event ?? null),
        state: clone(existingStep.ui_dispatch?.state ?? item.ui_dispatch?.state ?? null),
      };
    }
    if (existingStep.ui_frame && typeof existingStep.ui_frame === 'object') {
      item.ui_frame = clone(existingStep.ui_frame);
    }
  });
  return doc;
}

function writeTrace(tracePath, doc) {
  doc.steps.forEach((item, index) => {
    item.i = index;
  });
  fs.mkdirSync(path.dirname(tracePath), { recursive: true });
  fs.writeFileSync(tracePath, `${JSON.stringify(doc, null, 2)}\n`);
}

function readJson(pathname) {
  return JSON.parse(fs.readFileSync(pathname, 'utf8'));
}

function isSuccessfulGoldenUpdate(reportPath) {
  if (!fs.existsSync(reportPath)) {
    return false;
  }
  const reportDoc = readJson(reportPath);
  const stdoutJson = reportDoc?.result?.stdout_json;
  return stdoutJson?.failed === 0 && stdoutJson?.updated_golden === true;
}

function updateGolden(tracePath) {
  const reportPath = path.join(REPORT_DIR, `${path.basename(tracePath, '.json')}.report.json`);
  try {
    execFileSync(
      x07Wasm,
      [
        'app',
        'test',
        '--dir',
        appDir,
        '--trace',
        tracePath,
        '--update-golden',
        '--json',
        '--report-out',
        reportPath,
        '--quiet-json',
        '--strict',
      ],
      { cwd: ROOT, stdio: 'pipe' },
    );
  } catch (error) {
    if (isSuccessfulGoldenUpdate(reportPath)) {
      return;
    }
    throw error;
  }
}

function pushRoleLogin(doc, role) {
  doc.steps.push(click(`role_${role}`, {
    http: [
      exchange(
        'req_login',
        'POST',
        '/api/session/dev-login',
        200,
        loginDoc(role),
        jsonText({ role, user_id: sessionDefaults[role].user_id }),
      ),
    ],
  }));
}

function pushNavLoad(doc, target, requestId, targetPath, responseDoc) {
  doc.steps.push(click(target, {
    http: [
      exchange(requestId, 'GET', targetPath, 200, responseDoc),
    ],
  }));
}

function draftsText(mutator = null) {
  const drafts = defaultDrafts();
  if (mutator) {
    mutator(drafts);
  }
  return jsonText(drafts);
}

const traces = [
  {
    path: path.join(ROOT, 'tests/traces/bootstrap_demo_happy.trace.json'),
    build(doc) {
      return doc;
    },
  },
  {
    path: path.join(ROOT, 'tests/traces/dispatch_assign_happy.trace.json'),
    build(doc) {
      pushRoleLogin(doc, 'dispatcher');
      pushNavLoad(doc, 'nav_dispatch', 'req_dispatch_board', '/api/dispatch/board', dispatchBoardDoc());
      doc.steps.push(click('action_assign', {
        http: [
          exchange('req_assign', 'POST', '/api/work-orders/wo_001/assign', 200, workOrderAssignDoc('wo_001'), '{}'),
        ],
      }));
      return doc;
    },
  },
  {
    path: path.join(ROOT, 'tests/traces/dispatch_reassign_happy.trace.json'),
    build(doc) {
      pushRoleLogin(doc, 'dispatcher');
      pushNavLoad(doc, 'nav_dispatch', 'req_dispatch_board', '/api/dispatch/board', dispatchBoardDoc());
      doc.steps.push(click('wo_006'));
      doc.steps.push(click('action_reassign', {
        http: [
          exchange('req_reassign', 'POST', '/api/work-orders/wo_006/reassign', 200, workOrderReassignDoc('wo_006'), '{}'),
        ],
      }));
      return doc;
    },
  },
  {
    path: path.join(ROOT, 'tests/traces/technician_reassigned_mid_draft.trace.json'),
    build(doc) {
      doc.steps.push(click('wo_017'));
      doc.steps.push(input('input_note', 'Draft update saved before reassignment.'));
      doc.steps.push(click('action_save_draft', {
        http: [
          exchange('req_draft', 'POST', '/api/visits/visit_017/save-draft', 200, saveDraftDoc('visit_017'), '{}'),
        ],
      }));
      doc.steps.push(click('action_sync', {
        http: [
          exchange('req_sync_pull', 'GET', '/api/sync/pull', 200, syncPullReassignmentDoc('wo_017', 'user_tech_noah')),
        ],
      }));
      return doc;
    },
  },
  {
    path: path.join(ROOT, 'tests/traces/supervisor_request_correction.trace.json'),
    build(doc) {
      pushRoleLogin(doc, 'supervisor');
      pushNavLoad(doc, 'nav_review', 'req_review_queue', '/api/review/queue', reviewQueueDoc());
      doc.steps.push(click('wo_016'));
      doc.steps.push(input('review_note', 'Need clearer evidence and a tighter summary.'));
      doc.steps.push(click('action_request_correction', {
        http: [
          exchange(
            'req_request_correction',
            'POST',
            '/api/review/visit_016/request-correction',
            200,
            reviewRequestCorrectionDoc('visit_016'),
            '{}',
          ),
        ],
      }));
      return doc;
    },
  },
  {
    path: path.join(ROOT, 'tests/traces/technician_correction_resubmit.trace.json'),
    build(doc) {
      doc.steps.push(click('wo_017'));
      doc.steps.push(input('response_note', 'Added photos and clarified the findings.'));
      doc.steps.push(click('action_resubmit_correction', {
        http: [
          exchange(
            'req_resubmit_correction',
            'POST',
            '/api/corrections/correction_017/resubmit',
            200,
            correctionResubmitDoc('correction_017'),
            '{}',
          ),
        ],
      }));
      return doc;
    },
  },
  {
    path: path.join(ROOT, 'tests/traces/review_queue_filtering.trace.json'),
    build(doc) {
      pushRoleLogin(doc, 'supervisor');
      pushNavLoad(doc, 'nav_review', 'req_review_queue', '/api/review/queue', reviewQueueDoc());
      doc.steps.push(click('wo_016', {
        state: runtimeStateForRole('supervisor', { route: 'review', workOrderId: 'wo_016', reviewFilter: 'awaiting_review' }),
      }));
      doc.steps.push(click('wo_017', {
        state: runtimeStateForRole('supervisor', { route: 'review', workOrderId: 'wo_017', reviewFilter: 'correction_requested' }),
      }));
      doc.steps.push(click('wo_025', {
        state: runtimeStateForRole('supervisor', { route: 'review', workOrderId: 'wo_025', reviewFilter: 'resubmitted' }),
      }));
      return doc;
    },
  },
  {
    path: path.join(ROOT, 'tests/traces/manager_dashboard_rollup.trace.json'),
    build(doc) {
      pushRoleLogin(doc, 'manager');
      pushNavLoad(doc, 'nav_manager', 'req_manager_summary', '/api/manager/summary', managerSummaryDoc());
      doc.steps.push(click('action_scope_team'));
      doc.steps.push(click('action_scope_branch'));
      return doc;
    },
  },
  {
    path: path.join(ROOT, 'tests/traces/local_notification_assignment_alert.trace.json'),
    build(doc) {
      doc.steps.push(click('wo_017'));
      doc.steps.push(click('action_sync', {
        http: [
          exchange('req_sync_pull', 'GET', '/api/sync/pull', 200, syncPullReassignmentDoc('wo_017', 'user_tech_noah')),
        ],
      }));
      doc.steps.push(click('nav_activity', {
        http: [
          exchange('req_activity_feed', 'GET', '/api/activity/feed', 200, activityFeedReassignmentDoc('wo_017', 'user_tech_noah')),
        ],
      }));
      doc.steps.push(click('action_activity_ack'));
      return doc;
    },
  },
  {
    path: path.join(ROOT, 'tests/traces/conflict_reassign_vs_local_submit.trace.json'),
    build(doc) {
      doc.steps.push(click('wo_017'));
      doc.steps.push(click('action_sync', {
        state: runtimeStateForRole('technician', {
          route: 'today',
          workOrderId: 'wo_017',
          networkStatus: 'offline',
        }),
      }));
      doc.steps.push(click('arrival_toggle'));
      doc.steps.push(input('input_temperature', '71'));
      doc.steps.push(click('filter_clean'));
      doc.steps.push(input('input_findings', 'Completed work locally before reassignment arrived.'));
      doc.steps.push(input('input_signature_name', 'Ava Mercer'));
      doc.steps.push(input('input_signature_role', 'Technician'));
      doc.steps.push(click('action_signature_add'));
      doc.steps.push(click('action_complete'));
      doc.steps.push(click('action_sync', {
        http: [
          exchange(
            'req_sync_push',
            'POST',
            '/api/sync/push',
            200,
            syncPushConflictDoc('wo_017', 'user_tech_noah'),
            jsonText({ ops: ['op_submit_visit_017'] }),
          ),
        ],
      }));
      return doc;
    },
    postprocess(doc) {
      return clearStepStateAfter(doc, 0);
    },
  },
  {
    path: path.join(ROOT, 'tests/traces/invoice_generate_happy.trace.json'),
    build(doc) {
      pushRoleLogin(doc, 'manager');
      pushNavLoad(doc, 'nav_invoices', 'req_invoice_list', '/api/invoices', invoiceListDoc());
      doc.steps.push(click('action_invoice_generate', {
        http: [
          exchange(
            'req_invoice_generate',
            'POST',
            '/api/invoices/generate',
            200,
            invoiceGenerateDoc(),
            draftsText(),
          ),
        ],
      }));
      doc.steps.push(click('action_select_invoice_inv_001', {
        http: [
          exchange('req_invoice_detail', 'GET', '/api/invoices/inv_001', 200, invoiceDetailMap.inv_001),
        ],
      }));
      doc.steps.push(click('action_invoice_artifact', {
        http: [
          exchange('req_invoice_artifact', 'GET', '/api/invoices/inv_001/artifact', 200, invoiceArtifactMap.inv_001),
        ],
      }));
      return doc;
    },
  },
  {
    path: path.join(ROOT, 'tests/traces/invoice_edit_and_issue.trace.json'),
    build(doc) {
      pushRoleLogin(doc, 'manager');
      pushNavLoad(doc, 'nav_invoices', 'req_invoice_list', '/api/invoices', invoiceListDoc());
      doc.steps.push(click('action_select_invoice_inv_001', {
        http: [
          exchange('req_invoice_detail', 'GET', '/api/invoices/inv_001', 200, invoiceDetailMap.inv_001),
        ],
      }));
      doc.steps.push(input('input_invoice_memo', 'Commercial walkthrough invoice for the approved visit.'));
      doc.steps.push(input('input_invoice_line_rate', '152.00'));
      doc.steps.push(input('input_invoice_due_date', '2026-04-02'));
      doc.steps.push(click('action_invoice_patch', {
        http: [
          exchange(
            'req_invoice_patch',
            'PATCH',
            '/api/invoices/inv_001',
            200,
            invoicePatchDoc(),
            draftsText((drafts) => {
              drafts.invoice_memo = 'Commercial walkthrough invoice for the approved visit.';
              drafts.invoice_line_rate = '152.00';
              drafts.invoice_due_date = '2026-04-02';
            }),
          ),
        ],
      }));
      doc.steps.push(click('action_invoice_issue', {
        http: [
          exchange('req_invoice_issue', 'POST', '/api/invoices/inv_001/issue', 200, invoiceIssueMap.inv_001, '{}'),
        ],
      }));
      doc.steps.push(click('action_service_summary', {
        http: [
          exchange('req_service_summary', 'GET', '/api/invoices/inv_001/service-summary', 200, serviceSummaryMap.inv_001),
        ],
      }));
      return doc;
    },
    postprocess(doc) {
      return clearStepStateAfter(doc, 0);
    },
  },
  {
    path: path.join(ROOT, 'tests/traces/partial_payment_record.trace.json'),
    build(doc) {
      pushRoleLogin(doc, 'manager');
      pushNavLoad(doc, 'nav_invoices', 'req_invoice_list', '/api/invoices', invoiceListDoc());
      doc.steps.push(click('action_select_invoice_inv_007', {
        http: [
          exchange('req_invoice_detail', 'GET', '/api/invoices/inv_007', 200, invoiceDetailMap.inv_007),
        ],
      }));
      doc.steps.push(input('input_payment_amount', '90.00'));
      doc.steps.push(input('input_payment_method', 'check'));
      doc.steps.push(input('input_payment_reference', 'CHK-55209'));
      doc.steps.push(click('action_invoice_payment', {
        http: [
          exchange(
            'req_invoice_payment',
            'POST',
            '/api/invoices/inv_007/payments',
            200,
            invoicePaymentMap.inv_007,
            draftsText((drafts) => {
              drafts.payment_amount = '90.00';
              drafts.payment_method = 'check';
              drafts.payment_reference = 'CHK-55209';
            }),
          ),
        ],
      }));
      return doc;
    },
  },
  {
    path: path.join(ROOT, 'tests/traces/overdue_aging_view.trace.json'),
    build(doc) {
      pushRoleLogin(doc, 'manager');
      pushNavLoad(doc, 'nav_receivables', 'req_finance_receivables', '/api/finance/receivables', financeReceivablesDoc());
      doc.steps.push(click('action_select_receivable_branch_north'));
      doc.steps.push(click('action_receivable_aging_toggle'));
      doc.steps.push(click('action_receivable_scope_toggle'));
      doc.steps.push(click('action_finance_receivables_refresh', {
        http: [
          exchange('req_finance_receivables', 'GET', '/api/finance/receivables', 200, financeReceivablesDoc()),
        ],
      }));
      return doc;
    },
  },
  {
    path: path.join(ROOT, 'tests/traces/customer_statement_view.trace.json'),
    build(doc) {
      pushRoleLogin(doc, 'manager');
      pushNavLoad(doc, 'nav_customers', 'req_customer_account', '/api/customers/cust_013/account', customerAccountMap.cust_013);
      doc.steps.push(click('action_customer_balance_toggle'));
      doc.steps.push(click('action_select_customer_cust_019', {
        http: [
          exchange('req_customer_account', 'GET', '/api/customers/cust_019/account', 200, customerAccountMap.cust_019),
        ],
      }));
      doc.steps.push(click('action_customer_refresh', {
        http: [
          exchange('req_customer_account', 'GET', '/api/customers/cust_019/account', 200, customerAccountMap.cust_019),
        ],
      }));
      return doc;
    },
  },
  {
    path: path.join(ROOT, 'tests/traces/finance_export_happy.trace.json'),
    build(doc) {
      pushRoleLogin(doc, 'manager');
      pushNavLoad(doc, 'nav_exports', 'req_export_center', '/api/exports/jobs', exportCenterDoc());
      doc.steps.push(input('input_export_date_from', '2026-02-01'));
      doc.steps.push(input('input_export_date_to', '2026-03-31'));
      doc.steps.push(click('action_export_kind_toggle'));
      doc.steps.push(click('action_export_format_toggle'));
      doc.steps.push(click('action_export_status_toggle'));
      doc.steps.push(click('action_export_create', {
        http: [
          exchange(
            'req_export_create',
            'POST',
            '/api/exports/jobs',
            202,
            exportCreateDoc(),
            draftsText((drafts) => {
              drafts.export_date_from = '2026-02-01';
              drafts.export_date_to = '2026-03-31';
              drafts.export_kind = 'receivables';
              drafts.export_format = 'json';
              drafts.export_status_filter = 'all';
            }),
          ),
        ],
      }));
      doc.steps.push(click('action_select_export_job_003'));
      return doc;
    },
    postprocess(doc) {
      return clearStepStateAfter(doc, 0);
    },
  },
  {
    path: path.join(ROOT, 'tests/traces/finance_export_retry.trace.json'),
    build(doc) {
      pushRoleLogin(doc, 'manager');
      pushNavLoad(doc, 'nav_exports', 'req_export_center', '/api/exports/jobs', exportCenterDoc());
      doc.steps.push(click('action_select_export_job_002'));
      doc.steps.push(click('action_export_retry', {
        http: [
          exchange('req_export_retry', 'POST', '/api/exports/jobs/export_job_002/retry', 200, exportRetryMap.export_job_002, '{}'),
        ],
      }));
      return doc;
    },
  },
  {
    path: path.join(ROOT, 'tests/traces/invoice_lock_conflict.trace.json'),
    build(doc) {
      pushRoleLogin(doc, 'manager');
      pushNavLoad(doc, 'nav_invoices', 'req_invoice_list', '/api/invoices', invoiceListDoc());
      doc.steps.push(click('action_select_invoice_inv_007', {
        http: [
          exchange('req_invoice_detail', 'GET', '/api/invoices/inv_007', 200, invoiceDetailMap.inv_007),
        ],
      }));
      doc.steps.push(click('action_invoice_issue', {
        http: [
          exchange('req_invoice_issue', 'POST', '/api/invoices/inv_007/issue', 409, invoiceLockConflictDoc(), '{}'),
        ],
      }));
      return doc;
    },
  },
  {
    path: path.join(ROOT, 'tests/traces/pricing_revision_mismatch.trace.json'),
    build(doc) {
      pushRoleLogin(doc, 'manager');
      pushNavLoad(doc, 'nav_pricing', 'req_pricing_config', '/api/pricing/config', pricingConfigDoc());
      doc.steps.push(click('action_select_price_book_customer'));
      doc.steps.push(input('input_price_book_name', 'Customer Override C18'));
      doc.steps.push(input('input_labor_rate_hourly', '118.00'));
      doc.steps.push(input('input_travel_fee', '33.00'));
      doc.steps.push(click('action_pricing_conflict', {
        http: [
          exchange(
            'req_pricing_update_conflict',
            'PATCH',
            '/api/pricing/config/conflict',
            409,
            pricingUpdateConflictDoc(),
            draftsText((drafts) => {
              drafts.price_book_name = 'Customer Override C18';
              drafts.labor_rate_hourly = '118.00';
              drafts.travel_fee = '33.00';
            }),
          ),
        ],
      }));
      return doc;
    },
  },
  {
    path: path.join(ROOT, 'tests/traces/manager_finance_dashboard.trace.json'),
    build(doc) {
      pushRoleLogin(doc, 'manager');
      pushNavLoad(doc, 'nav_finance', 'req_finance_summary', '/api/finance/summary', financeSummaryDoc());
      doc.steps.push(click('action_select_finance_branch_north'));
      doc.steps.push(click('action_select_finance_branch_south'));
      doc.steps.push(click('action_select_finance_global'));
      doc.steps.push(click('action_finance_receivables_refresh', {
        http: [
          exchange('req_finance_receivables', 'GET', '/api/finance/receivables', 200, financeReceivablesDoc()),
        ],
      }));
      doc.steps.push(click('action_finance_refresh', {
        http: [
          exchange('req_finance_summary', 'GET', '/api/finance/summary', 200, financeSummaryDoc()),
        ],
      }));
      return doc;
    },
  },
  {
    path: path.join(ROOT, 'tests/traces/payment_revision_conflict.trace.json'),
    build(doc) {
      pushRoleLogin(doc, 'manager');
      pushNavLoad(doc, 'nav_invoices', 'req_invoice_list', '/api/invoices', invoiceListDoc());
      doc.steps.push(click('action_select_invoice_inv_005', {
        http: [
          exchange('req_invoice_detail', 'GET', '/api/invoices/inv_005', 200, invoiceDetailMap.inv_005),
        ],
      }));
      doc.steps.push(input('input_payment_amount', '220.00'));
      doc.steps.push(input('input_payment_method', 'ach'));
      doc.steps.push(input('input_payment_reference', 'ACH-55201'));
      doc.steps.push(click('action_invoice_payment', {
        http: [
          exchange(
            'req_invoice_payment',
            'POST',
            '/api/invoices/inv_005/payments',
            409,
            paymentRevisionConflictDoc(),
            draftsText((drafts) => {
              drafts.payment_amount = '220.00';
              drafts.payment_method = 'ach';
              drafts.payment_reference = 'ACH-55201';
            }),
          ),
        ],
      }));
      return doc;
    },
  },
  {
    path: path.join(ROOT, 'tests/traces/estimate_create_happy.trace.json'),
    build(doc) {
      pushRoleLogin(doc, 'manager');
      pushNavLoad(doc, 'nav_estimates', 'req_estimate_list', '/api/estimates', estimateListDoc());
      doc.steps.push(input('input_estimate_note', 'Bundle the spring PM with condenser cleaning.'));
      doc.steps.push(input('input_estimate_line_unit_price', '210.00'));
      doc.steps.push(input('input_estimate_expiration_date', '2026-04-18'));
      doc.steps.push(click('action_estimate_create', {
        http: [
          exchange(
            'req_estimate_create',
            'POST',
            '/api/estimates',
            201,
            estimateCreateDoc,
            draftsText((drafts) => {
              drafts.commercial_ops.estimate_note = 'Bundle the spring PM with condenser cleaning.';
              drafts.commercial_ops.estimate_line_unit_price = '210.00';
              drafts.commercial_ops.estimate_expiration_date = '2026-04-18';
            }),
          ),
        ],
      }));
      return doc;
    },
  },
  {
    path: path.join(ROOT, 'tests/traces/estimate_revision_then_send.trace.json'),
    build(doc) {
      pushRoleLogin(doc, 'manager');
      pushNavLoad(doc, 'nav_estimates', 'req_estimate_list', '/api/estimates', estimateListDoc());
      doc.steps.push(click('action_select_estimate_est_001', {
        http: [
          exchange('req_estimate_detail', 'GET', '/api/estimates/est_001', 200, estimateDetailMap.est_001),
        ],
      }));
      doc.steps.push(input('input_estimate_note', 'Revision includes condenser cleaning and filter bundle.'));
      doc.steps.push(input('input_estimate_line_unit_price', '245.00'));
      doc.steps.push(click('action_estimate_patch', {
        http: [
          exchange(
            'req_estimate_patch',
            'PATCH',
            '/api/estimates/est_001',
            200,
            estimatePatchMap.est_001,
            draftsText((drafts) => {
              drafts.commercial_ops.estimate_note = 'Revision includes condenser cleaning and filter bundle.';
              drafts.commercial_ops.estimate_line_unit_price = '245.00';
            }),
          ),
        ],
      }));
      doc.steps.push(click('action_estimate_send', {
        http: [
          exchange('req_estimate_send', 'POST', '/api/estimates/est_001/send', 200, estimateSendMap.est_001, '{}'),
        ],
      }));
      return doc;
    },
  },
  {
    path: path.join(ROOT, 'tests/traces/customer_approve_and_convert.trace.json'),
    build(doc) {
      pushRoleLogin(doc, 'manager');
      pushNavLoad(doc, 'nav_estimates', 'req_estimate_list', '/api/estimates', estimateListDoc());
      doc.steps.push(click('action_select_estimate_est_002', {
        http: [
          exchange('req_estimate_detail', 'GET', '/api/estimates/est_002', 200, estimateDetailMap.est_002),
        ],
      }));
      doc.steps.push(input('input_estimate_signature_name', 'Morgan Hale'));
      doc.steps.push(input('input_estimate_signature_note', 'Approved for next available service window.'));
      doc.steps.push(click('action_estimate_approve', {
        http: [
          exchange(
            'req_estimate_approve',
            'POST',
            '/api/estimates/est_002/approve',
            200,
            estimateApproveMap.est_002,
            draftsText((drafts) => {
              drafts.commercial_ops.estimate_signature_name = 'Morgan Hale';
              drafts.commercial_ops.estimate_signature_note = 'Approved for next available service window.';
            }),
          ),
        ],
      }));
      doc.steps.push(click('action_estimate_convert', {
        http: [
          exchange('req_estimate_convert', 'POST', '/api/estimates/est_002/convert', 200, estimateConvertMap.est_002, '{}'),
        ],
      }));
      return doc;
    },
  },
  {
    path: path.join(ROOT, 'tests/traces/stale_approval_blocked.trace.json'),
    build(doc) {
      pushRoleLogin(doc, 'manager');
      pushNavLoad(doc, 'nav_estimates', 'req_estimate_list', '/api/estimates', estimateListDoc());
      doc.steps.push(click('action_select_estimate_est_003', {
        http: [
          exchange('req_estimate_detail', 'GET', '/api/estimates/est_003', 200, estimateDetailMap.est_003),
        ],
      }));
      doc.steps.push(input('input_estimate_signature_name', 'Dana Flores'));
      doc.steps.push(click('action_estimate_approve', {
        http: [
          exchange(
            'req_estimate_approve',
            'POST',
            '/api/estimates/est_003/approve',
            409,
            estimateApprovalConflictDoc,
            draftsText((drafts) => {
              drafts.commercial_ops.estimate_signature_name = 'Dana Flores';
            }),
          ),
        ],
      }));
      return doc;
    },
  },
  {
    path: path.join(ROOT, 'tests/traces/contract_create_and_activate.trace.json'),
    build(doc) {
      pushRoleLogin(doc, 'manager');
      pushNavLoad(doc, 'nav_contracts', 'req_contract_list', '/api/contracts', contractListDoc());
      doc.steps.push(input('input_contract_start_date', '2026-04-01'));
      doc.steps.push(input('input_contract_end_date', '2027-03-31'));
      doc.steps.push(click('action_contract_create', {
        http: [
          exchange(
            'req_contract_create',
            'POST',
            '/api/contracts',
            201,
            contractCreateDoc,
            draftsText((drafts) => {
              drafts.commercial_ops.contract_start_date = '2026-04-01';
              drafts.commercial_ops.contract_end_date = '2027-03-31';
            }),
          ),
        ],
      }));
      doc.steps.push(click('action_contract_resume', {
        http: [
          exchange('req_contract_resume', 'POST', '/api/contracts/agreement_004/resume', 200, contractResumeMap.agreement_004, '{}'),
        ],
      }));
      return doc;
    },
  },
  {
    path: path.join(ROOT, 'tests/traces/recurring_plan_generate_schedule.trace.json'),
    build(doc) {
      pushRoleLogin(doc, 'manager');
      pushNavLoad(doc, 'nav_recurring', 'req_recurring_board', '/api/recurring/board', recurringBoardDoc());
      doc.steps.push(click('action_select_recurring_recurring_plan_001'));
      doc.steps.push(click('action_recurring_generate', {
        http: [
          exchange(
            'req_recurring_generate',
            'POST',
            '/api/recurring/recurring_plan_001/generate',
            200,
            recurringGenerateMap.recurring_plan_001,
            '{}',
          ),
        ],
      }));
      return doc;
    },
  },
  {
    path: path.join(ROOT, 'tests/traces/recurring_skip_and_resume.trace.json'),
    build(doc) {
      pushRoleLogin(doc, 'manager');
      pushNavLoad(doc, 'nav_recurring', 'req_recurring_board', '/api/recurring/board', recurringBoardDoc());
      doc.steps.push(click('action_select_recurring_recurring_plan_002'));
      doc.steps.push(input('input_recurring_skip_reason', 'Tenant blackout window through spring remodel.'));
      doc.steps.push(click('action_recurring_skip', {
        http: [
          exchange(
            'req_recurring_skip',
            'POST',
            '/api/recurring/recurring_plan_002/skip',
            200,
            recurringSkipMap.recurring_plan_002,
            draftsText((drafts) => {
              drafts.commercial_ops.recurring_skip_reason = 'Tenant blackout window through spring remodel.';
            }),
          ),
        ],
      }));
      doc.steps.push(click('nav_contracts', {
        http: [
          exchange('req_contract_list', 'GET', '/api/contracts', 200, contractListDoc()),
        ],
      }));
      doc.steps.push(click('action_select_contract_agreement_002'));
      doc.steps.push(click('action_contract_resume', {
        http: [
          exchange('req_contract_resume', 'POST', '/api/contracts/agreement_002/resume', 200, contractResumeMap.agreement_002, '{}'),
        ],
      }));
      return doc;
    },
  },
  {
    path: path.join(ROOT, 'tests/traces/webhook_delivery_retry.trace.json'),
    build(doc) {
      pushRoleLogin(doc, 'manager');
      pushNavLoad(doc, 'nav_integrations', 'req_integrations_center', '/api/integrations', integrationsCenterDoc());
      doc.steps.push(click('action_select_integration_endpoint_crm'));
      doc.steps.push(click('action_integrations_deliveries', {
        http: [
          exchange('req_integrations_deliveries', 'GET', '/api/integrations/deliveries', 200, integrationsDeliveriesDoc()),
        ],
      }));
      doc.steps.push(click('action_integrations_delivery_retry', {
        http: [
          exchange(
            'req_integrations_delivery_retry',
            'POST',
            '/api/integrations/deliveries/delivery_002/retry',
            200,
            integrationsDeliveryRetryDoc,
            '{}',
          ),
        ],
      }));
      return doc;
    },
  },
  {
    path: path.join(ROOT, 'tests/traces/renewal_dashboard_view.trace.json'),
    build(doc) {
      pushRoleLogin(doc, 'manager');
      pushNavLoad(doc, 'nav_contracts', 'req_contract_list', '/api/contracts', contractListDoc());
      doc.steps.push(click('action_select_contract_agreement_003'));
      doc.steps.push(click('action_contract_refresh', {
        http: [
          exchange('req_contract_list', 'GET', '/api/contracts', 200, contractListDoc()),
        ],
      }));
      return doc;
    },
  },
  {
    path: path.join(ROOT, 'tests/traces/conversion_revision_conflict.trace.json'),
    build(doc) {
      pushRoleLogin(doc, 'manager');
      pushNavLoad(doc, 'nav_estimates', 'req_estimate_list', '/api/estimates', estimateListDoc());
      doc.steps.push(click('action_select_estimate_est_003', {
        http: [
          exchange('req_estimate_detail', 'GET', '/api/estimates/est_003', 200, estimateDetailMap.est_003),
        ],
      }));
      doc.steps.push(click('action_estimate_convert', {
        http: [
          exchange('req_estimate_convert', 'POST', '/api/estimates/est_003/convert', 409, estimateConversionConflictDoc, '{}'),
        ],
      }));
      return doc;
    },
  },
];

const selectedTraces = traceFilter == null
  ? traces
  : traces.filter((trace) => path.basename(trace.path).includes(traceFilter));

if (selectedTraces.length === 0) {
  process.stderr.write(`no traces matched filter: ${traceFilter}\n`);
  process.exit(1);
}

const goldenFailures = [];
for (const trace of selectedTraces) {
  const existingDoc = fs.existsSync(trace.path)
    ? JSON.parse(fs.readFileSync(trace.path, 'utf8'))
    : null;
  const generatedDoc = trace.postprocess != null
    ? trace.postprocess(normalizeTraceStates(trace.build(traceDoc())))
    : normalizeTraceStates(trace.build(traceDoc()));
  const doc = updateGoldenEnabled || authoredOnly
    ? generatedDoc
    : existingDoc == null
      ? generatedDoc
      : mergeExistingGoldenFrames(generatedDoc, existingDoc);
  writeTrace(trace.path, doc);
  if (updateGoldenEnabled) {
    try {
      updateGolden(trace.path);
    } catch (error) {
      writeTrace(trace.path, generatedDoc);
      goldenFailures.push({
        path: trace.path,
        message: error instanceof Error ? error.message : String(error),
      });
    }
  }
  process.stdout.write(`${path.relative(ROOT, trace.path)}\n`);
}

if (goldenFailures.length > 0) {
  process.stderr.write('golden update failed for one or more traces\n');
  for (const failure of goldenFailures) {
    process.stderr.write(`${path.relative(ROOT, failure.path)}: ${failure.message}\n`);
  }
  process.exitCode = 1;
}
