#!/bin/zsh
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
export HOMEBREW_NO_AUTO_UPDATE=1
HERE="${0:A:h}"
CANON="$HOME/Downloads/edenOS"
VERSION="3.7.1"
[[ "$(id -u)" -ne 0 ]] || { print "ERROR: Do not run with sudo."; exit 10; }
print "edenOS M1–M3 v$VERSION — Install / Build"
print "Policy: CHECK EXISTING -> VERIFY -> INTEGRATE -> ADAPT -> BUILD -> TEST"
if [[ "$HERE" != "$CANON" ]]; then
  print "Applying release to canonical workspace first..."
  "$HERE/APPLY_UPDATE.command"
fi
cd "$CANON"
[[ -f RELEASE_VERSION && "$(<RELEASE_VERSION)" == "$VERSION" ]] || { print "FAIL stale/incomplete canonical release"; exit 20; }
./TEST_PACKAGE.command
./CHECK_LOCAL_TOOLS.command
./BUILD_EDENOS.command
