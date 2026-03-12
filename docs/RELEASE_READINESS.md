# CrewOps M7 Release Readiness

This note captures the local release bar for the `v0.6.0` M7 line.

## Canonical Gate

Run the full gate from the repo root:

```sh
./scripts/ci/check_all.sh
```

The gate is the source of truth for:

- frontend and backend `x07 check`
- frontend and backend `x07 test`
- app, device, ops, caps, and SLO validation
- deterministic trace generation and authored-trace replay
- incident-trace replay and generated regression replay
- app pack, verify, provenance, deploy-plan, and desktop smoke checks
- iOS and Android device package generation

## Required M7 Replay Coverage

The M7 release line is not ready unless these authored traces are green:

- `tests/traces/portal_login_and_history_happy.trace.json`
- `tests/traces/portal_approve_estimate.trace.json`
- `tests/traces/portal_request_to_office_conversion.trace.json`
- `tests/traces/branding_update_happy.trace.json`
- `tests/traces/tenant_role_change.trace.json`
- `tests/traces/inventory_consume_and_reconcile.trace.json`
- `tests/traces/purchase_order_receive_partial.trace.json`
- `tests/traces/connector_sync_retry.trace.json`
- `tests/traces/connector_config_revision_conflict.trace.json`
- `tests/traces/enterprise_dashboard_health.trace.json`

## Generated Regression Coverage

The local gate also expects these generated regressions to stay replayable after incident capture:

- `tests/regress/bootstrap_api_error.trace.json`
- `tests/regress/connector_delivery_failure.regress.trace.json`
- `tests/regress/portal_approval_revision_mismatch.regress.trace.json`

The incident-source traces are:

- `tests/incidents/connector_delivery_failure.trace.json`
- `tests/incidents/portal_approval_revision_mismatch.trace.json`

## Release Artifacts

The M7 release line is expected to produce these local artifacts:

- `dist/crewops_gate/app.crewops_dev`
- `dist/crewops_gate/app.crewops_release`
- `dist/crewops_gate/app.crewops_budget`
- `dist/crewops_gate/pack.crewops_release`
- `dist/crewops_gate/device_desktop_dev_bundle`
- `dist/crewops_gate/device_ios_dev_package`
- `dist/crewops_gate/device_android_dev_package`

## Operator Checklist

- Confirm `PROMPT.md`, `README.md`, and the local phase docs match the `v0.6.0` M7 route set.
- Confirm `frontend/x07.json` stays on `std-web-ui@0.2.4`.
- Confirm schema references stay on the published `x07.project@0.3.0` and `x07.x07ast@0.5.0` surfaces.
- Confirm `scripts/ci/seed_demo.sh` and generated `backend/src/demo_seed.x07.json` stay in sync.
- Confirm M7 sync fields for portal approval, tenant revision, inventory movement, receiving, and connector configuration are present in the seed and replay fixtures.
