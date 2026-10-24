# SWAYcore R2 — The Sims / Create-a-Sim avatar baseline

Authority: user instruction 2026-10-09 ("Use The Simps as avatar baseline"), applied as a **reference standard**, not as a license to copy EA game assets or replace SWAYcore's approved release architecture.

## Product intent

YOUR DANCER must feel like an individually created game avatar: a recognizable identity that persists across dance moves, heading changes and sessions. Its customization flow takes functional inspiration from The Sims 4 Create-a-Sim:

- One center-stage, continuously previewable character. Full-body, side and back viewing, zoom/detail, selections that visibly update without a reload.
- Distinct skin shades, body shapes, facial presets, hair and hair colors, layered tops/bottoms, shoes and accessories **when source-backed components exist**. No fake menu options.
- A coherent visual model in every heading: material colors, scale, face and clothes remain the same person when turning; hand/foot sides cannot be swapped unintentionally.
- Character artistry must retain SWAY's approved soft toy-like 3D-illustrated look from boards 136 and 125, not The Sims trademarked art, branding, clothing or character files.
- Every pose must keep anatomy and garment continuity: no free-floating sleeves, severed elbows, skirt/short polygons, disconnected feet, or opaque fill disks that replace the intended figure.

EA reference documentation:
- https://www.ea.com/games/the-sims/the-sims-4/how-to-play-the-sims
- https://eaassets-a.akamaihd.net/eahelp/manuals/the-sims-4-ps4-ukanz.pdf
- https://cdn-assets-ts4.pulse.ea.com/Guide/TheSims4_Players_Guide.pdf

## Project-specific implementation boundaries

- **Newest SWAYcore release canon (2026-10-08)** remains binding: 2.5D puppets, six character identities, SWAYHumanoid-v1, music/coach/YOU synchronization, offline-first, iPhone/iPad, eight TV directions with mirrored nearest-angle fallbacks.
- Keep the frozen `SWAYCharacterStage(character:source:profile:mirrored:)` and `SWAYAvatarCatalog` public contract. Avatar work happens behind them.
- YOUR DANCER is persistent **user-selected identity**. The camera-tracked YOU representation and five fixed coaches are separate, and their art must not inherit the user's appearance settings.
- Prefer existing 2D rig resources and measured fixes over a wholesale engine port or revival of rejected static cutouts/mannequins.
- Free tools only: existing Pillow/NumPy/SciPy pipeline, SwiftUI/UIKit and licensed open-source authoring/QA components; no paid Rive/Spine runtime or downloaded The Sims content.

## Proven techniques to apply to articulation

- **Bone-rest alignment:** bind pose and hierarchy must be consistent across all views and bone rotations.
- **Mesh/weighted deformation at bending joints:** rigid rectangular/silhouette cut pieces are insufficient for continuous elbow, shoulder, knee and hip bends.
- **UV/triangulation and controlled overlaps:** garment ownership, bend vertices, local masks and layer ordering must be verified in extreme poses, not just rest.
- **Reference compositor parity:** one source of movement truth, compare rendered alpha continuity for all six test poses in every view and preserve recognizable rest appearance.

Free, documented reference implementation: Godot Skeleton2D / Bone2D / Polygon2D with UV mapping, painted bone weights and internal bend vertices:
https://docs.godotengine.org/en/4.1/tutorials/animation/2d_skeletons.html

This is a technique reference, **not** approval to replace the Swift application with Godot.

## Increment delivered for isolated Task 10 candidate

- Added `AssetFactory/puppet/generate_personalization.py`: deterministic material-region skin/outfit colorways from 45 existing YOUR DANCER PNGs, no base or coach edits, alpha/pivot/size unchanged.
- Added a bundled palette manifest; 3 real skin options (Light / Medium / Umber) and 3 real coordinated outfits (Emerald / Ocean / Violet), covering all front/side/back views. Generated colorway images are deduplicated by source pixel identity.
- `SWAYPuppetPaletteResolver` selects an actual delivered image for the current `SwayCharacterProfile` and only for YOUR DANCER; idle/coach-move/tracked routes pass profile to the existing cutout renderer.
- Avatar creator displays only categories with actually delivered options. Independent body, face, hairstyles, hair colors, separate bottoms, shoes and accessories are NOT represented as working until separately authored.
- Generated palette choices require offline resource verification, image alpha/sizing and image-difference tests. An Xcode simulator build confirms compilation only; it is not visual/physical acceptance.

## Open quality gates — release cannot promote

| Acceptance | Current evidence or required gate |
|---|---|
| User avatar distinct from five coaches | Neutral YOUR DANCER base is pixel-distinct from Kyle; full identity remains for visual review |
| Skin/outfit across views | 3×3 colorway resolution; alpha invariance automated test; physical appearance review pending |
| Full Create-a-Dancer editing | PARTIAL — real skin/outfit choices only; face/body/hair/outfit separation deferred to authored art |
| Rotating detailed avatar preview | UNKNOWN / not implemented at Sims-level; frozen stage API preserved |
| All 18 rigs × six poses | FAIL — previously 25 PASS / 83 FAIL; no unverified geometry promotion |
| Full six-character coach/user movement | Simulator build + deterministic unit gates; visual and physical evidence still UNKNOWN |
| Native iOS Simulator build | Must run after integration and record actual exit code |
| Physical iPhone/iPad acceptance | UNKNOWN until device evidence |
| Last Known Good | Protected; no promotion without full evidence |

## Reproduction

1. After changing underlying rig PNGs, run `/opt/homebrew/bin/python3.14 AssetFactory/puppet/generate_personalization.py` from R2 (defaults to product root resolved from this file).
2. Run `python3 Tools/regression/run_unittest_suite.py -s AssetFactory/tests -p 'test_sims_palette_avatar.py'`.
3. Regenerate the Xcode project from `App/project.yml` and run the iOS Simulator compile and SWAYTests where supported.
4. Re-run `Tools/regression/check_puppet_rigs.py` as an independent **failing** articulation gate until all 108 poses pass.
5. Obtain physical visual review before any release promotion.

Source output and generated evidence remain an isolated candidate, not LKG.
