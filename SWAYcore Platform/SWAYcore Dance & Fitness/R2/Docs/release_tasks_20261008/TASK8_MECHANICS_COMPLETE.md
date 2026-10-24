# TASK 8 — SWAY mechanics, complete (Codex cloud, environment lucas-Private-edenOS-apps)

Branch: start from `swaycore-puppet-rig-20261008` (latest). Project root: `SWAYcore/R2`.
This REPLACES Task 7's mechanics part. Task 7 stopped after ~6 minutes having done a fraction of its brief. Do not repeat that.

## How to work
- Use EVERYTHING your environment offers: all your tools, skills, helpers, plugins and MCP connectors, shell, package managers, Swift toolchain if present, test runners, linters, image tools. Look for them first, list which you found in your final message, and use them.
- Project helpers in `Docs/release_tasks_20261008/helpers/` (ARTEMIS = QA ladder) apply. Governor = ForgeMASTER rules in `Docs/release_tasks_20261008/SWAYCORE_RELEASE_COMMON_2026-10-08.md`.
- Evidence ladder: GENERATED ≠ IMPLEMENTED ≠ BUILT ≠ TESTED ≠ VERIFIED. UNKNOWN is never PASS. Never claim a gate you did not run.
- Do NOT stop early. Work through every checklist item. An item may end only as DONE (with evidence) or BLOCKED (with the exact error/reason and what you tried). "Skipped for time" is not allowed.

## Checklist (all required)
M1. **Merge Task 2 output.** Diff branch `swaycore-release-mechanics-20261008` against the base. For every hunk: adopt, adapt, or drop — record each decision with a one-line reason in `Docs/MECHANICS_MERGE_LOG.md`.
M2. **Merge salvage.** Same for `swaycore-salvage-downloads-20261008` (music-clock salvage: local audio clock, workout phrase state, library analysis; regression scripts in `Tools/regression/run_*_state.py`). Same log.
M3. **Pause/resume freezes the musical clock.** Workout pause stops musical time; resume continues from the same beat; no wall-clock drift; `SWAYPoseSource.move(... paused:)` honoured by the coach stage. Add a deterministic test (Swift test or Python mirror in `Tools/regression/`).
M4. **Workout end derived from the timeline** (not an independent 1 s wall-clock task; see `Docs/UNRESOLVED_ITEMS.md` U-08), or document precisely why not.
M5. **Corrupted saves.** Unreadable/corrupt profile, character, library or settings files → recover to defaults, keep a `.corrupt` backup copy, show a user-visible notice; never crash. Test with a truncated JSON fixture.
M6. **Engine contracts untouched:** calibration machine, SwayMatchTruth (MATCH/NOT MATCHED/UNKNOWN), SwayTimelineMath (20 BPM floor), SwayPoseMapper. Run their tests.
M7. Do not edit avatar art, `SWAYRigPuppet.swift`, `SWAYPuppetRenderer.swift` (Task 6) or restyle views (Task 9). Only minimal view wiring needed for M3/M5 notices.

## Gates — run and paste the result lines
- `cd SWAYcore/R2 && ./RUN_R2_REGRESSION.command` (every gate line).
- `swift test` in the SWAYcoreEngine package.
- `python3 Tools/regression/check_oss_dependencies.py`.
- If Xcode exists: `xcodebuild -project App/SWAY.xcodeproj -scheme SWAY -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build`. If not: BUILD UNKNOWN (say so).

## Delivery
- One commit per checklist item, message prefixed `M1:`…`M7:`.
- Try `git push origin HEAD:swaycore-mechanics-codex8-20261008` and report whether it succeeded.
- Final message: checklist table (item / DONE|BLOCKED / evidence), tools found and used, gate lines, files changed list.
