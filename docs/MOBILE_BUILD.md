# CrewOps Mobile Build

CrewOps `v0.6.0` ships the same reducer across desktop, iOS, and Android. The frontend dependency baseline is `std-web-ui@0.2.5`, and the checked-in device profiles carry the `0.6.0` release version.

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

Current profile ids from [`arch/device/index.x07device.json`](../arch/device/index.x07device.json):

- `device_desktop_dev`
- `device_ios_dev`
- `device_android_dev`

Current packaging intent:

- desktop is the local smoke and operator demo profile
- iOS and Android package the same reducer for operations, finance, portal, enterprise admin, inventory, procurement, and connector-health routes
- all profiles keep dynamic code loading disabled

## Capability State

Desktop dev profile behavior:

- points at `http://127.0.0.1:17081`
- allows file import and blob storage
- enables local notifications
- keeps camera and foreground location disabled

Mobile dev profile behavior:

- `device_ios_dev` and `device_android_dev` still point at `https://example.invalid`
- both require a real backend `base_url` and `allowed_hosts` before simulator or device packaging
- mobile capabilities enable `camera.photo`, `files.pick`, `blob_store`, `location.foreground`, and `notifications.local`

## CI And Release Notes

[`scripts/ci/check_all.sh`](../scripts/ci/check_all.sh) remains the canonical CrewOps gate for the `v0.6.0` line, including trace replay, generated regressions, pack, verify, provenance, deploy-plan, desktop smoke, and mobile package generation.
