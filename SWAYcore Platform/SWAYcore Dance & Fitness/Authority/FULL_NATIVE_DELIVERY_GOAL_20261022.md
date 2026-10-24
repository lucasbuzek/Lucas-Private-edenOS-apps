# SWAYcore Dance & Fitness — Full Native Delivery Goal & Gap Matrix
**Assessment date:** 2026-10-22 · **Status:** WORKING EXECUTION GOAL / NOT A NEW PROJECT BIBLE / NOT RELEASE APPROVAL  
**Authority:** Explicit owner decisions → canonical AppDevRules → `SWAYcore Platform/Authority/PROJECT_BIBLE.md` → `Dance & Fitness/Authority/PRODUCT_BIBLE.md` → current source and real tests. This document tracks delivery; it never narrows full scope or changes acceptance gates.
**Product:** SWAYcore Dance & Fitness, flagship native iPhone/iPad consumer application. **Working source:** `SWAYcore Platform/SWAYcore Dance & Fitness/R2`. **LKG:** NONE.
**Evidence precision:** Code present ≠ operational test ≠ integrated end-to-end ≠ user/physical acceptance.

## 1 · Non-negotiable full native goal

Deliver a visually production-quality, local-first, complete native iOS/iPadOS app around one shared versioned movement definition, one SWAYHumanoid-v1 23-joint choreography contract, one beat/phrase/count timeline, and coherent COACH instruction, optional live YOU tracking, configurable YOUR DANCER, matching/scoring, creation, persistence and progress.

**Primary tabs:** HOME · MOVES · BEATS · PROFILE. **Consumer loop:** WATCH → COPY → MATCH → COMBO → SCORE → UNLOCK → DANCE. **Content hierarchy:** Move → Variation → Combination → Routine → Workout → Challenge → Program; mastery Discovered → Learning → Familiar → Mastered. **Learn:** 8 counts, mirroring, 20–180 BPM, count selection, spoken/visual cues and tracking-optional Practice. **Workout:** stage-first, pause/restart/end, complete 5–45-minute use cases, Quick Dance, Dance, Learn Moves, Party, Challenge, Freestyle, Daily Dance, Endurance, Low Impact and Adaptive modes. **Beats:** offline generated rhythm, supported local/imported audio and Apple Music, beat-grid/onset analysis and honest Shazam fallback. **Tracking:** six-action calibration (Step Into View, Wave L, Wave R, Lift L Foot, Lift R Foot, Jump→Ready); visual translucent YOU, lost-person recovery; camera-off Follow-Along still works. **Score:** confidence/reference-aware only; unknown ≠ matched. **Create:** editable real moves, combinations/routines and persistent library; versioned safe `.swaypack` import/export and native share. **Record:** Record Me and Record SWAY with explicit opt-in, review and Photos/Files sharing; no silent camera uploads. **Health:** consent-safe workout logging, failure isolation. **Progress:** achievements, challenges, mastery, local persistence. **Access:** iPhone/iPad portrait/landscape, readable distance UI, VoiceOver, Dynamic Type and Reduce Motion, offline/denial/loss paths. **Private consumer sessions:** two participants, distinct Household up to six independent profiles/devices, instructor/Studio separately entitled; actual network transport must work when advertised. **Final cast:** Lucia, Nandi, Thabo, Zuri, Kyle and YOUR DANCER through one rig contract; single-Lucia Alpha is an intermediate acceptance milestone, NOT a final-product scope cut. Later official optional community needs opt-in accounts, validated publish/discovery, moderation, privacy and legal/licensing before public deployment.

**Visual target:** high-quality, original, warm stylized humanoid 3D with expressive face and garment/hair geometry; Sims-like customization quality reference only, no third-party copyrighted character reuse. Use owner-approved private Lucas/Thembi reference designs via MEMOJIME / ARTEMIS / APELLES as creative input. No personal photographs may be sent to an external model without separate consent, and picture/mesh generation does not prove a licensed, rigged animation-ready model.

## 2 · Version / authority comparison

| Version / branch | Proven use | Decision |
| --- | --- | --- |
| Build 143 | Historical graphical/runtime recovery | Recover useful GUI, not LKG |
| Build 147 | Proven protected tracking path | Do not casually replace or regress |
| Build 148 | Rejected | Never promote |
| Build 149 | Bounded convergence recovery | Not baseline/LKG |
| Builds 151/152 | Historical static/package convergence evidence | Not accepted app |
| Build 153 | Signed physical build/install/launch and technical clip/rig evidence; rejected avatar appearance | Recover mechanics only; NOT LKG |
| Private GitHub `swaycore-one-avatar-20261009` | Historical source; verified earlier RealityKit Swift renderer SHA blob `03535f...` | Provenance, NOT current Mac R2 |
| Mac R2 (2026-10-22) | Swift/Xcode consumer code; native tests; isolated Blender 44-module/21-clip assets | CURRENT WORKING CANDIDATE, NOT APPROVED |
| Final product | Five instructors + complete consumer UX and real offline/online-qualified journeys | TARGET, NOT CLAIMED SHIPPED |

**Storage/version caveat:** The GitHub `main` path for latest surface-shell authoring is absent as of the authorized read-only check; Mac source and remote GitHub are separate unsynchronized stores. Do not push or create branches without separate permission. Current Mac R2 has no local Git repository. The single working archive `#Backups/SWAYcore/SWAYcore_WORKING_BACKUP_20261018.tar.zst` predates the latest Oct 21/22 implementation; a future safe in-place backup refresh must demonstrate restore/integrity and must not destroy the old recoverable baseline.

## 3 · Full-scope implementation / gap matrix

Statuses: **CODE** = implementation exists but full runtime not proven; **TESTED-BOUNDED** = named partial gates actually passed; **FAIL** = confirmed missing/misaligned gate; **UNKNOWN** = not tested/verified; **DEFERRED-OFFICIAL** = required for later official stage, not a condition to call an internal Alpha build compiled.

| Area | Current implementation evidence (Oct 22) | Gap and exact solution direction | Status |
| --- | --- | --- | --- |
| Native application shell + navigation | `RootView.swift` has Home/Moves/Beats/Profile, onboarding and settings; unsigned iOS Simulator-target build PASS | Actual first launch, navigation, state restore and iPad layout/VoiceOver must be reviewed on device | CODE / BUILD PASS |
| Movement model + shared counts | `SwayCoachPoseEngine`, common Swift engine; parity 12,610 samples; native Swift tests 31/31 | Verify every visible built-in/remixed move articulates correctly in Learn and Workout; maintain one source of truth | TESTED-BOUNDED |
| Learn count-by-count | `MoveLibraryView.swift` has 20–180 BPM, count selection, preview, practice | Confirm real native character pose, mirrored movement and tempo after profile selection on device | CODE |
| Workout generator/modes | `SwayStore.generate`, `WorkoutPlayerView`, stage-first controls, timeline, pause/restart/results | Execute complete real solo workout, interruption/restart/end, scoring and persistence; verify full-mode breadth and transitions | CODE / PHYSICAL UNKNOWN |
| Native Lucia COACH | Licensed continuous Blender rig, 21 native source clips and standalone RealityKit evidence | Production visual approval (including body roll, feet, hair/outfit), bundle and exercise actual native renderer; currently `runtimeApproved:false` fallback art visible | FAIL |
| YOUR DANCER full creator | Profile fields support body/face/hair/material/wardrobe; isolated 44 distinct skinned modules, 21 shared clips, 11 models selected | Live Creator offers only 3 skin / 3 outfit options; real 44 asset bundle, rotation/zoom/undo/save, material & geometry differences in actual running app not accepted; `runtimeApproved:false` | FAIL |
| Native asset pipeline | Blender repaired `surface_shell_v2` candidate; topology 44/44 PASS and geometry uniqueness 44/44 PASS; macOS RealityKit models 44/44 + clips 21/21 PASS; 5.74 MB USD payload | Visual renders still show garment neckline/face/seams failures; current Blender full-scene validator PASS at 1.7449 m/42,955 triangles (earlier hidden-mesh 196 m defect resolved). Still requires expressive appearance, garment/pose visual QA | TESTED-BOUNDED / VISUAL FAIL |
| Runtime RealityKit integration | `SWAYAvatarRendering.swift` has modular loading, 12-active cap, PBR material tokens, rollback code, iOS build PASS | Assets remain outside `App/SWAY/Resources/Characters`; app manifests each expose 10 legacy clips/no module map. Package verified art, test material A/B, failed/cancelled swap, animation replay, memory spikes, device thermal | FAIL / CODE |
| Graphical tracked YOU | `CameraLabView` + `SwayUserSilhouetteView` and Vision body-pose pipeline; optional camera state | Test actual calibration six steps, orientation/mirror truth, loss/reacquisition, denied permission, low lighting, camera off and live overlay alignment | CODE / PHYSICAL UNKNOWN |
| Matching and adaptive COACH | Pose normalizer/reference lookup, score confidence and `unknown` states; messages and difficulty hooks | Record actual correct/incorrect user motion, timing/phase alignment, stale/lost frames, fair scoring and accessibility adaptation | CODE / PHYSICAL UNKNOWN |
| Generated Beats/music | AVAudio/beat pattern engines, local file picker/analyzer, MusicKit + Shazam code | Prove offline sound, local audio BPM/onsets/confidence, Apple authorization/DRM fallback and no second/competing clock; song transitions/crossfade coverage unknown | CODE / INTEGRATED UNKNOWN |
| Health | HealthKit optional authorization and `HKWorkoutBuilder` workflow | Test denial, pause/resume, ending workout while paused, real Health entry and no duplication | CODE / PHYSICAL UNKNOWN |
| Recording | ReplayKit `SwayPerformanceRecorder` with explicit start/stop, microphone control and preview | Distinguish Record Me vs Record SWAY modes, preview/save/share, protected Apple Music audio restrictions, error recovery on actual device | CODE / PHYSICAL UNKNOWN |
| Create / user library | `CreateMoveView`, `SwayStore.addMove/addCreation`, private persistence | Verify substantive count/pose editing, round-trip through canonical move truth into Learn & Workout, no dummy text-only choreography | CODE / PRODUCT DEPTH UNKNOWN |
| `.swaypack` / local sharing | `SwayStore` and `SwayPackStore` implement JSON/schema and import/export/share UI | Real Files/AirDrop between devices, malicious/corrupt/duplicate version rejection, rights, no embedded licensed tracks, import preview + reliable persistence | CODE / END-TO-END UNKNOWN |
| Progress / mastery / challenges | Stats and awards source/UI present | Demonstrate movement-level Discovered→Mastered semantics, session history and actual program/challenge progression, relaunch preservation | CODE / DEPTH UNKNOWN |
| Shared Sessions / Household | `SwaySharedSessionCoordinator` enforces tier/capacity and stores snapshots | No verified Multipeer/SharePlay/hosted transport; current UI can create a LOCAL MODEL, not physically pair/sync two people. Do not advertise actual connected multiplayer until adapter passes | PARTIAL / TRANSPORT MISSING |
| Offline/privacy | Local-first core and on-device Vision; some provider separation | Airplane-mode journey, strict media permissions, retention and delete/revocation, privacy notice, explicit recording/Health/data handling tests | CODE / TEST UNKNOWN |
| Accessibility + iPad | Contrast/design tokens and some accessibility labels, Reduce Motion in Learn | Full VoiceOver traversal, large type/dynamic layout, one-handed reach, Reduce Motion across stage, physical iPad portrait/landscape test | PARTIAL / IPAD UNAVAILABLE |
| Brand / media / license | SWAY design language and licensed rig provenance; private visual references | Final product art signoff, license chain for all redistributed meshes/textures/music, family/owner reference consent and commercial brand clearance | PARTIAL |
| Official online community / marketplace | Informational “Coming to SWAY” (honest roadmap) | Optional secured backend, identity, validated upload, discovery, moderation, takedown/delete and rights; no false claim of public service | DEFERRED-OFFICIAL |
| Full five-coach final cast | Contract declares Lucia/Nandi/Thabo/Zuri/Kyle; Alpha root lineup currently Lucia only | One professional actor pipeline; individually accept full five character models/expressions with shared 23-bone 21-clip choreography, distinct personalities; beta/final gates | FINAL GAP |

## 4 · Fresh technical evidence — actual tests on 2026-10-22

- Core Python regression discovery: **86 tests, 0 failures, 1 skipped** (do not call the skipped test PASS).
- Application contract suite: **7/7 PASS**.
- Shared Swift/Python movement parity: **12,610 samples; 13 joints + heading; max error 0**.
- Native ARM64 `SWAYcoreEngine` Swift tests: **31/31 PASS**, 0 failures.
- Xcode 27: `SWAY` generic iOS Simulator-target unsigned **BUILD PASS**; no executable simulator runtime installed, no simulator session performed.
- Protected native modular Blender candidate: **44/44 topology PASS**, **44/44 geometric uniqueness PASS**.
- Current Blender full-scene validator: **PASS**, 42,955 triangles and height 1.7449 m; its previous hidden-mesh 196 m result is resolved in the current source; `visualQuality` still UNREVIEWED.
- Real macOS RealityKit imports **44 independent skinned modules and 21/21 common clips; 11 active**; animation seek delta 0.0. USD payload 5,742,296 bytes, source macOS base import 1.220 s, observed peak RSS approx 334 MB in test. These are not iOS performance acceptance metrics.
- Apple devices: paired iPhone 15 Pro Max is available but **not installed/launched**; iPad device currently unavailable; installed iOS Simulator runtime unavailable.
- Both app character manifests remain `runtimeApproved:false`; **LKG NONE**; no built app released or published by this assessment.

## 5 · Engineering execution: retain FULL scope, stage acceptance

**G0 — Protect current truth and working source.** Preserve single R2 source and the single proven archive; reconcile current local modification and stale private GitHub branch via read-only manifest, then request separate write authorization for remote source persistence. Refresh the one backup only with complete archive integrity/restore gate; preserve the rollback baseline. No cleanup, local Git clone or hidden cloud upload.

**G1 — One human-approved production character.** Pick one representative user/coach design from approved references (private Thembi/Lucas avatar previews via MEMOJIME/APELLES/ARTEMIS as appropriate, consent-controlled external generation). DÜRER fixes garment shell, neckline, seams, materials, expressions, 23-joint rig, extreme pose and 8-heading continuity using Blender—not body-sliced clothes or rejected PNG puppets. Acceptance: licensed editable source, realistic proportions/scale, clean topology and front/side/back/extreme animation renders approved by owner. New clean asset must work for both production character and creator architecture; no need for a different engine.

**G2 — Integrated REAL production character on-device.** ForgeGAME verifies the 21 clips, binding, joints, foot contacts and 12-active model cap. ForgeAPPLE packages the actually accepted USDs through the existing `SWAYAvatarManifestLoader` and validates selected options/materials/profile-change cancellation/failure rollback and memory/thermals in the real app. Do not flip `runtimeApproved` based on Mac tests. Lucia and YOUR DANCER remain distinct roles; tracked YOU remains graphical live input. No fallbacks masquerading as production.

**G3 — End-to-end offline consumer acceptance.** Demonstrate a complete device-visible first launch → onboarding → Beats offline → Moves count-by-count Learn → Quick Dance → pause/restart → Results/mastery → relaunch and persisted profile. One canonical choreography/music clock must agree throughout. Capture screen and log evidence, not a test-count summary.

**G4 — Integration and quality breadth.** Test 6-stage calibration and actual Vision camera tracking, exact-scored and UNKNOWN/denied/lost flows; physical music local and MusicKit Shazam fallbacks; ReplayKit Record Me/SWAY end to end; HealthKit records; Create → save → .swaypack round-trip; accessibility, offline/permission failures, iPad portrait/landscape. Introduce tested honest nearby/SharePlay transport for consumer duo if claimed. Physically pair and test two consenting devices; six-person Household and professional Master have separate identity/entitlement gates.

**G5 — Full final native product.** Five instructors with individually approved movement/art, full creator, full movement/style/mode library, mastery/programs/challenges, all declared session/share/privacy/accessibility behavior and device qualification. Public optional Community/backend, monetization, rights, moderation and StoreKit are gated separately for official distribution; do not confuse a private functional Alpha with official release readiness.

**Promotion rule:** production visual approval, integrated app playback and UI, offline/denial/error journeys, real device tests, rebuilt package and rollback are all required; **LKG stays NONE** until accepted. A test/migration/compilation PASS never completes the full product.

## 6 · Ownership, tools and rejected detours

- **CONDUCTOR:** cross-workstream orchestration and continuity; **ForgeMASTER:** AppDev implementation, evidence reconciliation and release governor.
- **ForgeGAME:** movement/animation/tempo/scene/performance architecture and acceptance; **ForgeAPPLE:** Swift/RealityKit/Apple APIs, actual iPhone/iPad physical verification; **APPLE Product & Engineering:** interface design and usability.
- **DÜRER:** editable 3D geometry, rig, topology, clothing and skeleton; **ARTEMIS/APELLES/MEMOJIME:** reference/image/art production and provenance; **AI TOOLKIT:** existing model-provider selection; optional Pixlie character-sheet and to3D mesh tools only when an actual licensed rig-compatible benefit is verified.
- **WORKinCODEX / Claude / Gemini:** provider-neutral approved engineering handoffs; **BIFROSTcore:** approved connections, not a runtime dependency of offline consumer dancing.
- **DO NOT:** replace one functioning movement engine with per-character choreography; restart the discarded 2D puppet/cutout production pipeline; migrate to Unity or a different 3D stack without hard evidence; split SWAYZ/Kid Dancers/Studio into this product; start a new connector architecture; weaken failing visual/physical gates; invent LKG; install unfinished packages; send Thembi/Lucas private reference material to external providers without explicit consent.

## 7 · Immediate proposed next action (only one critical path)

**Do G0 and G1 in that order, then test G2 in the actual app.** Specifically: keep the verified, unweakened 1.7449 m Blender height/rig validator; repair neckline, clean fitted garment and localized expressive face on the protected isolated candidate; review front/side/back/extreme frames, then make precisely one authorized, visibly accepted RealityKit resource integration for the native app. Reuse the existing isolated 44/21 export and Swift tests. Keep secondary provider/client setup out of the critical SWAYcore path.

**End of assessment.** The existence of this plan records a real scope/gap assessment only; it is NOT implementation of the missing product capabilities, an amended Product Bible, a release, or a backup verification.
