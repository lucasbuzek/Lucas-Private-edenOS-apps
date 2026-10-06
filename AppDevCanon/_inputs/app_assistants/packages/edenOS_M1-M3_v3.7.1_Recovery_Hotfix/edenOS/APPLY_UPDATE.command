#!/bin/zsh
set -euo pipefail
# edenOS v3.7.1 transactional canonical-workspace updater.
# Existing solution first: uses macOS rsync when available, ditto otherwise.
HERE="${0:A:h}"
CANON="$HOME/Downloads/edenOS"
VERSION="3.7.1"
[[ "$(id -u)" -ne 0 ]] || { print "ERROR: Do not run with sudo."; exit 10; }

required=(shell platform apps tests BUILD_EDENOS.command TEST_PACKAGE.command INSTALL_EDENOS.command CLEANUP_EDENOS.command)
for x in $required; do [[ -e "$HERE/$x" ]] || { print "FAIL release payload incomplete: $x missing"; exit 11; }; done
[[ -f "$HERE/RELEASE_VERSION" ]] && [[ "$(<$HERE/RELEASE_VERSION)" == "$VERSION" ]] || { print "FAIL release identity mismatch"; exit 12; }

if [[ "$HERE" == "$CANON" ]]; then
  print "PASS edenOS v$VERSION is already at canonical workspace."
  "$CANON/TEST_PACKAGE.command"
  exit 0
fi

mkdir -p "$CANON"/{cache,builds,images,logs,data,config,releases}
STAGE="$CANON/.update-stage-$VERSION-$$"
BACKUP="$CANON/releases/pre-v${VERSION}-$(date +%Y%m%d-%H%M%S)"
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE" "$BACKUP"

# Release-managed roots. Persistent roots are intentionally absent.
managed=(shell platform apps bifrost heimdall workspaces demo docs tests reference BUILD_EDENOS.command TEST_PACKAGE.command CHECK_LOCAL_TOOLS.command REPAIR_WORKSPACE.command CLEANUP_EDENOS.command INSTALL_EDENOS.command APPLY_UPDATE.command RUN_TEST_PIPELINE.command MANIFEST.txt RELEASE_M1-M3.txt WORKSPACE.txt RELEASE_VERSION)

print "edenOS v$VERSION — Transactional Update"
print "Source: $HERE"
print "Target: $CANON"
print "Validating release before touching canonical workspace..."
"$HERE/TEST_PACKAGE.command"

# Stage complete managed payload first.
for name in $managed; do
  [[ -e "$HERE/$name" ]] || continue
  if command -v ditto >/dev/null 2>&1; then ditto "$HERE/$name" "$STAGE/$name"; else cp -a "$HERE/$name" "$STAGE/$name"; fi
done

# Backup only current managed material, then replace atomically per root.
for name in $managed; do
  [[ -e "$CANON/$name" ]] && mv "$CANON/$name" "$BACKUP/$name"
  [[ -e "$STAGE/$name" ]] && mv "$STAGE/$name" "$CANON/$name"
done
chmod +x "$CANON"/*.command(N) 2>/dev/null || true

print "Validating installed canonical workspace..."
if ! "$CANON/TEST_PACKAGE.command"; then
  print "FAIL canonical validation; restoring previous managed files..."
  for name in $managed; do rm -rf "$CANON/$name"; [[ -e "$BACKUP/$name" ]] && mv "$BACKUP/$name" "$CANON/$name"; done
  exit 13
fi
print "PASS edenOS v$VERSION installed coherently."
print "PASS persistent cache/images/data/config/logs/builds/releases preserved."
print "Previous managed state: $BACKUP"
print "Next: $CANON/BUILD_EDENOS.command"
