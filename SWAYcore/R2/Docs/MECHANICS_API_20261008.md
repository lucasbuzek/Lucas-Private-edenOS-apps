# SWAYcore Release Mechanics API — 2026-10-08

The UI must observe these services rather than create independent timers or infer product truth.

## Observable app services

### `SwayTimelineSession`

Published: `musicalTime`, `position` (`beat`, `count`, `bar`, `phrase`, `beatPhase`), `isPaused`, `isComplete`. Configuration: `bpm`, `plan`. Actions: `start(at:)`, `tick(at:)`, `pause(at:)`, `resume(at:)`, `restart(at:)`. The caller feeds monotonic system uptime from the audio/render callback. Completion is `totalCounts × secondsPerBeat`, never a one-second wall timer.

### `CalibrationSession`

Published: `stage`, `instruction`, `isReady`, `trackingLost`, `timedOut`, `lowImpact`, `lastEvents`. Actions: `ingest(_:)`, `retry()`, `skipJump()`, `geometryChanged()`, `restart()`, `cancel()`. `CameraPoseService` maps Vision into normalized `SwayBodyPose` and `SwayCalibrationFrame`; the UI never scores unless `isReady`.

### Existing native observable adapters

* `CameraPoseService`: `bodyPose`, `personTrackingState`, `scoringReady`, camera permission/status, optional 3D-derived avatar yaw where supported.
* `SwayMusicKitProvider`: authorization/playback state. Denial is an explicit state; generated beats remain the offline path.
* `SwayHealthWorkoutManager`: workout lifecycle and HealthKit authorization summary; actions request, start, pause/resume and finish.
* `SwayRecordingService`: ReplayKit recording/preview/save/share lifecycle and explicit permission/error states.
* `SwayStore`: profile, selected coach, moves, creations, results, settings and local persistence. Import is validate → preview (`pendingImport`) → commit.

## Pure `SWAYcoreEngine` APIs

* `SwayMusicalClock` + `SwayTimelinePlan`: the only time truth; deterministic pause/resume and timeline completion.
* `SwayTimelineMath`: time → beat/count/bar/phrase and tempo scaling (20 BPM floor).
* `SwayCalibrationMachine`: canonical six-action calibration, timeout/retry, jitter rejection, tracking loss/reacquisition and left/right correctness.
* `SwayPoseMapper`: Vision-name input → normalized SWAYHumanoid-v1 joints. Missing evidence remains missing.
* `SwayMatchTruth`: evidence-aware match classification. Product wording maps `.good`/`.partial` to **MATCH**, `.notMatched` to **NOT MATCHED**, and every `.unknown(reason)` to **UNKNOWN**.
* `SwayWorkoutEngine`: WATCH → COPY → MATCH → COMBO → SCORE → UNLOCK → DANCE reducer; count truth, combo, score, NEXT, pause/resume/restart/end. UNKNOWN is excluded from average and does not change combo. Ended Early is persisted but is not a completion.
* `SwayAuthoredLibrary`: 26 executable move definitions (the protected 20 plus six ported cases), instructions/counts, named workouts and difficulty filtering.
* `SwayGeneratedBeatEngine`: deterministic offline Pop/Latin/Hip Hop/EDM/Tropical beat events with tempo and intensity. `SwayMusicProviding` normalizes provider authorization/offline capability. Shazam supplies alignment evidence only and never owns time.
* `SwayPack`: versioned validate/encode/decode format for export, import, edit and re-share. `SwayMoveParameters` contains tempo/range/arm style/intensity.
* `SwayLocalStore`: atomic JSON writes, last-known-good recovery and additive decode migration; no network dependency.
* `SwayProgressMath`: completed count, weekly activity and streak; `SwaySessionRecord` retains Completed/Ended Early, time, moves and active calories.
* `SwayCharacterRegistry`: metadata for Lucia, Nandi, Thabo, Zuri, Kyle and YOUR DANCER. Task 3 should adapt `SwayCharacterIdentifier.rawValue` to frozen `SWAYCharacterID` without changing the avatar contract.

## Diagnostics

Consumer navigation should include developer views only when `SwayDiagnostics.isEnabled` is true (`-SWAYDiagnostics` launch argument). Task 3 owns the navigation wiring.

## Platform evidence boundary

Pure logic is Linux-tested. Camera/Vision, iOS 17+ 3D pose yaw, MusicKit authorization/playback, Shazam, ReplayKit/AVFoundation/Photos/share and HealthKit read/write require Lucas's physical iPhone run and remain **UNKNOWN**, not PASS.
