## COMMON CONTRACT — SWAYcore Dance & Fitness FINAL COMPLETE RELEASE (shared by Tasks 1–4; 2026-10-08)

Governor: ForgeMASTER (sole AppDev governor; EITRI/EITRIMB are superseded provenance). Environment: lucas-Private-edenOS-apps. Repo: lucasbuzek/Lucas-Private-edenOS-apps, project root `SWAYcore/R2`.
BASE for all three tasks: branch `swaycore-puppet-pilot-20261007` at the commit that adds `App/SWAY/Avatar/SWAYCharacterStage.swift` (the frozen integration contract). Each task pushes ONLY to its own new branch (named in the task). Tasks 1, 2, 3 run IN PARALLEL; Task 4 starts from Task 1's branch once Task 1 lands. Claude integrates them on the Mac.

### Authority (read before editing; do not reconstruct from memory)
1. Lucas's newest decisions (section below) — they override older text.
2. `SWAYcore/HANDOFF.md`, `SWAYcore/AGENTS.md`, `SWAYcore/R2/CODEX_HANDOFF_SWAYCORE_DANCE_FITNESS_R2.md`.
3. `R2/App/PRODUCT_SPECIFICATION.md`, `CAPABILITY_LEDGER.md`, `UIX_CONTRACT.md`, `TIMING_CONTRACT.md`, `CHARACTER_CONTRACT.md`, `PROTECTED_CAPABILITIES.md`, `RELEASE_GATES.md`, `REGRESSION_CONTRACT.md`, `PHYSICAL_TEST_MATRIX.md`, `R2/Docs/UNRESOLVED_ITEMS.md`.
4. Current source and evidence. Evidence ladder: GENERATED != IMPLEMENTED != BUILT != TESTED != VERIFIED != RELEASED; UNKNOWN != PASS. Simulator != physical. Never promote an LKG.

### Lucas's decisions (newest first; binding)
- 2026-10-08: The goal is the FINAL COMPLETE RELEASE, split into four tasks: (1) 2.5D avatars — ALPHA characters Lucia + YOUR DANCER, (2) mechanics and app inner workings, (3) full complete UI, (4) the remaining four instructors Nandi, Thabo, Zuri, Kyle. Each task stays inside its own scope. Do NOT spend effort re-fixing gates that already pass; do NOT rework another task's area.
- 2026-10-08: The previous passes were wrong to keep the OLD UI and to spend effort on already-working build/regression plumbing instead of the avatars.
- 2026-10-07: Final UI direction = `R2/Reference/ArtDirection/FINAL_UI_DIRECTION_SWAY_UI_TARGET_BUILD122.jpeg` (12 screens, dark UI, hot-pink accents).
- 2026-10-07: Characters: coaches Lucia, Nandi, Thabo, Zuri, Kyle in the look of boards `136-SWAY_BUILD110_CHARACTER_ASSET_DIRECTION.png` and `125-IRIS_BUILD113_ARTICULATED_ASSET_DIRECTION.png` (soft toy-like 3D-render illustration). NOT the anime look of board 141 (141 only for its pose-silhouette rows). No real brand logos or band art on clothing.
- 2026-10-07: 2.5D avatars are the release route; RealityKit/Blender `YD_*` and `*Reality.usdc` (which contain only primitive mannequins) stay dormant and unrouted.
- 2026-10-07: The character IS the rig: a 2D cut-out puppet on SWAYHumanoid-v1 (23 joints). Coach puppet driven by move clips; YOU puppet driven live by camera tracking. 360° turns the animated-TV way: drawn angles FRONT, 3/4 FRONT, SIDE, 3/4 BACK, BACK, mirrored to 8 directions, swapped quickly during turns.
- 2026-10-07: FREE OPEN-SOURCE TOOLS ONLY (no Rive/Spine/paid or closed tools or generators). Apple SDK frameworks are the allowed platform.
- 2026-10-07 00:33: production-quality 2.5D satisfies character acceptance; P1B (runtime-consumed separated body-part/component library) binding; flattened concept-sheet cutouts, primitive mannequins and raw skeletons are prohibited final fallbacks.
- Release scope (this decision supersedes the older "Alpha = Lucia + YOUR DANCER only" text): all five coaches + YOUR DANCER + every capability in PRODUCT_SPECIFICATION; iPhone + iPad portrait/landscape; offline/local-first.

### Protected invariants (from HANDOFF.md; never break)
HOME · MOVES · BEATS · PROFILE. WATCH → COPY → MATCH → COMBO → SCORE → UNLOCK → DANCE. One movement/choreography truth. One musical timeline (TIMING_CONTRACT). Calibration STEP INTO VIEW → WAVE LEFT → WAVE RIGHT → LIFT LEFT FOOT → LIFT RIGHT FOOT → JUMP → READY TO SWAY; no progression/scoring before READY. MATCH / NOT MATCHED / UNKNOWN truth. COACH and YOU share one stage. Raw Vision skeleton is diagnostics only.

### Verified state of the base (Claude on Lucas's Mac, Xcode 27 / iOS 27 SDK, 2026-10-07/08)
- iOS Simulator `xcodebuild ... CODE_SIGNING_ALLOWED=NO build`: BUILD SUCCEEDED at bd6bcf6.
- `RUN_R2_REGRESSION.command`: 12 PASS / 0 FAIL / 2 UNKNOWN (visual regression, physical Alpha). Keep it green; do not rewrite passing gates.
- HealthKit entitlements: fixed at the root (declared in `App/project.yml`; XcodeGen used to empty the file). Do not regress.
- Lucia puppet pilot: runtime puppet renderer, 8-direction yaw selector (±10° hysteresis), Vision mapper, OSI licence gate exist. ART = FAIL (box-cut parts from a full figure, hair duplicated, joint gaps, minimal motion, no options).
- The app UI is still the OLD UI (TabView of HomeView/MoveLibraryView/SwayBeatsHubView/SwayProfileHubView plus developer views CameraLabView, NativeLabView, StickFigureView).
- AGENTS.md still names EITRIMB as governor (stale; Task 2 fixes the line to ForgeMASTER).

### Frozen integration contract (do not change signatures)
`R2/App/SWAY/Avatar/SWAYCharacterStage.swift`:
- `enum SWAYCharacterID { lucia, nandi, thabo, zuri, kyle, yourDancer }`
- `enum SWAYPoseSource { move(id:musicalTime:bpm:paused:), tracked(SwayBodyPose, visible:), idle }`
- `struct SWAYCharacterStage: View { init(character:source:profile:mirrored:) }`
- `enum SWAYAvatarCategory`, `struct SWAYAvatarOption`, `enum SWAYAvatarCatalog { options(_:), selectedIndex(_:in:), apply(_:to:) }`
Task 1 owns the implementation behind it. Task 3 renders characters ONLY via `SWAYCharacterStage` and builds the creator ONLY on `SWAYAvatarCatalog`. Task 2 keeps `SwayBodyPose`, `SwayCoachPoseEngine.pose(moveID:musicalTime:bpm:)` and `SwayCharacterProfile` source-compatible.

### File ownership (prevents merge conflicts)
- Task 1 AVATARS: `App/SWAY/Avatar/**`, `App/SWAY/Resources/Puppets/**`, `Resources/Avatars/**`, `Resources/Characters/**`, character imagesets in `Assets.xcassets` (`Rig_*`, `YD2D_*`, `Lucia*`, `UserPose*`, new `Puppet_*`), `AssetFactory/**`, `Docs/puppet_contact_sheets/**`, avatar tests.
- Task 4 COACHES (Nandi, Thabo, Zuri, Kyle): only their per-character data/assets — `AssetFactory/data/puppet/{nandi,thabo,zuri,kyle}_*`, `App/SWAY/Resources/Puppets/{Nandi,Thabo,Zuri,Kyle}/**`, their imagesets, their contact sheets/tests; it reuses Task 1's pipeline and renderer and changes them only via CROSS-TASK REQUESTS.
- Task 2 MECHANICS: `App/SWAY/Services/**`, `App/SWAY/Models/**`, `App/SWAY/App/**`, `Packages/SWAYcoreEngine/**`, `App/project.yml`, `Tools/**`, `*.command`, `App/Tests/**` (non-avatar, non-UI), `SWAYcore/AGENTS.md`, `SWAYcore/HANDOFF.md`, app/build docs.
- Task 3 UI: `App/SWAY/Views/**` (new subfolders allowed, e.g. `Views/Design`, `Views/Screens`, `Views/ViewModels`), UI colour/icon assets (`Assets.xcassets` entries named `UI_*`, `AccentColor`, `AppIcon`), UI tests/snapshots, `Docs/ui_screens/**`.
If you genuinely need a change in another task's files, do NOT make it: write it under "CROSS-TASK REQUESTS" in your receipt with the exact API you need, and use a local adapter inside your own files meanwhile.

### Engineering rules (all tasks)
- Free open-source tools only; record every new tool/asset licence in `AssetFactory/PROVENANCE/oss_dependencies.json` (the OSI gate must stay green).
- Swift must compile with the iOS 27 SDK / Swift 5.9 mode: spaces around binary operators (`a - .pi / 2`, never `a-.pi/2`), explicit types in long expressions/closures (avoid type-checker timeouts), no APIs newer than the iOS 26 deployment target without availability checks. Your environment has no Xcode, so write defensively; Claude runs the real build on the Mac.
- Every shipped PNG must decode strictly; unique resource names (no same-named files colliding in the flat bundle).
- Tests: zero discovered tests = FAIL; Pillow-dependent Python tests SKIP (not PASS) when Pillow is missing.
- Commit in small logical commits; push your branch; finish with a receipt `R2/Docs/RELEASE_TASK<N>_RECEIPT_20261008.md`: what changed (files), evidence state per acceptance item, what is UNKNOWN and why, CROSS-TASK REQUESTS, exact next steps. Do not claim BUILT/TESTED for anything you could not run.
- AUTO: continue all safe work inside your scope until your acceptance list is met or a genuinely unavailable dependency blocks it. Analysis/plans/receipts are not substitutes for implementation.
