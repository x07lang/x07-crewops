# CrewOps Mobile Build

This repo packages the current CrewOps reducer for desktop, iOS, and Android from the same [`frontend/x07.json`](../frontend/x07.json) project. The frontend dependency baseline is `std-web-ui@0.2.0`.

## Prereqs

Released toolchain:

```sh
x07up component add wasm
```

Workspace fallback:

```sh
PATH="/Users/webik/projects/x07lang/x07/target/debug:/Users/webik/projects/x07lang/x07-wasm-backend/target/debug:$PATH"
```

## Reducer-Only Build

From the repo root:

```sh
mkdir -p build/reports

x07-wasm web-ui profile validate --index arch/web_ui/index.x07webui.json --profile web_ui_debug --json --report-out build/reports/web_ui.profile.validate.json --quiet-json
x07-wasm web-ui build --project frontend/x07.json --index arch/web_ui/index.x07webui.json --profile web_ui_debug --out-dir dist/web_ui/web_ui_debug --clean --json --report-out build/reports/web_ui.build.debug.json --quiet-json
```

## Device Build And Package

Current device profile ids from [`arch/device/index.x07device.json`](../arch/device/index.x07device.json):

- `device_desktop_dev`
- `device_ios_dev`
- `device_android_dev`

Desktop smoke:

```sh
x07-wasm device build --index arch/device/index.x07device.json --profile device_desktop_dev --out-dir dist/device/device_desktop_dev --clean --json --report-out build/reports/device.build.desktop.json --quiet-json
x07-wasm device verify --dir dist/device/device_desktop_dev --json --report-out build/reports/device.verify.desktop.json --quiet-json
x07-wasm device run --bundle dist/device/device_desktop_dev --target desktop --headless-smoke --json --report-out build/reports/device.run.desktop.json --quiet-json
```

iOS package:

```sh
x07-wasm device build --index arch/device/index.x07device.json --profile device_ios_dev --out-dir dist/device/device_ios_dev --clean --json --report-out build/reports/device.build.ios.json --quiet-json
x07-wasm device verify --dir dist/device/device_ios_dev --json --report-out build/reports/device.verify.ios.json --quiet-json
x07-wasm device package --bundle dist/device/device_ios_dev --target ios --out-dir dist/device_package/device_ios_dev --json --report-out build/reports/device.package.ios.json --quiet-json
```

Android package:

```sh
x07-wasm device build --index arch/device/index.x07device.json --profile device_android_dev --out-dir dist/device/device_android_dev --clean --json --report-out build/reports/device.build.android.json --quiet-json
x07-wasm device verify --dir dist/device/device_android_dev --json --report-out build/reports/device.verify.android.json --quiet-json
x07-wasm device package --bundle dist/device/device_android_dev --target android --out-dir dist/device_package/device_android_dev --json --report-out build/reports/device.package.android.json --quiet-json
```

`x07-wasm device package` writes the packaged payload plus `package.manifest.json` under the `--out-dir` you choose.

## Current Network State

Current checked-in device dev profile behavior:

- `device_desktop_dev` points at `http://127.0.0.1:17081` and is the profile used by the desktop headless smoke in [`scripts/ci/check_all.sh`](../scripts/ci/check_all.sh).
- `device_ios_dev` and `device_android_dev` still point at `https://example.invalid` and must be edited before packaging for a real simulator or device.
- all device profiles keep dynamic code loading disabled.

Before pointing a package at a real backend:

1. Edit the relevant device profile.
2. Set `backend.base_url` and `backend.allowed_hosts`.
3. Keep `arch/device/profiles/device_dev.capabilities.json` aligned with the same host allowlist.
4. Rebuild and repackage.

## Script Notes

[`scripts/ci/seed_demo.sh`](../scripts/ci/seed_demo.sh) is the current data refresh script. [`scripts/ci/check_all.sh`](../scripts/ci/check_all.sh) is the canonical CrewOps gate, including desktop device smoke plus iOS/Android package generation. The only intentional TODO inside that script is the local `x07-platform` smoke probe when the platform runner is unavailable in the workspace.

Ship updated behavior by rebuilding and redistributing the bundle. Do not rely on runtime WASM replacement or dynamic code loading.
