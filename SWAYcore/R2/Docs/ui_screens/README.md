# SWAY final UI evidence

Authority: `Reference/ArtDirection/FINAL_UI_DIRECTION_SWAY_UI_TARGET_BUILD122.jpeg`.

## Screen inventory

| Board / implied screen | SwiftUI view | State / view model | Consumer entry |
|---|---|---|---|
| Home | `SWAYHomeScreen` | `SwayStore`, tab binding | HOME tab |
| Workout Setup | `SWAYWorkoutSetupScreen` | `SWAYWorkoutSetupViewModel` | Home DANCE |
| Workout | `SWAYWorkoutScreen` | `SWAYWorkoutViewModel` | Setup Start Workout |
| Workout Paused | `SWAYPauseOverlay` | `SWAYWorkoutViewModel.paused` | Workout pause control |
| End Workout? | confirmation dialog in `SWAYPauseOverlay` | `ending` | Paused End Workout |
| Workout Ended | `SWAYWorkoutEndedScreen` | result input | End confirmation |
| Great Job | `SWAYWorkoutEndedScreen(completed: true)` | result input | Completed workout |
| Moves | `SWAYMovesScreen` | `SWAYMoveLibraryViewModel`, `SwayStore` | MOVES tab |
| Learn Move | `SWAYLearnMoveScreen` | local step/repetition UI state | Move card |
| Create Move | `SWAYCreateMoveScreen` | local controls, `SwayStore` adapter | Moves add control |
| Beats | `SWAYBeatsScreen` | `SWAYBeatViewModel` | BEATS tab |
| Progress | `SWAYProgressScreen` | `SwayStore` | Home tile / Profile |
| Calibration | `SWAYCalibrationScreen` | ordered calibration step | Camera Tracking start |
| Tracking lost | `SWAYTrackingLostOverlay` | tracking visibility input | Workout stage overlay |
| Profile | `SWAYProfileScreen` | `SwayStore` | PROFILE tab |
| Your Dancer | `SWAYAvatarCreatorScreen` | `SWAYAvatarCatalog`, local profile | Profile Create / Edit |
| Coach choice | `SWAYCoachChoiceScreen` | `SwayStore` | Profile Coach |
| Record SWAY | `SWAYRecordPreviewScreen` | local share-sheet state | Profile Record SWAY |
| Permission denied | `SWAYPermissionDeniedView` | capability input | permission request failures |
| Empty state | `SWAYEmptyStateView` | title/message input | reusable consumer state |
| Onboarding | `SWAYOnboardingScreen` | first-launch state | root full-screen cover |
| Settings / Diagnostics | `SWAYSettingsScreen` | `SwayStore`, seven-tap unlock | gear / profile; labs hidden |

## Preview and comparison evidence

`SWAYReleasePreviewGallery` provides every inventory state with sample data and three canvases: iPhone 15 Pro Max portrait (430×932), iPad portrait (820×1180), and iPad landscape (1180×820). Choose the screen from the preview menu before capture.

PNG rendering is **UNKNOWN** in the Linux authoring environment because Xcode, iOS Simulator, and `xcrun` are unavailable. No fabricated render is committed. On a Mac, open `App/SWAY.xcodeproj`, select `SWAYReleasePreviews.swift`, choose each named canvas and use **Editor → Canvas → Pin Preview**, or run:

```bash
cd SWAYcore/R2/App
xcodegen generate
xcodebuild -project SWAY.xcodeproj -scheme SWAY -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro Max' CODE_SIGNING_ALLOWED=NO build
```

Capture each preview to this directory, then compare at 100% beside `Reference/ArtDirection/FINAL_UI_DIRECTION_SWAY_UI_TARGET_BUILD122.jpeg`. Required filenames are `<screen>_iphone.png`, `<screen>_ipad_portrait.png`, and `<screen>_ipad_landscape.png`.

## Visual comparison notes

The implementation follows the board's near-black ground, graphite cards, hot-pink primary actions, violet stage depth, rounded typography, large coach-first hierarchy, pill filters, two-column move library, compact stats, and four-item navigation canon. Device-rendered pixel comparison remains UNKNOWN until the Mac capture step above.
