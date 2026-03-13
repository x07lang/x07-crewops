#!/usr/bin/env node

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";

function resolveTarget(inputPath) {
  const absPath = path.resolve(inputPath);
  const stat = fs.statSync(absPath);
  if (stat.isDirectory()) {
    const frontendHost = path.join(absPath, "frontend", "app-host.mjs");
    if (fs.existsSync(frontendHost)) {
      return {
        bundlePath: path.join(absPath, "app.bundle.json"),
        hostPath: frontendHost,
      };
    }
    const directHost = path.join(absPath, "app-host.mjs");
    if (fs.existsSync(directHost)) {
      return {
        bundlePath: path.join(absPath, "app.bundle.json"),
        hostPath: directHost,
      };
    }
    throw new Error(`could not find app-host.mjs under ${absPath}`);
  }
  const hostPath = absPath;
  const bundlePath = path.join(path.dirname(path.dirname(hostPath)), "app.bundle.json");
  return { bundlePath, hostPath };
}

function patchHost(hostPath) {
  const source = fs.readFileSync(hostPath, "utf8");
  if (source.includes('  "style",')) {
    return false;
  }
  const needle = '  "strong",\n  "table",';
  if (!source.includes(needle)) {
    throw new Error(`could not locate tag allowlist insertion point in ${hostPath}`);
  }
  const nextSource = source.replace(needle, '  "strong",\n  "style",\n  "table",');
  fs.writeFileSync(hostPath, nextSource);
  return true;
}

function sha256Hex(buffer) {
  return crypto.createHash("sha256").update(buffer).digest("hex");
}

function syncBundleManifest(bundlePath, hostPath) {
  if (!fs.existsSync(bundlePath)) {
    return false;
  }
  const bundleJson = JSON.parse(fs.readFileSync(bundlePath, "utf8"));
  const hostBytes = fs.readFileSync(hostPath);
  const hostRelPath = path.relative(path.dirname(bundlePath), hostPath).replaceAll(path.sep, "/");
  const frontendArtifacts = bundleJson?.frontend?.artifacts;
  if (!Array.isArray(frontendArtifacts)) {
    throw new Error(`frontend.artifacts missing in ${bundlePath}`);
  }
  const artifact = frontendArtifacts.find((entry) => entry && entry.path === hostRelPath);
  if (!artifact) {
    throw new Error(`could not find artifact ${hostRelPath} in ${bundlePath}`);
  }
  const nextBytesLen = hostBytes.length;
  const nextSha256 = sha256Hex(hostBytes);
  const changed = artifact.bytes_len !== nextBytesLen || artifact.sha256 !== nextSha256;
  artifact.bytes_len = nextBytesLen;
  artifact.sha256 = nextSha256;
  if (changed) {
    fs.writeFileSync(bundlePath, `${JSON.stringify(bundleJson, null, 2)}\n`);
  }
  return changed;
}

const inputs = process.argv.slice(2);
if (inputs.length === 0) {
  console.error("usage: postprocess_app_host.mjs <build-dir-or-app-host-path> [...]");
  process.exit(1);
}

for (const inputPath of inputs) {
  const { bundlePath, hostPath } = resolveTarget(inputPath);
  const changed = patchHost(hostPath);
  const manifestChanged = syncBundleManifest(bundlePath, hostPath);
  console.log(
    `${changed ? "patched" : "unchanged"} ${hostPath}${
      manifestChanged ? ` (updated ${bundlePath})` : ""
    }`,
  );
}
