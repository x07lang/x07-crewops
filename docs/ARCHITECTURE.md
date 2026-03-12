# CrewOps Architecture

CrewOps `v0.6.0` keeps one repo, one deterministic reducer, and one seed-backed backend. M7 extends the M6 operations and finance core with customer portal, tenant administration, inventory, procurement, vendor connectors, and hosted-readiness reporting without splitting the app into separate products.

## Repo Layers

- [`frontend/`](../frontend)
  - reducer modules, state defaults, route helpers, and the `std-web-ui@0.2.4` dependency
- [`backend/`](../backend)
  - deterministic API handlers for bootstrap, execution, dispatch, review, finance, portal, enterprise admin, inventory, procurement, connectors, and readiness
- [`arch/`](../arch)
  - app, web UI, device, SLO, and provenance profiles
- [`tests/`](../tests)
  - deterministic fixtures, traces, incidents, regressions, and harness manifests
- [`scripts/ci/`](../scripts/ci)
  - seed regeneration plus the canonical build, replay, and release gate

## Frontend Reducer

The reducer entrypoint is [`frontend/src/app.x07.json`](../frontend/src/app.x07.json).

CrewOps keeps one shared state tree rather than one reducer per role. M7 extends that tree with:

- portal, enterprise, inventory, procurement, and connector-health route handling
- additional selected ids and filters for tenant, portal, inventory, purchasing, and connector surfaces
- `enterprise_ops` draft data for tenant settings, branding, portal requests, inventory adjustments, receiving, and connector retry selections
- `enterprise_ops` sync state for portal approval, tenant revision, inventory movement, receiving, and connector configuration status

Current primary routes:

- `today`
- `dispatch`
- `review`
- `manager`
- `finance`
- `pricing`
- `invoices`
- `activity`
- `customers`
- `receivables`
- `exports`
- `sites`
- `assets`
- `settings`
- `estimates`
- `contracts`
- `recurring`
- `integrations`
- `portal`
- `enterprise`
- `inventory`
- `procurement`
- `integration_dashboard`

Important state modules:

- [`frontend/src/state.x07.json`](../frontend/src/state.x07.json)
  - default UI, selected ids for M6 and M7 surfaces, and `0.6.0` app metadata
- [`frontend/src/entities.x07.json`](../frontend/src/entities.x07.json)
  - normalized entity maps and indexes for operations, finance, portal, tenants, inventory, procurement, and connectors
- [`frontend/src/drafts.x07.json`](../frontend/src/drafts.x07.json)
  - intake, pricing, invoice, payment, export, `commercial_ops`, and `enterprise_ops` draft fields
- [`frontend/src/sync.x07.json`](../frontend/src/sync.x07.json)
  - deterministic sync state for invoice, payment, pricing, estimate, agreement, recurrence, delivery, portal, tenant, stock, receiving, and connector conflicts
- [`frontend/src/routes.x07.json`](../frontend/src/routes.x07.json)
  - route selection for both the legacy operations routes and the M7 enterprise surfaces

## Backend Surface

The backend entrypoint is [`backend/src/app.x07.json`](../backend/src/app.x07.json).

Operations and finance keep their existing modules:

- [`backend/src/bootstrap.x07.json`](../backend/src/bootstrap.x07.json)
- [`backend/src/session.x07.json`](../backend/src/session.x07.json)
- [`backend/src/dispatch.x07.json`](../backend/src/dispatch.x07.json)
- [`backend/src/work_orders.x07.json`](../backend/src/work_orders.x07.json)
- [`backend/src/review.x07.json`](../backend/src/review.x07.json)
- [`backend/src/corrections.x07.json`](../backend/src/corrections.x07.json)
- [`backend/src/activity.x07.json`](../backend/src/activity.x07.json)
- [`backend/src/manager_summary.x07.json`](../backend/src/manager_summary.x07.json)
- [`backend/src/templates.x07.json`](../backend/src/templates.x07.json)
- [`backend/src/visits.x07.json`](../backend/src/visits.x07.json)
- [`backend/src/attachments.x07.json`](../backend/src/attachments.x07.json)
- [`backend/src/sync.x07.json`](../backend/src/sync.x07.json)
- [`backend/src/commercial_api.x07.json`](../backend/src/commercial_api.x07.json)
- [`backend/src/pricing.x07.json`](../backend/src/pricing.x07.json)
- [`backend/src/invoices.x07.json`](../backend/src/invoices.x07.json)
- [`backend/src/finance_summary.x07.json`](../backend/src/finance_summary.x07.json)
- [`backend/src/customers.x07.json`](../backend/src/customers.x07.json)
- [`backend/src/exports.x07.json`](../backend/src/exports.x07.json)
- [`backend/src/estimates.x07.json`](../backend/src/estimates.x07.json)
- [`backend/src/contracts.x07.json`](../backend/src/contracts.x07.json)
- [`backend/src/recurrence.x07.json`](../backend/src/recurrence.x07.json)
- [`backend/src/integrations.x07.json`](../backend/src/integrations.x07.json)

M7 adds dedicated deterministic handlers for:

- [`backend/src/tenants.x07.json`](../backend/src/tenants.x07.json)
- [`backend/src/enterprise_api.x07.json`](../backend/src/enterprise_api.x07.json)
- [`backend/src/portal.x07.json`](../backend/src/portal.x07.json)
- [`backend/src/inventory.x07.json`](../backend/src/inventory.x07.json)
- [`backend/src/procurement.x07.json`](../backend/src/procurement.x07.json)
- [`backend/src/connectors_vendor.x07.json`](../backend/src/connectors_vendor.x07.json)
- [`backend/src/hosted_readiness.x07.json`](../backend/src/hosted_readiness.x07.json)

## Seed, Bootstrap, And Sync

The canonical seed is generated by [`scripts/ci/seed_demo.sh`](../scripts/ci/seed_demo.sh) and mirrored into deterministic backend payloads under [`backend/src/demo_seed.x07.json`](../backend/src/demo_seed.x07.json).

M7 expands the seed with:

- tenants, workspaces, role definitions, permission grants, branding packs, and theme overrides
- portal accounts, portal sessions, service requests, and customer timeline events
- inventory items, stock locations, stock movements, vehicle stock, and cycle counts
- vendors, purchase orders, receiving records, and reorder suggestions
- connector instances, sync jobs, delivery records, and provider mappings
- tenant health snapshots, portal adoption rollups, and release-readiness summaries

Bootstrap still hydrates cache first and then HTTP when available. Sync remains deterministic and snapshot-based. Revision-sensitive workflows are represented through sync metadata and replayable incident traces rather than background workers or a database.

## Current Boundaries

- CrewOps is still seed-backed and deterministic rather than database-backed.
- The same reducer bundle ships across web and device targets.
- Dynamic code loading remains disabled.
- The iOS and Android dev profiles still need a real `backend.base_url` and allowlist before simulator or device packaging.
