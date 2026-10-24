# Release Task 9 Receipt — Final UI on the real SWAY app

Date: 2026-10-08
Branch/worktree: `work` (started at `476a1c0`, latest Task 9 brief descendant of the requested puppet-rig lineage)

## Scope delivered
U0–U10 were implemented as eleven ordered commits. The existing views, store/session bindings, navigation and product capabilities were retained. Character consumers touched by this UI task route through `SWAYCharacterStage`; YOUR DANCER uses `SWAYAvatarCatalog` only. Detailed per-screen before/after @APPLE decisions are in `Docs/UI_RESTYLE_LOG.md`.

## Evidence state
- Source implementation and static inventory: **IMPLEMENTED**.
- Deterministic/product Python and portable Swift gates: **TESTED / PASS** where shown below.
- Full iOS SDK module typecheck, ReplayKit SDK typecheck and XCTest: **BLOCKED by environment** (`xcrun`, `xcode-select`, Xcode and the iOS SDK are absent). These are not represented as PASS.
- Simulator build and screenshots: **BUILD UNKNOWN / VISUAL VERIFICATION UNKNOWN** because Xcode, Simulator and `simctl` are absent. No fake screenshots were created.
- Physical iPhone 15 Pro Max: **UNKNOWN**, as required by the evidence ladder.

## Regression gate lines
Run: `cd SWAYcore/R2 && ./RUN_R2_REGRESSION.command`

- `[PASS] app deterministic function contracts`
- `[PASS] asset complete suite including labelled fixtures (zero tests fails)`
- `[PASS] protected and builder contracts (zero tests fails)`
- `[PASS] DeviceSupport guard scenarios`
- `[PASS] historical avatar contract boundary`
- `[PASS] OSI dependency and provenance manifest`
- `[FAIL] complete SWAY app module iOS SDK typecheck` — `FileNotFoundError: xcrun`
- `[PASS] actual shared Swift pose versus Blender bake port`
- `[FAIL] ReplayKit callback iOS SDK typecheck` — `FileNotFoundError: xcrun`
- `[PASS] actual product model lifecycle`
- `[PASS] Swift core behavioural regression`
- `[FAIL] actual core XCTest through installed compiler` — `FileNotFoundError: xcode-select`
- `[UNKNOWN] Lucia and integrated app visual regression`
- `[UNKNOWN] physical Alpha`
- `RESULT: 3 FAILED GATE(S) | 2 UNKNOWN`

## Tools found and used
- Used: repository helpers (@APPLE workflow and @ARTEMIS ladder), `view_image` for both authoritative boards, Bash, Git, Python 3, ripgrep, Swift 6 toolchain, `swift-format`, regression scripts, pytest invoked by the regression runner, and GitHub CLI availability inspection.
- Found but not needed for asset creation: Node.js and `jq`.
- Not present: Xcode, `xcodebuild`, `xcrun`, `simctl`, SwiftLint, Pillow/ImageMagick. No UI art was generated or changed.

## CROSS-TASK REQUESTS
1. Run the complete iOS SDK typecheck and scheme `SWAY` simulator build on the integration Mac; repair only demonstrated compiler failures.
2. Capture every consumer screen at iPhone 15 Pro Max and small-iPhone sizes into `Docs/ui_screens/`, then perform human board comparison.
3. Run iPad portrait/landscape and physical iPhone accessibility journeys (Dynamic Type, VoiceOver, contrast and Reduce Motion).
4. Task 6/avatar owner should expand `SWAYAvatarCatalog` availability only when corresponding separated art is actually delivered; the creator intentionally does not fake unavailable options.
