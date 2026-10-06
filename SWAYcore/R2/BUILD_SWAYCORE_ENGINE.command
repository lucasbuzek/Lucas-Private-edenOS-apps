#!/bin/bash
# SWAYcore one-click entry point: SWAYcore ENGINE (reusable core: tests + regression)
# Double-click, or run from Terminal. Safe to re-run: idempotent, installs only missing declared tools, never deletes user data.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd -P)"
. "$HERE/Scripts/factory_lib.sh" || { echo "FAIL: cannot load Scripts/factory_lib.sh"; exit 2; }
fx_init "$HERE"

fx_gate "preflight: host (macOS/arch)" pf_host
fx_gate "preflight: disk >= 5 GB" pf_disk 5 "engine build"
fx_gate "static: portable verification" python3 "$FX_ROOT/Tools/verify_all.py" "$FX_ROOT"
if is_mac; then
  fx_gate "preflight: xcode / swift / SDKs" pf_xcode
  fx_gate "test: SWAYcoreEngine (swift test)" swift_test SWAYcoreEngine
else
  fx_unknown "test: SWAYcoreEngine (swift test)" "not macOS: Swift toolchain unavailable; Python mirror scenarios ran in the static gate (corroboration only)"
fi
fx_finish "ENGINE: Swift engine tests are BUILT/TESTED only if the swift test gate above is PASS."

fx_exit
