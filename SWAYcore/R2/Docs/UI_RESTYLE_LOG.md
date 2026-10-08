# SWAY UI Restyle Log

Evidence vocabulary: **IMPLEMENTED** means source exists; BUILD/TESTED/VERIFIED are recorded only after their respective gates.

## U0 — Shared design system
- **Before @APPLE:** REMOVE duplicated cyan/lime visual vocabulary; KEEP dark stage identity; SIMPLIFY component styling; ADAPT final-board hot pink hierarchy; REPLACE ad-hoc values with one token source.
- **Changed:** Centralized colour, gradient, typography-adjacent sizing, spacing, radii, minimum target, card, chip, section, stat and primary-button components in `SWAYDesignSystem.swift`.
- **Kept:** Existing `SwayTheme` and reusable component names so all functional callers remain source-compatible.
- **After @APPLE verdict:** **KEEP** the centralized system; **ADAPT** individual screens to it. IMPLEMENTED; build pending.

## U1 — Root navigation shell
- **Before @APPLE:** KEEP the canonical four destinations and onboarding bindings; REMOVE ambiguous grid/waveform tab symbols; SIMPLIFY tab state; ADAPT the shell to the final board; REPLACE legacy launch-character rendering.
- **Changed:** Added stable tab selection/tags, canonical HOME · MOVES · BEATS · PROFILE iconography, accessibility identity, pink selection, dark tab material, and routed launch dancers through `SWAYCharacterStage`.
- **Kept:** Every `NavigationStack`, destination, onboarding cover, launch timing, and `SwayStore` environment binding.
- **After @APPLE verdict:** **KEEP**—the consumer hierarchy is canonical and no parallel navigation was introduced. IMPLEMENTED; build pending.

## U2 — Home
- **Before @APPLE:** KEEP workout generation, music/playlist sheets, Beats analysis and all existing sections; REMOVE mixed cyan hero language and legacy renderer wrappers; SIMPLIFY the primary action; ADAPT the board's coach-led stage and four shortcuts; REPLACE profile-as-settings affordance.
- **Changed:** Restyled the existing 634-line view in place with the board's “Let's Dance” hierarchy, “Move • Feel • Progress” copy, “Set Up & Start” action, gear settings target, canonical Moves/Beats/Progress/Profile shortcuts, and `SWAYCharacterStage` coach previews.
- **Kept:** Progress data, Quick Start, Latest Moves, generated workout, playlist/song/SWAY Beats, MusicKit media picker, analysis, Shazam anchor, session/share features, every state binding and navigation destination.
- **After @APPLE verdict:** **KEEP** the large real Home flow; **SIMPLIFY** only its surface hierarchy. No fake data or replacement shell. IMPLEMENTED; build pending.

## U3 — Workout player and results
- **Before @APPLE:** KEEP the one musical timeline, calibration lock, camera, scoring, match truth, recording and session coordination; REMOVE direct puppet calls; SIMPLIFY pause language; ADAPT COACH/YOU presentation to one stage; REPLACE renderer entry points with the frozen stage contract.
- **Changed:** Coach and tracked YOU now render only through `SWAYCharacterStage`; legacy coach adapter also delegates to that contract. Paused controls use Resume/Restart/End Workout language, the shared stage has a VoiceOver label, and the existing result states retain completed/ended-early truth.
- **Kept:** `SwayStore`, `SwaySessionController`, `SwaySharedSessionCoordinator`, MusicKit/audio timeline, Shazam, HealthKit, calibration, tracking loss/reacquisition, MATCH/NOT MATCHED/UNKNOWN scoring, Record SWAY, pause/resume/restart/end and summary data.
- **After @APPLE verdict:** **KEEP** the real synchronized player architecture; **ADAPT** its presentation. IMPLEMENTED; build pending.

## U4 — Moves and Learn
- **Before @APPLE:** KEEP real authored moves, filtering, favourites and practice route; REMOVE adapter-based character thumbnails; SIMPLIFY title to the canonical “Moves”; ADAPT cards and step strip to the final board; REPLACE all character calls with the stage.
- **Changed:** Library cards, animated Learn demo and eight-count thumbnails now use `SWAYCharacterStage`; title and existing dark two-column hierarchy align with the target.
- **Kept:** Store-backed moves, difficulty filters, favourites, move detail/instructions, repetitions, tempo, Reduce Motion and Start Practice navigation.
- **After @APPLE verdict:** **KEEP**—the real library now uses the final visual hierarchy without changing data or routes. IMPLEMENTED; build pending.

## U5 — Create Move
- **Before @APPLE:** KEEP authored movement selection, customization bindings, save and practice flow; REMOVE legacy renderer calls; SIMPLIFY primary action styling; ADAPT preview to the board; REPLACE coach rendering with the stage.
- **Changed:** Base and saved-move previews use `SWAYCharacterStage`, while Save/Practice actions use the shared hot-pink primary treatment.
- **Kept:** `SwayStore` move persistence, base movement picker, tempo/range/arm/intensity customization, preview, Save Move, library insertion and workout navigation.
- **After @APPLE verdict:** **KEEP** the existing creator mechanics; **ADAPT** only presentation. IMPLEMENTED; build pending.

## U6 — Progress
- **Before @APPLE:** KEEP store-derived history, streak and achievements; REMOVE duplicated stat styling; SIMPLIFY overview metrics; ADAPT segmented hierarchy and weekly chart to the board; REPLACE chart-only meaning with accessible text.
- **Changed:** Progress uses shared stat tiles and exposes a complete spoken weekly-activity summary while preserving Overview/Activity/Achievements.
- **Kept:** Real `sessionResults`, completion state, durations, computed seven-day activity, day streak and unlock conditions; empty state remains truthful.
- **After @APPLE verdict:** **KEEP**—clear board-matched information hierarchy with no invented calorie or workout data. IMPLEMENTED; build pending.

## U7 — Settings
- **Before @APPLE:** KEEP every preference, permission, backup and package binding; REMOVE diagnostics from consumer navigation; SIMPLIFY destination grouping; ADAPT tint to the final board; REPLACE dead diagnostics description with real routes.
- **Changed:** Settings now provides a contained Diagnostics section linking the existing Camera and Native labs, and uses the shared pink interaction tint.
- **Kept:** Profile/share settings, YOUR DANCER route, mirror/impact/space/intensity/complexity/cues, Apple Music, HealthKit, coach, workout overlays, progress reset, backup/restore and `.swaypack` import/export.
- **After @APPLE verdict:** **KEEP** as the single settings/permissions authority; developer tooling is discoverable but no longer top-level. IMPLEMENTED; build pending.

## U8 — Camera Lab and Native Lab
- **Before @APPLE:** KEEP functional developer instrumentation and calibration truth; REMOVE noncanonical coach rendering; SIMPLIFY visual deviations; ADAPT labs to shared tint; REPLACE calibration coach with the character stage.
- **Changed:** Calibration's coach now renders through `SWAYCharacterStage`; both labs use the shared final-board accent while remaining intentionally developer-facing.
- **Kept:** Live camera session, six-step calibration, permission/cancel completion callbacks, body/tracking diagnostics, Motion, HealthKit connection and optional-permission messaging.
- **After @APPLE verdict:** **KEEP** functionality, **SIMPLIFY** styling, and keep both routes under Settings diagnostics. IMPLEMENTED; build pending.

## U9 — Coach picker and YOUR DANCER creator
- **Before @APPLE:** KEEP the persisted profile and truthful Lucia-only coach availability; REMOVE parallel hard-coded avatar arrays and legacy preview renderers; SIMPLIFY categories; ADAPT the creator board's tab/grid/preview layout; REPLACE selection logic with the frozen catalog API.
- **Changed:** YOUR DANCER is rebuilt in place solely on `SWAYAvatarCategory`, `SWAYAvatarCatalog`, `SWAYAvatarOption` and `SWAYCharacterStage`; unavailable catalog entries are disabled, never fabricated. Layout becomes side-by-side on wide devices. The coach picker continues to expose only the currently supported Lucia profile.
- **Kept:** Existing settings sheet route, `store.character` persistence, Save/Done behavior and the real coach preference binding.
- **After @APPLE verdict:** **KEEP** the catalog as the one creator truth; **REMOVE** every parallel option table. IMPLEMENTED; catalog breadth reflects delivered Task 6 art rather than fake UI.

## U10 — Accessibility and adaptive layout
- **Before @APPLE:** KEEP semantic SwiftUI controls and Reduce Motion behavior; REMOVE remaining character wrapper bypass; SIMPLIFY spoken stage context; ADAPT for Dynamic Type and compact/wide widths; REPLACE fixed creator stacking on iPad.
- **Changed:** Set a usable app-wide Dynamic Type range through Accessibility 3, retained 44-point shared targets, added semantic stage/chart/shortcut labels and values, preserved Reduce Motion, made YOUR DANCER responsive at 700 points, and removed the final consumer-side legacy character-stage wrapper.
- **Kept:** Native control semantics, dark high-contrast palette, device safe areas, ScrollViews for small-iPhone overflow, and workout landscape geometry behavior.
- **After @APPLE verdict:** **KEEP** the responsive single hierarchy. Source review covers iPhone 15 Pro Max, small iPhone scrolling and iPad split layouts; simulator/device visual verification remains UNKNOWN where Xcode is unavailable.

## @ARTEMIS QA ladder
- **PACKAGE / UNDERSTAND / INVENTORY:** Final board, supporting board, source screens, catalog contract and protected capabilities inspected.
- **SPECIFY / PRODUCE / INTEGRATE:** One token source and existing real-screen routes used; no bitmap UI assets were generated or altered.
- **ASSET / FAMILY QA:** Character consumers statically inventoried for stage routing; catalog controls display only delivered availability.
- **TARGET TEST:** Regression/typecheck evidence is recorded separately after execution. Xcode simulator and physical-device gates remain UNKNOWN unless actually run.
- **Evidence discipline:** UI is IMPLEMENTED in source. It is not called BUILT, TESTED or VERIFIED until those exact gates complete.
