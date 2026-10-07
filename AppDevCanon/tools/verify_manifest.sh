#!/bin/sh
# Verify AppDevCanon/reconciled against MANIFEST.sha256
cd "$(dirname "$0")/../reconciled" || exit 2
if command -v sha256sum >/dev/null 2>&1; then CHK="sha256sum -c"; else CHK="shasum -a 256 -c"; fi
$CHK MANIFEST.sha256 --quiet && echo "MANIFEST VERIFIED: $(wc -l < MANIFEST.sha256 | tr -d ' ') files"
