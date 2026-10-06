#!/bin/sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
required="README.txt MASTER.txt RULESET_MANIFEST.txt docs/QUICKSTART.txt docs/INSTRUCTIONS.txt docs/CHANGELOG.txt docs/RECOVERY.txt manifests/eden.manifest.yaml manifests/RegistryContribution.json manifests/AppReleaseRecord.json contracts/templates/EDC.template.yaml contracts/templates/IAC.template.yaml"
for f in $required; do
  [ -f "$ROOT/$f" ] || { echo "FAIL missing: $f"; exit 1; }
done
echo "PASS: EITRIMB package structure verified. Runtime/LCAS integration remains UNKNOWN until target-environment verification."
