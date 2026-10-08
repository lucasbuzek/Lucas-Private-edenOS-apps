# RELEASE TASK 3 RECEIPT — FINAL COMPLETE UI

Date: 2026-10-08
Branch: `swaycore-release-ui-20261008`

## What changed

- Replaced consumer root navigation with HOME · MOVES · BEATS · PROFILE and removed developer tools from visible navigation.
- Added the shared dark/hot-pink design system, adaptive cards, chips, buttons, stats, stages and accessibility sizing.
- Implemented the 12 board screens plus calibration, tracking-lost, profile, avatar creator, coach choice, recording/share, permission, empty and onboarding states.
- Routed every character appearance through `SWAYCharacterStage` and every creator choice through available `SWAYAvatarCatalog` options.
- Added thin view models and a Task 2 service adapter without moving business logic into views.
- Added a complete screen inventory and a selectable three-device preview gallery.

## Acceptance evidence

| Acceptance item | State | Evidence |
|---|---|---|
| Inventory board → view → state → navigation | IMPLEMENTED | `Docs/ui_screens/README.md` |
| iPhone/iPad portrait/iPad landscape previews | IMPLEMENTED | `SWAYReleasePreviews.swift` preview gallery |
| Preview PNGs and board comparison | UNKNOWN | Linux host has no Xcode/Simulator; exact Mac commands recorded in the evidence README |
| No consumer debug routes; controls wired | IMPLEMENTED | diagnostics require seven taps in Settings; navigation actions mutate state, navigate, save, share, or open Settings |
| Swift compile | UNKNOWN | Xcode/iOS SDK unavailable on this host |
| Regression | 7 non-Xcode gates PASS; 4 FAIL; 2 UNKNOWN | Linux run report `Build/report/BUILD_REPORT-20261008-044438.md`: build identity fixture missing; three Apple SDK/XCTest gates lack `xcrun`/`xcode-select`; visual and physical evidence UNKNOWN |

## CROSS-TASK REQUESTS

1. **Task 2 — workout session facade:** provide an observable `WorkoutSession` API exposing planned moves, current index, musical time, tracking visibility, pause/resume/restart/end, and completed/ended-early result. `SWAYWorkoutViewModel` is the local UI adapter meanwhile.
2. **Task 2 — progress facade:** provide persisted weekly activity, current streak, active calories, and recent workout completion state. The release UI currently presents deterministic sample values where the base store has no field.
3. **Task 2 — permission facade:** provide status/request/open-settings APIs for Camera, Health, Music, Motion, Microphone and Photos so all permission rows reflect live status.
4. **Task 2 — recording facade:** provide preview URL, save-to-library, and share payload APIs for Record SWAY. The UI/share sheet is ready but capture/save buttons require that service.
5. **Task 1 — avatar catalogue:** populate real available options and meaningful `displayName` values. The creator intentionally filters `available == false` rather than faking art.

## Exact next steps

1. On the Mac, run XcodeGen and the simulator build command from `Docs/ui_screens/README.md`.
2. Open `SWAYReleasePreviews.swift`; capture every screen on all three canvases and commit strict PNGs to `Docs/ui_screens/`.
3. Compare captures beside the final board at 100%, fix only Task 3 UI findings, then rerun regression.
4. Integrate Task 2 facades through `Views/ViewModels/Adapters` without changing service ownership.
