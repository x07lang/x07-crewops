# CrewOps Architecture

CrewOps is a single-repo showcase app that combines the `x07_atlas` full-stack app shape with the multi-device packaging flow used by `x07_field_notes`. One reducer drives all shells, one deterministic backend serves demo and execution data, and the same app bundle is packaged for desktop, iOS, and Android.

## Repo Layers

- [`frontend/`](../frontend)
  - reducer, execution flow, role shells, tests, and the `std-web-ui@0.2.1` dependency
- [`backend/`](../backend)
  - deterministic API handlers for the current read-only and execution surfaces
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
- [`frontend/src/execution.x07.json`](../frontend/src/execution.x07.json)
  - execution-state document builders for checklist progress, labor, parts, signatures, evidence, location, autosave, and validation
- [`frontend/src/session.x07.json`](../frontend/src/session.x07.json)
  - dev login payloads and role switching
- [`frontend/src/bootstrap.x07.json`](../frontend/src/bootstrap.x07.json)
  - cache key and startup source tracking
- [`frontend/src/sync.x07.json`](../frontend/src/sync.x07.json)
  - pending-op queue, pull/push bookkeeping, and conflict banner state

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
- `template`
- `execution`
- `meta`

Technician execution centers the current field workflow:

- checklist fields are template-driven and validated in the reducer
- edits queue autosave, offline draft ops, and reconnect sync without duplicating payload builders
- completion and blocked flows share the same visit state machine, then branch on validation and policy
- evidence capture/import, attachment registration/upload, and location-assisted check-in/out stay inside the same deterministic state tree

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

The backend keeps deterministic in-repo state, but it now exposes the full execution surface without adding a live database.

- [`backend/src/templates.x07.json`](../backend/src/templates.x07.json)
  - `GET /api/templates/:id`
- [`backend/src/visits.x07.json`](../backend/src/visits.x07.json)
  - `POST /api/visits/:id/check-in`
  - `POST /api/visits/:id/save-draft`
  - `POST /api/visits/:id/submit`
  - `POST /api/visits/:id/block`
  - `POST /api/visits/:id/check-out`
- [`backend/src/attachments.x07.json`](../backend/src/attachments.x07.json)
  - `POST /api/attachments/register`
  - `PUT /api/attachments/:id/content`
- [`backend/src/sync.x07.json`](../backend/src/sync.x07.json)
  - `GET /api/sync/pull`
  - `POST /api/sync/push`

## Bootstrap And Sync Flow

Startup and execution sequence:

1. The reducer initializes local defaults.
2. The web-ui host loads cached bootstrap data from `local_kv` when present.
3. The shell renders immediately with cached or empty state.
4. The frontend calls `GET /api/bootstrap`.
5. Fresh entities, indexes, summaries, templates, and visit execution metadata replace the bootstrap branch.

Execution sync sequence:

1. Technician edits mark the execution branch dirty and queue autosave.
2. Online autosave posts drafts directly; offline autosave writes a deterministic `pending_ops` envelope.
3. Check-in, complete, blocked, check-out, and attachment ops join the same queue when offline.
4. `POST /api/sync/push` drains queued visit and attachment ops when connectivity returns.
5. `GET /api/sync/pull` returns the latest cursor plus any conflict banner metadata.

This keeps the execution loop deterministic while preserving the real app shape for later live persistence work.

## Design System

CrewOps uses one shared reducer shell with role-specific panels instead of separate apps.

- Technician shell
  - queue-first layout optimized for smaller screens
- Dispatcher shell
  - board-first layout with status and assignment scanning
- Manager shell
  - summary cards and exception-focused metrics

The current visual system uses a warm field-service palette with high-contrast action controls. Status styling is intentionally consistent across list rows, execution cards, sync banners, and trace snapshots so replay output stays stable.

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
- execution, offline, denied-permission, and reconnect replay coverage
- app pack, verify, provenance attest/verify, deploy plan, and SLO evaluation
- device build/verify for desktop, iOS, and Android
- desktop headless smoke
- iOS and Android package generation

The only intentional gap is the local `x07-platform` smoke, which remains a documented TODO until the platform probe succeeds in the workspace.

## Current Boundaries

- No live database or multi-user sync backend
- No notifications, barcode scan, or background sync daemon
- Dispatcher and manager surfaces remain read-only while technician execution is active
- iOS and Android dev profiles still require a reachable backend URL before packaging for a real simulator or device
