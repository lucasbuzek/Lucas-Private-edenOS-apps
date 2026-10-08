# Release Task 2 Receipt — Mechanics & Inner Workings — 2026-10-08

Branch: `swaycore-release-mechanics-20261008`

## Inspect-first evidence matrix

Status here reflects the base before this task's edits. `TESTED` means an automated assertion was discovered; platform/device claims are never inferred.

| Item | Base implementation | Base tests | Initial evidence |
|---|---|---|---|
| 1. Musical clock | Timeline math/service existed; WorkoutPlayer also accumulated `activeClock` once/second | time mapping tests, only a trivial pause assertion | IMPLEMENTED / partial TESTED; U-08 open |
| 2. Tracking/calibration | Build-147-derived mapper, full state machine, tracking-loss states | extensive Linux calibration left/right/jitter/loss tests | IMPLEMENTED / TESTED; physical UNKNOWN |
| 3. Workout session | app player/scoring/results existed | scoring truth tests; no pure lifecycle reducer | IMPLEMENTED / partial TESTED |
| 4. Content model/library | app `DanceMove`, creations, 26 move rows | lifecycle/static package checks | IMPLEMENTED / partial TESTED |
| 5. Learn | app Learn route used timeline/pose engine | timeline tests | IMPLEMENTED / partial TESTED |
| 6. Beats/music | generated audio, MusicKit and Shazam adapters existed | source/typecheck gates | IMPLEMENTED; device UNKNOWN |
| 7. Create Move/.swaypack | app authoring and v2 envelope existed | model lifecycle gate | IMPLEMENTED / partial TESTED |
| 8. Record SWAY | ReplayKit/Photos/share service existed | SDK callback typecheck | IMPLEMENTED; device UNKNOWN |
| 9. Results/progress | results, awards and progress UI data existed | model lifecycle gate | IMPLEMENTED / partial TESTED |
| 10. Profile/Health | compatible character profile, selected coach, HealthKit manager and entitlements existed | static/typecheck only | IMPLEMENTED; device UNKNOWN |
| 11. Persistence | atomic app JSON existed; decode failure silently reset in memory | no migration/corruption/offline integration test | IMPLEMENTED / UNKNOWN |
| 12. Character registry | IDs existed in frozen avatar contract; complete mechanics metadata absent | avatar contract test | partial IMPLEMENTED / partial TESTED |
| 13. Build hygiene | regression already included Swift package and 12 gates | 12 PASS baseline reported by authority | TESTED on base; rerun below |

## Delivered

* Added a monotonic musical clock and count-derived completion plan; pause freezes every time consumer and resume reanchors without drift.
* Added a pure workout reducer with canonical coach phases, count truth, score/combo/mastery, NEXT, pause/resume/restart and completion/ended-early semantics. UNKNOWN has no score denominator and does not punish combo.
* Added the complete content hierarchy types, 26 instructed move definitions, named workouts, difficulty filtering, Create Move parameters and deterministic offline beat generation.
* Added validated, editable, round-trippable `.swaypack`, schema migration defaults, atomic local-first storage and last-known-good corruption recovery.
* Added session/progress math and complete six-character metadata registry.
* Added observable `CalibrationSession` and `SwayTimelineSession` binding surfaces plus a diagnostics launch flag.
* Added Linux tests covering clock drift, scoring truth, lifecycle, content, `.swaypack`, migration/corruption, offline journey, beats, progress and registry. Existing calibration tests cover ordered stages, left/right, jitter, timeout and reacquisition.
* Corrected the governor to ForgeMASTER. HealthKit entitlement properties in `App/project.yml` were not changed.

## Evidence after implementation

Items 1–7, 9, 11 and 12 have pure implementation with discovered Linux tests. Item 2's pure state machine is tested; camera behavior is device-UNKNOWN. Items 6, 8 and 10 retain their app adapters and compile gates, while actual platform authorization/capture/read-write behavior is device-UNKNOWN. The authoritative regression result is recorded by the final command run for this receipt.

## Device-only UNKNOWN

Camera/Vision accuracy, iOS 17+ 3D pose yaw, MusicKit authorization/denial and playback, Shazam evidence, ReplayKit/AVFoundation recording, Photos saving/share, HealthKit authorization/read/write, calories from hardware, and the full physical journey are **UNKNOWN until Lucas's iPhone run**.

## CROSS-TASK REQUESTS

Task 3 owns `App/SWAY/Views/**`. It must replace `WorkoutPlayerView.activeClock` as follows: bind `activeSeconds` and workout completion to `SwayTimelineSession.musicalTime/isComplete`, feed `tick(at:)` from the existing audio/render timeline callback, and remove the one-second Task loop. It must also gate CameraLabView, NativeLabView and StickFigureView navigation with `SwayDiagnostics.isEnabled`. No Task 3-owned file was modified here.

## Exact next steps on Mac/iPhone

1. Generate/open the Xcode project and run the SWAY scheme unit tests on Mac.
2. Apply the two Task 3 bindings above during UI integration.
3. Exercise the physical-device matrix for camera calibration/yaw, MusicKit denial/authorization, Shazam evidence, recording/Photos/share and HealthKit denial/authorization/read/write.
4. Record observed results as VERIFIED or FAIL; leave unobserved rows UNKNOWN.
