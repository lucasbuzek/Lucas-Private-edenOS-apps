#!/usr/bin/env python3
"""Typecheck the complete SWAY application module against the iOS SDK.

This is deliberately a compile-only gate: it proves that every checked-in app
source participates in one coherent module, but makes no build or playback
claim.  Keeping a hand-extracted renderer fragment here previously allowed its
real dependencies (Move.swift, NativeCapabilities.swift, and their transitive
dependencies) to drift without this check noticing.
"""
import hashlib
import json
import pathlib
import subprocess
import tempfile

root = pathlib.Path(__file__).resolve().parents[2]
app_root = root / "App/SWAY"
app_sources = sorted(app_root.rglob("*.swift"))
engine_sources = sorted((root / "Packages/SWAYcoreEngine/Sources/SWAYcoreEngine").glob("*.swift"))
if not app_sources:
    raise SystemExit("no SWAY application Swift sources found")

sdk = subprocess.check_output(["xcrun", "--sdk", "iphoneos", "--show-sdk-path"], text=True).strip()
with tempfile.TemporaryDirectory(prefix="sway-app-sdk-") as directory:
    temporary = pathlib.Path(directory)
    options = [
        "-target", "arm64-apple-ios26.0",
        "-sdk", sdk,
        "-module-cache-path", str(temporary / "cache"),
    ]
    subprocess.run([
        "xcrun", "swiftc", "-emit-module", "-module-name", "SWAYcoreEngine",
        *options, *map(str, engine_sources),
        "-emit-module-path", str(temporary / "SWAYcoreEngine.swiftmodule"),
    ], check=True)
    subprocess.run([
        "xcrun", "swiftc", "-typecheck", "-module-name", "SWAY",
        *options, "-I", str(temporary), *map(str, app_sources),
    ], check=True)

digest = hashlib.sha256()
for source in app_sources:
    digest.update(source.relative_to(root).as_posix().encode())
    digest.update(b"\0")
    digest.update(source.read_bytes())
print(json.dumps({
    "status": "FULL_APP_SDK_TYPECHECK_PASS",
    "sdk": sdk,
    "sourceCount": len(app_sources),
    "sourcesSHA256": digest.hexdigest(),
    "appBuild": "UNKNOWN",
    "simulatorRun": "UNKNOWN",
    "physicalDevice": "UNKNOWN",
}))
