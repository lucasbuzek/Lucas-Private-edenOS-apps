#!/bin/zsh
set -euo pipefail
HERE="${0:A:h}"
ROOT="$HERE"
"$HERE/tests/static-preflight.sh"
[[ -f "$HERE/RELEASE_VERSION" ]] || { print "FAIL RELEASE_VERSION missing"; exit 20; }
[[ "$(<"$HERE/RELEASE_VERSION")" == "3.7.1" ]] || { print "FAIL wrong release version"; exit 21; }
for req in shell platform apps tests; do [[ -d "$HERE/$req" ]] || { print "FAIL required managed directory missing: $req"; exit 22; }; done
grep -q "edenOS M1–M3 v\$VERSION" "$HERE/INSTALL_EDENOS.command" || { print "FAIL stale installer identity"; exit 23; }
print "PASS v3.7.1 release identity + required payload"

zsh -n "$HERE/BUILD_EDENOS.command"
zsh -n "$HERE/CHECK_LOCAL_TOOLS.command"
zsh -n "$HERE/APPLY_UPDATE.command"
zsh -n "$HERE/CLEANUP_EDENOS.command"
zsh -n "$HERE/RUN_TEST_PIPELINE.command"
[[ -f "$HERE/docs/EXISTING_SOLUTION_CHECK_v3.7.txt" ]] || { print "FAIL existing-solution audit missing"; exit 9; }
print "PASS existing-solution audit"
print "PASS zsh syntax"
print "NOTE: ARM64 VM boot/graphics cannot be truthfully marked PASS until run on Apple Silicon."

python3 "$HERE/tests/v18-lock-preflight.py"
