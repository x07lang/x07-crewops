# CrewOps Architecture

CrewOps is a single-repo showcase app that combines the `x07_atlas` full-stack app shape with the multi-device packaging flow used by `x07_field_notes`. One reducer drives all shells, one deterministic backend serves demo data, and the same app bundle is packaged for desktop, iOS, and Android.

## Repo Layers

- [`frontend/`](../frontend)
  - reducer, UI primitives, tests, and the `std-web-ui@0.2.0` dependency
- [`backend/`](../backend)
  - deterministic API handlers for the M2 shell
- [`arch/`](../arch)
  - wasm, web-ui, app, device, SLO, and provenance profiles
- [`tests/`](../tests)
  - trace replay fixtures, generated regressions, and deterministic seed files
- [`scripts/ci/check_all.sh`](../scripts/ci/check_all.sh)
  - canonical build, test, pack, provenance, deploy-plan, and device gate

## Frontend Reducer

The reducer entrypoint is [`frontend/src/app.x07.json`](../frontend/src/app.x07.json).

Primary modules:

- [`frontend/src/ui.x07.json`](../frontend/src/ui.x07.json)
  - reusable primitives for buttons, text, inputs, layout boxes, and status presentation
- [`frontend/src/routes.x07.json`](../frontend/src/routes.x07.json)
  - role-aware navigation and route selection
- [`frontend/src/state.x07.json`](../frontend/src/state.x07.json)
  - default document shape and reducer-facing state branches
- [`frontend/src/entities.x07.json`](../frontend/src/entities.x07.json)
  - normalized maps, selected-record helpers, and summary defaults
- [`frontend/src/session.x07.json`](../frontend/src/session.x07.json)
  - dev login payloads and role switching
- [`frontend/src/bootstrap.x07.json`](../frontend/src/bootstrap.x07.json)
  - cache key and startup source tracking
- [`frontend/src/sync.x07.json`](../frontend/src/sync.x07.json)
  - minimal push payload for M2-safe preference sync

The reducer state is organized into:

- `session`
- `bootstrap`
- `ui`
- `entities`
- `indexes`
- `sync`
- `settings`
- `diagnostics`
- `summary`

## Backend Surface

The backend entrypoint is [`backend/src/app.x07.json`](../backend/src/app.x07.json). It routes deterministic request envelopes to small handlers:

- [`backend/src/session.x07.json`](../backend/src/session.x07.json)
  - `POST /api/session/dev-login`
- [`backend/src/bootstrap.x07.json`](../backend/src/bootstrap.x07.json)
  - `GET /api/bootstrap`
  - `GET /api/meta/app`
- [`backend/src/sync.x07.json`](../backend/src/sync.x07.json)
  - `GET /api/sync/pull`
  - `POST /api/sync/push`
- [`backend/src/errors.x07.json`](../backend/src/errors.x07.json)
  - shared error envelope with `code`, `message`, `details.request_id`, and `details.category`
- [`backend/src/demo_seed.x07.json`](../backend/src/demo_seed.x07.json)
  - deterministic JSON payloads derived from the checked-in seed fixture

The backend is intentionally static for M2. It proves the app pipeline, bootstrap refresh, and structured error behavior without introducing live persistence.

## Bootstrap And Sync Flow

Startup sequence:

1. The reducer initializes local defaults.
2. The web-ui host loads cached bootstrap data from `local_kv` when present.
3. The shell renders immediately with cached or empty state.
4. The frontend calls `GET /api/bootstrap`.
5. Fresh entities, indexes, and summaries replace the bootstrap branch.

Minimal sync sequence:

1. The reducer emits lightweight preference ops.
2. `POST /api/sync/push` accepts the settings snapshot.
3. `GET /api/sync/pull` returns an updated cursor and no domain mutations.

This keeps M2 within the milestone boundary while preserving the real app shape for later sync work.

## Design System

CrewOps uses one shared reducer shell with role-specific panels instead of separate apps.

- Technician shell
  - queue-first layout optimized for smaller screens
- Dispatcher shell
  - board-first layout with status and assignment scanning
- Manager shell
  - summary cards and exception-focused metrics

The current visual system uses a dark-slate base with teal and amber accents. Status styling is intentionally consistent across list rows, summary chips, and detail panels so trace snapshots stay stable.

## Build And Packaging Pipeline

Profile registries live under [`arch/`](../arch):

- [`arch/web_ui/index.x07webui.json`](../arch/web_ui/index.x07webui.json)
- [`arch/app/index.x07app.json`](../arch/app/index.x07app.json)
- [`arch/device/index.x07device.json`](../arch/device/index.x07device.json)

Current app profiles:

- `crewops_dev`
- `crewops_release`
- `crewops_budget`

Current device profiles:

- `device_desktop_dev`
- `device_ios_dev`
- `device_android_dev`

The pipeline in [`scripts/ci/check_all.sh`](../scripts/ci/check_all.sh) covers:

- lock and profile validation
- frontend and backend test harness runs
- app build and serve smoke
- trace replay and generated regression replay
- app pack, verify, provenance attest/verify, deploy plan, and SLO evaluation
- device build/verify for desktop, iOS, and Android
- desktop headless smoke
- iOS and Android package generation

The only intentional gap is the local `x07-platform` smoke, which remains a documented TODO until the platform probe succeeds in the workspace.

## Known M2 Boundaries

- No live database or multi-user sync backend
- No operational work-order editing
- No camera, location, notification, or dynamic-code capabilities
- iOS and Android dev profiles still require a reachable backend URL before packaging for a real simulator or device
