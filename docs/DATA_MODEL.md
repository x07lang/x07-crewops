# CrewOps Data Model

CrewOps now ships the M4 multi-role demo seed. The handwritten generator is [`scripts/ci/seed_demo.sh`](../scripts/ci/seed_demo.sh). It regenerates the canonical fixture [`tests/fixtures/demo_org.json`](../tests/fixtures/demo_org.json) and mirrors the same tenant shape into [`backend/src/demo_seed.x07.json`](../backend/src/demo_seed.x07.json) for deterministic backend bootstrap and replay flows.

## Seed Scope

- `1` organization: `org_demo`
- `2` branches: `branch_north`, `branch_south`
- `3` teams: `team_north_alpha`, `team_north_beta`, `team_south_gamma`
- `11` users: `8` technicians, `1` dispatcher, `1` supervisor, `1` manager
- `20` customers
- `30` sites
- `60` assets
- `25` work orders
- `25` visits
- `25` assignments
- `25` schedule windows
- `3` review queue items
- `1` review decision
- `1` correction task
- `1` correction response
- `25` activity events
- `4` alerts
- `1` SLA policy bundle
- `2` branch summaries
- `3` team summaries
- `1` dashboard rollup
- `3` workload snapshots
- `1` dispatch filter profile
- `3` checklist templates
- `3` catalog parts

The generated fixture top level now includes:

- `organization`
- `branches`
- `teams`
- `users`
- `customers`
- `sites`
- `assets`
- `work_orders`
- `visits`
- `assignments`
- `schedule_windows`
- `templates`
- `parts_catalog`
- `review_queue_items`
- `review_decisions`
- `correction_tasks`
- `correction_responses`
- `activity_events`
- `alerts`
- `sla_policies`
- `dispatch_filters`
- `branch_summaries`
- `team_summaries`
- `dashboard_rollups`
- `workload_snapshots`
- `indexes`
- `summary`

## Roles And Ownership

- One organization owns all branches.
- Each branch owns teams, customers, sites, and primary branch assignment for users.
- Technician users belong to one team.
- Dispatcher, supervisor, and manager demo users span the full seeded organization so the same dataset drives all role shells.

The seeded role set is:

- `technician`
- `dispatcher`
- `supervisor`
- `manager`

## Core Operational Entities

### Work orders and visits

Work orders remain the primary operational envelope. In M4 they carry both technician execution context and dispatcher or supervisor control fields:

- identity: `id`, `number`, `title`
- ownership: `branch_id`, `team_id`, `assignee_user_id`
- customer context: `customer_id`, `site_id`, `asset_id`
- scheduling: `scheduled_day`, `window`
- status and priority: `status`, `priority`, `sla_bucket`
- execution binding: `template_id`, `completion_policy`, `allowed_part_ids`
- M4 control state: `assignment_revision`, `latest_assignment_id`, review-state indexes, and summary rollup participation

Visits remain the technician execution records attached to work orders. They still own the nested execution payload, but they now also participate in review, correction, activity, and alert flows.

### Assignments and schedule windows

Assignments are first-class M4 records rather than implicit work-order fields. Each assignment captures:

- `id`
- `work_order_id`
- `assignee_user_id`
- `team_id`
- `branch_id`
- `revision`
- `scheduled_day`
- `window`
- `priority`
- `changed_at`

Schedule windows keep the dispatcher-facing planning window normalized separately from visit execution.

### Review and correction loop

Supervisor review is modeled by four connected entity families:

- `review_queue_items`
- `review_decisions`
- `correction_tasks`
- `correction_responses`

These records let the app represent:

- awaiting-review submissions
- approval or rejection decisions
- correction requests with reason codes and supervisor notes
- technician resubmission back to the queue

The current seeded review-state families in indexes are:

- `not_ready`
- `not_required`
- `awaiting_review`
- `approved`
- `correction_requested`
- `resubmitted`

### Activity and alerts

`activity_events` model role-visible operational feed items such as assignment, dispatch readiness, arrival, blocked work, submit, awaiting review, approval, and intake creation.

`alerts` model higher-signal role-aware exceptions:

- dispatcher overdue or SLA risk
- supervisor review backlog
- manager branch risk
- technician reassignment

Unread rollups are summarized under `summary.activity_unread` and mirrored into sync metadata.

### Rollups and summaries

M4 adds normalized management views rather than ad hoc joined blobs:

- `branch_summaries`
- `team_summaries`
- `dashboard_rollups`
- `workload_snapshots`
- `sla_policies`
- `dispatch_filters`

The `summary` branch exposes shell-facing aggregates:

- `counts`
- `status_counts`
- `attention_work_orders`
- `dispatcher_focus`
- `manager_metrics`
- `supervisor_metrics`
- `technician_today`
- `activity_unread`
- `branch_rollups`
- `team_rollups`
- `dashboard_rollup`

## Reducer Maps And Indexes

The reducer normalizes seeded entities under `entities.*`. M4 requires more read-optimized indexes than the earlier technician-only flow.

Current index families:

- `work_orders_by_status`
- `work_orders_by_assignee`
- `work_orders_by_branch`
- `work_orders_by_team`
- `work_orders_by_day`
- `work_orders_by_priority`
- `work_orders_by_review_state`
- `review_queue_by_status`
- `alerts_by_role`
- `activity_by_role`
- `assets_by_site`
- `sites_by_customer`

These indexes let dispatcher, supervisor, manager, and technician shells read the same normalized source of truth without per-view scanning logic.

## Execution, Drafts, And Sync

Technician execution still lives in the nested `execution` branch and selected visit state. M4 keeps that execution model but adds operational overlays rather than replacing it.

Reducer-only operational state now includes:

- intake and correction drafts
- review selection state
- activity and alert selection state
- unread counters
- sync conflict fields such as `conflict_status`, `conflict_code`, and `conflict_entity_id`

Pending client ops still live in `sync.pending_ops`. They remain deterministic envelopes, but the release bar now includes dispatch-related state changes, correction resubmission, and alert or activity propagation alongside technician offline work.

## Lifecycle Enums

### Work-order status line

- `draft`
- `scheduled`
- `dispatched`
- `en_route`
- `on_site`
- `blocked`
- `completed`
- `needs_review`
- `invoiced`
- `closed`
- `canceled`

### Role surface routing

- `technician` defaults to `today`
- `dispatcher` defaults to `dispatch`
- `supervisor` defaults to `review`
- `manager` defaults to `manager`

## Relationship Invariants

- IDs are deterministic, ASCII, and stable across regenerated fixtures.
- Cross-entity references stay normalized by id.
- Each work order points at exactly one customer, site, asset, assignee, team, branch, and template.
- Each visit belongs to one work order and one technician assignee.
- Assignment revisions are explicit and deterministic.
- Review and correction entities link back to the originating visit or work order.
- Activity and alerts are role-scoped rather than duplicated per shell.
- Reducer-only drafts and execution state stay separate from seeded normalized entities.
- Web, desktop, iOS, Android, and replay flows all consume the same tenant shape.
