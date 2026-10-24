#!/bin/bash
# SWAYcore one-click entry point: SWAYcore BUILD ALL (assets -> engine -> Dance & Fitness -> verify)
# Double-click, or run from Terminal. Safe to re-run: idempotent, installs only missing declared tools, never deletes user data.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd -P)"
. "$HERE/Scripts/factory_lib.sh" || { echo "FAIL: cannot load Scripts/factory_lib.sh"; exit 2; }
fx_init "$HERE"

export FX_NONINTERACTIVE=1; overall=0; summary=""
for step in BUILD_ASSETS BUILD_SWAYCORE_ENGINE BUILD_DANCE_FITNESS VERIFY_ALL; do
  echo ""; echo "################ $step ################"
  if bash "$HERE/$step.command"; then summary="$summary\n  no failed gates   $step"; else summary="$summary\n  FAILED GATE(S)    $step"; overall=1; fi
done
echo ""; echo "======== BUILD_ALL SUMMARY ========"; printf "$summary\n"
echo "Open Build/report/LATEST_BUILD_REPORT.md and the per-step reports. UNKNOWN rows (visual quality, physical device) are NOT passes."
FX_FAILS=$overall; fx_finish "BUILD_ALL finished (exit $overall)"; unset FX_NONINTERACTIVE

fx_exit
