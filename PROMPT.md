# `x07 CrewOps` Prompt

Use this repo as the current CrewOps `v0.5.0` showcase. The active product shape is `M6`: technician execution, dispatch, review, finance, estimates, service contracts, recurring work, integrations, deterministic replay, and sealed-pack release validation in one app.

## Scope

- Frontend: [`frontend/src/app.x07.json`](frontend/src/app.x07.json) is the `std-web-ui` reducer.
- Backend: [`backend/src/app.x07.json`](backend/src/app.x07.json) is the deterministic WASI HTTP proxy component.
- Frontend package baseline: [`frontend/x07.json`](frontend/x07.json) is locked to `std-web-ui@0.2.3`.
- App profiles: `crewops_dev`, `crewops_release`, `crewops_budget`
- Device profiles: `device_desktop_dev`, `device_ios_dev`, `device_android_dev`
- Roles: `technician`, `dispatcher`, `supervisor`, `manager`
- Primary docs: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), [`docs/DATA_MODEL.md`](docs/DATA_MODEL.md), [`docs/DISPATCH_AND_REVIEW.md`](docs/DISPATCH_AND_REVIEW.md), [`docs/MANAGER_DASHBOARDS.md`](docs/MANAGER_DASHBOARDS.md), [`docs/DEMO_WALKTHROUGH.md`](docs/DEMO_WALKTHROUGH.md), [`docs/RELEASE_READINESS.md`](docs/RELEASE_READINESS.md)

## Current Product Shape

- One reducer and one backend power technician execution, dispatcher control, supervisor review, manager dashboards, finance, and the full M6 commercial route set.
- Primary routes are `today`, `dispatch`, `review`, `manager`, `finance`, `pricing`, `invoices`, `activity`, `customers`, `receivables`, `exports`, `sites`, `assets`, `settings`, `estimates`, `contracts`, `recurring`, and `integrations`.
- Shared state includes normalized entities, indexes, summaries, drafts, replay-safe sync metadata, billing selections, commercial selections, and conflict metadata.
- Backend routes cover bootstrap, session, dispatch, review, corrections, activity, manager summary, technician execution, attachments, pricing config, invoices, finance summaries, customer accounts, exports, estimate lifecycle, contract lifecycle, recurring-plan generation, integration control, and sync.
- Sync state carries `invoice_lock_status`, `payment_revision_status`, `pricing_revision_status`, `export_status`, `estimate_revision_status`, `agreement_revision_status`, `recurring_generation_status`, `delivery_retry_status`, and stale-entity ids.

## Working Rules

- Treat [`scripts/ci/check_all.sh`](scripts/ci/check_all.sh) as the canonical CrewOps gate.
- Regenerate demo data through [`scripts/ci/seed_demo.sh`](scripts/ci/seed_demo.sh); do not hand-edit generated payloads.
- Keep authored traces and generated regressions aligned with the current M6 ids, routes, and sync schema.
- Keep docs and release notes aligned to the `v0.5.0` release line and the current `std-web-ui@0.2.3` dependency baseline.
- Prefer direct `x07` and `x07-wasm` commands that target the checked-in manifests and emit JSON reports.
