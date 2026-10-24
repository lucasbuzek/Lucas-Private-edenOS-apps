#!/bin/bash
# SWAYcore one-click builder: SWAYcore Dance & Fitness
# Double-click in Finder, or run from Terminal. Safe to re-run (idempotent; preserves Last Known Good before replacing outputs).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd -P)"
# shellcheck source=Scripts/lib.sh
source "$HERE/Scripts/lib.sh" || { echo "FAIL: cannot load Scripts/lib.sh"; exit 2; }
sway_init "$HERE"
build_product "DanceFitness" DanceFitness SWAYcoreDanceFitness yes "iphoneos" com.lucasbuzek.private.swaycore.danceandfitness SWAYcoreKit
rc=$([ "${SWAY_FAILS:-0}" -eq 0 ] && echo 0 || echo 1)
if [ -t 0 ] && [ -z "$SWAY_NONINTERACTIVE" ]; then read -r -p "Press Return to close…" _; fi
exit $rc
