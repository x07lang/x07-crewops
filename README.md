# `x07 CrewOps`

CrewOps `v0.3.0` is the M4 multi-role x07 showcase for field-service operations. One reducer and one deterministic backend now serve dispatcher, supervisor, manager, and technician workflows across web, desktop, iOS, and Android packaging.

- Prompt: [`PROMPT.md`](PROMPT.md)
- Architecture: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- Data model: [`docs/DATA_MODEL.md`](docs/DATA_MODEL.md)
- Dispatch and review: [`docs/DISPATCH_AND_REVIEW.md`](docs/DISPATCH_AND_REVIEW.md)
- Manager dashboards: [`docs/MANAGER_DASHBOARDS.md`](docs/MANAGER_DASHBOARDS.md)
- Mobile packaging: [`docs/MOBILE_BUILD.md`](docs/MOBILE_BUILD.md)
- Frontend entry: [`frontend/src/app.x07.json`](frontend/src/app.x07.json)
- Backend entry: [`backend/src/app.x07.json`](backend/src/app.x07.json)
- Demo seed generator: [`scripts/ci/seed_demo.sh`](scripts/ci/seed_demo.sh)

## Current Shape

- Release baseline: `v0.3.0`
- Frontend package baseline: [`frontend/x07.json`](frontend/x07.json) is locked to `std-web-ui@0.2.1`
- App profiles: `crewops_dev`, `crewops_release`, `crewops_budget`
- Device profiles: `device_desktop_dev`, `device_ios_dev`, `device_android_dev`
- Roles: `technician`, `dispatcher`, `supervisor`, `manager`
- Primary reducer routes: `today`, `dispatch`, `review`, `manager`, `activity`, `customers`, `sites`, `assets`, `settings`
- Shared reducer branches: `session`, `bootstrap`, `ui`, `entities`, `indexes`, `sync`, `settings`, `diagnostics`, `summary`, `drafts`, `template`, `execution`, `meta`
- Core M4 entities: assignments, review queue items, review decisions, correction tasks and responses, activity events, alerts, branch and team summaries, dashboard rollups, workload snapshots
- Offline bootstrap cache key: `crewops.bootstrap.snapshot.v1`
- Offline execution cache key: `crewops.execution.state.v1`

## Backend Surface

CrewOps exposes deterministic `/api` routes for:

- bootstrap and metadata: `GET /api/meta/app`, `GET /api/bootstrap`
- dev login: `POST /api/session/dev-login`
- dispatcher and intake: `GET /api/dispatch/board`, `POST /api/work-orders`, `PATCH /api/work-orders/:id`, `POST /api/work-orders/:id/assign`, `POST /api/work-orders/:id/reassign`
- supervisor review: `GET /api/review/queue`, `POST /api/review/:visit_id/approve`, `POST /api/review/:visit_id/reject`, `POST /api/review/:visit_id/request-correction`, `POST /api/corrections/:id/resubmit`
- manager and activity: `GET /api/manager/summary`, `GET /api/activity/feed`
- technician execution and evidence: `GET /api/templates/:id`, `POST /api/visits/:id/check-in`, `POST /api/visits/:id/save-draft`, `POST /api/visits/:id/submit`, `POST /api/visits/:id/block`, `POST /api/visits/:id/check-out`, `POST /api/attachments/register`, `PUT /api/attachments/:id/content`
- sync: `GET /api/sync/pull`, `POST /api/sync/push`

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) and [`docs/DISPATCH_AND_REVIEW.md`](docs/DISPATCH_AND_REVIEW.md) for the role-by-role breakdown.

## Build And Gate

From the repo root:

```sh
mkdir -p build/reports

x07up component add wasm
./scripts/ci/seed_demo.sh
x07 pkg lock --project frontend/x07.json --json --report-out build/reports/frontend.lock.json --quiet-json
x07 test --manifest frontend/tests/tests.json --json --report-out build/reports/frontend.tests.json --quiet-json
x07 test --manifest backend/tests/tests.json --json --report-out build/reports/backend.tests.json --quiet-json
x07-wasm app profile validate --profile-file arch/app/profiles/crewops_dev.json --json --report-out build/reports/app.profile.crewops_dev.json --quiet-json
x07-wasm app build --index arch/app/index.x07app.json --profile crewops_dev --out-dir dist/app/crewops_dev --clean --json --report-out build/reports/app.build.crewops_dev.json --quiet-json
x07-wasm app serve --dir dist/app/crewops_dev --mode smoke --json --report-out build/reports/app.serve.crewops_dev.json --quiet-json
./scripts/ci/check_all.sh
```

[`scripts/ci/seed_demo.sh`](scripts/ci/seed_demo.sh) regenerates the canonical demo fixture and backend mirror:

- [`tests/fixtures/demo_org.json`](tests/fixtures/demo_org.json)
- [`backend/src/demo_seed.x07.json`](backend/src/demo_seed.x07.json)

[`scripts/ci/check_all.sh`](scripts/ci/check_all.sh) remains the authoritative CrewOps gate for build, test, replay, pack, verify, provenance, SLO, desktop smoke, and mobile package generation. The only intentional workspace-local gap is the optional `x07-platform` smoke probe.

## Replay And Release Coverage

The `v0.3.0` release bar is the M4 multi-role replay matrix:

- bootstrap and cache hydrate
- dispatcher board filters, intake, assign, and reassign flows
- supervisor review queue, approve and reject decisions, and correction requests
- technician check-in, autosave, evidence capture or import, blocked submission, offline completion, resubmission, and reconnect sync
- manager summary and branch or team drill-down
- activity feed and role-aware alert delivery
- deterministic failure plus generated regression replay

The checked-in trace and regression assets live under [`tests/traces`](tests/traces) and [`tests/regress`](tests/regress).

## Device Packaging

Use the current device profiles directly:

```sh
x07-wasm device build --index arch/device/index.x07device.json --profile device_desktop_dev --out-dir dist/device/device_desktop_dev --clean --json --report-out build/reports/device.build.desktop.json --quiet-json
x07-wasm device run --bundle dist/device/device_desktop_dev --target desktop --headless-smoke --json --report-out build/reports/device.run.desktop.json --quiet-json

x07-wasm device build --index arch/device/index.x07device.json --profile device_ios_dev --out-dir dist/device/device_ios_dev --clean --json --report-out build/reports/device.build.ios.json --quiet-json
x07-wasm device package --bundle dist/device/device_ios_dev --target ios --out-dir dist/device_package/device_ios_dev --json --report-out build/reports/device.package.ios.json --quiet-json

x07-wasm device build --index arch/device/index.x07device.json --profile device_android_dev --out-dir dist/device/device_android_dev --clean --json --report-out build/reports/device.build.android.json --quiet-json
x07-wasm device package --bundle dist/device/device_android_dev --target android --out-dir dist/device_package/device_android_dev --json --report-out build/reports/device.package.android.json --quiet-json
```

The device profiles are already at `0.3.0`. Desktop dev targets `http://127.0.0.1:17081` and enables dispatch, review, activity, notifications, file import, and blob storage. The iOS and Android dev profiles still require a real backend `base_url` and allowlist before simulator or device packaging, but both mobile profiles now enable camera capture, import, blob storage, foreground location, and local notifications for M4 operations.
