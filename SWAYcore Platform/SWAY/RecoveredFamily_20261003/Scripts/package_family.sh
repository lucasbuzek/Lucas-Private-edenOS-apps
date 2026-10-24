#!/bin/bash
# Reproducible archive of the source tree (+ assets) with inventory, hashes and build manifest. mode: core|family
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"; MODE="${1:-family}"; cd "$ROOT"
VERSION="$(cat VERSION)"; OUT="$ROOT/Build/Output/Dist"; mkdir -p "$OUT"
NAME="SWAYcore-$MODE-$VERSION"
STAGE="$(mktemp -d)/$NAME"; mkdir -p "$STAGE"
INCLUDE="Docs Packages Blender Scripts Config Tests Apps VERSION README.md .gitignore Build_SWAYcore_Core.command"
[ "$MODE" = family ] && INCLUDE="$INCLUDE Build_SWAYcore_ALL.command Build_SWAYcore_DanceFitness.command Build_SWAYcore_SWAYZ.command Build_SWAYcore_KidDancers.command Build_SWAYcore_StudioManagement.command"
[ -d Assets ] && INCLUDE="$INCLUDE Assets"
for p in $INCLUDE; do [ -e "$p" ] && tar -cf - --exclude '.build' --exclude '*.xcodeproj' --exclude 'DerivedData' --exclude '.DS_Store' --exclude 'Signing.local.xcconfig' "$p" | tar -xf - -C "$STAGE" ; done
# Build manifest + inventory (sorted, with sha256) inside the archive
( cd "$STAGE" && find . -type f ! -name BUILD_MANIFEST.json ! -name INVENTORY.sha256 | LC_ALL=C sort | while read -r f; do printf '%s  %s\n' "$( (shasum -a 256 "$f" 2>/dev/null || sha256sum "$f") | cut -d' ' -f1)" "$f"; done > INVENTORY.sha256 )
python3 - "$STAGE" "$VERSION" "$MODE" <<'PY'
import json,sys,hashlib,os,datetime
stage,ver,mode=sys.argv[1:4]
inv=open(os.path.join(stage,"INVENTORY.sha256")).read().splitlines()
tree=hashlib.sha256("\n".join(inv).encode()).hexdigest()
json.dump({"name":"SWAYcore","mode":mode,"version":ver,"inventoryCount":len(inv),"treeSha256":tree,
 "states":{"source":"IMPLEMENTED","swiftCompile":"UNKNOWN until builder BUILD PASS","blenderAssets":"UNKNOWN until builder generates+validates","visualQuality":"UNKNOWN","physical":"UNKNOWN"},
 "note":"Archive built reproducibly: sorted entries, fixed mtimes. States here are NOT evidence of build/test success; see Build/report."},
 open(os.path.join(stage,"BUILD_MANIFEST.json"),"w"),indent=2,sort_keys=True)
PY
find "$STAGE" -exec touch -t 202601010000 {} +
ZIP="$OUT/$NAME.zip"; rm -f "$ZIP"
( cd "$(dirname "$STAGE")" && find "$NAME" -type f | LC_ALL=C sort | zip -X -q "$ZIP" -@ )
# Verify integrity + inventory
unzip -tq "$ZIP"
COUNT_ZIP="$(unzip -Z1 "$ZIP" | grep -vc '/$' || true)"; COUNT_STAGE="$(find "$STAGE" -type f | wc -l | tr -d ' ')"
[ "$COUNT_ZIP" = "$COUNT_STAGE" ] || { echo "inventory mismatch zip=$COUNT_ZIP stage=$COUNT_STAGE"; exit 1; }
for c in Build_SWAYcore_Core.command; do unzip -Z "$ZIP" "$NAME/$c" | grep -q '^-rwx' || { echo "exec bit lost on $c"; exit 1; }; done
(shasum -a 256 "$ZIP" 2>/dev/null || sha256sum "$ZIP") | tee "$ZIP.sha256"
echo "archive OK: $ZIP ($COUNT_ZIP files)"
