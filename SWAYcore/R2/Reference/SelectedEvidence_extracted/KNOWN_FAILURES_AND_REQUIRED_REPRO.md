# Known failures / mandatory reproduction

These are evidence targets, not assumed current failures. Reproduce against CurrentCandidate before modifying code.

1. SWAYcoreKit historical compile failure: `TrackingTests.swift` line 71 used `T.obs(Self.n, t: tt)` inside `func stand(_ t: Double)`; `tt` was undefined. If present, first preserve a failing compile log, correct to the intended parameter only after inspecting surrounding test helpers, then rerun the complete SWAYcoreKit test target.
2. Family-package historical Studio test failure: `testMembershipLifecycle` failed an `XCTAssertTrue`. StudioManagement is OUT OF CURRENT DELIVERY SCOPE except where shared SWAYcore changes affect it. Do not spend current milestone time rebuilding the Studio app.
3. Xcode physical-device preparation incident: Xcode 27 / Swift 6.4 environment repeatedly consumed large disk while DeviceSupport/dyld shared-cache extraction remained incomplete, with `.tmp`/`.copying_lock` evidence. Root cause UNKNOWN. Diagnose before cleanup; do not recursively purge unrelated Xcode data.
4. Build153 physically built/installed/launched as a stepping stone, but avatar quality was rejected. Never treat its visual acceptance as PASS.
5. Earlier regressions reported across historical builds included static/cutout characters, broken/unchanged menu paths, insufficient coach differentiation, music/analysis regressions and missing camera-tracking affordance. Use LKG and authority to characterize these before replacing code.

Required response to every reproduced failure: STAGE / ACTION / RESULT / ERROR / IMPACT / NEXT ACTION, then continue safe diagnostics/repair.
