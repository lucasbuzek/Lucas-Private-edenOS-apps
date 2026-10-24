# WORKinCODEX — SWAYcore FINAL RELEASE — TASK 1 of 4: 2.5D AVATARS — ALPHA CHARACTERS (2026-10-08)

New branch: `swaycore-release-avatars-20261008` (from the base in the common contract). Scope: the ALPHA characters ONLY — coach LUCIA and YOUR DANCER (whose look is also the live YOU puppet) — plus the shared puppet pipeline, renderer and catalogue they need. Nandi, Thabo, Zuri and Kyle are TASK 4 (later, built on your pipeline): do not build them here. Do not touch UI screens, mechanics, build plumbing or passing regression gates.

## Goal
Production-quality 2.5D cut-out puppets for LUCIA and YOUR DANCER, in the board-136/125 look, rigged to SWAYHumanoid-v1, rendered through the frozen `SWAYCharacterStage` / `SWAYAvatarCatalog` contract — plus a reusable, documented pipeline (kit extraction → rig segmentation → assembly → manifest) and renderer that Task 4 will reuse unchanged for the other four coaches. For `nandi/thabo/zuri/kyle`, `SWAYCharacterStage` keeps rendering Lucia as a declared fallback until Task 4 lands.

## What went wrong before (do not repeat)
1. Pillow primitives (rectangles/ellipses at fixed coordinates) as art.
2. Upscaling the 65 px `App/ProductionAssets/Lucia` parts.
3. Cutting parts out of a FINISHED full-body figure (the Lucia turnaround): hidden pixels don't exist, so parts came out as boxes with background slivers, hair repeated 3x (hairBack/hairFront/head each contained hair), gaps at elbows/knees, almost no motion.

## The correct source: the PARTS KITS (Lucas's own art)
`R2/Reference/ArtDirection/125-IRIS_BUILD113_ARTICULATED_ASSET_DIRECTION.png` and `136-SWAY_BUILD110_CHARACTER_ASSET_DIRECTION.png` contain parts that are ALREADY drawn complete and separate on plain backgrounds:
- bald heads in several skin tones and face shapes (front, side, back), face/eye detail tiles;
- hairstyles separate from heads (front, side, back): Lucia's ponytail, buns, braids, curls/afro, blonde ponytail, cap variants;
- tops (crop tops, sports bras in black/pink/yellow/blue/white, long-sleeve crop, hoodie, jacket), bottoms (joggers, leggings, shorts, skorts);
- complete arms with hands and wristbands in several skin tones, bare legs in several tones, gloves;
- sneakers row (white/pink, yellow, blue, black…), caps, headbands, visors.
Board 136 also has each coach in front/side/back turnaround + expressions + action poses — use those ONLY as the reference for how each coach's parts combine and as proportion/pivot reference, not as the cut source.

## Required pipeline (open-source, scripted, reproducible)
1. Extract every kit part by background keying (the backgrounds are plain/dark) + connected components + small morphological clean-up; keep the part whole with clean anti-aliased alpha. Grid/tile regions may be located with hand-authored JSON boxes per board (reviewable); NEVER crop into a neighbouring part. Upscale only with a quality OSS method if needed and record it; target ≥ 512 px on the part's long side where the source allows, honestly report where it doesn't.
2. Classify parts into the catalogue: head(skin tone, face), hair(style, colour, view), top, bottom, arm(skin, L/R), leg(skin, L/R), shoes, accessory; record source board + pixel box per part in `AssetFactory/data/parts_kit_catalog.json`.
3. Rig segmentation for limbs: split complete arms/legs into upper/lower/hand-foot segments at the joints with ROUNDED, OVERLAPPING joint caps (repaint the overlap region from the part's own pixels so a bend never shows a gap or a hard cut). Clothing that covers a limb (joggers, sleeves) is split the same way.
4. Assemble Lucia from kit parts to match board 136 (her skin tone, brown ponytail, black crop top with pink trim, black joggers with pink stripe, white/pink sneakers, wristbands). Extract and catalogue the WHOLE kit (all hair, tops, bottoms, skin tones, shoes, accessories) because YOUR DANCER's options and Task 4 both depend on it. Write `AssetFactory/PUPPET_PIPELINE.md` explaining exactly how to assemble another coach (inputs, commands, manifest fields). One hair part per view (hairBack behind head, hairFront over it) — never hair baked into the head.
5. Angles: FRONT, SIDE, BACK from the kit's views; mirror for the opposite side; 3/4 views where the kit or board has them, otherwise nearest-angle fallback declared in the manifest (never fabricated).
6. Pivots per part per angle named by SWAYHumanoid-v1 joints; draw order per angle; manifest per character `AssetFactory/data/puppet/<character>_puppet_manifest.json` + catalogue manifest for YOUR DANCER options.
7. YOUR DANCER = the same part system with every kit option selectable (body, skin, face, hair, hair colour, top, bottom, shoes, accessory). Implement `SWAYAvatarCatalog` from the real catalogue (`available=false` for anything not delivered). Lucas's personal YOU-avatar reference image is not in the repo yet; if `R2/Reference/ArtDirection/YOU_REFERENCE.*` appears, use it as the default YOUR DANCER look; otherwise use the kit and list it as pending.
8. Remove from the runtime path (keep files only if tests need them): the `YD2D_*` primitive art, the upscaled `App/SWAY/Resources/Puppets/Lucia/front/base` parts and the box-cut turnaround parts. They must not ship as visible art.

## Runtime (inside `App/SWAY/Avatar/**` only)
- Implement `SWAYCharacterStage` for `lucia` and `yourDancer` (other IDs fall back to Lucia, declared in code and receipt); the character→manifest lookup must be data-driven so Task 4 only adds manifests/assets: `.move` → coach puppet on `SwayCoachPoseEngine` joints; `.tracked` → YOU puppet from `SwayBodyPose` via the Vision mapper (last-good joints, honest lost-tracking state); `.idle` → neutral pose. Yaw → angle selection with the existing ±10° hysteresis.
- Motion must READ: amplify/clean the 2D projection so Step Touch, Squat, Side Lunge, March, Knee Lift, Grapevine, Jumping Jack, Pivot Turn (360° via angle swaps) and Body Roll are clearly visible at phone size (current Step Touch barely moves). Do not change choreography truth; adjust only the projection/presentation layer.
- Performance: 60 fps target on iPhone 15 Pro Max; draw with a single SwiftUI `Canvas` or SpriteKit node tree; cache images.

## Acceptance (evidence required)
1. Contact sheets in `Docs/puppet_contact_sheets/`: Lucia × all 8 angles (neutral); YOUR DANCER × every option category and 3 full example looks; 8-frame strips of Step Touch, Squat, Side Lunge, Pivot Turn (full 360°) and Body Roll for Lucia and Step Touch + Squat for YOUR DANCER — rendered by a Python reference compositor that uses the SAME manifest/pivot maths as Swift (keep the parity test ≤ 0.5 px).
2. No visible box edges, background slivers, duplicated hair or joint gaps in any sheet frame (add an automated check: alpha coverage at every joint overlap at bend angles 0–150° has no holes; no part bounding box touches non-transparent background colour).
3. Every catalogue option changes the rendered part set at every angle (test).
4. Tracking fixtures drive the YOU puppet incl. dropped joints (existing fixtures; keep green).
5. OSI licence gate and strict PNG decode stay green; regression stays 12 PASS / 0 FAIL.
6. Receipt `R2/Docs/RELEASE_TASK1_RECEIPT_20261008.md` with per-character, per-angle availability table, every MISSING item named, and the exact entry points Task 4 must call.
visualQuality stays UNREVIEWED until Lucas reviews the sheets.
