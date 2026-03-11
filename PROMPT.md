# `x07 CrewOps` Prompt

Use this repo as the current CrewOps `v0.3.0` showcase. The active product shape is M4 multi-role operations, not the older M3 technician-only narrative.

## Scope

- Frontend: [`frontend/src/app.x07.json`](frontend/src/app.x07.json) is the `std.web_ui` reducer.
- Backend: [`backend/src/app.x07.json`](backend/src/app.x07.json) is the WASI HTTP proxy component.
- Frontend package baseline: [`frontend/x07.json`](frontend/x07.json) is locked to `std-web-ui@0.2.1`.
- App profiles: `crewops_dev`, `crewops_release`, `crewops_budget`
- Device profiles: `device_desktop_dev`, `device_ios_dev`, `device_android_dev`
- Roles: `technician`, `dispatcher`, `supervisor`, `manager`
- Demo seed source: [`scripts/ci/seed_demo.sh`](scripts/ci/seed_demo.sh)
- Replay coverage: [`tests/traces`](tests/traces) and [`tests/regress`](tests/regress)
- Role docs: [`docs/DISPATCH_AND_REVIEW.md`](docs/DISPATCH_AND_REVIEW.md) and [`docs/MANAGER_DASHBOARDS.md`](docs/MANAGER_DASHBOARDS.md)

## Current Product Shape

- One reducer and one backend power technician execution plus dispatcher, supervisor, manager, and shared activity surfaces.
- Primary routes are `today`, `dispatch`, `review`, `manager`, `activity`, `customers`, `sites`, `assets`, and `settings`.
- Shared state includes normalized entities, indexes, summaries, drafts, sync status, activity or alert unread counts, and conflict metadata.
- Backend routes cover bootstrap, dev login, work-order intake and assignment, supervisor review and corrections, manager summary, activity feed, technician execution, attachments, and sync.
- The device profiles are versioned at `0.3.0` and enable local notifications for M4 operations.

## Working Rules

- Treat [`scripts/ci/check_all.sh`](scripts/ci/check_all.sh) as the canonical CrewOps gate.
- Regenerate demo data through [`scripts/ci/seed_demo.sh`](scripts/ci/seed_demo.sh); do not hand-edit generated payloads.
- Keep docs and automation aligned to the current CrewOps ids, four roles, and `v0.3.0` release baseline.
- Keep replay and regression coverage centered on dispatch, review, correction, activity, manager rollups, and technician offline flows.
- Prefer direct `x07` and `x07-wasm` commands that target the current manifests and emit JSON reports.
