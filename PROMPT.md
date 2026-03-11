# `x07 CrewOps` Prompt

Use this repo as the current CrewOps `v0.4.0` showcase. The active product shape is M5 commercial operations, not the older M4-only operations narrative.

## Scope

- Frontend: [`frontend/src/app.x07.json`](frontend/src/app.x07.json) is the `std-web-ui` reducer.
- Backend: [`backend/src/app.x07.json`](backend/src/app.x07.json) is the deterministic WASI HTTP proxy component.
- Frontend package baseline: [`frontend/x07.json`](frontend/x07.json) is locked to `std-web-ui@0.2.2`.
- App profiles: `crewops_dev`, `crewops_release`, `crewops_budget`
- Device profiles: `device_desktop_dev`, `device_ios_dev`, `device_android_dev`
- Roles: `technician`, `dispatcher`, `supervisor`, `manager`
- Role and commercial docs: [`docs/DISPATCH_AND_REVIEW.md`](docs/DISPATCH_AND_REVIEW.md), [`docs/MANAGER_DASHBOARDS.md`](docs/MANAGER_DASHBOARDS.md), [`docs/DATA_MODEL.md`](docs/DATA_MODEL.md)

## Current Product Shape

- One reducer and one backend power technician execution, dispatcher control, supervisor review, manager dashboards, shared activity, and the M5 commercial routes.
- Primary routes are `today`, `dispatch`, `review`, `manager`, `finance`, `pricing`, `invoices`, `activity`, `customers`, `receivables`, `exports`, `sites`, `assets`, and `settings`.
- Shared state includes normalized entities, indexes, summaries, drafts, sync status, billing and export selections, and conflict metadata.
- Backend routes cover bootstrap, session, dispatch, review, corrections, activity, manager summary, technician execution, attachments, pricing config, invoices, finance summaries, customer accounts, exports, and sync.
- Sync state now carries `invoice_lock_status`, `payment_revision_status`, `pricing_revision_status`, `export_status`, `finance_revision`, and stale-entity ids alongside the existing conflict fields.

## Working Rules

- Treat [`scripts/ci/check_all.sh`](scripts/ci/check_all.sh) as the canonical CrewOps gate.
- Regenerate demo data through [`scripts/ci/seed_demo.sh`](scripts/ci/seed_demo.sh); do not hand-edit generated payloads.
- Keep docs and automation aligned to the current ids, the four-role reducer shape, the M5 commercial routes, and the `v0.4.0` release line.
- Keep replay and regression coverage centered on dispatch, review, correction, technician offline work, and the commercial billing and finance loop.
- Prefer direct `x07` and `x07-wasm` commands that target the current manifests and emit JSON reports.
