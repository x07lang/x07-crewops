#!/usr/bin/env bash
set -euo pipefail

# Patch the x07-web-ui host TAG_ALLOWLIST to include <style> and semantic HTML5 tags.
# This is needed because std-web-ui@0.2.5 does not include these in its default allowlist,
# causing <style> tags in the VDOM to render as visible <div> text instead of being applied.
#
# Usage: ./scripts/ci/patch_host_allowlist.sh <app-dir>
# Example: ./scripts/ci/patch_host_allowlist.sh dist/app/crewops_dev

APP_DIR="${1:?usage: patch_host_allowlist.sh <app-dir>}"
HOST_FILE="$APP_DIR/frontend/app-host.mjs"
BUNDLE_FILE="$APP_DIR/app.bundle.json"

if [ ! -f "$HOST_FILE" ]; then
  echo "error: $HOST_FILE not found" >&2
  exit 1
fi

python3 -c "
import hashlib, json, sys

host_path = sys.argv[1]
bundle_path = sys.argv[2]

with open(host_path) as f:
    content = f.read()

old_end = '  \"ul\",\n]);'
new_end = '  \"ul\",\n  \"article\",\n  \"aside\",\n  \"footer\",\n  \"header\",\n  \"main\",\n  \"nav\",\n  \"section\",\n  \"style\",\n]);'

if old_end not in content:
    if '\"style\"' in content.split('TAG_ALLOWLIST')[1].split(']);')[0]:
        print('already patched')
        sys.exit(0)
    else:
        print('error: TAG_ALLOWLIST not found in expected format', file=sys.stderr)
        sys.exit(1)

content = content.replace(old_end, new_end)

with open(host_path, 'w') as f:
    f.write(content)

new_hash = hashlib.sha256(content.encode()).hexdigest()
new_size = len(content.encode())

with open(bundle_path) as f:
    bundle = json.load(f)

for artifact in bundle['frontend']['artifacts']:
    if artifact['path'] == 'frontend/app-host.mjs':
        artifact['sha256'] = new_hash
        artifact['bytes_len'] = new_size
        break

with open(bundle_path, 'w') as f:
    json.dump(bundle, f, indent=2)
    f.write('\n')

print(f'patched: {host_path} ({new_size} bytes)')
" "$HOST_FILE" "$BUNDLE_FILE"
