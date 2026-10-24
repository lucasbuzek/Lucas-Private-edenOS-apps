#!/bin/bash
# SWAYcore one-click builder: SWAYcore Engine/Core (tests + production character assets)
# Double-click in Finder, or run from Terminal. Safe to re-run (idempotent; preserves Last Known Good before replacing outputs).
HERE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd -P)"
# shellcheck source=Scripts/lib.sh
source "$HERE/Scripts/lib.sh" || { echo "FAIL: cannot load Scripts/lib.sh"; exit 2; }
sway_init "$HERE"
require_gate "preflight: host" preflight_host
require_gate "preflight: xcode" preflight_xcode
require_gate "preflight: xcodegen" preflight_xcodegen
require_gate "static: repository verification" python3 "$SWAY_ROOT/Scripts/verify_static.py" "$SWAY_ROOT"
preserve_lkg "Core"
require_gate "test: SWAYcoreKit (swift test, macOS host)" swift_test_pkg SWAYcoreKit
require_gate "test: SWAYStudioKit (swift test, macOS host)" swift_test_pkg SWAYStudioKit
require_gate "build: SWAYAppKit for iOS (shared services/character runtime)" bash -c "cd '$SWAY_ROOT/Packages/SWAYAppKit' && xcodebuild -scheme SWAYAppKit -destination 'generic/platform=iOS' -derivedDataPath '$SWAY_BUILD/DerivedData/AppKit' CODE_SIGNING_ALLOWED=NO build"
build_assets
require_gate "package: Core source+assets archive" bash "$SWAY_ROOT/Scripts/package_family.sh" core
if [ "$SWAY_FAILS" -eq 0 ]; then mkdir -p "$SWAY_OUT/Core"; touch "$SWAY_OUT/Core/.verified"; fi
finish_report "Core: tests/assets/package gates complete. Visual character quality and physical acceptance remain UNKNOWN."
rc=$([ "${SWAY_FAILS:-0}" -eq 0 ] && echo 0 || echo 1)
if [ -t 0 ] && [ -z "$SWAY_NONINTERACTIVE" ]; then read -r -p "Press Return to close…" _; fi
exit $rc
