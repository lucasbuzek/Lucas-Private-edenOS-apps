#!/bin/bash
# Behavioural tests for devicesupport_guard.sh using a throw-away fake DeviceSupport tree. Runs on Linux or macOS.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"; source "$HERE/../../Scripts/devicesupport_guard.sh"
T="$(mktemp -d)"; fail=0; pass=0
ok()  { pass=$((pass+1)); echo "PASS: $1"; }
bad() { fail=$((fail+1)); echo "FAIL: $1"; }
# 1 missing folder is healthy
devicesupport_audit "$T/none" >/dev/null && ok "missing DeviceSupport folder is healthy" || bad "missing folder flagged"
# 2 complete entry is healthy
mkdir -p "$T/ok/iPhone 15 26.0 (23A1)/Symbols"; head -c 2000000 /dev/zero > "$T/ok/iPhone 15 26.0 (23A1)/Symbols/f"
devicesupport_audit "$T/ok" >/dev/null && ok "complete entry is healthy" || bad "complete entry flagged"
# 3 lock file is suspicious
mkdir -p "$T/lock/iPhone 15 26.0 (23A1)"; touch "$T/lock/iPhone 15 26.0 (23A1)/.copying_lock"
out="$(devicesupport_audit "$T/lock")"; rc=$?; [ $rc -eq 1 ] && echo "$out" | grep -q "LOCK present" && ok ".copying_lock detected" || bad ".copying_lock not detected"
# 4 incomplete entry (no Symbols, has data) is suspicious
mkdir -p "$T/inc/iPad 26.0 (23A1)"; head -c 3000000 /dev/zero > "$T/inc/iPad 26.0 (23A1)/partial.bin"
out="$(devicesupport_audit "$T/inc")"; rc=$?; [ $rc -eq 1 ] && echo "$out" | grep -q INCOMPLETE && ok "incomplete extraction detected" || bad "incomplete extraction not detected"
# 5 size sanity limit
SWAY_DEVICESUPPORT_MAX_MB=0 devicesupport_audit "$T/ok" >/dev/null; [ $? -eq 1 ] && ok "size sanity limit enforced" || bad "size limit not enforced"
# 6 growth watch trips on fast growth
mkdir -p "$T/grow"; ( for i in 1 2 3 4 5 6; do head -c 3000000 /dev/zero > "$T/grow/f$i"; sleep 0.4; done ) &
SWAY_DEVICESUPPORT_MAX_GROWTH_MB=2 devicesupport_growth_watch "$T/grow" 2 >/dev/null; [ $? -eq 1 ] && ok "runaway growth detected" || bad "runaway growth not detected"; wait
# 7 stable folder passes growth watch
devicesupport_growth_watch "$T/ok" 1 >/dev/null && ok "stable folder passes growth watch" || bad "stable folder flagged"
# 8 low-disk stop (impossible requirement)
require_free_gb "$T" 99999999 "test" >/dev/null; [ $? -eq 1 ] && ok "low free disk stops safely" || bad "low disk not detected"
require_free_gb "$T" 0 "test" >/dev/null && ok "sufficient disk passes" || bad "sufficient disk rejected"
# 9 nothing is ever deleted by the guard
[ -e "$T/lock/iPhone 15 26.0 (23A1)/.copying_lock" ] && [ -e "$T/inc/iPad 26.0 (23A1)/partial.bin" ] && ok "guard performed no deletion" || bad "guard deleted data"
# 10 gate returns failure and prints safe steps (no rm in guard source)
out="$(SWAY_ROOT="$T" SWAY_MIN_FREE_GB_DEVICE=0 devicesupport_gate "$T/lock" 2>&1)"; echo "$out" | grep -q "SAFE NEXT STEPS" && ok "gate prints safe recovery steps" || bad "gate silent on failure"
grep -nE '(^|[^#]*)\brm +-' "$HERE/../../Scripts/devicesupport_guard.sh" | grep -v '^[0-9]*:\s*#' | grep -v 'Do NOT' >/dev/null && bad "guard source contains rm" || ok "guard source contains no rm"
rm -rf "$T"; echo "devicesupport guard: $pass passed, $fail failed"; [ $fail -eq 0 ]
