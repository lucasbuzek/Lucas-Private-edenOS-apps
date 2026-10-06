# CLAUDE START HERE — SWAYcore MASTER RECOVERY / COMPLETION HANDOFF

Date: 2026-10-04

You are receiving a cold-start engineering handoff. Assume NO access to prior ChatGPT conversations or files outside this package. Inspect this package before asking Lucas for history.

## Mission
Recover, repair and complete the reusable SWAYcore movement engine and the first full product, SWAYcore Dance & Fitness. Deliver one cumulative corrected package buildable from one click, with editable Blender sources/assets, tests and evidence. Do not return only advice or patches.

## Authority order
1. Authority/PRODUCT_BIBLE.md + REQUIREMENTS_MATRIX.md
2. Authority/EVIDENCE_LEDGER.md + MODEL_AND_BLENDER_RESEARCH_BRIEF.md + CLAUDE_RETURN_CONTRACT.md
3. current-candidate/ = implementation candidate, not automatically accepted
4. LKG-reference-BUILD143/ = protected graphical/runtime recovery reference
5. RecoveryEvidence/ = evidence only; never silently promote rejected/historical material

GENERATED != IMPLEMENTED != BUILT != TESTED != VERIFIED != RELEASED. UNKNOWN != PASS. Preserve LKG before changes.

## Product canon
SWAYcore is reusable engine; Dance & Fitness is immediate app. Navigation: HOME · MOVES · BEATS · PROFILE. Core loop: WATCH -> COPY -> MATCH -> COMBO -> SCORE -> UNLOCK -> DANCE. Content: Move -> Variation -> Combination -> Routine -> Workout -> Challenge -> Program. Mastery: Discovered -> Learning -> Familiar -> Mastered.

One movement definition drives Learn, Workout and scoring. One musical timeline drives beat/downbeat/bar/phrase/count/move/repetition, COACH animation/cues, expected YOU and scoring.

Required production surfaces: Home, Moves, Move Detail, Learn, Practice, Create, Beats, Setup, Calibration, Workout, Results, Profile. iPhone+iPad, portrait+landscape. No final placeholders.

Calibration EXACTLY: STEP INTO VIEW -> WAVE LEFT -> WAVE RIGHT -> LIFT LEFT FOOT -> LIFT RIGHT FOOT -> JUMP -> READY TO SWAY. Tracking optional/on-device. In tracked Workout, YOU is a live graphical/translucent silhouette; Vision skeleton is diagnostic only. Tracking loss must not stop COACH.

Lucia is Alpha instructor; architecture supports Lucia/Nandi/Thabo/Zuri/Kyle. YOUR DANCER is persistent customizable identity, distinct from tracked YOU. SWAYHumanoid-v1 = 23 joints. Build153 avatar visuals are rejected. Target polished stylized human, only slightly Memoji-inspired, expressive, strong silhouette, not photorealistic. Static cutouts/cropped fragments/primitive mannequins rejected.

Preserve generated/local/Apple Music Beats, analysis, appropriate Shazam preflight/alignment, Create/save/library, .swaypack, Record Me/Record SWAY, Health, progress/mastery, accessibility, local persistence and offline/local-first core.

## Recovery truth
Build143 graphical/runtime reference. Build147 tracking protected where recovered. Build148 rejected. Build149 working recovery baseline. Build153 protected stepping-stone: useful 23-joint rig/clip/binding evidence and physical build/install/launch evidence, but rejected avatar visuals and NOT final authority. Never regress protected behavior merely to compile.

Xcode/device incident: Xcode 27 / Swift 6.4 era DeviceSupport repeatedly created incomplete .tmp + .copying_lock extraction and very large disk use around dyld shared-cache copying. Cleanup happened; root cause remains UNKNOWN. Preserve signing unless evidence requires change.

## Engineering mandate
Inventory all Swift, project config, entitlements, tests, Python, shell, Blender and assets. Establish demonstrated state. Compile/static-audit syntax, unresolved symbols, API/concurrency/lifecycle/target membership/resources/orientation/entitlements/deployment settings. Investigate historical undefined `tt` and Studio membership/lifecycle failures only where evidence applies.

Make coherent reusable SWAYcore boundaries for movement/library; musical timeline; pose/tracking; calibration; scoring/matching; choreography/session; progression/mastery; Beats/audio; persistence/share packs; recording; Health; avatar/assets. Dance & Fitness consumes these boundaries rather than duplicating them.

Regression-test movement truth, musical timeline, exact calibration state machine, tracking loss, scoring determinism, persistence, .swaypack, Beats source switching, denied permissions, resource loading and adaptive layouts. Produce a physical test matrix for camera/tracking, MusicKit, HealthKit, recording, sharing, orientation and offline use. Never claim physical PASS without device evidence.

## Blender / asset factory
Use Blender 5.2.2 LTS-compatible automation. Blender owns geometry/topology/rig/skinning/deformation/source animation; RealityKit owns runtime. First evaluate existing suitable rigged/base humanoids. Every external candidate needs exact source/license, modification+redistribution+app-distribution rights, topology/deformation notes, 23-joint conversion effort, mobile suitability and Lucia suitability. Unclear licensing = reject.

Create editable .blend masters plus deterministic scripts for canonical 23-joint rig, production Lucia, reusable instructor base, YOUR DANCER customization base, materials/textures, expression where practical, LOD/mobile optimization, retargeting, validation and USD/USDZ export. Preserve/validate Build153 proof motions: idle, march, step touch, grapevine, knee lift, squat, side lunge, jumping jack, body roll, pivot turn; then expand to required product movement content. Ten clips are proof, not ceiling.

Validation rejects missing/duplicate joints, invalid hierarchy, broken weights, non-finite transforms, absent clips, wrong scale/orientation, excessive mobile footprint, missing provenance/license metadata and placeholder geometry.

## Research / references
Research current official Apple docs/samples and suitable open-source projects for Vision 2D/3D body pose, RealityKit/USD animation, MusicKit, ShazamKit, AVFoundation, HealthKit, SwiftUI adaptive layout, local persistence/document packages/sharing and testable state machines. Study Apple Fitness+, Just Dance, Dance Reality, STEEZY, Peloton/Nike Training Club-like progression for interaction ideas only. Do not copy proprietary code/assets.

For each external code/model/library candidate record source, exact license, solved problem, legal incorporation status, maintenance/current-platform status, dependency cost, offline behavior and adopt/adapt/reject decision. Prefer Apple-native -> installed tool -> small maintained library -> custom code. Avoid bloat.

## One-click builders
Return executable:
- BUILD_SWAYCORE_ENGINE.command
- BUILD_DANCE_FITNESS.command
- BUILD_ASSETS.command
- VERIFY_ALL.command
- BUILD_ALL.command

BUILD_ALL must robustly locate root; preflight macOS/architecture/free disk; locate full Xcode and validate xcode-select; report Xcode/Swift/SDK; verify Homebrew; fetch only missing appropriate dependencies including XcodeGen/Blender; never blindly reinstall heavy tools; preserve/validate signing; validate/generate assets; run Python/shell tests; deterministically regenerate Xcode project when project.yml is authority; run Swift/Xcode tests; build simulator and device candidate when available; package; emit SHA-256 and evidence report.

Every failure reports STAGE / ACTION / RESULT / ERROR / IMPACT / NEXT ACTION. Repairable failure is not a blocker. Detect low disk and repeated/incomplete DeviceSupport extraction. Never recursively delete unrelated Xcode/user data.

## Pipeline
REFERENCE -> BASELINE -> IMPLEMENT -> STATIC VERIFY -> ENVIRONMENT VERIFY -> REGRESSION VERIFY -> PACKAGE -> PACKAGE VERIFY -> PHYSICAL GATE -> PROMOTE. Retry must change something. Preserve LKG. Build success alone does not prove behavior; simulator success does not prove device-only APIs.

## Required return
ONE cumulative ZIP: corrected engine source; complete Dance & Fitness source; project config; tests; editable Blender sources/scripts; distributable runtime assets; five one-click entry points; dependency/preflight logic; external reference/license ledger; manifests/checksums; implementation/regression/unresolved reports; physical-test checklist; exact build/run instructions. Unpack your own returned ZIP into a clean temp directory and verify that copy. Anything not executed is UNKNOWN, not PASS.
