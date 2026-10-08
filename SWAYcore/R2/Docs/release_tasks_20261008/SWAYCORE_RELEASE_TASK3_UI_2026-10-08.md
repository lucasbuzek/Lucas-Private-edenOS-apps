# WORKinCODEX — SWAYcore FINAL RELEASE — TASK 3 of 3: FULL COMPLETE UI (2026-10-08)

New branch: `swaycore-release-ui-20261008` (from the base in the common contract). Scope: every consumer screen, navigation, design system, layouts, accessibility. Do NOT implement engine/service logic (Task 2) or character art/rendering (Task 1). Characters render ONLY via `SWAYCharacterStage`; the YOUR DANCER creator uses ONLY `SWAYAvatarCatalog`.

## The authority: the final UI board
`R2/Reference/ArtDirection/FINAL_UI_DIRECTION_SWAY_UI_TARGET_BUILD122.jpeg` (1536×1024, 12 iPhone screens). Rebuild the app to match it screen by screen. The current UI is the OLD UI and is replaced, not restyled. Also use `134-SWAY_GENERATED_UIX_ASSET_BOARD.png` for the Create Avatar tabs (Style/Hair/Face/Outfit/Body/Shoes) and `SWAY_UI_REFERENCE` boards only where the final board is silent.

Screens on the final board (match layout, hierarchy, copy, components):
1. HOME — "SWAY" wordmark, settings gear, large coach (waving), "Let's Dance" / "Move • Feel • Progress", pink DANCE button "Set Up & Start", shortcut tiles Moves · Beats · Progress · Profile, bottom tab bar.
2. WORKOUT SETUP — "How do you want to dance?": Camera Tracking ("Get real-time feedback") vs Follow Along ("No camera needed"); Choose a Workout with chips All/Beginner/Dance Fit/Cardio/Strength; workout rows with thumbnail, name, duration • level; pink Start Workout.
3. WORKOUT (playing) — title + "1 of 8 • March", music button; big coach centre; NEXT card (next move mini coach + name); YOU card (YOUR puppet, Camera Tracking mode); stats column Move Time / Moves x/y / Total Time; bottom bar now-playing track, pause button, Next →.
4. WORKOUT PAUSED — blurred background; Resume (pink), Restart, End Workout.
5. END WORKOUT? — "Your progress so far will be saved, but this will not count as a completed workout." End Workout (pink) / Cancel.
6. WORKOUT ENDED — coach waving; Time / Moves / Active Cal; "Ended early" info card; Back to Home / Try Again.
7. GREAT JOB — coach thumbs-up; "You completed Foundation Flow"; Time / Moves / Active Cal; Continue / Share.
8. MOVES — filter chips All/Beginner/Intermediate/Advanced; 2-column grid of move cards (coach pose thumbnail, favourite heart, name, level).
9. LEARN: <move> — large coach demo with prev/next, step thumbnails strip, Repetitions stepper, Start Practice.
10. CREATE MOVE — Base Movement picker; Customize: Tempo, Range sliders, Arm Style, Intensity; Preview player; Save Move.
11. BEATS — segmented SWAY Beats / Your Music; hero "GOOD ENERGY" card; Style chips Pop/Latin/Hip Hop/EDM/Tropical; Tempo and Intensity sliders; Generate New Beat.
12. PROGRESS — Overview/Activity/Achievements; tiles Workouts / Day Streak / Calories; Weekly Activity bars; Recent Workouts with Completed / Ended Early states.
Plus screens the board implies but doesn't draw (design them in the same system): CALIBRATION (same stage as workout; the six steps with clear prompts and progress; "READY TO SWAY"), tracking-lost guidance overlay, PROFILE (YOUR DANCER card + Create/Edit, coach choice, Health/Music/permissions, settings), YOUR DANCER creator (category tabs, option grid from `SWAYAvatarCatalog` — unavailable options hidden/disabled, never faked; live `SWAYCharacterStage(character:.yourDancer, source:.idle, profile:)` preview; save), Record SWAY preview/save/share sheet, permission-denied states, empty states, onboarding (first launch).

## Design system (create once, use everywhere)
`Views/Design/`: colour tokens (near-black backgrounds, card greys, hot pink primary, violet/neon secondary as on the board), typography scale (bold rounded display, readable from 2 m on the workout screen), corner radii, pill buttons, chips, cards, stat tiles, sliders, tab bar. Dark appearance by default. Dynamic Type, VoiceOver labels, minimum 44 pt targets, Reduce Motion respected.

## Layout
iPhone (15 Pro Max reference, iPhone 13 minimum) and iPad portrait + landscape: on iPad use the space for a larger coach and side-by-side COACH/YOU and stats — not dashboard clutter. Safe areas, rotation, split view.

## Wiring
Bind every screen to Task 2's services through view models in `Views/ViewModels/` (thin; no business logic). Where a needed Task 2 API doesn't exist yet on your base, put a small adapter in `Views/ViewModels/Adapters/` over the existing code and list it in CROSS-TASK REQUESTS. Move developer screens (CameraLabView, NativeLabView, StickFigureView diagnostics) out of consumer navigation into a hidden Diagnostics entry in Settings. Navigation canon HOME · MOVES · BEATS · PROFILE (Progress reachable from Home tiles and Profile).

## Acceptance (evidence required)
1. A screen inventory table mapping each board screen → SwiftUI view → state/view-model → navigation entry.
2. SwiftUI previews for every screen in iPhone portrait, iPad portrait, iPad landscape, with sample data.
3. Render the previews to PNG where your environment allows (otherwise state UNKNOWN and provide the exact Mac command; Claude will capture simulator screenshots); commit to `Docs/ui_screens/` and a side-by-side comparison against the board.
4. No developer/debug UI reachable from consumer navigation; no placeholder text; every button wired or explicitly marked with its pending dependency.
5. Swift compiles under the common rules; regression stays green. Receipt `R2/Docs/RELEASE_TASK3_RECEIPT_20261008.md`.
