# `x07 CrewOps` Prompt

Use this repo as the CrewOps `v0.6.0` M7 showcase. The active product shape is one deterministic app that covers field execution, dispatch, review, finance, contracts, portal access, enterprise administration, inventory, procurement, vendor connectors, deterministic replay, and sealed-pack release validation.

## Scope

- Frontend: [`frontend/src/app.x07.json`](frontend/src/app.x07.json) is the `std-web-ui` reducer.
- Backend: [`backend/src/app.x07.json`](backend/src/app.x07.json) is the deterministic WASI HTTP proxy component.
- Frontend package baseline: [`frontend/x07.json`](frontend/x07.json) is locked to `std-web-ui@0.2.4`.
- App profiles: `crewops_dev`, `crewops_release`, `crewops_budget`
- Device profiles: `device_desktop_dev`, `device_ios_dev`, `device_android_dev`
- Roles: `technician`, `dispatcher`, `supervisor`, `manager`, `portal_user`, `enterprise_admin`
- Primary docs: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), [`docs/DATA_MODEL.md`](docs/DATA_MODEL.md), [`docs/PORTAL.md`](docs/PORTAL.md), [`docs/ENTERPRISE_ADMIN.md`](docs/ENTERPRISE_ADMIN.md), [`docs/INVENTORY_AND_PROCUREMENT.md`](docs/INVENTORY_AND_PROCUREMENT.md), [`docs/VENDOR_CONNECTORS.md`](docs/VENDOR_CONNECTORS.md), [`docs/HOSTED_READINESS.md`](docs/HOSTED_READINESS.md), [`docs/RELEASE_READINESS.md`](docs/RELEASE_READINESS.md)

## Current Product Shape

- One reducer and one backend power operations, finance, portal, enterprise admin, inventory, procurement, and connector-health routes.
- Primary routes are `today`, `dispatch`, `review`, `manager`, `finance`, `pricing`, `invoices`, `activity`, `customers`, `receivables`, `exports`, `sites`, `assets`, `settings`, `estimates`, `contracts`, `recurring`, `integrations`, `portal`, `enterprise`, `inventory`, `procurement`, and `integration_dashboard`.
- Shared state includes normalized entities, indexes, summaries, drafts, replay-safe sync metadata, commercial selections, enterprise selections, and conflict metadata.
- Sync state carries both `commercial_ops` and `enterprise_ops` status subtrees.
- Backend routes cover the original operations and commercial APIs plus M7 tenant admin, branding, portal, inventory, procurement, vendor connectors, and hosted readiness.

## Working Rules

- Treat [`scripts/ci/check_all.sh`](scripts/ci/check_all.sh) as the canonical CrewOps gate.
- Regenerate demo data through [`scripts/ci/seed_demo.sh`](scripts/ci/seed_demo.sh); do not hand-edit generated payloads.
- Keep authored traces and generated regressions aligned with the current M7 ids, routes, and sync schema.
- Keep docs and release notes aligned to the `v0.6.0` release line and the `std-web-ui@0.2.4` dependency baseline.
- Keep schema usage aligned with the published `x07-project.v0.3.0` and `x07ast.v0.5.0` surfaces.
