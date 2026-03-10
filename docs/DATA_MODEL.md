# CrewOps Data Model

CrewOps ships one deterministic demo tenant for M2. The seed lives in [`tests/fixtures/demo_org.json`](../tests/fixtures/demo_org.json) and is mirrored into [`backend/src/demo_seed.x07.json`](../backend/src/demo_seed.x07.json) for the backend bootstrap routes.

## Tenant Shape

- `1` organization: `org_demo`
- `2` branches: `branch_north`, `branch_south`
- `3` teams: `team_north_alpha`, `team_north_beta`, `team_south_gamma`
- `8` technicians
- `20` customers
- `30` sites
- `60` assets
- `25` work orders
- `25` visits
- `3` workflow templates

## Entity Relationships

- `Organization -> Branch`
  - each branch belongs to one organization
- `Branch -> Team`
  - each team belongs to one branch
- `Branch -> User`
  - each user has one primary branch
- `Team -> User`
  - technicians belong to one team
  - dispatcher and manager demo users span all teams
- `Customer -> Site`
  - each site belongs to one customer and one branch
- `Site -> Asset`
  - each asset belongs to one site and inherits that site branch
- `WorkOrder -> Customer/Site/Asset`
  - each work order points at one customer, one site, and one asset
- `WorkOrder -> Assignee`
  - each work order has one assigned technician for M2
- `Visit -> WorkOrder/User`
  - each visit belongs to one work order and one technician

## IDs And Invariants

- IDs are deterministic, ASCII, and stable across regenerated fixtures.
- Cross-entity references are normalized by id; M2 does not duplicate nested entity payloads in reducer state.
- Branch and team selectors must stay consistent with the active session role.
- Device, web, and backend flows all read the same seeded tenant shape.

## Reducer Entity Maps

The frontend stores normalized maps under:

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

Computed indexes stay separate under `indexes`:

- `work_orders_by_status`
- `work_orders_by_assignee`
- `assets_by_site`
- `sites_by_customer`

The `summary` branch stores read-optimized rollups for the technician, dispatcher, and manager shells.

## Roles

- `technician`
  - default mobile-oriented queue and assigned work focus
- `dispatcher`
  - cross-team dispatch board and workload triage
- `manager`
  - branch summary, completion metrics, and exception counts

M2 uses `POST /api/session/dev-login` to swap between these roles without changing the seeded tenant.

## Work Order Status Enum

The M2 seed includes the full future-safe work-order status line:

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

Current seeded counts:

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

## Visit State Enum

Visits in the demo tenant use:

- `planned`
- `logged`

M2 does not expose visit editing yet; visits are present so reducer summaries and future milestones have stable shape.

## Sync Scope

M2 sync is intentionally narrow. Client mutations are limited to lightweight preference-style state:

- role selection
- branch/team selection
- saved filters
- pinned views
- local settings

Operational edits to work orders, visits, assets, or customers are out of scope for M2.
