# CrewOps Architecture

CrewOps `v0.3.0` is a single-repo, single-reducer, single-backend operations app. The M4 step keeps the same deterministic web or device showcase shape from earlier milestones, but it now exposes four role surfaces, shared activity and alert state, supervisor review and correction loops, and manager rollups on top of the technician execution foundation.

## Repo Layers

- [`frontend/`](../frontend)
  - reducer modules, role shells, tests, and the `std-web-ui@0.2.1` dependency
- [`backend/`](../backend)
  - deterministic API handlers for bootstrap, execution, dispatch, review, corrections, activity, manager summary, and sync
- [`arch/`](../arch)
  - web-ui, app, wasm, device, SLO, and provenance profiles
- [`tests/`](../tests)
  - trace replay assets, generated regression artifacts, and deterministic seed files
- [`scripts/ci/`](../scripts/ci)
  - seed regeneration and the canonical build or test or package gate

## Frontend Reducer

The reducer entrypoint is [`frontend/src/app.x07.json`](../frontend/src/app.x07.json).

The app still runs one shared state tree instead of one reducer per role. M4 extends that tree with new operational branches rather than duplicating state across shells.

Primary frontend modules:

- [`frontend/src/routes.x07.json`](../frontend/src/routes.x07.json)
  - role-aware route selection for dispatcher, supervisor, manager, and technician
- [`frontend/src/session.x07.json`](../frontend/src/session.x07.json)
  - dev login payloads and deterministic role switching
- [`frontend/src/state.x07.json`](../frontend/src/state.x07.json)
  - default document shape, `0.3.0` app metadata, and M4 route or filter defaults
- [`frontend/src/entities.x07.json`](../frontend/src/entities.x07.json)
  - normalized entity maps, indexes, and summary defaults for multi-role views
- [`frontend/src/drafts.x07.json`](../frontend/src/drafts.x07.json)
  - intake and correction-related draft documents
- [`frontend/src/execution.x07.json`](../frontend/src/execution.x07.json)
  - technician execution state, validation, evidence, location, and submission helpers
- [`frontend/src/sync.x07.json`](../frontend/src/sync.x07.json)
  - queue state, unread counters, and deterministic conflict banners
- [`frontend/src/shell_dispatcher.x07.json`](../frontend/src/shell_dispatcher.x07.json)
  - dispatch board identity and copy
- [`frontend/src/shell_supervisor.x07.json`](../frontend/src/shell_supervisor.x07.json)
  - review queue identity and copy
- [`frontend/src/shell_manager.x07.json`](../frontend/src/shell_manager.x07.json)
  - manager dashboard identity and copy

The reducer state is organized into:

- `session`
- `bootstrap`
- `ui`
- `entities`
- `indexes`
- `sync`
- `settings`
- `diagnostics`
- `summary`
- `drafts`
- `template`
- `execution`
- `meta`

## Role Surfaces

### Technician

- `today` remains the primary route.
- Execution still owns checklist progression, evidence capture or import, signatures, check-in or check-out, blocked submission, autosave, offline queueing, and reconnect sync.
- M4 adds reassignment awareness, correction-task resubmission context, and activity or alert unread state.

### Dispatcher

- `dispatch` is the primary route.
- The dispatcher board reads normalized work orders, assignments, day filters, branch filters, team filters, priority, review state, and role-specific alerts.
- Intake and editing flows live alongside assignment and reassignment APIs instead of separate admin tooling.

### Supervisor

- `review` is the primary route.
- The supervisor surface reads `review_queue_items`, `review_decisions`, `correction_tasks`, and `correction_responses`.
- Approve, reject, and request-correction actions all use deterministic backend responses with snapshot updates.

### Manager

- `manager` is the primary route.
- Dashboard cards and drill-down views are driven by normalized summary structures such as `manager_metrics`, `branch_rollups`, `team_rollups`, and `dashboard_rollup`.
- Managers also consume shared activity and alert state rather than a separate reporting app.

### Shared Activity

- `activity` is a shared route available across roles.
- The reducer reads `activity_events`, `alerts`, `activity_by_role`, `alerts_by_role`, and unread counts from the same normalized seed snapshot and sync updates.

## Backend Surface

The backend entrypoint is [`backend/src/app.x07.json`](../backend/src/app.x07.json). It routes deterministic request envelopes to focused handlers:

- [`backend/src/bootstrap.x07.json`](../backend/src/bootstrap.x07.json)
  - `GET /api/bootstrap`
  - `GET /api/meta/app`
- [`backend/src/session.x07.json`](../backend/src/session.x07.json)
  - `POST /api/session/dev-login`
- [`backend/src/work_orders.x07.json`](../backend/src/work_orders.x07.json)
  - `POST /api/work-orders`
  - `PATCH /api/work-orders/:id`
  - `POST /api/work-orders/:id/assign`
  - `POST /api/work-orders/:id/reassign`
- [`backend/src/dispatch.x07.json`](../backend/src/dispatch.x07.json)
  - `GET /api/dispatch/board`
- [`backend/src/review.x07.json`](../backend/src/review.x07.json)
  - `GET /api/review/queue`
  - `POST /api/review/:visit_id/approve`
  - `POST /api/review/:visit_id/reject`
  - `POST /api/review/:visit_id/request-correction`
- [`backend/src/corrections.x07.json`](../backend/src/corrections.x07.json)
  - `POST /api/corrections/:id/resubmit`
- [`backend/src/activity.x07.json`](../backend/src/activity.x07.json)
  - `GET /api/activity/feed`
- [`backend/src/manager_summary.x07.json`](../backend/src/manager_summary.x07.json)
  - `GET /api/manager/summary`
- [`backend/src/templates.x07.json`](../backend/src/templates.x07.json)
  - `GET /api/templates/:id`
- [`backend/src/visits.x07.json`](../backend/src/visits.x07.json)
  - technician execution routes
- [`backend/src/attachments.x07.json`](../backend/src/attachments.x07.json)
  - attachment registration and content upload
- [`backend/src/sync.x07.json`](../backend/src/sync.x07.json)
  - `GET /api/sync/pull`
  - `POST /api/sync/push`

The backend remains deterministic and seed-backed. It does not introduce a live database for M4, but it now returns richer role snapshots and operational response envelopes.

## Seed, Bootstrap, And Sync

The canonical demo data still starts in [`scripts/ci/seed_demo.sh`](../scripts/ci/seed_demo.sh), which regenerates:

- [`tests/fixtures/demo_org.json`](../tests/fixtures/demo_org.json)
- [`backend/src/demo_seed.x07.json`](../backend/src/demo_seed.x07.json)

M4 expands the generated snapshot to include:

- assignments and assignment revisions
- schedule windows and dispatch filters
- review queue items and review decisions
- correction tasks and correction responses
- role-aware activity events and alerts
- branch or team summaries, dashboard rollups, and workload snapshots
- unread counts and conflict metadata under sync and summary branches

Bootstrap still hydrates cache first and then HTTP when available. Sync still uses deterministic pull or push envelopes, but the envelope now carries richer server state such as unread counts, conflict fields, and M4 summaries.

## CI And Release Shape

[`scripts/ci/check_all.sh`](../scripts/ci/check_all.sh) remains the authoritative CrewOps gate for:

- lock and profile validation
- frontend and backend test harness runs
- app build and serve smoke
- trace replay and generated regression replay
- pack, verify, provenance, deploy-plan, and SLO evaluation
- desktop headless smoke
- iOS and Android package generation

The `v0.3.0` release bar is the M4 multi-role matrix: dispatcher control, supervisor review and correction loops, manager drill-down, shared activity and alerts, and technician offline or evidence flows. The only intentional workspace-local gap remains the optional `x07-platform` smoke probe.

## Current Boundaries

- CrewOps is still seed-backed and deterministic rather than database-backed.
- The mobile dev profiles still require a reachable backend URL before real simulator or device packaging.
- Release and device packaging use the same reducer bundle; there is no dynamic code loading or runtime WASM replacement.
