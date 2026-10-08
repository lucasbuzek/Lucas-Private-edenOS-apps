# TASK 7 — Final UI on the REAL app + mechanics follow-ups (Codex cloud, env lucas-Private-edenOS-apps)

Start from branch `swaycore-puppet-rig-20261008` @ 2b21781 (or newer). Project root: `SWAYcore/R2`.
Use every helper, plugin and tool available (@APPLE review for UI/UX, @ARTEMIS QA ladder). Work in the cloud only.
Read `Docs/release_tasks_20261008/COMMON*.md` and `TASK3_*.md` (final UI direction + board image in `Reference/`).

## Why this task exists
The previous UI task (Task 3) built new shell screens with fake data and ignored the working app. That output is REJECTED. This task restyles the EXISTING screens in place.

## Rules
- Restyle existing views one screen at a time (`App/SWAY/Views/*`, `RootView`). Keep every existing binding, store/session call, navigation route and feature (Record Me/SWAY, Beats analysis, MusicKit, Shazam anchor, HealthKit, calibration, workout player, library, import .swaypack). No mock data, no placeholder screens.
- Every character on screen goes through `SWAYCharacterStage(character:source:profile:mirrored:)` ONLY. Replace direct `SWAYCoachPuppetView` / `SWAYTrackedPuppetView` uses (`SWAYAvatarRendering.swift:325`, `WorkoutPlayerView.swift:209`) with the stage.
- YOUR DANCER creator built only on `SWAYAvatarCatalog`.
- Do NOT touch avatar art or `SWAYRigPuppet.swift` (Task 6 owns them).
- Do NOT change SWAYcoreEngine contracts (calibration, SwayMatchTruth, SwayTimelineMath 20-BPM floor).

## Mechanics follow-ups
1. Workout pause/resume must freeze and resume the musical clock (`SWAYPoseSource.move(... paused:)` honoured; no wall-clock drift).
2. Corrupted/unreadable saved profile or library file: recover to defaults with a user-visible notice; never crash. Add a test.
3. Merge-check `swaycore-release-mechanics-20261008` (Task 2 output) and `swaycore-salvage-downloads-20261008` (music-clock salvage): take what is correct and compatible, document what you dropped and why.

## Gates (UNKNOWN is never PASS)
- `SWAYcore/R2/RUN_R2_REGRESSION.command` — report every gate line.
- `swift test` in the SWAYcoreEngine package.
- If Xcode available: iphonesimulator build of scheme SWAY + screenshots of each restyled screen. Otherwise BUILD UNKNOWN.

## Delivery
- Small commits, one per screen / mechanic.
- If your environment can push: `git push origin HEAD:swaycore-ui-mechanics-codex7-20261008`; state whether it succeeded.
- Final message: screens × state table, mechanics results, gate results, anything dropped.
