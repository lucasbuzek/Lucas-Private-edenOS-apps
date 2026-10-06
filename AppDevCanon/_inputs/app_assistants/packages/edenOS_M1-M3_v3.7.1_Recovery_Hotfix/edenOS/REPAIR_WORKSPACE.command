#!/bin/zsh
set -euo pipefail
ROOT="$HOME/Downloads/edenOS"
[[ "$(id -u)" -ne 0 ]] || { print "ERROR: Run this normally, not with sudo. It will request elevation only for the repair step."; exit 2; }
print "edenOS Workspace Ownership Repair"
print "Target: $ROOT"
mkdir -p "$ROOT"
print "This repairs ownership only inside the canonical edenOS workspace."
print "macOS may request your login password."
sudo chown -R "$USER":staff "$ROOT"
chmod -R u+rwX "$ROOT"
mkdir -p "$ROOT"/{cache/alpine,source,build,images,releases,logs,config,tools}
# Only disposable staging is cleaned. Cache, images, releases and logs are preserved.
rm -rf "$ROOT/build/m1m3-apkovl"
print "PASS workspace owner: $(stat -f '%Su:%Sg' "$ROOT")"
print "PASS logs writable: $(test -w "$ROOT/logs" && echo YES || echo NO)"
print "PASS build writable: $(test -w "$ROOT/build" && echo YES || echo NO)"
print "Repair complete. Now run BUILD_EDENOS.command normally (without sudo)."
