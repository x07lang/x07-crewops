# x07-crewops

Cross-target field-service demo app for X07.

CrewOps is a showcase application that proves one X07 codebase can power a serious browser, desktop, and mobile product without rewriting the UI for each platform. It is a demo, not a production product.

## What This Repo Proves

- one reducer can drive web, desktop, iOS, and Android builds
- UI behavior can stay deterministic and replayable
- a realistic line-of-business app can move through the broader X07 release and lifecycle toolchain

## What’s In The Demo

- shared frontend reducer and deterministic backend
- field-service flows for technicians, dispatchers, supervisors, managers, portal users, and enterprise admins
- traces, incidents, and regression fixtures
- app, web-ui, device, provenance, and release profiles

## Quick Start

Install the X07 toolchain and WASM component, then from the repo root:

```sh
./scripts/ci/seed_demo.sh
x07 pkg lock --project frontend/x07.json
x07 check --project frontend/x07.json
x07 check --project backend/x07.json
x07 test --manifest frontend/tests/tests.json
x07 test --manifest backend/tests/tests.json
x07-wasm app build --index arch/app/ops/index.x07ops.json --profile crewops_dev --out-dir dist/app/crewops_dev --clean
x07-wasm app serve --dir dist/app/crewops_dev
```

## Device Packaging

Desktop:

```sh
x07-wasm device build --index arch/device/index.x07device.json --profile device_desktop_dev --out-dir dist/device/device_desktop_dev --clean
x07-wasm device verify --dir dist/device/device_desktop_dev
x07-wasm device run --bundle dist/device/device_desktop_dev --target desktop --headless-smoke
```

Mobile packaging uses the matching iOS and Android device profiles in `arch/device/`.

## How It Fits The X07 Ecosystem

- [`x07`](https://github.com/x07lang/x07) provides the language and core toolchain
- [`x07-web-ui`](https://github.com/x07lang/x07-web-ui) provides the reducer-side UI contracts
- [`x07-wasm-backend`](https://github.com/x07lang/x07-wasm-backend) builds the app and device bundles
- [`x07-device-host`](https://github.com/x07lang/x07-device-host) runs the same reducer on desktop and mobile
- [`x07-platform`](https://github.com/x07lang/x07-platform) provides the lifecycle and release side once the app moves beyond a local demo

## Docs

- [`docs/`](docs/)
- [`docs/DEPLOY_WITH_X07_PLATFORM.md`](docs/DEPLOY_WITH_X07_PLATFORM.md)
- [`scripts/ci/check_all.sh`](scripts/ci/check_all.sh)

## License

Dual-licensed under [Apache 2.0](LICENSE-APACHE) and [MIT](LICENSE-MIT).
