# CrewOps M6 Release Readiness

This note captures the local release bar for the `v0.5.0` M6 line.

## Canonical Gate

Run the full gate from the repo root:

```sh
./scripts/ci/check_all.sh
```

The gate is the source of truth for:

- frontend and backend `x07 check`
- frontend and backend `x07 test`
- dev, release, and budget app profile validation
- deterministic trace generation and authored-trace replay
- generated regression replay
- app pack, verify, provenance, deploy-plan, and SLO checks
- desktop smoke and iOS or Android device package generation

## Required M6 Replay Coverage

The M6 release line is not ready unless these authored traces are green:

- `tests/traces/customer_approve_and_convert.trace.json`
- `tests/traces/contract_create_and_activate.trace.json`
- `tests/traces/recurring_plan_generate_schedule.trace.json`
- `tests/traces/recurring_skip_and_resume.trace.json`
- `tests/traces/webhook_delivery_retry.trace.json`
- `tests/traces/renewal_dashboard_view.trace.json`
- `tests/traces/conversion_revision_conflict.trace.json`

## Generated Regression Coverage

The local gate also expects generated regressions to stay replayable after incident capture. The current baseline includes:

- `tests/regress/bootstrap_api_error.trace.json`
- `tests/regress/payment_revision_conflict.trace.json`

When a replay mismatch is fixed:

1. rebuild the app bundle
2. regenerate or refresh the regression trace and final UI artifact through the canonical gate path
3. re-run `./scripts/ci/check_all.sh`

## Release Artifacts

The M6 release line is expected to produce these local artifacts:

- `dist/crewops_gate/app.crewops_dev`
- `dist/crewops_gate/app.crewops_release`
- `dist/crewops_gate/app.crewops_budget`
- `dist/crewops_gate/pack.crewops_release`
- `dist/crewops_gate/device_desktop_dev_bundle`
- `dist/crewops_gate/device_ios_dev_package`
- `dist/crewops_gate/device_android_dev_package`

## Operator Checklist

- Confirm `PROMPT.md`, `README.md`, and the M6 phase docs match the current route ids and release line.
- Confirm `frontend/x07.json` stays on `std-web-ui@0.2.3` unless a deliberate upgrade is part of the release.
- Confirm `scripts/ci/seed_demo.sh` and generated `backend/src/demo_seed.x07.json` stay in sync.
- Confirm integration retry, recurring-generation conflict, and estimate-approval conflict sync fields are present in the seed and replay fixtures.
