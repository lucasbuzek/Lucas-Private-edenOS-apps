# SWAYcore R2 — YOUR DANCER M1 (one simple working avatar)

Date: 2026-10-09 · Governor: ForgeMASTER · branch: `swaycore-one-avatar-20261009`.
Parent / evidence-preserving base: `fef51e2` (The Sims-inspired reference branch). Source remains private on Lucas-MacBook.

## Explicitly limited scope
Lucas directed **"Simple one is the first since we've been failing the avatar for 3 weeks."**
Deliver only ONE authentic neutral YOUR DANCER rig before advanced Sims-like customization or repairing five other coaches. This is a working original stylized 2.5D *prototype candidate*, NOT Sims-level final-quality art or a released Alpha.

## Implementation
- `AssetFactory/puppet/generate_simple_your_dancer.py` generates the 15 front rigid art parts; `generate_simple_your_dancer_views.py` generates an authored rear hairstyle and side profile, retargeting each part to back/side bone rest positions.
- 45 distinct original parts across front/back/side + three `yourDancer_*_rig.json` files in `App/SWAY/Resources/Puppets/YourDancerRig`. The SHA test proves none of these parts is the equivalent Kyle PNG. No third-party likeness/EA assets.
- Corrected neutral wrist/arm placements to keep actual anatomical negative space open, avoiding overlap loops without blurring/filling holes or weakening numerical thresholds.
- `SWAYPuppetRenderer.swift`: pass `angle.mirrored` to the existing rig Canvas to apply left/right heading mirroring (same fix previously identified in the isolated integration candidate).
- Existing `SWAYCharacterStage` signatures, coach/movement clock, Vision mapper, other characters, storage and app UI remain unchanged.
- `pose.py` and `check_puppet_rigs.py`: stopped reversing every back-view pose delta. The Swift runtime passes the **same skeleton** regardless of view; only authored art is switched. Prior inversion made crouches unrealistically cross limbs in back view. This is a reference/runtime parity fix, not relaxed hole or area thresholds.
- Six canonical motion checks: rest, arms out, arms up, point+knee, squat, lean+hip.

## Verified gates (evidence is on the Mac)
- `/private/tmp/SWAY_ONE_AVATAR_COMPLETE_GATE_20261009.log`: **18 PASS / 0 FAIL**: front 6/6, back 6/6, side 6/6, 45/45 corresponding Kyle images have different SHA-256. Source verifier `Tools/regression/check_first_avatar.py`.
- `/private/tmp/SWAY_ONE_AVATAR_FINAL_REGRESSION_20261009.log`: existing R2 regression **12 PASS / 0 FAIL / 2 UNKNOWN**. UNKNOWN: visual/on-device review and physical Alpha.
- `/private/tmp/SWAY_ONE_AVATAR_SIM_BUILD_20261009.log`: generated Xcode project; iOS Simulator `xcodebuild ... CODE_SIGNING_ALLOWED=NO build` exit 0. Build output: `/private/tmp/SWAY_ONE_AVATAR_DERIVED_20261009/Build/Products/Debug-iphonesimulator/SWAY.app`.
- `/private/tmp/SWAY_ONE_AVATAR_BUNDLE_VERIFY_20261009.log`: 45 bundled Apple-optimized CgBI PNGs decoded via Xcode `pngcrush -revert-iphone-optimizations`; alpha identical and composited RGB difference at most 1/255 from original source; 3 rig JSONs byte-exact. These optimized PNGs do NOT have byte-for-byte identical SHA to source, by design.
- Three six-pose contact sheets: `AssetFactory/puppet/evidence/yourDancer_one_avatar_{front,back,side}_6_poses_20261009.png`.

## Environment and outstanding gates
- Mac: Homebrew Python 3.14, NumPy/SciPy/Pillow and Xcode toolchain available.
- `xcrun simctl list devices available` reported iOS 27 runtime **unavailable**: no live Simulator journey or screenshot accepted. A *generic simulator build* is not live simulation.
- Physical iPhone/iPad, tracking visual/readability, thermal/performance and user acceptance remain **UNKNOWN**. No release, LKG promotion, or unattended push.
- No actual multi-option skin/hair/body/clothes customization in M1. The pre-existing catalog still enables one option per category; genuine custom choices await the next milestone. No misleading UI count was added.
- Five instructor rigs remain unaccepted by the full `check_puppet_rigs.py` gate. The scoped M1 test does **not** claim these other rigs pass.

## Repeat on Lucas-MacBook
From `SWAYcore/R2`:
```bash
/opt/homebrew/bin/python3.14 AssetFactory/puppet/generate_simple_your_dancer.py
/opt/homebrew/bin/python3.14 AssetFactory/puppet/generate_simple_your_dancer_views.py
/opt/homebrew/bin/python3.14 Tools/regression/check_first_avatar.py
PATH=/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin FX_NONINTERACTIVE=1 ./RUN_R2_REGRESSION.command
/opt/homebrew/bin/xcodegen generate --spec App/project.yml --project App
xcodebuild -project App/SWAY.xcodeproj -scheme SWAY -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/SWAY_ONE_AVATAR_DERIVED_20261009 CODE_SIGNING_ALLOWED=NO build
```

## Next acceptance milestone (do NOT silently expand M1)
M2 is ONE real selectable customization (e.g. top palette) reflected in creator and workout, with real asset/renderer binding and local persistence. Next, complete richer body/face/hair and all other coaches. All eight heading transitions and on-device views need physical review. Preserve M1 candidate and LKG until that evidence exists.
