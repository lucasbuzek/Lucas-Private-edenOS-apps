# WORKinCODEX — SWAYcore FINAL RELEASE — TASK 4 of 4: REMAINING INSTRUCTORS — NANDI, THABO, ZURI, KYLE (2026-10-08)

Base: Task 1's branch `swaycore-release-avatars-20261008` (Lucia + YOUR DANCER puppets, shared pipeline, renderer, `AssetFactory/PUPPET_PIPELINE.md`). New branch: `swaycore-release-coaches-20261008`. Scope: the four remaining coaches ONLY. Do not touch Lucia, YOUR DANCER, UI screens, mechanics, build plumbing or passing regression gates.

## Goal
Production-quality 2.5D cut-out puppets for Nandi, Thabo, Zuri and Kyle, built with Task 1's pipeline and rendered by Task 1's renderer through the frozen `SWAYCharacterStage` contract, so each coach is selectable and performs every move exactly like Lucia (one choreography truth, shared SWAYHumanoid-v1 rig).

## Character definitions (from board 136 / 125; match them exactly — no logos)
- NANDI: deep brown skin, long black box braids, hot-pink sports crop top, dark leggings with pink/purple panels, white sneakers with pink, wristbands.
- THABO: dark brown skin, short black curly/fade hair, white tank top, black joggers with white side stripe, white sneakers, wristbands.
- ZURI: medium-brown skin, big curly hair with a yellow headband, yellow crop top, black shorts with yellow trim, white/yellow sneakers.
- KYLE: light skin, black backwards/forward cap over short dark hair, blue tank top, black shorts with blue trim, white/blue sneakers, wristbands.
Use board 136's per-coach turnaround (front/side/back), expressions and action poses as the reference for combination, proportions and pivots; take the actual parts from the kits (boards 125/136) exactly as Task 1's pipeline does. Body proportions differ per coach (Thabo and Kyle broader shoulders; Zuri and Nandi as drawn) — encode per-character limb lengths/scales in the manifest, never distort the shared rig.

## Required work
1. Read `AssetFactory/PUPPET_PIPELINE.md` and Task 1's receipt first; reuse its extraction, segmentation (rounded overlapping joints, one hair layer per view), assembly and manifest schema. If anything in the shared pipeline must change, record it as a CROSS-TASK REQUEST and use a local adapter in your own files.
2. Per coach: manifest `AssetFactory/data/puppet/<coach>_puppet_manifest.json`, assets under `App/SWAY/Resources/Puppets/<Coach>/`, angles FRONT/SIDE/BACK (+3/4 where the kit has them, else declared nearest-angle fallback), mirrored to 8 directions.
3. Register the four coaches in the data-driven character lookup so `SWAYCharacterStage(character: .nandi/.thabo/.zuri/.kyle, …)` renders their own puppet (remove the Lucia fallback for each coach as it lands).
4. Optional per-coach style flavour ONLY in presentation (e.g. slightly different idle bounce) — never a separate choreography engine.

## Acceptance (evidence required)
1. Contact sheets in `Docs/puppet_contact_sheets/`: each coach × all 8 angles (neutral) and 8-frame strips of Step Touch, Squat and Pivot Turn (full 360°) per coach, rendered by Task 1's reference compositor (parity ≤ 0.5 px).
2. Same automated cleanliness checks as Task 1 (no box edges, background slivers, duplicated hair or joint gaps at bend angles 0–150°).
3. Tests: every coach resolves its own manifest and assets; every move renders for every coach; strict PNG decode; unique resource names; OSI licence gate green; regression stays green.
4. Receipt `R2/Docs/RELEASE_TASK4_RECEIPT_20261008.md` with a per-coach, per-angle availability table and every MISSING item named. visualQuality stays UNREVIEWED until Lucas reviews.
