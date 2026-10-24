#!/bin/bash
# Product regression receipts. Never packages or promotes an LKG.
ROOT="$(cd "$(dirname "$0")" && pwd -P)"
cd "$ROOT" || exit 2
source Scripts/factory_lib.sh
fx_init "$ROOT"
CACHE="$FX_BUILD/cache/regression"
mkdir -p "$CACHE"
export CLANG_MODULE_CACHE_PATH="$CACHE/clang" SWIFTPM_MODULECACHE_OVERRIDE="$CACHE/clang"
fx_gate "app deterministic function contracts" python3 App/Tests/run_contract_tests.py
fx_gate "asset complete suite including labelled fixtures" python3 -m unittest discover -s AssetFactory/tests -v
fx_gate "protected and builder contracts" python3 -m unittest discover -s Tools/regression -p 'test_*.py' -v
fx_gate "DeviceSupport guard scenarios" bash Tools/regression/test_devicesupport_guard.sh
fx_gate "historical avatar contract boundary" python3 Tools/regression/check_avatar_contract.py
fx_gate "actual RealityKit renderer iOS SDK typecheck" python3 Tools/regression/check_avatar_sdk.py
fx_gate "actual shared Swift pose versus Blender bake port" python3 Tools/regression/check_coach_pose_port.py
fx_gate "ReplayKit callback iOS SDK typecheck" python3 Tools/regression/check_replaykit_sdk.py
fx_gate "actual product model lifecycle" python3 Tools/regression/run_model_lifecycle.py
fx_gate "Swift core behavioural regression" swift test --package-path Packages/SWAYcoreEngine --scratch-path "$CACHE/swift"
fx_gate "actual core XCTest through installed compiler (separate from SwiftPM packaging)" python3 Tools/regression/run_core_xctest.py
fx_unknown "Lucia and integrated app visual regression" "native Blender numerical evidence exists; rendered readability, RealityKit and human review remain unpassed"
fx_unknown "physical Alpha" "requires observed iPhone 15 Pro Max journey; simulator is not physical evidence"
fx_finish "R2 regression receipts only. UNKNOWN is not PASS."
fx_exit
