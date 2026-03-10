# `x07 CrewOps`

CrewOps is a full-stack x07 showcase for field-service operations. The frontend reducer drives technician, dispatcher, and manager views, the backend serves deterministic demo data over `/api`, and the same UI is packaged for desktop, iOS, and Android device profiles.

- Prompt: [`PROMPT.md`](PROMPT.md)
- Architecture: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- Data model: [`docs/DATA_MODEL.md`](docs/DATA_MODEL.md)
- Mobile packaging: [`docs/MOBILE_BUILD.md`](docs/MOBILE_BUILD.md)
- Frontend entry: [`frontend/src/app.x07.json`](frontend/src/app.x07.json)
- Backend entry: [`backend/src/app.x07.json`](backend/src/app.x07.json)
- Demo seed generator: [`scripts/ci/seed_demo.sh`](scripts/ci/seed_demo.sh)

## Current IDs And Baseline

- Frontend package baseline: [`frontend/x07.json`](frontend/x07.json) is locked to `std-web-ui@0.2.0`
- App profiles: `crewops_dev`, `crewops_release`, `crewops_budget`
- Device profiles: `device_desktop_dev`, `device_ios_dev`, `device_android_dev`
- HTTP routes: `GET /api/meta/app`, `GET /api/bootstrap`, `POST /api/session/dev-login`, `GET /api/sync/pull`, `POST /api/sync/push`
- Routes in the reducer: `today`, `dispatch`, `manager`, `customers`, `sites`, `assets`, `settings`
- Offline bootstrap cache key: `crewops.bootstrap.snapshot.v1`
- Current script state:
  [`scripts/ci/seed_demo.sh`](scripts/ci/seed_demo.sh) is the current data refresh script.
  [`scripts/ci/check_all.sh`](scripts/ci/check_all.sh) is the authoritative CrewOps gate. It covers lock/validate, app build/serve/test/regress, pack/verify/provenance/deploy-plan/SLO, desktop smoke, and iOS/Android package generation. The local `x07-platform` smoke remains a documented TODO until the platform probe succeeds in the workspace.

## Tooling

Released toolchain:

```sh
x07up component add wasm
```

Workspace fallback:

```sh
PATH="/Users/webik/projects/x07lang/x07/target/debug:/Users/webik/projects/x07lang/x07-wasm-backend/target/debug:$PATH"
```

## Build And Replay

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
```

Passing trace suite:

- `tests/traces/bootstrap_demo_happy.trace.json`
- `tests/traces/bootstrap_cached_then_refresh.trace.json`
- `tests/traces/dispatcher_board_filter.trace.json`
- `tests/traces/technician_today_nav.trace.json`
- `tests/traces/settings_role_switch.trace.json`

Run any of those against the built `crewops_dev` bundle:

```sh
x07-wasm app test --dir dist/app/crewops_dev --trace tests/traces/bootstrap_demo_happy.trace.json --json --report-out build/reports/app.test.bootstrap_demo_happy.json --quiet-json
```

Intentional failure and regression flow:

```sh
x07-wasm app test --dir dist/app/crewops_dev --trace tests/traces/bootstrap_api_error.trace.json --json --report-out build/reports/app.test.bootstrap_api_error.json --quiet-json
# expect non-zero; read incident_dir from build/reports/app.test.bootstrap_api_error.json
x07-wasm app regress from-incident <incident_dir> --out-dir tests/regress --name bootstrap_api_error --json --report-out build/reports/app.regress.bootstrap_api_error.json --quiet-json
x07-wasm app test --dir dist/app/crewops_dev --trace tests/regress/bootstrap_api_error.trace.json --json --report-out build/reports/app.test.regress.bootstrap_api_error.json --quiet-json
```

[`scripts/ci/seed_demo.sh`](scripts/ci/seed_demo.sh) regenerates [`tests/fixtures/demo_org.json`](tests/fixtures/demo_org.json) and [`backend/src/demo_seed.x07.json`](backend/src/demo_seed.x07.json). The generated regression snapshot lives under [`tests/regress`](tests/regress), including `bootstrap_api_error.final.ui.json`.

Frontend reducer unit harness files live under [`frontend/tests/unit`](frontend/tests/unit). The current manifest is [`frontend/tests/tests.json`](frontend/tests/tests.json).

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

See [`docs/MOBILE_BUILD.md`](docs/MOBILE_BUILD.md) for profile-specific packaging notes.

Desktop dev uses the checked-in local backend profile at `http://127.0.0.1:17081`. The iOS and Android dev profiles remain placeholders that must be pointed at a reachable backend before packaging for a simulator or device.
