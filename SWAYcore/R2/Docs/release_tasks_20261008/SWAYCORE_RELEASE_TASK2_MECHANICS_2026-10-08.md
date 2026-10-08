# WORKinCODEX — SWAYcore FINAL RELEASE — TASK 2 of 4: MECHANICS & APP INNER WORKINGS (2026-10-08)

New branch: `swaycore-release-mechanics-20261008` (from the base in the common contract). Scope: engine, services, models, data, persistence, integrations, build tooling. Do NOT build UI screens (Task 3) or character art/rendering (Task 1). Expose clean, testable APIs the UI binds to.

## Goal
Every non-visual capability of the complete release works end to end, is protected by real tests, and is exposed to the UI through observable view-model-ready services.

## Inspect first
Build an evidence matrix from current source/tests for each item below (IMPLEMENTED / TESTED / UNKNOWN) before changing anything; repair and extend, never rewrite working subsystems (Build 147 tracking path is protected).

## Scope (complete each; tests for each)
1. Single musical clock (TIMING_CONTRACT): audio → beat → downbeat/bar/phrase → count → move → repetition → coach phase → visual/spoken cue → expected YOU pose → scoring. Pause freezes the clock and all consumers; resume without drift. Replace the 1 s wall-clock `activeClock` workout end (U-08) with timeline-derived completion.
2. Tracking + calibration engine: Vision body pose → normalized `SwayBodyPose`; six-action calibration STEP INTO VIEW → WAVE LEFT → WAVE RIGHT → LIFT LEFT FOOT → LIFT RIGHT FOOT → JUMP → READY TO SWAY with per-stage state, timeouts, retry, left/right correctness (U-06), jitter-safe thresholds (U-05); tracking loss → guide → reacquire state machine; no scoring before READY. Expose `CalibrationSession` observable state for the UI. Optional iOS 17+ 3D pose yaw estimate exposed for the avatar angle selector.
3. Workout session engine: WATCH → COPY → MATCH → COMBO → SCORE → UNLOCK → DANCE; MATCH / NOT MATCHED / UNKNOWN per count (resolve U-07 consistently and document); combo, score, mastery (Discovered → Learning → Familiar → Mastered), move sequencing with NEXT, pause/resume/restart/end-early semantics matching the final UI board (Ended early = progress saved, not counted as completed).
4. Content model: Move → Variation → Combination → Routine → Workout → Challenge → Program; the authored move library (20 protected moves + port the 6 missing coach pose cases from U-09) with instructions and counts; workouts list (Foundation Flow, Latin Vibes, Full Body Groove and others defined in data); difficulty filters.
5. Learn: user tempo (BPM scaling), counts 1–8, repetitions, play/pause, step-by-step on the same clock.
6. Beats/music: offline Generated Beat engine (styles Pop, Latin, Hip Hop, EDM, Tropical; tempo and intensity), Apple Music (MusicKit) path with authorization/denied states, Shazam alignment evidence (not the runtime clock), one provider interface.
7. Create Move: base movement + tempo/range/arm style/intensity parameters → saved move usable in Learn/workouts; `.swaypack` unified external format: export/import/edit/re-share with versioning and validation.
8. Record SWAY: ReplayKit/AVFoundation capture → preview → save to Photos → share; permission/denied states.
9. Results & Progress: session summary (time, moves, active calories), history (Completed / Ended Early), weekly activity, streaks, achievements data.
10. Profile & Health: HealthKit write/read workouts and active energy with permission + denied states (entitlement already fixed — keep `project.yml` properties); YOUR DANCER profile persistence (`SwayCharacterProfile`, keep source-compatible) + selected coach.
11. Persistence/relaunch/migration: local-first store, migrate don't reset, corruption-safe writes; fully offline journey.
12. Character registry data: coach metadata (id, name, style, default workout) for the five coaches + YOUR DANCER, keyed by `SWAYCharacterID` (art itself is Task 1).
13. Build & repo hygiene: one authoritative macOS one-click builder; deterministic resources (no duplicate names in the bundle); remove developer views from the consumer navigation dependency graph only by exposing a diagnostics flag (Task 3 moves the screens); fix `SWAYcore/AGENTS.md` governor line (ForgeMASTER, not EITRIMB); keep `RUN_R2_REGRESSION.command` green and add the new tests to it.

## Acceptance (evidence required)
- Unit/integration tests for items 1–12 discovered and passing on Linux where possible (Swift package tests in `Packages/SWAYcoreEngine` for pure logic — move as much pure logic there as is sensible without breaking app imports); app-only pieces with XCTest marked for Mac execution.
- Clock/no-drift test across pause/resume; calibration state-machine tests incl. left/right and jitter; scoring tests incl. MATCH/NOT MATCHED/UNKNOWN; `.swaypack` round-trip test; persistence migration test; offline journey test (no network calls on the core path).
- A short API document `R2/Docs/MECHANICS_API_20261008.md` listing every observable service/view-model entry point the UI should bind to (names, published properties, actions) so Task 3 can wire against it.
- Regression stays green (12 PASS / 0 FAIL plus your new gates). Receipt `R2/Docs/RELEASE_TASK2_RECEIPT_20261008.md`.
Device-only behaviour (camera, HealthKit, MusicKit, ReplayKit on hardware) is UNKNOWN until Lucas's iPhone run; say so explicitly.
