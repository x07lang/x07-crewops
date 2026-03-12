# `x07 CrewOps`

CrewOps `v0.6.0` is the M7 field-operations showcase. One deterministic `std-web-ui` reducer and one seed-backed backend now cover technician, dispatcher, supervisor, manager, portal, and enterprise-admin workflows across web, desktop, iOS, and Android, with finance, estimates, contracts, recurring work, portal access, tenant administration, inventory, procurement, vendor connectors, and hosted-readiness reporting in the same app.

- Prompt: [`PROMPT.md`](PROMPT.md)
- Architecture: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- Data model: [`docs/DATA_MODEL.md`](docs/DATA_MODEL.md)
- Portal: [`docs/PORTAL.md`](docs/PORTAL.md)
- Enterprise admin: [`docs/ENTERPRISE_ADMIN.md`](docs/ENTERPRISE_ADMIN.md)
- Inventory and procurement: [`docs/INVENTORY_AND_PROCUREMENT.md`](docs/INVENTORY_AND_PROCUREMENT.md)
- Vendor connectors: [`docs/VENDOR_CONNECTORS.md`](docs/VENDOR_CONNECTORS.md)
- Hosted readiness: [`docs/HOSTED_READINESS.md`](docs/HOSTED_READINESS.md)
- Demo walkthrough: [`docs/DEMO_WALKTHROUGH.md`](docs/DEMO_WALKTHROUGH.md)
- Dispatch and review: [`docs/DISPATCH_AND_REVIEW.md`](docs/DISPATCH_AND_REVIEW.md)
- Manager dashboards: [`docs/MANAGER_DASHBOARDS.md`](docs/MANAGER_DASHBOARDS.md)
- Release readiness: [`docs/RELEASE_READINESS.md`](docs/RELEASE_READINESS.md)
- Mobile packaging: [`docs/MOBILE_BUILD.md`](docs/MOBILE_BUILD.md)

## Current Shape

- Release line: `v0.6.0`
- Frontend dependency baseline: [`frontend/x07.json`](frontend/x07.json) uses `std-web-ui@0.2.4`
- Roles: `technician`, `dispatcher`, `supervisor`, `manager`, `portal_user`, `enterprise_admin`
- Primary routes: `today`, `dispatch`, `review`, `manager`, `finance`, `pricing`, `invoices`, `activity`, `customers`, `receivables`, `exports`, `sites`, `assets`, `settings`, `estimates`, `contracts`, `recurring`, `integrations`, `portal`, `enterprise`, `inventory`, `procurement`, `integration_dashboard`
- Shared reducer branches: `session`, `bootstrap`, `ui`, `entities`, `indexes`, `sync`, `settings`, `diagnostics`, `summary`, `drafts`, `template`, `execution`, `meta`
- Sync subtrees: `commercial_ops` and `enterprise_ops`
- Bootstrap cache key: `crewops.bootstrap.snapshot.v2`

## Backend Surface

CrewOps exposes deterministic `/api` routes for:

- bootstrap and session: `GET /api/meta/app`, `GET /api/bootstrap`, `POST /api/session/dev-login`
- operations core: `GET /api/dispatch/board`, `POST /api/work-orders`, `PATCH /api/work-orders/:id`, `POST /api/work-orders/:id/assign`, `POST /api/work-orders/:id/reassign`, `GET /api/review/queue`, `POST /api/review/:visit_id/approve`, `POST /api/review/:visit_id/reject`, `POST /api/review/:visit_id/request-correction`, `POST /api/corrections/:id/resubmit`, `GET /api/activity/feed`, `GET /api/manager/summary`, `GET /api/templates/:id`, `POST /api/visits/:id/check-in`, `POST /api/visits/:id/save-draft`, `POST /api/visits/:id/submit`, `POST /api/visits/:id/block`, `POST /api/visits/:id/check-out`, `POST /api/attachments/register`, `PUT /api/attachments/:id/content`
- finance and commercial: `GET /api/pricing/config`, `PATCH /api/pricing/config`, `PATCH /api/pricing/config/conflict`, `GET /api/invoices`, `POST /api/invoices/generate`, `GET /api/invoices/:id`, `PATCH /api/invoices/:id`, `POST /api/invoices/:id/issue`, `POST /api/invoices/:id/void`, `POST /api/invoices/:id/payments`, `GET /api/invoices/:id/artifact`, `GET /api/invoices/:id/service-summary`, `GET /api/finance/summary`, `GET /api/finance/receivables`, `GET /api/customers/:id/account`, `GET /api/exports/jobs`, `POST /api/exports/jobs`, `POST /api/exports/jobs/:id/retry`, `GET /api/estimates`, `POST /api/estimates`, `GET /api/estimates/:id`, `PATCH /api/estimates/:id`, `POST /api/estimates/:id/send`, `POST /api/estimates/:id/approve`, `POST /api/estimates/:id/reject`, `POST /api/estimates/:id/convert`, `GET /api/contracts`, `POST /api/contracts`, `PATCH /api/contracts/:id`, `POST /api/contracts/:id/pause`, `POST /api/contracts/:id/resume`, `POST /api/contracts/:id/renew`, `GET /api/recurring/board`, `POST /api/recurring/:id/generate`, `POST /api/recurring/:id/skip`, `GET /api/integrations`, `GET /api/integrations/deliveries`, `POST /api/integrations/deliveries/:id/retry`, `POST /api/integrations/api-keys`, `POST /api/integrations/webhooks`
- M7 enterprise and portal: `GET /api/admin/tenants`, `POST /api/admin/tenants`, `PATCH /api/admin/tenants/:id`, `GET /api/admin/roles`, `POST /api/admin/roles`, `POST /api/admin/branding`, `POST /api/portal/session`, `GET /api/portal/me`, `GET /api/portal/invoices`, `GET /api/portal/service-history`, `POST /api/portal/requests`, `POST /api/portal/requests/:id/convert`
- M7 inventory, procurement, connectors, and readiness: `GET /api/inventory/items`, `POST /api/inventory/movements`, `POST /api/inventory/counts`, `GET /api/procurement/purchase-orders`, `POST /api/procurement/purchase-orders`, `POST /api/procurement/receiving`, `GET /api/connectors/vendor`, `POST /api/connectors/vendor`, `POST /api/connectors/vendor/:id/sync`, `GET /api/connectors/vendor/:id/deliveries`, `GET /api/release/readiness`
- sync: `GET /api/sync/pull`, `POST /api/sync/push`

## Build And Gate

From the repo root:

```sh
mkdir -p build/reports

./scripts/ci/seed_demo.sh
x07 pkg lock --project frontend/x07.json --json --report-out build/reports/frontend.lock.json --quiet-json
x07 check --project frontend/x07.json
x07 check --project backend/x07.json
x07 test --manifest frontend/tests/tests.json --json --report-out build/reports/frontend.tests.json --quiet-json
x07 test --manifest backend/tests/tests.json --json --report-out build/reports/backend.tests.json --quiet-json
./scripts/ci/check_all.sh
```

[`scripts/ci/check_all.sh`](scripts/ci/check_all.sh) remains the canonical CrewOps gate for lock verification, deterministic replay, generated regressions, pack, verify, provenance, deploy-plan, desktop smoke, and device package generation.

## Release Coverage

The `v0.6.0` release bar adds M7 deterministic coverage for:

- portal login and portal-state replay
- portal approval and request handoff state
- tenant and branding administration
- inventory and procurement surfaces
- vendor connector health and configuration conflict state
- enterprise dashboard rollups
- generated regressions for `connector_delivery_failure.regress` and `portal_approval_revision_mismatch.regress`

## Device Packaging

The checked-in dev device profiles are versioned at `0.6.0`:

- `device_desktop_dev` points at `http://127.0.0.1:17081` and is the local smoke profile
- `device_ios_dev` and `device_android_dev` still require a real backend `base_url` and allowlist before simulator or device packaging
- desktop keeps file import, blob storage, and local notifications enabled
- mobile keeps camera capture, file import, blob storage, foreground location, and local notifications enabled
