#!/bin/bash
# SWAYcore one-click entry point: SWAYcore Dance & Fitness (generate project, test, build simulator + device candidate, package)
# Double-click, or run from Terminal. Safe to re-run: idempotent, installs only missing declared tools, never deletes user data.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd -P)"
. "$HERE/Scripts/factory_lib.sh" || { echo "FAIL: cannot load Scripts/factory_lib.sh"; exit 2; }
fx_init "$HERE"

fx_need "preflight: host" pf_host
fx_need "preflight: disk >= 15 GB" pf_disk 15 "Xcode build"
fx_need "preflight: xcode / swift / SDKs" pf_xcode
fx_need "preflight: xcodegen (install only if missing)" pf_xcodegen
fx_gate "static: portable verification" python3 "$FX_ROOT/Tools/verify_all.py" "$FX_ROOT"
fx_preserve_recovery "DanceFitness" "$FX_OUT/DanceFitness"                        # previous packaged outputs preserved before anything is replaced
echo "$(cd "$FX_ROOT/App" && find SWAY project.yml -type f -print0 | sort -z | xargs -0 shasum -a 256 | shasum -a 256)" > "$FX_REPORT/app-source.sha256"
fx_gate "test: SWAYcoreEngine (swift test)" swift_test SWAYcoreEngine
fx_need "xcode: generate project from project.yml" gen_project
fx_need "build: simulator candidate" build_sim
SIMAPP="$FX_BUILD/DerivedData/sim/Build/Products/Debug-iphonesimulator/SWAY.app"
fx_gate "package: simulator candidate" package_zip "DanceFitness-simulator" "$SIMAPP" && fx_gate "verify package: simulator candidate (zip CRC, plist, sha256)" verify_zip "DanceFitness-simulator"
SIM="$(sim_name)"
if [ -n "$SIM" ]; then fx_gate "environment: app tests on simulator '$SIM'" test_sim "$SIM"; else fx_unknown "environment: simulator tests" "no iPhone simulator runtime installed"; fi
# ----- physical gate: only when every non-physical gate above is done -----
DEV="$(xcrun devicectl list devices 2>/dev/null | grep -E 'iPhone|iPad' | grep -Ei 'connected|available' | head -1)"
if [ "$FX_FAILS" -ne 0 ]; then fx_unknown "physical gate" "skipped: earlier gates failed; fix those first"
elif [ -z "$DEV" ]; then
  echo ""; echo "======== PHYSICAL GATE IS NEXT ========"; echo "Connect and unlock the iPhone. Keep it connected. No other action is required."
  fx_unknown "physical: device present" "no connected iPhone/iPad detected"
else
  if fx_gate "physical: DeviceSupport safety (disk, locks, incomplete extraction, growth)" devicesupport_gate; then
    if fx_gate "physical: device candidate build (signing from project.yml)" build_device; then
      DEVAPP="$FX_BUILD/DerivedData/device/Build/Products/Debug-iphoneos/SWAY.app"
      fx_gate "package: device candidate" package_zip "DanceFitness-device" "$DEVAPP" && fx_gate "verify package: device candidate" verify_zip "DanceFitness-device"
      ID="$(echo "$DEV" | awk '{for(i=1;i<=NF;i++) if ($i ~ /^[0-9A-Fa-f-]{36}$/) {print $i; exit}}')"
      fx_gate "physical: INSTALLED only (installed != functional)" xcrun devicectl device install app --device "$ID" "$DEVAPP"
      fx_gate "physical: LAUNCHED only (launched != accepted)" xcrun devicectl device process launch --device "$ID" com.lucasbuzek.private.sway
      fx_unknown "physical: acceptance" "walk Docs/PHYSICAL_DEVICE_CHECKLIST.md on iPhone and iPad (portrait+landscape); simulator never proves camera/Vision/MusicKit/HealthKit/recording/thermal"
    fi
  else fx_unknown "physical: device preparation" "stopped safely by DeviceSupport guard; no data deleted; read the diagnostics in the gate log"; fi
fi
fx_finish "DANCE & FITNESS: BUILT/PACKAGED states are exactly the PASS rows above. Physical acceptance is UNKNOWN until performed."

fx_exit
