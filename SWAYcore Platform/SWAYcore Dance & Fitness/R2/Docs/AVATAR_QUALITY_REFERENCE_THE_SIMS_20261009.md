# SWAYcore — The Sims–inspired avatar baseline (2026-10-09)
Status: USER-DIRECTED REFERENCE / ACCEPTANCE TARGET, NOT A RELEASE CLAIM
Authority: Lucas's newest avatar reference; preserve R2 product canon and proven LKG.
Scope: CURRENT SWAYcore R2; this is not a license to import/copy EA assets or replace the app.

## Visual quality baseline
Reference: EA The Sims 4 Create a Sim, for expressive, distinct, customizable stylized people and believable character movement. Keep SWAYcore's own five coaches (Lucia, Nandi, Thabo, Zuri, Kyle), brand identity, existing character boards 136/125 (soft 3D-render illustration), and offline-first use. Do not copy EA meshes, art, interface, characters, rigs, names, sounds, or other copyrighted material.

Baseline qualities: readable facial identity at phone scale; consistent bone lengths/proportions across front, 3/4, side, 3/4 back and back; different skin tones and body forms; distinct hair, face, clothing and accessories; natural silhouette and facial expression changes; continuous shoulders/elbows/hips/knees; appropriate ground contact; no popping while turning; believable simultaneous instructor and YOU poses.

## Creator acceptance, not merely editable data
Reuse frozen SWAYCharacterStage and SWAYAvatarCatalog APIs. The existing categories are body, skin, face, hair, hairColor, top, bottom, shoes, accessory. A selectable option counts as DONE only if it changes rendered pixels in the character's preview and active dance stage, persists in profile, survives restarting/pack import where applicable, and remains compatible with all views and animated poses. Options without valid art must remain disabled. No fake swatches or placeholder counts.

YOUR DANCER must be a genuine independent base with coherent frontal, back and side artwork, not a hue change of any coach. The 2026-10-09 audit established that the three yourDancer_*_rgba.png source alpha masks are byte-for-byte pixel-identical to the respective Kyle masks; the recolor alters RGB only. This is NOT distinct geometry or complete creator functionality.

## Articulation contract
Release route remains native 2.5D SWAYHumanoid-v1, 23 joints, 8 TV-style yaw directions using authored/mirrored views. Existing primary implementation remains Swift, with no new proprietary engine, cloud dependency or unnecessary background service.

Rigid cutouts should be evaluated against documented alternatives: deformation/skinned meshes (Unity 2D Animation reference, Godot Skeleton2D reference) and Apple's native SpriteKit SKWarpGeometryGrid. Apple SDK availability was typechecked on the actual Mac using /private/tmp/SWAYNative2DMeshWarpPilot.swift (exit 0). This only validates API availability, NOT visual quality, integration, physics, actual deformation, device frame rates or app API behavior. Do not modify frozen public SWAYCharacterStage contract to trial a renderer. Do not introduce Rive/Spine or proprietary production dependencies.

Prototype a single character's front+side connected deformable shoulder/hip/elbow/knee mesh. First compare source fidelity against the existing board, then render the six existing oracle poses, intermediate poses, mirroring and turn transitions. Preserve accepted Lucia front/back. Replace no working route before regression, native build, and visual/physical gates.

## QA bar and known false positives
- Existing Task 10 objective gate: 18 rigs x 6 poses must pass under TASK10_PUPPET_ARTICULATION_FIX.md. Preserve the original failed evidence (25 PASS / 83 FAIL; 18 rigs failed at least one pose). Do not claim this is passing.
- Original gate uses width+400 and height+400 with offset 200 and can clip long outstretched arms and legs. The 2026-10-09 edge audit showed nonzero alpha at its output border for Kyle front arms-out and lean+hip, Kyle side arms-out and lean+hip, Nandi side arms-out; an expanded 700 px margin removed border clipping. Fix the test viewport in a controlled and evidence-preserving checker change.
- A blanket >60 px enclosed-hole threshold is NOT an anatomical quality oracle. The accepted Lucia back source matte itself has a ~5605 px natural enclosed transparent region. An acceptance test must distinguish intentional arm/leg negative space from newly introduced transparent seams. Keep original A1 evidence; do not silently relax its threshold to manufacture PASS.
- Test silhouette connected-component count and new hole creation relative to authored/reference pose; detached limb islands; overlay clipping; joint skin-surface continuity; original matte reconstruction (coverage and IoU); 6 poses per rig plus in-between poses, mirroring and transitions.
- Check differences in selectable profile options by rendered pixels, asset/model identity and saved profile roundtrip, not just catalog array lengths.
- Two angles visible on source board are not by themselves production runtime validation. Human review of all coach/creator renders remains UNKNOWN until performed.

## Current evidence / gates
TASK10 candidate is isolated at /Users/lucas/edenOS/Temporary/SWAYcore/_claude_work/task10_verify_20261009 (detached from Git integration LKG). Simulator build PASS (exit 0); routine regression PASS (12 gates, 0 failed, 2 UNKNOWN visual/physical); separate articulation gate FAIL 83 of 108 poses; iPhone/iPad physical acceptance UNKNOWN. Temporary cap and side-joint-spacing experiments all rejected. No source modifications, branch promotion or release authorized merely by this reference brief.

## Sources / techniques
- EA The Sims 4 Create a Sim: https://thesims-api.ea.com/game-info/smarter-sims
- EA players guide: https://cdn-assets-ts4.pulse.ea.com/Guide/TheSims4_PlayersGuide_ENGLISH.pdf
- EA CAS quality criteria, especially clipping/body-frame variation: https://media.contentapi.ea.com/content/dam/eacom/SIMS/common/create-a-sim-technical-test-criteria.pdf
- Unity Sprite Skin and weights: https://docs.unity.cn/Packages/com.unity.2d.animation%408.0/manual/SpriteSkin.html
- Godot Skeleton2D: https://docs.godotengine.org/en/4.5/classes/class_skeleton2d.html
- Apple native warp: https://developer.apple.com/documentation/spritekit/skwarpgeometrygrid

## Next authorized evidence steps
1. Correct oracle viewport/cropping while retaining old gate record. Separate natural source holes from holes caused by deformations.
2. Demonstrate truly connected, original-identity deformable front+side pilot; quantify fidelity vs existing 18-rig baseline and test all six poses.
3. Recover/reuse suitable independent base artwork from the reference body-part kit for YOUR DANCER; prohibit Kyle-shaped recolor as production outcome.
4. Add genuinely rendered and persisted creator options to the existing catalog without altering public entrypoint signatures.
5. Re-run 18x6 pose gate, Swift SDK and full simulator build, regression, then human visual/physical iPhone/iPad gates; only then consider promotion.
