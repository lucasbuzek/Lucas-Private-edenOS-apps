# TASK 9 — SWAY final UI on the REAL app, complete (Codex cloud, environment lucas-Private-edenOS-apps)

Branch: start from `swaycore-puppet-rig-20261008` (latest). Project root: `SWAYcore/R2`.
This REPLACES Task 3 (rejected: new shell screens with fake data) and Task 7's UI part (stopped after ~6 minutes, a fraction done). Do not repeat either.

## How to work
- Use EVERYTHING your environment offers: all tools, skills, helpers, plugins, MCP connectors, image viewing/analysis of the reference boards, Swift toolchain/Xcode/simulator if present, linters. Look for them first, list which you found in your final message, and use them.
- Run @APPLE (UI/UX + architecture review, KEEP/REMOVE/SIMPLIFY/ADAPT/REPLACE) on each screen before and after, and @ARTEMIS as the QA ladder. Helper files: `Docs/release_tasks_20261008/helpers/`. Rules: `Docs/release_tasks_20261008/SWAYCORE_RELEASE_COMMON_2026-10-08.md` and `SWAYCORE_RELEASE_TASK3_UI_2026-10-08.md` (design intent only).
- Visual target: `Reference/ArtDirection/FINAL_UI_DIRECTION_SWAY_UI_TARGET_BUILD122.jpeg` (final). Supporting: `134-SWAY_GENERATED_UIX_ASSET_BOARD.png`. Do NOT use `141-…UIX_DIRECTION.png` styling (superseded anime look).
- Evidence ladder: GENERATED ≠ IMPLEMENTED ≠ BUILT ≠ TESTED ≠ VERIFIED. UNKNOWN is never PASS.
- Do NOT stop early. Every checklist item ends DONE (evidence) or BLOCKED (exact reason + attempts). "Skipped for time" is not allowed.

## Hard rules
- Restyle the EXISTING views IN PLACE. Keep every binding, `@EnvironmentObject` (SwayStore, SwaySessionController, SwaySharedSessionCoordinator), navigation route and feature: Record Me / Record SWAY, Beats analysis, MusicKit, Shazam anchor, HealthKit, calibration, camera, workout player, library, create move, .swaypack import, settings. No mock/sample data, no placeholder screens, no new parallel screen hierarchy.
- Characters render ONLY through `SWAYCharacterStage(character:source:profile:mirrored:)`. Replace `SWAYCoachPuppetView(...)` in `App/SWAY/Avatar/SWAYAvatarRendering.swift` (~line 325) and `SWAYTrackedPuppetView(...)` in `App/SWAY/Views/WorkoutPlayerView.swift` (~line 209) with the stage.
- YOUR DANCER creator uses only `SWAYAvatarCatalog` / `SWAYAvatarOption`.
- Shared design tokens (colours, type, spacing, corner radii, components) in ONE file, e.g. `App/SWAY/Views/SWAYDesignSystem.swift`; screens use the tokens.
- Do not edit avatar art / rig / renderer (Task 6) or mechanics/engine logic (Task 8).

## Checklist — one commit per screen (all required)
U0. `SWAYDesignSystem.swift` tokens + reusable components derived from the final board.
U1. `RootView.swift` — tab/navigation shell.
U2. `HomeView.swift` (634 lines — largest; keep all its sections working).
U3. `WorkoutPlayerView.swift` — coach stage + YOU stage via SWAYCharacterStage, score/match states, timeline, pause/resume controls.
U4. `MoveLibraryView.swift`.
U5. `CreateMoveView.swift`.
U6. `ProgressViewScreen.swift`.
U7. `SettingsView.swift`.
U8. `CameraLabView.swift` and `NativeLabView.swift` (keep functional; developer-facing styling acceptable).
U9. Coach picker + YOUR DANCER creator (find where they live; build on the catalog).
U10. Accessibility: Dynamic Type, VoiceOver labels, contrast; iPhone 15 Pro Max baseline + small iPhone layout.
For each screen record in `Docs/UI_RESTYLE_LOG.md`: what changed, what was kept, @APPLE verdict.

## Gates — run and paste result lines
- `cd SWAYcore/R2 && ./RUN_R2_REGRESSION.command` (every gate line; the "complete SWAY app module iOS SDK typecheck" gate must PASS).
- If Xcode exists: simulator build of scheme SWAY + screenshot of every screen (save under `Docs/ui_screens/`). If not: BUILD UNKNOWN (say so).

## Delivery
- Commits prefixed `U0:`…`U10:`.
- Try `git push origin HEAD:swaycore-ui-codex9-20261008` and report whether it succeeded.
- Final message: checklist table (item / DONE|BLOCKED / evidence), tools found and used, gate lines, files changed list.
