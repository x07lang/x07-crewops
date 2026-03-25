#!/usr/bin/env bash
# Packages the SvelteKit build output into device bundles for desktop, iOS, and Android.
#
# Usage:
#   ./scripts/device-package.sh [--target desktop|ios|android|all]
#
# Prerequisites:
#   - npm run build (SvelteKit static output in web/build/)
#   - x07-wasm device build (produces device bundle with reducer.wasm + profile)
#
# What it does:
#   1. Runs x07-wasm device build to get reducer.wasm + profile metadata
#   2. Runs x07-wasm device package to generate native project templates
#   3. Replaces the generated VDOM host assets with SvelteKit build output
#   4. Copies the WASM binary into the SvelteKit asset tree

set -euo pipefail

WEB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(cd "$WEB_DIR/.." && pwd)"
BUILD_DIR="$WEB_DIR/build"
DIST_DIR="$ROOT/dist/sveltekit_device"

TARGET="${1:---target}"
if [ "$TARGET" = "--target" ]; then
  TARGET="${2:-all}"
fi

X07_WASM_BIN="${X07_WASM_BIN:-x07-wasm}"

note() { echo "  → $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

# Verify SvelteKit build exists
[ -f "$BUILD_DIR/index.html" ] || die "SvelteKit build not found. Run: cd web && npm run build"
[ -f "$BUILD_DIR/app.wasm" ] || die "app.wasm not in build/. Check static/ directory."

# Inject SvelteKit output into a device package's x07/ directory
inject_sveltekit() {
  local x07_dir="$1"
  local bundle_dir="$2"

  note "Clearing old host assets from $x07_dir"
  # Remove old VDOM host files but keep profile/, bundle.manifest.json, and ui/
  rm -f "$x07_dir/index.html" \
        "$x07_dir/bootstrap.js" \
        "$x07_dir/app-host.mjs" \
        "$x07_dir/main.mjs" \
        "$x07_dir/app.manifest.json"

  note "Copying SvelteKit build output"
  # Copy all SvelteKit files
  cp "$BUILD_DIR/index.html" "$x07_dir/"
  cp -r "$BUILD_DIR/_app" "$x07_dir/"
  cp "$BUILD_DIR/app.manifest.json" "$x07_dir/"

  # Keep ui/reducer.wasm in place for the device host runtime,
  # AND provide app.wasm for SvelteKit's bridge (which fetches /app.wasm)
  if [ -f "$bundle_dir/ui/reducer.wasm" ]; then
    mkdir -p "$x07_dir/ui"
    cp "$bundle_dir/ui/reducer.wasm" "$x07_dir/ui/reducer.wasm"
    cp "$bundle_dir/ui/reducer.wasm" "$x07_dir/app.wasm"
    note "Copied reducer.wasm to both ui/reducer.wasm and app.wasm"
  elif [ -f "$x07_dir/ui/reducer.wasm" ]; then
    cp "$x07_dir/ui/reducer.wasm" "$x07_dir/app.wasm"
    note "Copied existing ui/reducer.wasm as app.wasm"
  else
    cp "$BUILD_DIR/app.wasm" "$x07_dir/app.wasm"
    note "Copied app.wasm from SvelteKit static"
  fi

  # Preserve profile/ and bundle.manifest.json (already in place from device package)
  note "Injected SvelteKit into $x07_dir"
}

# Build device bundle
build_bundle() {
  local profile_id="$1"
  local bundle_dir="$2"

  note "Building device bundle: $profile_id"
  "$X07_WASM_BIN" device build \
    --index "$ROOT/arch/device/index.x07device.json" \
    --profile "$profile_id" \
    --out-dir "$bundle_dir" \
    --clean \
    --json --quiet-json --report-out "$DIST_DIR/reports/device.build.${profile_id}.json"
}

# Package for a mobile target
package_target() {
  local profile_id="$1"
  local target="$2"
  local bundle_dir="$3"
  local package_dir="$4"

  note "Packaging: $profile_id → $target"
  "$X07_WASM_BIN" device package \
    --bundle "$bundle_dir" \
    --target "$target" \
    --out-dir "$package_dir"
}

mkdir -p "$DIST_DIR/reports"

# Desktop
# The x07-device-host-desktop binary embeds its own app-host.mjs VDOM renderer
# and does NOT load our index.html. For desktop, we serve the SvelteKit build
# as a static site alongside the WASM backend and open in the default browser.
if [ "$TARGET" = "desktop" ] || [ "$TARGET" = "all" ]; then
  echo ""
  echo "=== Desktop ==="
  DESKTOP_OUT="$DIST_DIR/desktop"

  rm -rf "$DESKTOP_OUT"
  mkdir -p "$DESKTOP_OUT"

  # Copy the full SvelteKit build output
  cp -r "$BUILD_DIR/." "$DESKTOP_OUT/"

  note "Desktop ready: $DESKTOP_OUT"
  note "  Serve:"
  note "    1. Start backend: x07-wasm serve --component releases/web/backend/app.http.component.wasm --mode listen --addr 127.0.0.1:17081 --stop-after 0 --max-response-bytes 16777216"
  note "    2. Serve SvelteKit: npx serve $DESKTOP_OUT -l 17080 --single"
  note "    3. Open: http://127.0.0.1:17080"
fi

# iOS
if [ "$TARGET" = "ios" ] || [ "$TARGET" = "all" ]; then
  echo ""
  echo "=== iOS ==="
  IOS_BUNDLE="$DIST_DIR/ios_bundle"
  IOS_PACKAGE="$DIST_DIR/ios_package"

  build_bundle "device_ios_dev" "$IOS_BUNDLE"
  package_target "device_ios_dev" "ios" "$IOS_BUNDLE" "$IOS_PACKAGE"

  X07_DIR="$IOS_PACKAGE/ios_project/X07DeviceApp/x07"
  [ -d "$X07_DIR" ] || die "iOS x07/ directory not found at $X07_DIR"
  inject_sveltekit "$X07_DIR" "$IOS_BUNDLE"

  note "iOS ready: $IOS_PACKAGE/ios_project/"
  note "  Build: cd $IOS_PACKAGE/ios_project && xcodebuild -scheme X07DeviceApp"
fi

# Android
if [ "$TARGET" = "android" ] || [ "$TARGET" = "all" ]; then
  echo ""
  echo "=== Android ==="
  ANDROID_BUNDLE="$DIST_DIR/android_bundle"
  ANDROID_PACKAGE="$DIST_DIR/android_package"

  build_bundle "device_android_dev" "$ANDROID_BUNDLE"
  package_target "device_android_dev" "android" "$ANDROID_BUNDLE" "$ANDROID_PACKAGE"

  X07_DIR="$ANDROID_PACKAGE/android_project/app/src/main/assets/x07"
  [ -d "$X07_DIR" ] || die "Android x07/ directory not found at $X07_DIR"
  inject_sveltekit "$X07_DIR" "$ANDROID_BUNDLE"

  note "Android ready: $ANDROID_PACKAGE/android_project/"
  note "  Build: cd $ANDROID_PACKAGE/android_project && ./gradlew build"
fi

echo ""
echo "Done. Device packages with SvelteKit UI are in: $DIST_DIR"
