# ForgeMASTER → Codex Handoff — SWAYcore Dance & Fitness R2

## WORKinCODEX
You are the implementation engineer. Work in the existing R2 project. Inspect first; do not restart, redesign, simplify, port, or replace demonstrated functionality. Reuse → integrate → repair → extend → create last.

## Authority
Priority: current handoff → AppDevRules/ForgeMASTER rules → SWAYcore Project Bible/canon → current R2 source → verified evidence → bounded historical recovery evidence.
Canon determines what should exist. Evidence determines what does exist. UNKNOWN != PASS.

Primary product now: **SWAYcore Dance & Fitness**. Build and verify the complete Dance & Fitness Alpha first. SWAYcore Engine is derived afterward from reusable capabilities proven in the product; engine extraction must not block Alpha.

There is **NO historical LKG**. Builds 143/147/149/151/152/153 are bounded capability/source/evidence references only; Build 148 is rejected. R2 is the first candidate eligible to become a genuine LKG when all Alpha capabilities coexist and pass integrated + physical regression.

## Working source
Current R2 tree: `/Users/lucas/Downloads/SWAYcore-R2-0.1.0`
Do not treat Downloads as permanent canonical storage. Work on the existing R2 tree now; preserve recovery evidence and prepare eventual canonical/Git consolidation rather than inventing another tree.

Read before changes:
- `Build/dance_fitness/R2_DANCE_FITNESS_EXECUTION.md`
- `Build/consolidation/R2_ALPHA_CAPABILITY_CONTRACT.md`
- `App/CAPABILITY_LEDGER.md`
- `App/REGRESSION_CONTRACT.md`
- `App/PRODUCT_SPECIFICATION.md`
- `App/PHYSICAL_TEST_MATRIX.md`
- AssetFactory docs/tests/contracts
- current Swift source and tests

## Alpha scope
Alpha characters: **Lucia + YOUR DANCER only**. Nandi/Thabo/Zuri/Kyle are Beta and must not block Alpha.
`YOU` is separate: live camera-derived graphical user representation during workouts, not YOUR DANCER and not a diagnostic skeleton.

Required product capability set must coexist:
1. Lucia production instructor in real app.
2. YOUR DANCER create/customize/persist/reload/movement-preview/runtime-use.
3. Graphical YOU + camera tracking + six-action calibration + tracking loss/reacquisition.
4. Moves/Learn with authored move library, instructions/counts, user tempo and pause/no-drift behavior.
5. Beats/Music: offline Generated Beat plus established Apple Music/analysis paths; one musical clock.
6. Create Move + save/library/Learn + `.swaypack` import/export/edit/reshare.
7. Follow-Along/workout with synchronized COACH/YOU/music/count/cues/scoring.
8. Record SWAY + native preview/save/share.
9. Results/mastery/next action.
10. Profile/Health permissions + denied states + persistence/relaunch.
11. Offline/local-first journey.
12. iPhone + iPad portrait/landscape adaptive UI.
13. Package verification + physical gates.

Six-action calibration canon:
STEP INTO VIEW → WAVE LEFT → WAVE RIGHT → LIFT LEFT FOOT → LIFT RIGHT FOOT → JUMP → READY TO SWAY.

Single-clock invariant:
audio → beat/count → movement → COACH → visual/spoken cues → YOU → scoring.

## Current Lucia truth — do not hallucinate PASS
Accepted for Alpha: slim anime-influenced Girush CC0 source/silhouette. Refinement can occur after functional Alpha.
Known source: repaired Girush candidate under `Build/experiments/girush_sway_alpha_repaired/`.

A concrete retarget defect was just found: `Root` and `Hips` both mapped to `Sacrum`. Actual inspected source hierarchy proves `Sacrum` is root and `Sacrum.001` is pelvis/leg-chain child. Mapping was corrected and protected by `AssetFactory/tests/test_girush_map_contract.py`.

After that correction a fresh Lucia rebuild produced:
- native driver created
- 21 clips baked
- structural validator PASS
- height 1.68 m
- triangles 6432
- materials 5
- textures 2
- p99 edge growth 0.0052 m

But **STRUCTURAL PASS IS NOT VISUAL/MOTION PASS**. The previous candidate also passed structural checks while rendered anatomy was visibly broken: bad arms/hands/wrists/elbows/shoulders, implausible pose, foot problems and missing/washed-out materials. Do not promote Lucia until actual rendered motion passes.

Immediate Lucia task:
1. Inspect current corrected blend and all 21 baked clips.
2. Render representative/extreme frames for every clip, not only neutral.
3. Compare accepted rest/source anatomy → intended SWAY pose → rendered 3D pose.
4. Repair retarget orientation/anatomical correctness. Preserve native Girush skinning/twist/helper chains where appropriate.
5. Repair actual runtime materials/textures/face/body appearance.
6. Add automated anatomical/pose regression: joint orientation/angle sanity, left/right continuity, wrist/hand orientation, ankle/foot orientation, attachment/continuity, canonical-pose comparison. Do not weaken deformation gates.
7. Add rendered visual regression evidence. Human visual gate remains required.
8. Only then integrate Lucia into real Dance & Fitness resources and verify RealityKit playback.

## Existing-solution research mandate
Before inventing or repeatedly patching custom subsystems, research proven implementations and use suitable existing/native/open-source approaches. SWAY canon remains product authority.
For Lucia/animation specifically evaluate established Blender retarget workflows, Rigify/constraint approaches, glTF/VRM tooling and proven humanoid-retarget techniques. Determine whether the custom retargeter should survive at all. Prefer a proven path if it preserves the Girush rig and correctly transfers SWAY's 21 motions.
For other capabilities prefer Apple Vision/body pose, HealthKit, MusicKit, ShazamKit, AVFoundation/ReplayKit/Photos/share mechanisms and established algorithms/libraries where compatible with licensing, privacy, offline/local-first and deployment constraints.
Record sources, licences, rationale and rejected alternatives. Do not copy incompatible code/licences.

## Evidence rules
Evidence pipeline: AUTHORITY → REFERENCE → BASELINE/RECOVERY EVIDENCE → IMPLEMENT → STATIC VERIFY → ENVIRONMENT VERIFY → REGRESSION → PACKAGE → PACKAGE VERIFY → PHYSICAL GATE → PROMOTE.
Generated != implemented != built != tested != verified != released.
Build PASS != functional PASS. Simulator != physical device. Structural asset PASS != visual PASS. UNKNOWN != PASS.
A failed gate is evidence, not automatically a blocker. AUTO continues while safe repair/research work remains.
Never fix one capability by silently deleting/regressing another. Add regression protection as each capability is consolidated.

## Device truth
There is one physical target owned by the user: **physical iPhone 15 Pro Max**. Any `SWAYcore ...` simulator names are test infrastructure only and never physical evidence. Current physical availability to Xcode may change; if unavailable, mark physical gate UNKNOWN and continue all non-physical work.

## ForgeMASTER execution order
Execute autonomously; do not stop at a plan/report while implementable work remains.

A. Recover/inspect the complete existing Dance & Fitness implementation and tests. Build a capability-by-capability evidence matrix; historical builds are recovery sources, never wholesale baselines.
B. Fix Lucia correctly as above; strengthen validation; produce visual evidence; integrate only after gate passes.
C. Complete YOUR DANCER functional chain in the real app: creator UI → visible customization → persistence/reload → movement preview → actual use. Preserve established body/skin/hair/face/outfit/footwear/accessory choices where implemented.
D. Complete graphical YOU/tracking and canonical six-action calibration. Tracking loss must fade/guide/reacquire; do not expose developer skeleton as product UI.
E. Consolidate Moves/Learn + Beats/Music + workout around the single musical/movement clock. Pause freezes clock and character together; resume must not drift.
F. Verify/fix Create Move and `.swaypack` full lifecycle.
G. Verify/fix workout, Record SWAY, Results, Health, persistence, offline and adaptive layouts.
H. Run automated capability regression after every substantive repair, then integrated regression. Preserve evidence logs.
I. Generate/package Dance & Fitness only after integrated gates pass. Verify the delivered artifact from clean extraction/build inputs.
J. When physical iPhone 15 Pro Max is available, install and execute the established physical Alpha checklist. Do not substitute simulator evidence.
K. After capabilities are proven in Dance & Fitness, identify and extract genuinely reusable implementation into SWAYcore Engine without changing product behavior; rerun product regression after extraction.

## Test infrastructure corrections
Existing `App/Tests/test_full_feature_alpha_package.py` contains pytest-style functions; do not treat `unittest discover` reporting 0 tests as verification. Use the project's deterministic runner/current correct mechanism or convert tests cleanly without adding unnecessary dependencies.
AssetFactory negative-validator fixtures intentionally emit failure messages to prove rejection behavior; separate/labelling of negative-test output from production candidate evidence is required so recovery cannot misread fixture FAIL lines as candidate failures.

## UI/UX
Do not replace established final-product UI with debug dashboards, placeholders or generic developer controls. Navigation canon: HOME · MOVES · BEATS · PROFILE. Required production flows include Home/Moves/Learn/Beats/Setup/Calibration/Workout/Results/Profile. iPhone and iPad portrait/landscape are required. Alpha may use accepted Lucia art quality but functionality and readable movement are mandatory.

## Deliverables from this Codex run
Do not merely return recommendations. Modify the existing R2 implementation and leave:
- working source changes
- tests/regression guards
- research/reference/licensing notes where used
- evidence logs/reports
- current capability matrix with PASS/FAIL/UNKNOWN grounded in evidence
- updated one-click builders for required Blender/Xcode/asset/app operations
- clean package candidate only if its gates actually pass
- exact blockers only where an attempted action proves an unavailable dependency
- recovery instructions/checksums/manifests as applicable

At completion report: what changed, exact files, tests run/results, known failures, physical state, next gate. Never call R2 LKG until the full Alpha promotion contract passes.

## AUTO instruction
**Continue AUTO. WORKinCODEX.** Inspect, research, implement, test, repair, regress and package all safe available work until the complete SWAYcore Dance & Fitness Alpha milestone is reached or a genuine unavailable dependency blocks further safe work. A failure, incomplete stage, missing physical device, or known next action is not by itself a reason to stop; continue every independent safe task that remains.
