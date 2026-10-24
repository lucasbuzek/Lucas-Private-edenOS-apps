# SWAYcore R2 Avatar Production Receipt — 2026-10-06

## Pinned contract

PROJECT=SWAYcore; PRODUCT=Dance & Fitness; MILESTONE=complete production-UI Alpha.
Build 143 graphical/runtime and Build 147 tracking remain protected recovery references; Build 148 remains rejected. This change is a Build 153-lineage remediation successor, not an LKG. Coaches are Lucia, Nandi, Thabo, Zuri and Kyle; targets are iPhone plus iPad portrait/landscape. Primitive mannequins, raw skeletons, static PNG/cutouts and 2.5D placeholders are prohibited final fallbacks. GENERATED != IMPLEMENTED != BUILT != TESTED != VERIFIED != RELEASED; UNKNOWN != PASS.

## Implemented in this change

- **PASS (source + tests):** one registry describes Lucia, Nandi, Thabo, Zuri, Kyle and YOUR DANCER on `SWAYHumanoid-v1`; bundle lookup is registry-driven.
- **PASS (source + tests):** the YOUR DANCER resolver changes visible meshes, material parameters or articulated-root transforms for all 18 production 3D profile fields. `portraitData` remains private input-only data and is deliberately never mapped to a texture/cutout.
- **PASS (source + tests):** the AssetFactory modular contract and RealityKit resolver share exact `YD_*` names for body, face, facial features, hair, top/bottom, shoes and accessories, plus material and scale parameters.
- **PASS (source + tests):** the Blender authoring/export path derives modular skinned geometry from the recorded Girush CC0 source, retains the shared armature, exports hidden alternatives, embeds the module contract and rejects missing meshes/transform roots.
- **PASS (numeric source regression):** squat, side-lunge, body-roll and pivot-turn authority was made more readable; the Swift authority and Python bake port match at 9,700 samples with maximum error 0.

## Gate ledger

| Gate | Result | Evidence / reason |
|---|---|---|
| AssetFactory unit suite | **PASS** | 61 tests discovered and passed; zero-test discovery did not occur. |
| YOUR DANCER exhaustive option resolver | **PASS** | Every runtime field mutation changes the resolved mesh/material/transform set; invalid options fail closed. |
| Swift syntax parse | **PASS** | `swiftc -parse` accepted renderer, model and new XCTest source. |
| Historical avatar resource/rig boundary | **PASS** | Bundle fixture resolves nested base/clip resources without cross-character leakage and rejects v2/wrong joint names. |
| Swift-to-Blender movement authority port | **PASS** | 9,700 samples, all 13 joints plus heading, maximum error 0. |
| Current packaged runtime assets (`validate_runtime_assets`) | **FAIL** | Existing Lucia manifest has clip/timing omissions; existing UserAvatar has no packaged clip directory. Newly authored modules were not generated in this Linux environment. |
| Full `RUN_R2_REGRESSION` | **FAIL** | Portable asset/protected/builder/DeviceSupport/model/Swift gates pass, but the imported build-identity fixture is absent and Apple SDK/XCTest gates require Xcode. A pre-fix run also exposed and led to repair of the portable avatar-contract extractor. |
| Blender 5.2.2 authoring/export/deformation | **UNKNOWN** | `blender` is not installed in this cloud. No new `.blend`/USDC was generated and no prior receipt was relabelled. |
| Every-option and every-clip contact sheets | **UNKNOWN / UNREVIEWED** | Cannot render without Blender. Existing Oct 6 Lucia contact sheets predate the readability edits and are not evidence for them. |
| RealityKit iOS compile/runtime swaps | **UNKNOWN** | Linux has no Xcode/iOS SDK. Swift source parse is not an iOS build or runtime verification. |
| Simulator build and app XCTest | **UNKNOWN** | Must run on the Mac. Earlier runner-never-started evidence remains UNKNOWN. |
| Physical iPhone 15 Pro Max | **UNKNOWN** | No physical-device execution occurred. |
| Human visual quality | **UNREVIEWED** | Numeric/structural tests do not substitute for review. |
| LKG / release | **NOT PROMOTED** | Required build, visual, simulator and physical gates are not all PASS. |

## Exact Mac-only completion steps

Run from `SWAYcore/R2` on the Mac with Blender 5.2.2 and full Xcode selected.

1. Generate the modular, articulated YOUR DANCER source and runtime asset:
   ```bash
   blender --background --factory-startup \
     Build/resume/20261006/eye_verified/attire.blend \
     --python-exit-code 3 \
     --python AssetFactory/blender/sway_author_yourdancer.py -- \
     --contract AssetFactory/data/your_dancer_modules.json \
     --out Build/avatars/20261006/yourdancer.blend
   ```
   Follow with the existing bake/export pipeline, passing
   `--modules AssetFactory/data/your_dancer_modules.json` to `sway_export_runtime.py`.
   Copy only gate-passing output into `App/SWAY/Resources/Characters/UserAvatar`, then run:
   ```bash
   python3 AssetFactory/python/validate_runtime_assets.py \
     App/SWAY/Resources/Characters AssetFactory/data/clip_manifest.json \
     --require Lucia,UserAvatar --only-required
   ```
2. Re-bake Lucia readability from the preserved attire stage, without changing deformation thresholds:
   ```bash
   blender --background --factory-startup \
     Build/resume/20261006/eye_verified/attire.blend \
     --python-exit-code 3 \
     --python AssetFactory/blender/sway_bake_clips.py -- \
     --clips AssetFactory/data/clip_manifest.json \
     --out-blend Build/resume/20261006/readability/authored.blend
   ```
   Run `sway_bake_native_ik.py`, `sway_validate_character.py`, `sway_inspect_motion.py`, runtime USD export and native-vs-USD every-frame comparison. Render front/side contact sheets for every one of the 21 clips and every YOUR DANCER option. Record human review; until then `visualQuality` stays `UNREVIEWED` and `runtimeApproved` stays false.
3. Run non-device gates:
   ```bash
   ./REPAIR_NATIVE_SKIN.command
   ./RUN_R2_REGRESSION.command
   ./VERIFY_ALL.command
   (cd Packages/SWAYcoreEngine && swift test)
   ```
4. Build for the iOS Simulator (the internal target remains SWAY):
   ```bash
   cd App
   xcodebuild -project SWAY.xcodeproj -scheme SWAY -configuration Debug \
     -destination 'platform=iOS Simulator,name=iPhone 15 Pro Max' \
     CODE_SIGNING_ALLOWED=NO build
   xcodebuild -project SWAY.xcodeproj -scheme SWAY \
     -destination 'platform=iOS Simulator,name=iPhone 15 Pro Max' test
   ```
   Zero executed tests is **FAIL**. Exercise Create Avatar and capture screenshots proving each option visibly changes the articulated mesh/material/accessory while a clip plays.
5. Connect and unlock the owned physical iPhone 15 Pro Max, then run:
   ```bash
   ./BUILD_DANCE_FITNESS.command
   ```
   Complete `Docs/PHYSICAL_DEVICE_CHECKLIST.md` and `App/PHYSICAL_TEST_MATRIX.md`, including persistence/relaunch, calibration in the exact canonical order, tracking loss/reacquisition and MATCH / NOT MATCHED / UNKNOWN truth. Do not promote an LKG unless every required gate is observed PASS.
