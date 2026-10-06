#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
python3 "$ROOT/tests/integration-preflight.py" "$ROOT"
for f in shell/index.html shell/eden.css shell/eden.js platform/app-registry.json platform/profiles.json platform/provider-model.json platform/user-environment.json platform/ux-principles.json docs/DP07_V17_INTEGRATED_EXPERIENCE.txt; do test -s "$ROOT/$f"; done
echo "PASS static package preflight"
