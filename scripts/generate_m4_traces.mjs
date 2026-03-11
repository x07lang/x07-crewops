import fs from 'fs';
import path from 'path';
import { execFileSync } from 'child_process';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT = path.resolve(__dirname, '..');
const FIXTURE_PATH = path.join(ROOT, 'tests/fixtures/demo_org.json');
const REPORT_DIR = path.join(ROOT, 'build/reports');
const APP_DIR = path.join(ROOT, 'dist/crewops_gate/app.crewops_dev');
const X07_WASM = path.join(ROOT, '../x07-wasm-backend/target/debug/x07-wasm');
const CREATED_UTC = '2026-03-11T00:00:00Z';
const APP_VERSION = '0.3.0';
const TOOL_VERSION = '0.2.3';
const NOW = '2026-03-11T00:00:00Z';

const argv = process.argv.slice(2);
const updateGoldenEnabled = argv.includes('--update-golden');
const appDirArg = argv.find((value) => value.startsWith('--app-dir='));
const x07WasmArg = argv.find((value) => value.startsWith('--x07-wasm='));
const appDir = appDirArg ? appDirArg.slice('--app-dir='.length) : APP_DIR;
const x07Wasm = x07WasmArg ? x07WasmArg.slice('--x07-wasm='.length) : X07_WASM;

const fixture = JSON.parse(fs.readFileSync(FIXTURE_PATH, 'utf8'));
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
};
const bootstrapWorkOrderIds = ['wo_001', 'wo_002', 'wo_003', 'wo_004', 'wo_005', 'wo_006'];
const bootstrapTemplateIds = ['tmpl_arrival', 'tmpl_pm', 'tmpl_closeout'];
const reviewSnapshotWorkOrderIds = ['wo_016', 'wo_017', 'wo_025'];
const baseIndexes = fixture.indexes;
const baseSummary = fixture.summary;
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
    bootstrapWorkOrderIds.map((id) => [
      id,
      compactWorkOrder(fixture.work_orders[id]),
    ]),
  ),
  templates: Object.fromEntries(
    bootstrapTemplateIds.map((id) => [
      id,
      compactTemplate(fixture.templates[id]),
    ]),
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
    selected_customer_id: null,
    selected_site_id: null,
    selected_asset_id: null,
    selected_review_visit_id: 'visit_001',
    selected_correction_id: null,
    selected_activity_id: null,
    selected_alert_id: null,
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
    unread_alerts: 4,
    unread_activity: 6,
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

function emptyFrame(state = null) {
  return {
    kind: 'x07.web_ui.frame',
    state: state == null ? null : clone(state),
    effects: [],
    patches: [],
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
    item.ui_frame = {
      kind: 'x07.web_ui.frame',
      effects: Array.isArray(item?.ui_frame?.effects) ? item.ui_frame.effects : [],
      patches: Array.isArray(item?.ui_frame?.patches) ? item.ui_frame.patches : [],
      state: nextFrameState == null ? null : clone(nextFrameState),
    };
    previousState = nextFrameState == null ? previousState : clone(nextFrameState);
  }
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

function updateGolden(tracePath) {
  const reportPath = path.join(REPORT_DIR, `${path.basename(tracePath, '.json')}.report.json`);
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
      doc.steps.push(click('role_dispatcher', {
        http: [
          exchange(
            'req_login',
            'POST',
            '/api/session/dev-login',
            200,
            loginDoc('dispatcher'),
            jsonText({ role: 'dispatcher', user_id: sessionDefaults.dispatcher.user_id }),
          ),
        ],
      }));
      doc.steps.push(click('nav_dispatch', {
        http: [
          exchange('req_dispatch_board', 'GET', '/api/dispatch/board', 200, dispatchBoardDoc()),
        ],
      }));
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
      doc.steps.push(click('role_dispatcher', {
        http: [
          exchange(
            'req_login',
            'POST',
            '/api/session/dev-login',
            200,
            loginDoc('dispatcher'),
            jsonText({ role: 'dispatcher', user_id: sessionDefaults.dispatcher.user_id }),
          ),
        ],
      }));
      doc.steps.push(click('nav_dispatch', {
        http: [
          exchange('req_dispatch_board', 'GET', '/api/dispatch/board', 200, dispatchBoardDoc()),
        ],
      }));
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
      doc.steps.push(click('role_supervisor', {
        http: [
          exchange(
            'req_login',
            'POST',
            '/api/session/dev-login',
            200,
            loginDoc('supervisor'),
            jsonText({ role: 'supervisor', user_id: sessionDefaults.supervisor.user_id }),
          ),
        ],
      }));
      doc.steps.push(click('nav_review', {
        http: [
          exchange('req_review_queue', 'GET', '/api/review/queue', 200, reviewQueueDoc()),
        ],
      }));
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
      doc.steps.push(click('role_supervisor', {
        http: [
          exchange(
            'req_login',
            'POST',
            '/api/session/dev-login',
            200,
            loginDoc('supervisor'),
            jsonText({ role: 'supervisor', user_id: sessionDefaults.supervisor.user_id }),
          ),
        ],
      }));
      doc.steps.push(click('nav_review', {
        http: [
          exchange('req_review_queue', 'GET', '/api/review/queue', 200, reviewQueueDoc()),
        ],
      }));
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
      doc.steps.push(click('role_manager', {
        http: [
          exchange(
            'req_login',
            'POST',
            '/api/session/dev-login',
            200,
            loginDoc('manager'),
            jsonText({ role: 'manager', user_id: sessionDefaults.manager.user_id }),
          ),
        ],
      }));
      doc.steps.push(click('nav_manager', {
        http: [
          exchange('req_manager_summary', 'GET', '/api/manager/summary', 200, managerSummaryDoc()),
        ],
      }));
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
  },
];

const goldenFailures = [];
for (const trace of traces) {
  const existingDoc = fs.existsSync(trace.path)
    ? JSON.parse(fs.readFileSync(trace.path, 'utf8'))
    : null;
  const doc = updateGoldenEnabled || existingDoc == null
    ? mergeExistingGoldenFrames(
        normalizeTraceStates(trace.build(traceDoc())),
        existingDoc,
      )
    : existingDoc;
  writeTrace(trace.path, doc);
  if (updateGoldenEnabled) {
    try {
      updateGolden(trace.path);
    } catch (error) {
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
