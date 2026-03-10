# `x07 CrewOps` Prompt

Use this repo as the current CrewOps showcase, not the older Atlas or Field Notes variants.

## Scope

- Frontend: [`frontend/src/app.x07.json`](frontend/src/app.x07.json) is the `std.web_ui` reducer.
- Backend: [`backend/src/app.x07.json`](backend/src/app.x07.json) is the WASI HTTP proxy component.
- Frontend package baseline: [`frontend/x07.json`](frontend/x07.json) is locked to `std-web-ui@0.2.0`.
- App profiles: `crewops_dev`, `crewops_release`, `crewops_budget`
- Device profiles: `device_desktop_dev`, `device_ios_dev`, `device_android_dev`
- Demo seed source: [`scripts/ci/seed_demo.sh`](scripts/ci/seed_demo.sh)
- Replay coverage: [`tests/traces`](tests/traces) and [`tests/regress`](tests/regress)

## Current Product Shape

- Role-aware views for technician, dispatcher, and manager
- Reducer routes: `today`, `dispatch`, `manager`, `customers`, `sites`, `assets`, `settings`
- Offline-first bootstrap caching via `crewops.bootstrap.snapshot.v1`
- Backend routes:
  `GET /api/meta/app`, `GET /api/bootstrap`, `POST /api/session/dev-login`, `GET /api/sync/pull`, `POST /api/sync/push`
- Passing app traces:
  `bootstrap_demo_happy`, `bootstrap_cached_then_refresh`, `dispatcher_board_filter`, `technician_today_nav`, `settings_role_switch`
- Intentional failure trace:
  `bootstrap_api_error.trace.json` should fail `x07-wasm app test`, emit an incident bundle, and feed `tests/regress/bootstrap_api_error.trace.json`

## Working Rules

- Keep docs and automation on the current CrewOps ids and trace names.
- Prefer direct `x07` and `x07-wasm` commands that target the current manifests.
- For released toolchains, install the wasm component first: `x07up component add wasm`.
- For scripted invocations, use `--json --report-out <file> --quiet-json`.
- Regenerate demo data through [`scripts/ci/seed_demo.sh`](scripts/ci/seed_demo.sh), not by hand-editing generated payloads.
- [`scripts/ci/check_all.sh`](scripts/ci/check_all.sh) still references Atlas-era ids and old trace names; do not copy commands from it as the current CrewOps source of truth.
