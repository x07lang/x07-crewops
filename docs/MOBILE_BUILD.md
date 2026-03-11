# CrewOps Mobile Build

CrewOps `v0.3.0` packages the same M4 reducer and backend bundle for desktop, iOS, and Android. The frontend dependency baseline remains `std-web-ui@0.2.1`, while the checked-in device profiles are already versioned at `0.3.0`.

## Prereqs

Released toolchain:

```sh
x07up component add wasm
```

Workspace fallback:

```sh
PATH="/Users/webik/projects/x07lang/x07/target/debug:/Users/webik/projects/x07lang/x07-wasm-backend/target/debug:$PATH"
```

## Build And Package

From the repo root:

```sh
mkdir -p build/reports

x07-wasm web-ui profile validate --index arch/web_ui/index.x07webui.json --profile web_ui_debug --json --report-out build/reports/web_ui.profile.validate.json --quiet-json
x07-wasm web-ui build --project frontend/x07.json --index arch/web_ui/index.x07webui.json --profile web_ui_debug --out-dir dist/web_ui/web_ui_debug --clean --json --report-out build/reports/web_ui.build.debug.json --quiet-json

x07-wasm device build --index arch/device/index.x07device.json --profile device_desktop_dev --out-dir dist/device/device_desktop_dev --clean --json --report-out build/reports/device.build.desktop.json --quiet-json
x07-wasm device verify --dir dist/device/device_desktop_dev --json --report-out build/reports/device.verify.desktop.json --quiet-json
x07-wasm device run --bundle dist/device/device_desktop_dev --target desktop --headless-smoke --json --report-out build/reports/device.run.desktop.json --quiet-json

x07-wasm device build --index arch/device/index.x07device.json --profile device_ios_dev --out-dir dist/device/device_ios_dev --clean --json --report-out build/reports/device.build.ios.json --quiet-json
x07-wasm device verify --dir dist/device/device_ios_dev --json --report-out build/reports/device.verify.ios.json --quiet-json
x07-wasm device package --bundle dist/device/device_ios_dev --target ios --out-dir dist/device_package/device_ios_dev --json --report-out build/reports/device.package.ios.json --quiet-json

x07-wasm device build --index arch/device/index.x07device.json --profile device_android_dev --out-dir dist/device/device_android_dev --clean --json --report-out build/reports/device.build.android.json --quiet-json
x07-wasm device verify --dir dist/device/device_android_dev --json --report-out build/reports/device.verify.android.json --quiet-json
x07-wasm device package --bundle dist/device/device_android_dev --target android --out-dir dist/device_package/device_android_dev --json --report-out build/reports/device.package.android.json --quiet-json
```

## Device Profiles

Current device profile ids from [`arch/device/index.x07device.json`](../arch/device/index.x07device.json):

- `device_desktop_dev`
- `device_ios_dev`
- `device_android_dev`

Current M4 packaging intent:

- desktop is the local smoke and operator demo profile
- iOS and Android package the same reducer for technician, dispatcher, supervisor, manager, and activity surfaces
- all profiles keep dynamic code loading disabled

## Capability State

Desktop dev profile behavior:

- points at `http://127.0.0.1:17081`
- allows file import and blob storage
- enables local notifications for dispatch, review, and activity flows
- remains the profile used by desktop smoke in [`scripts/ci/check_all.sh`](../scripts/ci/check_all.sh)

Mobile dev profile behavior:

- `device_ios_dev` and `device_android_dev` still point at `https://example.invalid`
- both profiles require a real backend `base_url` and `allowed_hosts` before simulator or device packaging
- `arch/device/profiles/device_mobile_dev.capabilities.json` enables `camera.photo`, `files.pick`, `blob_store`, `location.foreground`, and `notifications.local`

Before pointing a mobile package at a real backend:

1. Edit the relevant device profile.
2. Set `backend.base_url` and `backend.allowed_hosts`.
3. Keep the referenced capabilities profile aligned with the same allowlist.
4. Rebuild and repackage.

## CI And Release Notes

[`scripts/ci/seed_demo.sh`](../scripts/ci/seed_demo.sh) remains the seed regeneration entrypoint. [`scripts/ci/check_all.sh`](../scripts/ci/check_all.sh) remains the canonical CrewOps build, replay, pack, verify, provenance, SLO, and device gate for the `v0.3.0` release line.

The only intentional workspace-local TODO is the optional `x07-platform` smoke probe. Ship updated behavior by rebuilding and redistributing the bundle. Do not rely on runtime WASM replacement or dynamic code loading.
