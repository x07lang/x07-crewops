#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="$ROOT/build/crewops_gate"
REPORT_DIR="$BUILD_DIR/reports"
DIST_DIR="$ROOT/dist/crewops_gate"
APP_DEV_DIR="$DIST_DIR/app.crewops_dev"
APP_RELEASE_DIR="$DIST_DIR/app.crewops_release"
APP_BUDGET_DIR="$DIST_DIR/app.crewops_budget"
PACK_RELEASE_DIR="$DIST_DIR/pack.crewops_release"
DEPLOY_RELEASE_DIR="$DIST_DIR/deploy.crewops_release"
DESKTOP_BUNDLE_DIR="$DIST_DIR/device_desktop_dev_bundle"
IOS_BUNDLE_DIR="$DIST_DIR/device_ios_dev_bundle"
ANDROID_BUNDLE_DIR="$DIST_DIR/device_android_dev_bundle"
IOS_PACKAGE_DIR="$DIST_DIR/device_ios_dev_package"
ANDROID_PACKAGE_DIR="$DIST_DIR/device_android_dev_package"
INCIDENTS_ROOT="$ROOT/.x07-wasm/incidents"
GENERATED_BOOTSTRAP_REGRESSION_TRACE="$ROOT/tests/regress/bootstrap_api_error.trace.json"
GENERATED_BOOTSTRAP_REGRESSION_UI="$ROOT/tests/regress/bootstrap_api_error.final.ui.json"
GENERATED_PAYMENT_CONFLICT_REGRESSION_TRACE="$ROOT/tests/regress/payment_revision_conflict.trace.json"
GENERATED_PAYMENT_CONFLICT_REGRESSION_UI="$ROOT/tests/regress/payment_revision_conflict.final.ui.json"
PLATFORM_STATE_DIR="$BUILD_DIR/platform_state"
PLATFORM_METRICS_DIR="$BUILD_DIR/platform_metrics"
PLATFORM_TODO_REPORT="$REPORT_DIR/platform.smoke.todo.txt"
TRACE_GENERATOR="$ROOT/scripts/generate_m4_traces.mjs"
WASM_BACKEND_ROOT="${WASM_BACKEND_ROOT:-$ROOT/../x07-wasm-backend}"
X07_PLATFORM_ROOT="${X07_PLATFORM_ROOT:-$ROOT/../x07-platform}"

TRACE_FIXTURES=(
  "$ROOT/tests/traces/bootstrap_demo_happy.trace.json"
  "$ROOT/tests/traces/dispatch_assign_happy.trace.json"
  "$ROOT/tests/traces/dispatch_reassign_happy.trace.json"
  "$ROOT/tests/traces/technician_reassigned_mid_draft.trace.json"
  "$ROOT/tests/traces/supervisor_request_correction.trace.json"
  "$ROOT/tests/traces/technician_correction_resubmit.trace.json"
  "$ROOT/tests/traces/review_queue_filtering.trace.json"
  "$ROOT/tests/traces/manager_dashboard_rollup.trace.json"
  "$ROOT/tests/traces/local_notification_assignment_alert.trace.json"
  "$ROOT/tests/traces/conflict_reassign_vs_local_submit.trace.json"
  "$ROOT/tests/traces/invoice_generate_happy.trace.json"
  "$ROOT/tests/traces/invoice_edit_and_issue.trace.json"
  "$ROOT/tests/traces/partial_payment_record.trace.json"
  "$ROOT/tests/traces/overdue_aging_view.trace.json"
  "$ROOT/tests/traces/customer_statement_view.trace.json"
  "$ROOT/tests/traces/finance_export_happy.trace.json"
  "$ROOT/tests/traces/finance_export_retry.trace.json"
  "$ROOT/tests/traces/invoice_lock_conflict.trace.json"
  "$ROOT/tests/traces/pricing_revision_mismatch.trace.json"
  "$ROOT/tests/traces/manager_finance_dashboard.trace.json"
  "$ROOT/tests/traces/payment_revision_conflict.trace.json"
  "$ROOT/tests/traces/bootstrap_api_error.trace.json"
)

APP_SMOKE_TRACES=(
  "$ROOT/tests/traces/bootstrap_demo_happy.trace.json"
)

APP_REQUIRED_TRACES=(
  "$ROOT/tests/traces/dispatch_assign_happy.trace.json"
  "$ROOT/tests/traces/dispatch_reassign_happy.trace.json"
  "$ROOT/tests/traces/technician_reassigned_mid_draft.trace.json"
  "$ROOT/tests/traces/supervisor_request_correction.trace.json"
  "$ROOT/tests/traces/technician_correction_resubmit.trace.json"
  "$ROOT/tests/traces/review_queue_filtering.trace.json"
  "$ROOT/tests/traces/manager_dashboard_rollup.trace.json"
  "$ROOT/tests/traces/local_notification_assignment_alert.trace.json"
  "$ROOT/tests/traces/conflict_reassign_vs_local_submit.trace.json"
  "$ROOT/tests/traces/invoice_generate_happy.trace.json"
  "$ROOT/tests/traces/invoice_edit_and_issue.trace.json"
  "$ROOT/tests/traces/partial_payment_record.trace.json"
  "$ROOT/tests/traces/overdue_aging_view.trace.json"
  "$ROOT/tests/traces/customer_statement_view.trace.json"
  "$ROOT/tests/traces/finance_export_happy.trace.json"
  "$ROOT/tests/traces/finance_export_retry.trace.json"
  "$ROOT/tests/traces/invoice_lock_conflict.trace.json"
  "$ROOT/tests/traces/pricing_revision_mismatch.trace.json"
  "$ROOT/tests/traces/manager_finance_dashboard.trace.json"
  "$ROOT/tests/traces/payment_revision_conflict.trace.json"
)
EXPECTED_BOOTSTRAP_FAILURE_TRACE="$ROOT/tests/traces/bootstrap_api_error.trace.json"

cd "$ROOT"

rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p \
  "$REPORT_DIR" \
  "$PACK_RELEASE_DIR" \
  "$DEPLOY_RELEASE_DIR" \
  "$ROOT/tests/regress" \
  "$INCIDENTS_ROOT"

FAILURES=0

note() {
  printf '%s\n' "$*"
}

mark_failure() {
  FAILURES=$((FAILURES + 1))
  note "FAIL: $*"
}

write_todo() {
  local message="$1"
  printf '%s\n' "$message" >"$PLATFORM_TODO_REPORT"
  note "$message"
}

run_step() {
  local name="$1"
  shift
  note "==> $name"
  if ! "$@"; then
    mark_failure "$name"
  fi
  return 0
}

run_json() {
  local report_path="$1"
  shift
  "$@" --json --report-out "$report_path" --quiet-json
}

resolve_python() {
  if command -v python3 >/dev/null 2>&1; then
    command -v python3
    return 0
  fi
  if command -v python >/dev/null 2>&1; then
    command -v python
    return 0
  fi
  return 1
}

resolve_node() {
  if command -v node >/dev/null 2>&1; then
    command -v node
    return 0
  fi
  return 1
}

resolve_versioned_tool() {
  local probe_arg="$1"
  shift
  local candidate=""
  for candidate in "$@"; do
    if [ -z "${candidate:-}" ] || [ ! -x "$candidate" ]; then
      continue
    fi
    if "$candidate" "$probe_arg" >/dev/null 2>&1; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

resolve_stdlib_lock() {
  local x07_path="$1"
  local candidates=(
    "$ROOT/stdlib.lock"
    "$ROOT/../x07/stdlib.lock"
    "$(dirname "$x07_path")/stdlib.lock"
    "$(cd "$(dirname "$x07_path")/.." && pwd)/stdlib.lock"
  )
  local cand=""
  for cand in "${candidates[@]}"; do
    if [ -f "$cand" ]; then
      printf '%s\n' "$cand"
      return 0
    fi
  done
  return 1
}

report_incident_dir() {
  local report_path="$1"
  if [ ! -f "$report_path" ]; then
    return 1
  fi
  "$PYTHON" - "$report_path" <<'PY'
import json
import pathlib
import sys

report = pathlib.Path(sys.argv[1])
doc = json.loads(report.read_text(encoding="utf-8"))
result = doc.get("result", {})
stdout_json = result.get("stdout_json", {}) if isinstance(result, dict) else {}
incident_dir = stdout_json.get("incident_dir")
if isinstance(incident_dir, str) and incident_dir:
    print(incident_dir)
PY
}

extract_compile_error() {
  local report_path="$1"
  if [ ! -f "$report_path" ]; then
    return 1
  fi
  "$PYTHON" - "$report_path" <<'PY'
import json
import pathlib
import sys

report = pathlib.Path(sys.argv[1])
doc = json.loads(report.read_text(encoding="utf-8"))
compile_doc = doc.get("compile", {})
compile_error = compile_doc.get("compile_error")
if isinstance(compile_error, str) and compile_error:
    print(compile_error)
PY
}

resolve_path() {
  local path="$1"
  case "$path" in
    /*)
      printf '%s\n' "$path"
      ;;
    *)
      printf '%s\n' "$ROOT/$path"
      ;;
  esac
}

require_path() {
  local path="$1"
  local label="$2"
  if [ ! -e "$path" ]; then
    mark_failure "$label missing: $path"
  fi
}

validate_json_files() {
  "$PYTHON" - "$@" <<'PY'
import json
import pathlib
import sys

for raw_path in sys.argv[1:]:
    path = pathlib.Path(raw_path)
    with path.open("r", encoding="utf-8") as handle:
        json.load(handle)
PY
}

run_expect_failure_with_incident() {
  local name="$1"
  local report_path="$2"
  shift 2
  note "==> $name"
  if "$@"; then
    mark_failure "$name (expected failure)"
    return 0
  fi
  local incident_dir=""
  incident_dir="$(report_incident_dir "$report_path" || true)"
  if [ -z "$incident_dir" ]; then
    mark_failure "$name (missing incident_dir)"
  fi
  return 0
}

resolve_x07_device_host_desktop() {
  local repo_root="$1"
  local snapshot_path="${repo_root}/vendor/x07-device-host/host_abi.snapshot.json"
  local expected_hash=""

  if [ -f "${snapshot_path}" ]; then
    expected_hash="$("$PYTHON" - "${snapshot_path}" <<'PY'
import json
import pathlib
import sys

snapshot = pathlib.Path(sys.argv[1])
doc = json.loads(snapshot.read_text(encoding="utf-8"))
value = doc.get("host_abi_hash")
if isinstance(value, str):
    print(value)
PY
)"
  fi

  local candidates=()
  local candidate=""
  local abi_hash=""

  if [ -n "${X07_DEVICE_HOST_DESKTOP:-}" ]; then
    candidates+=("${X07_DEVICE_HOST_DESKTOP}")
  fi

  if command -v x07-device-host-desktop >/dev/null 2>&1; then
    candidates+=("$(command -v x07-device-host-desktop)")
  fi

  for candidate in \
    "${repo_root}/../x07-device-host/target/debug/x07-device-host-desktop" \
    "${repo_root}/../x07-device-host/target/release/x07-device-host-desktop"
  do
    if [ -x "${candidate}" ]; then
      candidates+=("${candidate}")
    fi
  done

  for candidate in "${candidates[@]}"; do
    if ! abi_hash="$("${candidate}" --host-abi-hash 2>/dev/null)"; then
      continue
    fi
    case "${abi_hash}" in
      [0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]*)
        if [ "${#abi_hash}" -ne 64 ]; then
          continue
        fi
        if [ -n "${expected_hash}" ] && [ "${abi_hash}" != "${expected_hash}" ]; then
          continue
        fi
        printf '%s\n' "${candidate}"
        return 0
        ;;
    esac
  done

  return 1
}

prepare_platform_metrics_dir() {
  mkdir -p "$PLATFORM_METRICS_DIR"
  cp "$ROOT/tests/fixtures/metrics/crewops_canary_ok.json" "$PLATFORM_METRICS_DIR/analysis.1.json"
  cp "$ROOT/tests/fixtures/metrics/crewops_canary_ok.json" "$PLATFORM_METRICS_DIR/analysis.2.json"
  cp "$ROOT/tests/fixtures/metrics/crewops_canary_ok.json" "$PLATFORM_METRICS_DIR/analysis.3.json"
}

run_x07_platform() {
  local runner_report="$1"
  local stdout_path="$2"
  shift 2
  "$X07_BIN" run \
    --project "$X07_PLATFORM_ROOT/x07.json" \
    --json \
    --report-out "$runner_report" \
    --quiet-json \
    --out "$stdout_path" \
    -- "$@"
}

probe_platform_smoke() {
  local probe_report="$REPORT_DIR/platform.smoke.probe.runner.json"
  local probe_stdout="$REPORT_DIR/platform.smoke.probe.stdout.txt"

  if [ ! -f "$X07_PLATFORM_ROOT/x07.json" ]; then
    write_todo "TODO: local platform smoke not run: missing x07-platform at $X07_PLATFORM_ROOT"
    return 1
  fi

  if run_x07_platform "$probe_report" "$probe_stdout" --help; then
    return 0
  fi

  local compile_error=""
  compile_error="$(extract_compile_error "$probe_report" || true)"
  if [ -n "$compile_error" ]; then
    write_todo "TODO: local platform smoke not run: x07-platform probe failed: $compile_error"
  else
    write_todo "TODO: local platform smoke not run: x07-platform probe failed; see $probe_report"
  fi
  return 1
}

run_platform_smoke() {
  if ! probe_platform_smoke; then
    return 0
  fi

  prepare_platform_metrics_dir

  local change_request="$X07_PLATFORM_ROOT/spec/fixtures/phaseA/change_request.min.json"
  local deployment_id="lpexec_crewops_local_smoke"

  run_step "x07-platform deploy accept crewops_release" \
    run_x07_platform \
      "$REPORT_DIR/platform.deploy.accept.runner.json" \
      "$REPORT_DIR/platform.deploy.accept.stdout.json" \
      deploy accept \
      --pack-dir "$PACK_RELEASE_DIR" \
      --pack-manifest app.pack.json \
      --change "$change_request" \
      --state-dir "$PLATFORM_STATE_DIR" \
      --json

  run_step "x07-platform deploy run crewops_release" \
    run_x07_platform \
      "$REPORT_DIR/platform.deploy.run.runner.json" \
      "$REPORT_DIR/platform.deploy.run.stdout.json" \
      deploy run \
      --deployment-id "$deployment_id" \
      --plan "$DEPLOY_RELEASE_DIR/deploy.plan.json" \
      --metrics-dir "$PLATFORM_METRICS_DIR" \
      --state-dir "$PLATFORM_STATE_DIR" \
      --json

  run_step "x07-platform deploy query crewops_release" \
    run_x07_platform \
      "$REPORT_DIR/platform.deploy.query.runner.json" \
      "$REPORT_DIR/platform.deploy.query.stdout.json" \
      deploy query \
      --deployment-id "$deployment_id" \
      --view full \
      --state-dir "$PLATFORM_STATE_DIR" \
      --json
}

build_device_bundle() {
  local profile_id="$1"
  local bundle_dir="$2"

  run_step "x07-wasm device build ${profile_id}" \
    run_json \
      "$REPORT_DIR/device.build.${profile_id}.json" \
      "$X07_WASM_BIN" device build \
      --index arch/device/index.x07device.json \
      --profile "$profile_id" \
      --out-dir "$bundle_dir" \
      --clean \
      --strict

  run_step "x07-wasm device verify ${profile_id}" \
    run_json \
      "$REPORT_DIR/device.verify.${profile_id}.json" \
      "$X07_WASM_BIN" device verify \
      --dir "$bundle_dir"
}

run_desktop_smoke() {
  local host_tool=""
  local serve_pid=""
  local serve_ready=0
  local attempt=0
  local max_attempts=30

  build_device_bundle "device_desktop_dev" "$DESKTOP_BUNDLE_DIR"

  host_tool="$(resolve_x07_device_host_desktop "$WASM_BACKEND_ROOT" || true)"
  if [ -z "$host_tool" ]; then
    mark_failure "device_desktop_dev smoke requires x07-device-host-desktop"
    return 0
  fi

  export X07_DEVICE_HOST_DESKTOP="$host_tool"

  note "==> x07-wasm app serve listen crewops_dev"
  "$X07_WASM_BIN" app serve \
    --dir "$APP_DEV_DIR" \
    --mode listen \
    --addr 127.0.0.1:17081 \
    --json \
    --report-out "$REPORT_DIR/app.serve.crewops_dev.listen.json" \
    --quiet-json \
    --strict \
    >"$REPORT_DIR/app.serve.crewops_dev.listen.stdout.json" 2>&1 &
  serve_pid="$!"

  while [ "$attempt" -lt "$max_attempts" ]; do
    if curl -fsS http://127.0.0.1:17081/api/meta/app >/dev/null 2>&1; then
      serve_ready=1
      break
    fi
    if ! kill -0 "$serve_pid" >/dev/null 2>&1; then
      break
    fi
    attempt=$((attempt + 1))
    sleep 1
  done

  if [ "$serve_ready" -ne 1 ]; then
    if [ -n "$serve_pid" ] && kill -0 "$serve_pid" >/dev/null 2>&1; then
      kill "$serve_pid" >/dev/null 2>&1 || true
      wait "$serve_pid" >/dev/null 2>&1 || true
    fi
    mark_failure "x07-wasm app serve listen crewops_dev"
    return 0
  fi

  run_step "x07-wasm device run device_desktop_dev" \
    run_json \
      "$REPORT_DIR/device.run.device_desktop_dev.json" \
      "$X07_WASM_BIN" device run \
      --bundle "$DESKTOP_BUNDLE_DIR" \
      --target desktop \
      --headless-smoke

  if [ -n "$serve_pid" ] && kill -0 "$serve_pid" >/dev/null 2>&1; then
    kill "$serve_pid" >/dev/null 2>&1 || true
    wait "$serve_pid" >/dev/null 2>&1 || true
  fi
}

package_mobile_target() {
  local profile_id="$1"
  local target="$2"
  local bundle_dir="$3"
  local package_dir="$4"
  local project_dir="$5"
  local embedded_assets_dir="$6"

  build_device_bundle "$profile_id" "$bundle_dir"

  run_step "x07-wasm device package ${profile_id}" \
    run_json \
      "$REPORT_DIR/device.package.${profile_id}.json" \
      "$X07_WASM_BIN" device package \
      --bundle "$bundle_dir" \
      --target "$target" \
      --out-dir "$package_dir"

  require_path "$package_dir/package.manifest.json" "${profile_id} package manifest"
  require_path "$package_dir/$project_dir" "${profile_id} project"
  require_path "$package_dir/$embedded_assets_dir" "${profile_id} embedded assets"
}

PYTHON="$(resolve_python || true)"
if [ -z "$PYTHON" ]; then
  note "missing required python interpreter: python3 or python"
  exit 1
fi

NODE_BIN="${NODE_BIN:-$(resolve_node || true)}"
if [ -z "$NODE_BIN" ]; then
  note "missing required node interpreter: node"
  exit 1
fi

X07_BIN="$(resolve_versioned_tool --version "${X07_BIN:-}" "$(command -v x07 2>/dev/null || true)" "$ROOT/../x07/target/debug/x07" "$ROOT/../x07/target/release/x07" || true)"
X07_WASM_BIN="$(resolve_versioned_tool --version "${X07_WASM_BIN:-}" "$ROOT/../x07-wasm-backend/target/debug/x07-wasm" "$ROOT/../x07-wasm-backend/target/release/x07-wasm" "$(command -v x07-wasm 2>/dev/null || true)" || true)"

if [ -z "$X07_BIN" ] || [ -z "$X07_WASM_BIN" ]; then
  note "missing required binaries: x07 and/or x07-wasm"
  exit 1
fi

STDLIB_LOCK="$(resolve_stdlib_lock "$X07_BIN" || true)"
if [ -z "$STDLIB_LOCK" ]; then
  note "could not resolve stdlib.lock for x07 test"
  exit 1
fi

note "using x07: $X07_BIN"
note "using x07-wasm: $X07_WASM_BIN"
note "using node: $NODE_BIN"

run_step "x07 check frontend" \
  run_json \
    "$REPORT_DIR/frontend.check.json" \
    "$X07_BIN" check \
    --project "$ROOT/frontend/x07.json"

run_step "x07 check backend" \
  run_json \
    "$REPORT_DIR/backend.check.json" \
    "$X07_BIN" check \
    --project "$ROOT/backend/x07.json"

run_step "x07 test frontend" \
  run_json \
    "$REPORT_DIR/frontend.test.json" \
    "$X07_BIN" test \
    --manifest "$ROOT/frontend/tests/tests.json" \
    --stdlib-lock "$STDLIB_LOCK"

run_step "x07 test backend" \
  run_json \
    "$REPORT_DIR/backend.test.json" \
    "$X07_BIN" test \
    --manifest "$ROOT/backend/tests/tests.json" \
    --stdlib-lock "$STDLIB_LOCK"

run_step "x07-wasm app profile validate crewops_dev" \
  run_json \
    "$REPORT_DIR/app.profile.validate.crewops_dev.json" \
    "$X07_WASM_BIN" app profile validate \
    --index arch/app/index.x07app.json \
    --profile crewops_dev \
    --strict

run_step "x07-wasm app profile validate crewops_release" \
  run_json \
    "$REPORT_DIR/app.profile.validate.crewops_release.json" \
    "$X07_WASM_BIN" app profile validate \
    --index arch/app/index.x07app.json \
    --profile crewops_release \
    --strict

run_step "x07-wasm app profile validate crewops_budget" \
  run_json \
    "$REPORT_DIR/app.profile.validate.crewops_budget.json" \
    "$X07_WASM_BIN" app profile validate \
    --index arch/app/index.x07app.json \
    --profile crewops_budget \
    --strict

run_step "x07-wasm ops validate ops_release" \
  run_json \
    "$REPORT_DIR/ops.validate.ops_release.json" \
    "$X07_WASM_BIN" ops validate \
    --profile "$ROOT/arch/app/ops/ops_release.json"

run_step "x07-wasm caps validate caps_release" \
  run_json \
    "$REPORT_DIR/caps.validate.caps_release.json" \
    "$X07_WASM_BIN" caps validate \
    --profile "$ROOT/arch/app/ops/caps_release.json"

run_step "x07-wasm slo validate slo_min" \
  run_json \
    "$REPORT_DIR/slo.validate.slo_min.json" \
    "$X07_WASM_BIN" slo validate \
    --profile "$ROOT/arch/slo/slo_min.json"

run_step "x07-wasm device index validate" \
  run_json \
    "$REPORT_DIR/device.index.validate.json" \
    "$X07_WASM_BIN" device index validate \
    --index arch/device/index.x07device.json

run_step "x07-wasm device profile validate" \
  run_json \
    "$REPORT_DIR/device.profile.validate.json" \
    "$X07_WASM_BIN" device profile validate \
    --index arch/device/index.x07device.json \
    --strict

run_step "x07-wasm app build crewops_dev" \
  run_json \
    "$REPORT_DIR/app.build.crewops_dev.json" \
    "$X07_WASM_BIN" app build \
    --index arch/app/index.x07app.json \
    --profile crewops_dev \
    --out-dir "$APP_DEV_DIR" \
    --clean \
    --strict

run_step "x07-wasm app build crewops_release" \
  run_json \
    "$REPORT_DIR/app.build.crewops_release.json" \
    "$X07_WASM_BIN" app build \
    --index arch/app/index.x07app.json \
    --profile crewops_release \
    --out-dir "$APP_RELEASE_DIR" \
    --clean \
    --strict

run_step "x07-wasm app build crewops_budget" \
  run_json \
    "$REPORT_DIR/app.build.crewops_budget.json" \
    "$X07_WASM_BIN" app build \
    --index arch/app/index.x07app.json \
    --profile crewops_budget \
    --out-dir "$APP_BUDGET_DIR" \
    --clean \
    --strict

run_step "x07-wasm app serve smoke crewops_dev" \
  run_json \
    "$REPORT_DIR/app.serve.crewops_dev.smoke.json" \
    "$X07_WASM_BIN" app serve \
    --dir "$APP_DEV_DIR" \
    --mode smoke \
    --strict

run_step "generate M5 app traces" \
  "$NODE_BIN" "$TRACE_GENERATOR" --update-golden

run_step "validate M5 trace JSON fixtures" \
  validate_json_files \
    "${TRACE_FIXTURES[@]}"

for trace_path in "${APP_SMOKE_TRACES[@]}"; do
  trace_name="$(basename "$trace_path" .trace.json)"
  run_step "x07-wasm app test ${trace_name}" \
    run_json \
      "$REPORT_DIR/app.test.${trace_name}.json" \
      "$X07_WASM_BIN" app test \
      --dir "$APP_DEV_DIR" \
      --trace "$trace_path" \
      --strict
done

for trace_path in "${APP_REQUIRED_TRACES[@]}"; do
  trace_name="$(basename "$trace_path" .trace.json)"
  run_step "x07-wasm app test ${trace_name}" \
    run_json \
      "$REPORT_DIR/app.test.${trace_name}.json" \
      "$X07_WASM_BIN" app test \
      --dir "$APP_DEV_DIR" \
      --trace "$trace_path" \
      --strict
done

EXPECTED_FAILURE_REPORT="$REPORT_DIR/app.test.bootstrap_api_error.expected_failure.json"
run_expect_failure_with_incident \
  "x07-wasm app test bootstrap_api_error (expected failure)" \
  "$EXPECTED_FAILURE_REPORT" \
  run_json \
    "$EXPECTED_FAILURE_REPORT" \
    "$X07_WASM_BIN" app test \
    --dir "$APP_DEV_DIR" \
    --trace "$EXPECTED_BOOTSTRAP_FAILURE_TRACE" \
    --strict

INCIDENT_DIR="$(report_incident_dir "$EXPECTED_FAILURE_REPORT" || true)"
if [ -n "$INCIDENT_DIR" ]; then
  INCIDENT_DIR="$(resolve_path "$INCIDENT_DIR")"
  rm -f "$GENERATED_BOOTSTRAP_REGRESSION_TRACE" "$GENERATED_BOOTSTRAP_REGRESSION_UI"
  run_step "x07-wasm app regress from-incident bootstrap_api_error" \
    run_json \
      "$REPORT_DIR/app.regress.from_incident.bootstrap_api_error.json" \
      "$X07_WASM_BIN" app regress from-incident \
      "$INCIDENT_DIR" \
      --out-dir "$ROOT/tests/regress" \
      --name bootstrap_api_error \
      --strict
  require_path "$GENERATED_BOOTSTRAP_REGRESSION_TRACE" "generated bootstrap_api_error regression trace"
  require_path "$GENERATED_BOOTSTRAP_REGRESSION_UI" "generated bootstrap_api_error final UI"
  if [ -f "$GENERATED_BOOTSTRAP_REGRESSION_TRACE" ]; then
    run_step "x07-wasm app test generated bootstrap_api_error regression" \
      run_json \
        "$REPORT_DIR/app.test.regress.bootstrap_api_error.json" \
        "$X07_WASM_BIN" app test \
        --dir "$APP_DEV_DIR" \
        --trace "$GENERATED_BOOTSTRAP_REGRESSION_TRACE" \
        --strict
  fi
else
  note "skipping bootstrap_api_error regression replay: incident bundle unavailable"
fi

require_path "$GENERATED_PAYMENT_CONFLICT_REGRESSION_TRACE" "generated payment_revision_conflict regression trace"
require_path "$GENERATED_PAYMENT_CONFLICT_REGRESSION_UI" "generated payment_revision_conflict final UI"
if [ -f "$GENERATED_PAYMENT_CONFLICT_REGRESSION_TRACE" ]; then
  run_step "x07-wasm app test generated payment_revision_conflict regression" \
    run_json \
      "$REPORT_DIR/app.test.regress.payment_revision_conflict.json" \
      "$X07_WASM_BIN" app test \
      --dir "$APP_DEV_DIR" \
      --trace "$GENERATED_PAYMENT_CONFLICT_REGRESSION_TRACE" \
      --strict
fi

require_path "$APP_RELEASE_DIR/app.bundle.json" "crewops_release app bundle manifest"

run_step "x07-wasm app pack crewops_release" \
  run_json \
    "$REPORT_DIR/app.pack.crewops_release.json" \
    "$X07_WASM_BIN" app pack \
    --bundle-manifest "$APP_RELEASE_DIR/app.bundle.json" \
    --profile-id crewops_release \
    --out-dir "$PACK_RELEASE_DIR"

require_path "$PACK_RELEASE_DIR/app.pack.json" "crewops_release pack manifest"

run_step "x07-wasm app verify crewops_release" \
  run_json \
    "$REPORT_DIR/app.verify.crewops_release.json" \
    "$X07_WASM_BIN" app verify \
    --pack-manifest "$PACK_RELEASE_DIR/app.pack.json"

run_step "x07-wasm provenance attest crewops_release" \
  run_json \
    "$REPORT_DIR/provenance.attest.crewops_release.json" \
    "$X07_WASM_BIN" provenance attest \
    --pack-manifest "$PACK_RELEASE_DIR/app.pack.json" \
    --ops "$ROOT/arch/app/ops/ops_release.json" \
    --signing-key "$ROOT/arch/provenance/dev.ed25519.signing_key.b64" \
    --out "$PACK_RELEASE_DIR/app.provenance.dsse.json"

run_step "x07-wasm provenance verify crewops_release" \
  run_json \
    "$REPORT_DIR/provenance.verify.crewops_release.json" \
    "$X07_WASM_BIN" provenance verify \
    --attestation "$PACK_RELEASE_DIR/app.provenance.dsse.json" \
    --pack-dir "$PACK_RELEASE_DIR" \
    --trusted-public-key "$ROOT/arch/provenance/dev.ed25519.public_key.b64"

run_step "x07-wasm deploy plan crewops_release" \
  run_json \
    "$REPORT_DIR/deploy.plan.crewops_release.json" \
    "$X07_WASM_BIN" deploy plan \
    --pack-manifest "$PACK_RELEASE_DIR/app.pack.json" \
    --ops "$ROOT/arch/app/ops/ops_release.json" \
    --out-dir "$DEPLOY_RELEASE_DIR"

run_step "x07-wasm slo eval crewops_canary_ok" \
  run_json \
    "$REPORT_DIR/slo.eval.crewops_canary_ok.json" \
    "$X07_WASM_BIN" slo eval \
    --profile "$ROOT/arch/slo/slo_min.json" \
    --metrics "$ROOT/tests/fixtures/metrics/crewops_canary_ok.json"

require_path "$DEPLOY_RELEASE_DIR/deploy.plan.json" "crewops_release deploy plan"

run_platform_smoke

run_desktop_smoke
package_mobile_target \
  "device_ios_dev" \
  "ios" \
  "$IOS_BUNDLE_DIR" \
  "$IOS_PACKAGE_DIR" \
  "ios_project" \
  "ios_project/X07DeviceApp/x07"
package_mobile_target \
  "device_android_dev" \
  "android" \
  "$ANDROID_BUNDLE_DIR" \
  "$ANDROID_PACKAGE_DIR" \
  "android_project" \
  "android_project/app/src/main/assets/x07"

if [ "$FAILURES" -ne 0 ]; then
  note "crewops gate finished with $FAILURES failure(s)"
  exit 1
fi

if [ -f "$PLATFORM_TODO_REPORT" ]; then
  note "crewops gate finished with TODO marker: $PLATFORM_TODO_REPORT"
fi

note "check_all.sh: PASS"
