# Claude findings 2026-10-06 (isolated copy: _claude_work/R2_copy; live R2 untouched)
- xcodegen generate: OK
- xcodebuild SWAY, iphonesimulator, CODE_SIGNING_ALLOWED=NO: BUILD SUCCEEDED, 0 errors (log: R2_copy/Build/logs/xcodebuild_sim.log)
- swift test SWAYcoreEngine: 31 tests, 0 failures
- StateMacro failure in Codex log = nested sandbox (sandbox-exec "Operation not permitted", DARWIN_USER_TEMP_DIR confstr failed). Environment, not source. Run builds from a normal shell.
- NOT run: app XCTest on simulator, Blender (Metal crash exit 139), device. Those remain UNKNOWN/FAIL as in Codex continuity report.
- No source changes were needed or made.
- App XCTest on simulator (iPhone 15 Pro Max Regression sim): launched, simulator booted, test runner never started; xcodebuild stalled 9+ min with no test output, killed by me. UNKNOWN (not PASS/FAIL).
