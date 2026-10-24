#!/bin/bash
# SWAYcore one-click entry point: SWAYcore VERIFY ALL (portable static tier + every macOS non-device gate)
# Double-click, or run from Terminal. Safe to re-run: idempotent, installs only missing declared tools, never deletes user data.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd -P)"
. "$HERE/Scripts/factory_lib.sh" || { echo "FAIL: cannot load Scripts/factory_lib.sh"; exit 2; }
fx_init "$HERE"

fx_gate "portable verification (static + executable Python/shell suites)" python3 "$FX_ROOT/Tools/verify_all.py" "$FX_ROOT"
if is_mac; then
  fx_gate "preflight: xcode" pf_xcode
  fx_gate "preflight: xcodegen" pf_xcodegen
  fx_gate "test: SWAYcoreEngine (swift test)" swift_test SWAYcoreEngine
  fx_gate "xcode: generate project (deterministic from project.yml)" gen_project
  fx_gate "build: simulator candidate (compile)" build_sim
  SIM="$(sim_name)"
  if [ -n "$SIM" ]; then fx_gate "environment: app tests on simulator '$SIM'" test_sim "$SIM"; else fx_unknown "environment: simulator tests" "no iPhone simulator runtime installed"; fi
else
  fx_unknown "macOS gates (swift test / xcodegen / xcodebuild)" "host is $(uname -s); run VERIFY_ALL.command on the Mac"
fi
fx_unknown "physical-device gates" "never executed by VERIFY_ALL; see Docs/PHYSICAL_DEVICE_CHECKLIST.md"
fx_finish "VERIFY_ALL complete. See per-gate states above; UNKNOWN != PASS."

fx_exit
