# CrewOps Data Model

CrewOps now ships the current technician execution seed. The generated source of truth lives in [`tests/fixtures/demo_org.json`](../tests/fixtures/demo_org.json) and is mirrored into [`backend/src/demo_seed.x07.json`](../backend/src/demo_seed.x07.json) for deterministic backend bootstrap and replay flows.

## Seed Scope

- `1` organization: `org_demo`
- `2` branches: `branch_north`, `branch_south`
- `3` teams: `team_north_alpha`, `team_north_beta`, `team_south_gamma`
- `10` users: `8` technicians, `1` dispatcher, `1` manager
- `20` customers
- `30` sites
- `60` assets
- `25` work orders
- `25` visits
- `3` checklist templates
- `3` catalog parts

The fixture top level uses `organization`, `branches`, `teams`, `users`, `customers`, `sites`, `assets`, `work_orders`, `visits`, `templates`, `parts_catalog`, `indexes`, and `summary`. The frontend normalizes those into reducer maps under `entities.*`, while execution-only state stays under the dedicated `execution` and `sync` branches.

## Core Entities

### Organization, branches, teams, and users

- One organization owns all branches.
- Each branch owns teams, customers, sites, and the primary branch assignment for users.
- Technician users belong to one team.
- Dispatcher and manager demo users span all teams so the same seed supports all three shells.

### Customers, sites, and assets

- Customers belong to a branch.
- Sites belong to one customer and one branch.
- Assets belong to one site and inherit the customer and branch context through that site.
- The reducer keeps supporting indexes for `assets_by_site` and `sites_by_customer`.

### Work orders

Each work order is the dispatcher-facing assignment envelope for one visitable task. The seeded shape includes:

- identity: `id`, `number`, `title`
- scheduling: `scheduled_day`, `window`
- routing: `branch_id`, `team_id`, `assignee_user_id`
- customer context: `customer_id`, `site_id`, `asset_id`
- workflow control: `status`, `priority`, `sla_bucket`
- execution binding: `template_id`, `completion_policy`, `allowed_part_ids`

`completion_policy` is duplicated at the work-order layer so scheduling surfaces can reason about required signoff, block reasons, and optional location capture without opening the template in detail.

### Visits

Visits are the technician execution records attached to work orders. The seeded visit record carries:

- assignment context: `work_order_id`, `user_id`, `team_id`, `branch_id`
- field context: `site_id`, `asset_id`, `template_id`
- planning: `planned_start`
- coarse visit state: `state`
- execution seed: `execution`

Current seeded visit-state distribution:

- `planned`: `10`
- `logged`: `15`

The coarse `state` stays aligned with the broader operational pipeline. Detailed technician progress lives inside the nested `execution` object.

### Templates

Checklist templates are first-class seeded entities under `entities.templates`. A template includes:

- identity: `id`, `name`, `version`
- `sections`
- `completion_policy`
- `evidence_policy`

Each section contains ordered `fields` with:

- `id`
- `type`
- `label`
- `required`
- optional `options` for choice fields

Current seeded templates:

- `tmpl_arrival`
- `tmpl_pm`
- `tmpl_closeout`

The technician flow reads template structure directly from the entity map and does not duplicate template definitions into ad hoc frontend-only registries.

### Parts catalog

`entities.parts_catalog` is the seeded source for consumables referenced by visit execution. Each part record includes:

- `id`
- `sku`
- `name`
- `uom`

Work orders use `allowed_part_ids` to constrain which catalog entries can be added during execution.

## Execution Overlay

The current execution surface adds a reducer-owned document for the actively selected visit. The canonical default comes from [`frontend/src/execution.x07.json`](../frontend/src/execution.x07.json).

Execution state includes:

- progress and save state:
  - `status`
  - `draft_status`
  - `autosave_status`
  - `unsaved`
  - `last_action`
  - `validation_error`
- template binding and completion mode:
  - `template_id`
  - `completion_mode`
  - `signature_required`
  - `signature_status`
- checklist fields:
  - `arrival_ready`
  - `temperature`
  - `filter_condition`
  - `findings`
- technician work logging:
  - `note`
  - `labor_minutes`
  - `labor_running`
  - `labor_cycles`
  - `parts_qty`
  - `block_reason`
- signature capture:
  - `signature_name`
  - `signature_role`
  - `signature_strokes`
- evidence capture/import:
  - `capture_status`
  - `capture_attachment`
  - `import_status`
  - `import_attachment`
  - `blob_status`
- permissions and location:
  - `permission_status`
  - `permission_state`
  - `location_status`
  - `checkin_location`
  - `checkout_location_status`
  - `checkout_location`

Current seeded execution-status distribution on visits:

- `planned`: `10`
- `resume_required`: `15`

The reducer can move that execution branch through the technician flow without mutating the normalized seed entities directly until sync/persist effects complete.

## Attachment And Sync Envelopes

### Attachment manifest

The frontend uses a compact attachment document shape for capture/import cards:

- `source`
- `label`
- `handle`
- `size_bytes`
- `upload_status`

The backend registration response adds the server attachment envelope:

- `attachment_id`
- `status`
- `upload_path`
- `manifest`

Upload completion is modeled separately with `attachment_id`, `status`, and `uploaded_at`.

### Pending client ops

Offline technician work is represented in `sync.pending_ops`. Each queued op includes:

- `op_id`
- `kind`
- `entity_id`
- `status`
- `payload`

The current seed and traces exercise at least these op families:

- check-in
- draft save
- submit
- sync push acceptance

The reducer treats these as deterministic, replay-safe envelopes instead of mutating server-backed entities optimistically without a queue record.

## Reducer Maps And Indexes

Normalized entity maps live under:

- `entities.org`
- `entities.branches`
- `entities.teams`
- `entities.users`
- `entities.customers`
- `entities.sites`
- `entities.assets`
- `entities.work_orders`
- `entities.visits`
- `entities.templates`
- `entities.parts_catalog`

Read-optimized indexes stay separate under `indexes`:

- `work_orders_by_status`
- `work_orders_by_assignee`
- `assets_by_site`
- `sites_by_customer`

The `summary` branch keeps shell-friendly aggregates such as counts, status counts, dispatcher focus rows, and technician-today groupings.

## Relationship Invariants

- IDs are deterministic, ASCII, and stable across regenerated fixtures.
- Cross-entity references stay normalized by id.
- Each work order points at exactly one customer, site, asset, technician, and template.
- Each visit belongs to one work order and one technician.
- Templates own checklist structure and evidence/completion policy.
- Reducer-only execution state is separate from seeded entity maps and can be safely cached under `crewops.execution.state.v1`.
- Storage, browser, desktop, iOS, Android, and replay flows all read the same seeded tenant shape.

## Roles

- `technician`
  - primary surface: visit execution, evidence, signatures, offline queue, reconnect sync
- `dispatcher`
  - read-only dispatch board and assignment visibility during technician execution
- `manager`
  - read-only branch summary and exception visibility during technician execution

`POST /api/session/dev-login` still swaps between those roles deterministically for local replay and device packaging smoke.

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

Seeded counts:

- `draft`: `1`
- `scheduled`: `4`
- `dispatched`: `4`
- `en_route`: `2`
- `on_site`: `2`
- `blocked`: `2`
- `completed`: `4`
- `needs_review`: `3`
- `invoiced`: `1`
- `closed`: `1`
- `canceled`: `1`

### Visit execution outcomes

Completion flows distinguish:

- normal completion
- blocked submission with required block reason
- check-out with optional location capture

Template and work-order completion policies currently default to:

- signature required on completion
- block reason required when blocked
- location capture optional

## Sync Scope

The current sync surface expands beyond the earlier preference-only shell. The local/offline surface includes:

- technician execution draft persistence
- queued visit operations
- attachment registration/upload progress
- reconnect push and pull cursor advancement
- deterministic conflict/status messaging in the reducer

Dispatcher, manager, billing, review, and notification orchestration remain outside the current mutation scope.
