#!/bin/bash
# SWAYcore one-click builder: SWAYcore FAMILY (master)
# Double-click in Finder, or run from Terminal. Safe to re-run (idempotent; preserves Last Known Good before replacing outputs).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd -P)"
# shellcheck source=Scripts/lib.sh
source "$HERE/Scripts/lib.sh" || { echo "FAIL: cannot load Scripts/lib.sh"; exit 2; }
sway_init "$HERE"
say "Building the complete SWAYcore family. Core builds/validates assets first; products reuse validated assets."
export SWAY_NONINTERACTIVE=1
overall=0; summary=""
for b in Build_SWAYcore_Core Build_SWAYcore_DanceFitness Build_SWAYcore_SWAYZ Build_SWAYcore_KidDancers Build_SWAYcore_StudioManagement; do
  say ""; say "################ $b ################"
  if bash "$HERE/$b.command"; then summary="$summary\n  PASS(gates)  $b"; else summary="$summary\n  FAIL         $b"; overall=1; fi
done
say ""; say "════════ FAMILY SUMMARY ════════"; printf "$summary\n"
say "PASS(gates) means every executed gate passed; UNKNOWN gates (visual quality, physical device acceptance) are listed in each report under $SWAY_REPORT."
require_gate "package: full family distribution + build manifest" bash "$SWAY_ROOT/Scripts/package_family.sh" family
finish_report "Family build finished (exit $overall). Read Build/report/LATEST_BUILD_REPORT.md for exact evidence."
unset SWAY_NONINTERACTIVE
SWAY_FAILS=$overall
rc=$([ "${SWAY_FAILS:-0}" -eq 0 ] && echo 0 || echo 1)
if [ -t 0 ] && [ -z "$SWAY_NONINTERACTIVE" ]; then read -r -p "Press Return to close…" _; fi
exit $rc
