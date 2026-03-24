# Deploy CrewOps with x07-platform (OSS)

This guide walks through building a sealed CrewOps release pack and deploying it through **x07-platform** to:

- a **local** target (`__local__`)
- a **self-hosted wasmCloud** target (`oss-wasmcloud`) using the reference Docker Compose stack

Scope: **`x07-platform` OSS only** (no `x07-platform-cloud` / hosted control-plane).

## 0) Prerequisites

Install the X07 toolchain:

```bash
curl -fsSL https://x07lang.org/install.sh | sh -s -- --yes --channel stable
```

Explanation: installs the `x07` toolchain manager (`x07up`) plus the `x07` CLI.

Add the required components:

```bash
x07up update
x07up component add wasm
x07up component add device-host
```

Explanation: `wasm` provides `x07-wasm` (build/pack/verify/deploy-plan), and `device-host` provides `x07-device-host-desktop` for the desktop smoke flow.

You also need:

- `python3` (JSON extraction + small helpers)
- `node` + `npx` (CrewOps post-processing + optional UI screenshots)
- `docker` + `docker compose` (wasmCloud reference target)

## 1) Expected repo layout

This guide assumes sibling repos:

```text
workspace/
  x07-crewops/
  x07-platform/
```

Explanation: commands below reference both repos by relative path.

## 2) Build a CrewOps release pack + deploy plan

From the workspace root, define a few variables:

```bash
cd /path/to/workspace
export CREWOPS_ROOT="$PWD/x07-crewops"
export PLATFORM_ROOT="$PWD/x07-platform"
```

Explanation: keeps later commands copy/paste-safe.

Create the standard CrewOps build output directories:

```bash
mkdir -p "$CREWOPS_ROOT/build/crewops_gate/reports" "$CREWOPS_ROOT/dist/crewops_gate"
```

Explanation: `build/` holds reports + CI artifacts; `dist/` holds app bundles/packs.

Generate deterministic demo seed data:

```bash
cd "$CREWOPS_ROOT"
./scripts/ci/seed_demo.sh
```

Explanation: CrewOps is seed-driven; the build/test artifacts depend on these generated fixtures.

Build the CrewOps **release** app bundle:

```bash
x07-wasm app build \
  --index arch/app/index.x07app.json \
  --profile crewops_release \
  --out-dir dist/crewops_gate/app.crewops_release \
  --clean \
  --strict
```

Explanation: compiles the X07 reducer + backend into a web-servable app directory with a bundle manifest.

Patch the generated app host (used by desktop/mobile hosts):

```bash
node scripts/postprocess_app_host.mjs dist/crewops_gate/app.crewops_release
```

Explanation: updates the embedded app host wiring so desktop/mobile targets can load the same reducer deterministically.

Package the sealed **app pack** (the artifact x07-platform admits):

```bash
x07-wasm app pack \
  --bundle-manifest dist/crewops_gate/app.crewops_release/app.bundle.json \
  --profile-id crewops_release \
  --out-dir dist/crewops_gate/pack.crewops_release
```

Explanation: creates `dist/crewops_gate/pack.crewops_release/app.pack.json` plus the content-addressed pack payload.

Verify the pack is self-consistent:

```bash
x07-wasm app verify \
  --pack-manifest dist/crewops_gate/pack.crewops_release/app.pack.json
```

Explanation: checks digests and required files in the pack directory.

Create and verify a provenance attestation (optional, but recommended):

```bash
x07-wasm provenance attest \
  --pack-manifest dist/crewops_gate/pack.crewops_release/app.pack.json \
  --ops arch/app/ops/ops_release.json \
  --signing-key arch/provenance/dev.ed25519.signing_key.b64 \
  --out dist/crewops_gate/pack.crewops_release/app.provenance.dsse.json
```

Explanation: signs the release pack with the demo signing key and produces a DSSE envelope.

```bash
x07-wasm provenance verify \
  --attestation dist/crewops_gate/pack.crewops_release/app.provenance.dsse.json \
  --pack-dir dist/crewops_gate/pack.crewops_release \
  --trusted-public-key arch/provenance/dev.ed25519.public_key.b64
```

Explanation: verifies the attestation matches the pack contents.

Generate the deploy plan used by x07-platform:

```bash
x07-wasm deploy plan \
  --pack-manifest dist/crewops_gate/pack.crewops_release/app.pack.json \
  --ops arch/app/ops/ops_release.json \
  --out-dir dist/crewops_gate/deploy.crewops_release
```

Explanation: produces `dist/crewops_gate/deploy.crewops_release/deploy.plan.json`.

Seed canary metrics fixtures (used by the platform’s SLO gate in local demo runs):

```bash
mkdir -p build/crewops_gate/platform_metrics
for n in 1 2 3; do
  cp tests/fixtures/metrics/crewops_canary_ok.json "build/crewops_gate/platform_metrics/analysis.${n}.json"
done
```

Explanation: the platform’s demo rollout gate reads `analysis.N.json` files as if they were incoming telemetry.

## 3) Deploy CrewOps locally through x07-platform (`__local__`)

Define a local platform state directory:

```bash
cd "$PLATFORM_ROOT"
export LP="$PLATFORM_ROOT/scripts/x07lp-driver"
export STATE_DIR="$PLATFORM_ROOT/_tmp/crewops_local_state"
mkdir -p "$STATE_DIR"
```

Explanation: `STATE_DIR` is the local control-plane state store; it holds accepted packs, executions, incidents, and query indexes.

Accept (admit) the pack:

```bash
$LP accept \
  --target __local__ \
  --pack-dir "$CREWOPS_ROOT/dist/crewops_gate/pack.crewops_release" \
  --pack-manifest app.pack.json \
  --change "$PLATFORM_ROOT/spec/fixtures/phaseA/change_request.min.json" \
  --state-dir "$STATE_DIR" \
  --json >"$STATE_DIR/accept.json"
```

Explanation: writes the admitted artifact and returns a new deployment execution id.

Extract the deployment id:

```bash
DEPLOY_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[\"result\"][\"exec_id\"])' "$STATE_DIR/accept.json")"
echo "$DEPLOY_ID"
```

Explanation: later `run` and `query` commands need the execution id.

Run the deploy plan:

```bash
$LP run \
  --target __local__ \
  --deployment-id "$DEPLOY_ID" \
  --plan "$CREWOPS_ROOT/dist/crewops_gate/deploy.crewops_release/deploy.plan.json" \
  --metrics-dir "$CREWOPS_ROOT/build/crewops_gate/platform_metrics" \
  --state-dir "$STATE_DIR" \
  --json
```

Explanation: executes the rollout locally (candidate → promote/rollback) using the provided metrics fixtures.

Query the finished deployment:

```bash
$LP query \
  --target __local__ \
  --deployment-id "$DEPLOY_ID" \
  --view full \
  --state-dir "$STATE_DIR" \
  --json
```

Explanation: prints the full deploy record (steps, decisions, artifacts, incidents).

Optional: serve the Command Center UI:

```bash
$LP ui-serve --state-dir "$STATE_DIR" --addr 127.0.0.1:17090
```

Explanation: opens a web UI on `http://127.0.0.1:17090` to browse apps, deployments, and incidents.

## 4) Deploy CrewOps to a self-hosted wasmCloud target (`oss-wasmcloud`)

Start the reference wasmCloud stack:

```bash
cd "$PLATFORM_ROOT"
./examples/targets/wasmcloud/scripts/gen-dev-cert.sh
X07LP_DEV_CERT_DIR="$PLATFORM_ROOT/examples/targets/wasmcloud/certs/out" \
  docker compose -f examples/targets/wasmcloud/docker-compose.yml up -d
```

Explanation: brings up wasmCloud + NATS + an OCI registry + a gateway with a dev TLS certificate chain.

Create an isolated local x07lp config directory (recommended):

```bash
export RUN_DIR="$PLATFORM_ROOT/_tmp/crewops_wasmcloud_run"
export X07LP_CONFIG_DIR="$RUN_DIR/x07lp-config"
mkdir -p "$RUN_DIR/secrets"
```

Explanation: keeps targets/tokens out of your global `~/.config/x07lp`.

Write local auth files:

```bash
printf 'x07lp-oss-dev-token\n' >"$RUN_DIR/secrets/oss-wasmcloud.token"
printf 'x07lp-oci-dev-user\n' >"$RUN_DIR/secrets/oci.username"
printf 'x07lp-oci-dev-pass\n' >"$RUN_DIR/secrets/oci.password"
```

Explanation: the reference stack uses these fixed dev credentials.

Materialize the target profile from the example template:

```bash
python3 - <<'PY'
from pathlib import Path
import json

platform = Path.cwd()
run_dir = platform / "_tmp" / "crewops_wasmcloud_run"
home_profile = json.loads((platform / "examples/targets/wasmcloud/target.example.json").read_text(encoding="utf-8"))
home_profile["auth"]["token_ref"] = f"file://{run_dir}/secrets/oss-wasmcloud.token"
home_profile["tls"]["ca_bundle_path"] = str(platform / "examples/targets/wasmcloud/certs/out/dev-ca.pem")
home_profile["oci_auth"]["username_ref"] = f"file://{run_dir}/secrets/oci.username"
home_profile["oci_auth"]["password_ref"] = f"file://{run_dir}/secrets/oci.password"
home_profile["oci_tls"]["ca_bundle_path"] = str(platform / "examples/targets/wasmcloud/certs/out/dev-ca.pem")
run_dir.mkdir(parents=True, exist_ok=True)
(run_dir / "oss-wasmcloud.target.json").write_text(json.dumps(home_profile, indent=2) + "\n", encoding="utf-8")
print(run_dir / "oss-wasmcloud.target.json")
PY
```

Explanation: wires your local token/password files into the target profile via `file://` references.

Onboard and select the target:

```bash
$LP target-add --profile "$RUN_DIR/oss-wasmcloud.target.json" --json
$LP target-use --name oss-wasmcloud --json
```

Explanation: `target-add` persists the profile into `$X07LP_CONFIG_DIR`, and `target-use` makes it the active default.

Accept the CrewOps pack remotely:

```bash
$LP accept \
  --target oss-wasmcloud \
  --pack-manifest "$CREWOPS_ROOT/dist/crewops_gate/pack.crewops_release/app.pack.json" \
  --change "$PLATFORM_ROOT/spec/fixtures/phaseA/change_request.min.json" \
  --json >"$RUN_DIR/remote.accept.json"
```

Explanation: uploads the pack to the target registry / adapter boundary and returns a remote run id.

Extract the remote run id:

```bash
REMOTE_RUN_ID="$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); r=d.get(\"result\",{}); print(r.get(\"run_id\") or r.get(\"pipeline_run_id\") or \"\")' "$RUN_DIR/remote.accept.json")"
echo "$REMOTE_RUN_ID"
```

Explanation: the remote lane uses an accepted run id instead of a local state-dir exec id.

Execute the remote deploy:

```bash
$LP run \
  --target oss-wasmcloud \
  --accepted-run "$REMOTE_RUN_ID" \
  --json >"$RUN_DIR/remote.run.json"
```

Explanation: tells the target to execute the rollout and returns the remote deployment id.

Extract the remote deployment id:

```bash
REMOTE_DEPLOY_ID="$(python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); r=d.get(\"result\",{}); print(r.get(\"deployment_id\") or r.get(\"exec_id\") or \"\")' "$RUN_DIR/remote.run.json")"
echo "$REMOTE_DEPLOY_ID"
```

Explanation: used for query and incident listing.

Query and inspect:

```bash
$LP query --target oss-wasmcloud --deployment "$REMOTE_DEPLOY_ID" --view full --json
$LP incident-list --target oss-wasmcloud --deployment "$REMOTE_DEPLOY_ID" --json
```

Explanation: `query` returns the full remote rollout record; `incident-list` shows any captured incidents for that deployment.

Optional: capture docker logs for evidence:

```bash
docker compose -f "$PLATFORM_ROOT/examples/targets/wasmcloud/docker-compose.yml" logs --no-color >"$RUN_DIR/wasmcloud-stack.log"
```

Explanation: useful when debugging target onboarding, OCI auth, TLS, or runtime issues.

Cleanup:

```bash
$LP target-remove --name oss-wasmcloud --json
docker compose -f "$PLATFORM_ROOT/examples/targets/wasmcloud/docker-compose.yml" down -v
```

Explanation: removes the target from local config and tears down the reference stack.

## 5) One-command alternative (recommended)

If you want the full end-to-end gate (build + traces + pack + platform smoke + device packaging), run:

```bash
cd "$CREWOPS_ROOT"
./scripts/ci/check_all.sh
```

Explanation: this is the canonical CrewOps release gate; it exercises the x07-platform local deploy flow as part of the pipeline.

