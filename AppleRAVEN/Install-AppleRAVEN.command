#!/bin/bash
# Lean, reversible candidate staging. Runs no background services.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
PYTHON="$(command -v python3 || true)"
if [ -z "$PYTHON" ] || ! "$PYTHON" -c 'import sys; assert sys.version_info >= (3,10)' >/dev/null 2>&1; then
  echo 'Python 3.10+ is required'; exit 2
fi
TARGET="$HOME/Library/Application Support/AppleRAVEN/candidate-0.1.0"
if [ -e "$TARGET" ]; then echo "Existing candidate preserved; refusing overwrite: $TARGET"; exit 3; fi
mkdir -p "$(dirname "$TARGET")"
STAGE="$(mktemp -d "$(dirname "$TARGET")/.candidate.XXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/appleraven"
cp "$HERE"/appleraven/*.py "$STAGE/appleraven/"
cp "$HERE/README.md" "$STAGE/README.md"
"$PYTHON" -m compileall -q "$STAGE/appleraven"
mv -n "$STAGE" "$TARGET"
trap - EXIT
CONFIG="$HOME/.config/appleraven/config.json"
if [ ! -e "$CONFIG" ]; then PYTHONPATH="$TARGET" "$PYTHON" -m appleraven.server --init-config; fi
printf 'AppleRAVEN candidate staged; not started or authorized: %s\n' "$TARGET"
printf 'Use /bin/bash with Run-AppleRAVEN.command from your retained source folder, or register Python with PYTHONPATH=%s\n' "$TARGET"
