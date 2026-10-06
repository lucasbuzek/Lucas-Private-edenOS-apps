# R2 resumed execution receipt — 2026-10-06

This receipt supersedes the earlier Blender-unavailable state. Active source is the existing R2 under the canonical workspace; original Downloads and recovered family sources remain recovery evidence. No historical LKG, app-resource promotion, package or Alpha completion.

## Implemented repairs

- Corrected native elbows/knees to `LowerArm.L/R` and `Tibia.L/R`, distinct from their distal helpers; Root/Sacrum and Hips/Sacrum.001 remain separate. Exact source rest endpoints and roll are protected by executed Blender checks.
- Replaced incompatible local-offset transfer with world-space orientation transfer. Muted only the two proven legacy calf parent-copy constraints that doubled knee rotation. Native helpers, finger chains, skin and rest geometry remain.
- Used Blender native IK on temporary connected full-span limb controls, calibrated pole angles separately per limb, and baked rotations back onto the original rest rig. Rejected disconnected-chain and flat-displacement trials remain preserved.
- Corrected meter-to-native translation and applied whole-body motion through Root because native spine and pelvis are sibling branches. Added per-frame pelvis, projected arm, symmetric elbow/hand, wrist and ankle checks without lowering deformation thresholds.
- Restored original CC0 body/face/eye textures, a single portable Principled output per source material, and original hair colour. Applied the existing R2 Lucia attire palette on native surface faces. Appearance is UNREVIEWED.
- Attached the previously static eye meshes to their existing native eye bones through rigid one-influence skinning. This preserves original rest geometry and includes both eyes in skeletal export.
- Export now clones the actual native skinning skeleton with canonical mapped names plus native helper bones, rather than exporting the unskinned driver. Bakes native non-skin modifiers on isolated copies; retains weights/UVs. Blender 5.2 texture-export options are queried correctly. No scene-world texture export.
- Added binary OpenUSD checks for skeleton/mesh bindings, canonical joints, unchanged hierarchy across clips, <=4 normalized influences, >=18 body coverage, texture references and musical duration. Added every-frame native-vs-USD joint comparison and clean-scene USD reimport renders. Three labelled corrupt fixtures prove rejection.
- Repaired the actual app resource route: it excluded factory `.usdc` files and flattened character animation paths. A shared Foundation locator resolves base/clip resources by character folder and supported USD extensions, and the renderer loads the resolved URL. Approval is required in both stage selection and renderer load; no unapproved candidate enters the product route. Regression first failed for the missing resolver, then passed against an actual nested fixture Bundle.

## Current concrete candidate

`eye_verified/candidate.blend` is the latest source candidate; `eye_verified/motion.json` and `structural.json` are its receipts. Its 244 front/side representative/extreme renders cover all 21 clips; 21 contact sheets are under `eye_verified/contact_sheets/`.

`runtime_verified/Lucia/` is an unapproved isolated binary USD export of that candidate. `usd_contract.json` verifies 22 actual binary stages with five skinned meshes, 65 exported deform/helper joints and 60 weighted body bones. `usd_motion.json` compares every mapped joint at every exported frame: worst error 0.000502324 m against a 0.001 m gate. `roundtrip/` contains five exported clip imports and rendered evidence; this is Blender/OpenUSD evidence, not RealityKit.

Structural: height 1.68 m, 7,040 triangles (including recovered eyes), 8 materials, 5 packed images; p99 edge growth 0.0135 m and gross growth 0.1114 m pass unchanged deformation gates. All-frame transfer/canonical numerical gates PASS. Human visual gate UNKNOWN and `runtimeApproved:false`, `visualQuality:UNREVIEWED` remain.

Agent inspection of all 21 contact sheets found repaired limbs/material continuity, but shallow squat/lunge and limited turn/body-roll readability remain concerns. Source `SwayCoachPoseEngine` encodes these as 2D displacements; numerical agreement cannot certify correct dance instruction. Do not integrate or ask to promote this candidate as visually passed.

## Capability evidence matrix

| Alpha capability | Functional state | Current evidence / remaining gate |
|---|---|---|
| Lucia instructor | FAIL | Numerical native/export gates PASS; production visual/motion and real-app integration unpassed. |
| YOUR DANCER chain | FAIL | Actual profile serialization/reload PASS; creator scroll/persistence repaired. Active atlas ignores body, face, hairstyle, footwear and accessory choices. Recovered v2 is a different contract, not a drop-in asset. |
| Graphical YOU / six-action calibration | UNKNOWN | Existing graphical camera path and canonical machine retained; physical tracking/loss/reacquisition not executed. |
| Moves/Learn | UNKNOWN | Authored library and deterministic timing protected; full Learn/tempo/pause UI journey unexecuted. |
| Beats/Music | UNKNOWN | Existing offline/native paths retained; audible/common-clock integrated gate unexecuted. |
| Create Move / swaypack | UNKNOWN | Actual Foundation export/import/edit/reshare and duplicate rejection PASS; UI/library/native share gate unknown. |
| Follow-along workout | UNKNOWN | Existing synchronisation/matching/calibration retained; integrated native journey unknown. |
| Record SWAY | UNKNOWN | Actual unchanged callback recorder typechecks against iOS27 SDK; capture/native preview/save/share unknown. |
| Results/mastery/next action | UNKNOWN | Existing source retained; integrated scoring/results flow unexecuted. |
| Profile/Health | UNKNOWN | HealthKit entitlement and actual model persistence repaired/checked; permission/denial/relaunch/device gate unknown. |
| Offline journey | UNKNOWN | Local paths retained; end-to-end offline journey unexecuted. |
| Adaptive iPhone/iPad | UNKNOWN | Creator scrolling repaired; actual portrait/landscape runtime layouts unexecuted. |
| Package/physical | UNKNOWN | No package generated while integrated gates fail. Device query timed out; no simulator evidence substituted. |

## Executed regression and environment

- AssetFactory: 46 Python tests PASS, with labelled negative validator fixtures.
- Product/protected/builder regressions: 58 Python tests PASS (`product_regression.log`). Historical defect reproduction output is explicitly a received-candidate fixture, not current engine failure.
- Deterministic App runner: 7/7 functions PASS (`app_contracts.log`), not unittest zero discovery.
- Actual native rest, hidden skin data-API and portable source-material Blender fixtures PASS.
- Actual binary USD contract: 22 stages PASS; every-frame USD/native comparison: 21 clips PASS; isolated corrupt USD fixtures 3/3 correctly rejected.
- Actual recorder SDK typecheck, actual extracted manifest boundary and Foundation model lifecycle PASS within their narrow scopes; native UI/runtime not certified.
- Actual updated resource locator + RealityKit renderer typecheck against iPhoneOS27 SDK PASS (`avatar_sdk.log`); no SwiftUI view macro removal or full-app claim. Actual fixture Bundle USDC base/clip resolution and cross-character rejection PASS (`avatar_contract.log`).
- Python compilation and changed builder shell syntax PASS.
- Installed-compiler native XCTest: 31/31 existing core methods PASS, zero failures (`core_direct_xctest.log`). Test copies add Objective-C discovery metadata; assertion bodies and production source are unchanged. This verifies core behaviour, not SwiftPM packaging or app integration.
- SwiftPM rerun attempted with explicit cache and environment cache paths. Cache relocation resolved the first problem; nested `sandbox_apply: Operation not permitted` prevents package execution. Requested escalation rejected with `approval request failed`, no further reason. Prior SwiftPM receipt is historical to this run. Direct compiler XCTest receipt, if present, is a separate test route, not SwiftPM packaging.
- Installed Xcode 27.0 / 27A266a observed. Device service query timed out after 10 seconds. Current whole-app build, device connectivity, install and playback remain UNKNOWN.

## Exact source changes and operations

AssetFactory: `data/retarget_map_girush.json`; `blender/sway_add_native_driver.py`, `sway_limit_native_weights.py`, `sway_bake_clips.py`, `sway_bake_native_ik.py`, `sway_restore_girush_materials.py`, `sway_apply_native_attire.py`, `sway_inspect_motion.py`, `sway_export_runtime.py`, `sway_verify_runtime_usd.py`, `sway_verify_usd_motion.py`, `sway_render_usd_roundtrip.py`; `python/retarget_math.py`, `motion_evidence.py`; tests `test_girush_map_contract.py`, `test_native_proportions.py`, `test_motion_evidence.py`, `blender_native_rest_contract.py`, `blender_hidden_native_skin.py`, `blender_material_contract.py`, `blender_usd_negative_contract.py`.

App: `App/SWAY/Avatar/SWAYAvatarRendering.swift`; actual fixture-bundle regression in `Tools/regression/avatar_contract_regression.swift`; native API check `Tools/regression/check_avatar_sdk.py`.

Builders: `BUILD_LUCIA_CANDIDATE.command`, `EXPORT_LUCIA_RUNTIME_CANDIDATE.command`, exception exit-code protection in `BUILD_ASSETS.command`, `INSPECT_LUCIA_MOTION.command`, `REPAIR_NATIVE_SKIN.command`. `BUILD_ASSETS.command` now routes registered Girush to the native candidate pipeline and explicitly reports YOUR DANCER/native integration unpassed, instead of running the incompatible generic UE adapter or cloning Lucia. `RUN_R2_REGRESSION.command` includes the separate installed-compiler existing-core test runner `Tools/regression/run_core_xctest.py` and actual avatar SDK check; SwiftPM failure is never relabelled PASS.

Reproduce from R2: `./BUILD_LUCIA_CANDIDATE.command` creates fresh isolated staged native candidate evidence; `./EXPORT_LUCIA_RUNTIME_CANDIDATE.command <candidate.blend>` exports/verifies/reimports an isolated unapproved candidate. Neither builder changes app resources or approves an asset. Use `--python-exit-code 3` on direct Blender scripts to prevent Python exceptions returning false-success exit0.

## Next gates / physical connection

Continue native motion/readability repair and YOUR DANCER visible variants while resolving native build environment. Human rendered visual review is required before Lucia integration. iPhone 15 Pro Max connection is required when the approved asset and native app build are ready to install for the six-action camera/calibration, tracking loss/reacquisition, synchronised workout, recording/Photos/share and Health journey. No phone is required for current Blender/source repairs. A real iPad is required for the physical iPad adaptive gate; no ownership or current connection is assumed.

Preserve all failed derivative receipts and original sources. `RESEARCH.md` records primary references, licensing and rejected approaches. No engine extraction before product proof, no Alpha package until integrated gates, no R2 LKG until full promotion contract.
