#!/bin/zsh
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
export HOMEBREW_NO_AUTO_UPDATE=1
HERE="${0:A:h}"
CANON="$HOME/Downloads/edenOS"
VERSION="3.7.1"
[[ "$(id -u)" -ne 0 ]] || { print "ERROR: Do not run with sudo."; exit 10; }
print "edenOS M1–M3 v$VERSION — Test Pipeline"
print "CHECK EXISTING -> VERIFY -> UPDATE -> STATIC TEST -> TOOLS -> BUILD -> RUNTIME GATE"
if [[ "$HERE" != "$CANON" ]]; then
  "$HERE/APPLY_UPDATE.command"
fi
cd "$CANON"
./TEST_PACKAGE.command
./CHECK_LOCAL_TOOLS.command
print "PASS pre-build validation. Starting ARM64 build/runtime gate..."
./BUILD_EDENOS.command
