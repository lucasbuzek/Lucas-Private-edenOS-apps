# SWAYcore R2 — The Sims Avatar Baseline
**Authority:** user's 2026-10-09 request, "Use The Sims as avatar baseline."
**Status:** adopted reference/acceptance target, NOT a claim of implementation, verified artwork, or EA authorization.
**Scope:** YOUR DANCER; five distinct coaches Lucia, Nandi, Thabo, Zuri, Kyle. Governed by ForgeMASTER; separate from Task 10's art-repair branch.

## Interpretation: take proven design principles, not EA assets
The Sims 4 is the new quality reference for how the user creates, recognizes, dresses and moves an avatar. Adapt the character-first visual editor, direct body/face adjustment, angle inspection, style presets, clothing coordination, layered hair/skin and distinct movement expression. The SWAY appearance should be cohesive, legible, stylized-human and lively rather than a collection of disconnected rigid images. Retain the established SWAY illustration character identities (board 136 / board 125), adapted to this higher-quality standard. No Sims graphics, textures, models, code, fonts, trademarks, or CC are licensed for inclusion.

**Do not silently convert the accepted October 8 2.5D release into full 3D.** Preserve the SWAYHumanoid-v1 skeleton, offline-first iPhone+iPad target, five coaches + YOUR DANCER, authored front/back/side 2.5D views with mirrored eight-direction playback, and the frozen public SWAYCharacterStage API. A real 3D pivot is a separate decision and evidence gate.

## Required visual and functional characteristics
1. **Body / face.** Expressive, proportional, distinct people; balanced diversity across human skin and body shape. Author anatomy-correct shoulder/elbow/wrist/hip/knee/ankle pivots for every angle. Changes to head/body/limb scaling must deform skin and clothes, never pull them apart.
2. **Hair / face details.** Distinct shape, texture and color options where art exists; facial detail readable at workout distance. Proper hair-back/head/hair-front order and attachments during movement.
3. **Wardrobe.** Independent tops, bottoms, shoes and optional accessories. Authentic garment overlays and swatches, compatible geometry/occlusion on moving rigs; nonbranded original art. Do not offer a select control until its option is visibly rendered.
4. **Create experience.** Center-stage high-resolution avatar, browse by category, visible live feedback, body-part contextual editing where supported, touch turntable (front/three-quarter/side/back), zoom/reset, simple preset first, detail editing on demand, undo/reset and save. iPhone portrait and iPad layouts, VoiceOver.
5. **Animation.** Neutral stance, six Task 10 articulation poses, actual dance clips, camera-tracked YOU, handedness/mirroring, pauses and transitions must all keep characters joined and readable. Coach expression may vary but never distorts the single music clock or scoring.
6. **Privacy/performance.** Save choices locally by default and support offline editing. Validate iPhone/iPad memory, frame rate, accessibility, and physical tracking; UNKNOWN is not PASS.

## Current code facts (2026-10-09, evidence—not assumptions)
- `App/SWAY/Avatar/SWAYCharacterStage.swift`: SWAYAvatarCatalog lists *one* option per nine categories and only index 0 as available. It does NOT provide Sims-level choices.
- `App/SWAY/Models/Move.swift`: SwayCharacterProfile stores body style, tone, face/hair/clothing indices, body/head/limb/hair scale, etc. Stored fields do NOT prove drawing works.
- `App/SWAY/Views/SettingsView.swift`: SwayAvatarCreatorView has a live stage and category grid, but no demonstrated rotation/zoom, detail geometry or multi-option renderer.
- `App/SWAY/Avatar/SWAYPuppetRenderer.swift`: articulated rig draws SWAYRigPuppetCanvas without applying the selected appearance to its part images. The renderer's profile property by itself does not change those images.
- `AssetFactory/puppet/YOUR_DANCER_LAYERS.json`: part/category mapping exists, not complete independent selectable appearances.
- Task 10 art verification: 18 rigs x six poses; last measured 25 PASS, 83 FAIL. Source-rest silhouette overlap roughly 0.89–0.97 does not establish motion continuity. Increasing overlap caps and reducing limb spacing did not solve Kyle side-view articulation.
- Task 10 isolated simulator build reported exit 0. Regular 12-gate regression with a sanitized Python PATH reported zero failed gates and two UNKNOWN visual/physical gates; the 108-pose art gate is not covered by that regular runner.
- No LKG promotion is authorized by this reference.

## Architecture and implementation route
- Keep existing `SwayCharacterProfile` as stored settings and frozen `SWAYAvatarCatalog.options / selectedIndex / apply` as UI contract.
- Derive selectable options from real, uniquely packaged, correctly rigged component sets and their per-view metadata. Verify options via render-image differences, not mere stored index changes; false options remain unavailable.
- Use proven **connected skeletal hierarchies, weighted deformation, limb attachments and explicit depth ordering**. Blender armature weighting and Godot 2D skeletons are evidence-bearing open-source design references; prototype in tooling before considering any runtime replacement. Respect license/provenance.
- Appearance must match in creator, idle, workout and tracked YOU at identical pose/direction; no brand art, generic mannequin fallback or disconnected strips.
- Preserve original accepted Lucia front/back. Regenerate disconnected rig assets one character/view at a time, with side-view angles first; never bulk-apply a failed cap/joint experiment.

## Acceptance gates — do not skip
**A — Articulation:** All six poses for all 18 rig views pass the established independent Task 10 checker. Record per-rig PASS/FAIL and side-by-side contact sheets; don't game thresholds by hiding or inflating artifacts.
**B — Real choices:** Each enabled body/face/skin/hair/outfit option changes actual assembled image, with all views compatible and no seams in motion; unsupported categories visibly unavailable.
**C — Interaction:** rotate, inspect, zoom, choose, reset/undo, save/relaunch, offline; all selected appearances persist and render identically in creator and workout.
**D — Runtime:** signed-off handedness, motion, tracked YOU, five coaches, independent character identity, orientation and accessibility; app simulator build + regression suite.
**E — Physical/release:** actual iPhone/iPad animation and camera test, device performance, packaged clean-extraction verification, checksums and LKG promotion only after accepted gates.

## Sequenced work
(1) Fix Task 10 art failures in its isolated candidate; (2) author one connected original neutral YOUR DANCER including complete angles and layers; (3) deliver a small **real** skin+top customization slice with renderer binding and accurate catalog; (4) extend hair/face/body/wardrobe and the Sims-inspired editor; (5) complete coach parity and full physical acceptance. Do not introduce dummy previews or fake high option counts.

## Research / provenance
- EA The Sims 4 Player Guide: direct manipulation, detail editing, rotation, styled outfits: https://cdn-assets-ts4.pulse.ea.com/Guide/TheSims4_Players_Guide.pdf
- EA ways to play: body, clothing, voice, movement and hair customization: https://www.ea.com/en-au/games/the-sims/the-sims-4/how-to-play-the-sims
- EA Skin Details diary: visually layered details respond to body alteration: https://www.ea.com/games/the-sims/the-sims-4/news/skin-details-dev-diary
- Blender armature and vertex groups: https://docs.blender.org/manual/en/latest/modeling/modifiers/deform/armature.html
- Godot cutout/skeleton animation: https://docs.godotengine.org/en/stable/tutorials/animation/

This reference is a SWAY product-quality standard. EA has not licensed its artwork or code for SWAY and no such assets are needed.
