# `x07 CrewOps`

CrewOps `v0.5.0` is the M6 contracted-service field-ops showcase. One deterministic `std-web-ui` reducer and one seed-backed backend now cover technician, dispatcher, supervisor, and manager workflows across web, desktop, iOS, and Android, with estimates, approvals, service agreements, recurring work generation, integration control, billing, receivables, exports, and finance in the same app.

- Prompt: [`PROMPT.md`](PROMPT.md)
- Architecture: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- Data model: [`docs/DATA_MODEL.md`](docs/DATA_MODEL.md)
- Dispatch and review: [`docs/DISPATCH_AND_REVIEW.md`](docs/DISPATCH_AND_REVIEW.md)
- Manager dashboards: [`docs/MANAGER_DASHBOARDS.md`](docs/MANAGER_DASHBOARDS.md)
- Demo walkthrough: [`docs/DEMO_WALKTHROUGH.md`](docs/DEMO_WALKTHROUGH.md)
- Release readiness: [`docs/RELEASE_READINESS.md`](docs/RELEASE_READINESS.md)
- Mobile packaging: [`docs/MOBILE_BUILD.md`](docs/MOBILE_BUILD.md)
- Frontend entry: [`frontend/src/app.x07.json`](frontend/src/app.x07.json)
- Backend entry: [`backend/src/app.x07.json`](backend/src/app.x07.json)

## Current Shape

- Release line: `v0.5.0`
- Frontend dependency baseline: [`frontend/x07.json`](frontend/x07.json) uses `std-web-ui@0.2.3`
- Roles: `technician`, `dispatcher`, `supervisor`, `manager`
- Primary routes: `today`, `dispatch`, `review`, `manager`, `finance`, `pricing`, `invoices`, `activity`, `customers`, `receivables`, `exports`, `sites`, `assets`, `settings`, `estimates`, `contracts`, `recurring`, `integrations`
- Shared reducer branches: `session`, `bootstrap`, `ui`, `entities`, `indexes`, `sync`, `settings`, `diagnostics`, `summary`, `drafts`, `template`, `execution`, `meta`
- Bootstrap cache key: `crewops.bootstrap.snapshot.v2`

## Backend Surface

CrewOps exposes deterministic `/api` routes for:

- bootstrap and session: `GET /api/meta/app`, `GET /api/bootstrap`, `POST /api/session/dev-login`
- dispatcher and review: `GET /api/dispatch/board`, `POST /api/work-orders`, `PATCH /api/work-orders/:id`, `POST /api/work-orders/:id/assign`, `POST /api/work-orders/:id/reassign`, `GET /api/review/queue`, `POST /api/review/:visit_id/approve`, `POST /api/review/:visit_id/reject`, `POST /api/review/:visit_id/request-correction`, `POST /api/corrections/:id/resubmit`
- technician execution: `GET /api/templates/:id`, `POST /api/visits/:id/check-in`, `POST /api/visits/:id/save-draft`, `POST /api/visits/:id/submit`, `POST /api/visits/:id/block`, `POST /api/visits/:id/check-out`, `POST /api/attachments/register`, `PUT /api/attachments/:id/content`
- activity and ops summary: `GET /api/activity/feed`, `GET /api/manager/summary`
- commercial M5: `GET /api/pricing/config`, `PATCH /api/pricing/config`, `PATCH /api/pricing/config/conflict`, `GET /api/invoices`, `POST /api/invoices/generate`, `GET /api/invoices/:id`, `PATCH /api/invoices/:id`, `POST /api/invoices/:id/issue`, `POST /api/invoices/:id/void`, `POST /api/invoices/:id/payments`, `GET /api/invoices/:id/artifact`, `GET /api/invoices/:id/service-summary`, `GET /api/finance/summary`, `GET /api/finance/receivables`, `GET /api/customers/:id/account`, `GET /api/exports/jobs`, `POST /api/exports/jobs`, `POST /api/exports/jobs/:id/retry`
- commercial M6: `GET /api/estimates`, `POST /api/estimates`, `GET /api/estimates/:id`, `PATCH /api/estimates/:id`, `POST /api/estimates/:id/send`, `POST /api/estimates/:id/approve`, `POST /api/estimates/:id/reject`, `POST /api/estimates/:id/convert`, `GET /api/contracts`, `POST /api/contracts`, `PATCH /api/contracts/:id`, `POST /api/contracts/:id/pause`, `POST /api/contracts/:id/resume`, `POST /api/contracts/:id/renew`, `GET /api/recurring/board`, `POST /api/recurring/:id/generate`, `POST /api/recurring/:id/skip`, `GET /api/integrations`, `GET /api/integrations/deliveries`, `POST /api/integrations/deliveries/:id/retry`, `POST /api/integrations/api-keys`, `POST /api/integrations/webhooks`
- sync: `GET /api/sync/pull`, `POST /api/sync/push`

## Build And Gate

From the repo root:

```sh
mkdir -p build/reports

x07up component add wasm
./scripts/ci/seed_demo.sh
x07 pkg lock --project frontend/x07.json --json --report-out build/reports/frontend.lock.json --quiet-json
x07 test --manifest frontend/tests/tests.json --json --report-out build/reports/frontend.tests.json --quiet-json
x07 test --manifest backend/tests/tests.json --json --report-out build/reports/backend.tests.json --quiet-json
x07-wasm app build --index arch/app/index.x07app.json --profile crewops_dev --out-dir dist/app/crewops_dev --clean --json --report-out build/reports/app.build.crewops_dev.json --quiet-json
./scripts/ci/check_all.sh
```

[`scripts/ci/check_all.sh`](scripts/ci/check_all.sh) remains the canonical CrewOps gate for lock, tests, replay, generated regressions, pack, verify, provenance, SLO, desktop smoke, and device packaging.

## Release Coverage

The `v0.5.0` release bar is the M6 end-to-end loop:

- dispatch, review, correction, activity, and technician offline execution
- pricing config, invoicing, payments, receivables, exports, and finance rollups
- estimate draft creation, revision, send, approval conflict handling, and conversion
- service agreement, recurring-plan, renewal, and contract-health surfaces
- integrations center, API key creation, webhook creation, delivery logs, delivery retry, and retry-state visibility
- deterministic traces and regressions for estimate, contract, recurring, and integration paths

## Device Packaging

The checked-in dev device profiles are versioned at `0.5.0`:

- `device_desktop_dev` points at `http://127.0.0.1:17081` and is the local smoke and operator demo profile
- `device_ios_dev` and `device_android_dev` still require a real backend `base_url` and allowlist before simulator or device packaging
- desktop keeps file import, blob storage, and local notifications enabled
- mobile keeps camera capture, file import, blob storage, foreground location, and local notifications enabled

The same reducer bundle ships across web and device targets. Dynamic code loading remains disabled.
