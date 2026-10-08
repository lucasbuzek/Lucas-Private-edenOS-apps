# TASK 6 — Finish every SWAY cut-out puppet on the proven rig (Codex cloud, env lucas-Private-edenOS-apps)

Start from branch `swaycore-puppet-rig-20261008` @ 2b21781 (or newer). Project root: `SWAYcore/R2`.
Use every helper, plugin and tool available to you. Free/open-source tools only. Work in the cloud, never on Lucas's Mac.
Read first: `Docs/release_tasks_20261008/COMMON*.md`, `TASK5_PUPPET_ASSETS_IRIS_ARTEMIS_DURER.md`, `Docs/release_tasks_20261008/helpers/` (IRIS, ARTEMIS, DURER contract). Run @ARTEMIS as orchestrator/QA ladder and @IRIS as the visual-fidelity lock.

## What already works (do NOT rewrite)
- `App/SWAY/Avatar/SWAYRigPuppet.swift` — rig JSON loader, solver (bone directions from motion, bone lengths from art), Canvas renderer.
- `App/SWAY/Avatar/SWAYPuppetRenderer.swift` + `SWAYCharacterStage.swift` — frozen contract; routes `SWAYCharacterID.rawValue` to `<name>_<view>_rig.json`; falls back to Lucia when a rig is missing.
- `App/SWAY/Avatar/SWAYAvatarGalleryView.swift` — DEBUG screen (`-SWAYAvatarGallery`) showing all six characters front/back/side.
- `AssetFactory/puppet/` — `matte.py` (rembg isnet-anime), `cut.py` (config-driven part cutter; options: groups, cuts, erase, force, caps incl. `auto`, `capFrom`, `fillPolys`, `fillRows`, `open`, `main`), `pose.py` (reference compositor = same math as Swift). Configs `configs/lucia_front.json`, `lucia_back.json` are the worked examples. Evidence sheets in `AssetFactory/puppet/evidence/`.
- Lucia front + back parts in `App/SWAY/Resources/Puppets/LuciaRig/` — accepted quality bar.

## Deliverables (in this order)
1. **Lucia side view** (`lucia_side_*`, rig JSON with `"view":"side"`) from `AssetFactory/puppet/mattes/lucia_side_rgba.png`. Near arm over torso, far limbs drawn behind (z below torso, slightly darkened). Renderer already mirrors left/right.
2. **Nandi, Thabo, Zuri, Kyle**: front, back, side each, from the SWAYcore board art in `Reference/ArtDirection/` (`upscaled_x4/` = Real-ESRGAN 4x of boards 125/136; use the character turnarounds/parts kits there). Folder `Resources/Puppets/<Name>Rig/`, file prefix lowercase rawValue (`nandi_front_rig.json`, …).
3. **YOUR DANCER** (`yourDancer_*`): neutral base built from the board parts kits; a separable head/hair/top/bottom/shoes layer set mapped to `SWAYAvatarCatalog` options. Do NOT invent Lucas's likeness. NO third-party logos/band art (the reference tee's logo must not ship).
4. For each view: run `cut.py` → `pose.py` and commit the contact sheet to `AssetFactory/puppet/evidence/<name>_<view>_poses.png`. Fix visible defects (slivers, crescents, gaps at joints, background spill, notches) before moving on — same bar as `lucia_back_poses.png`.
5. Register any new Python import in `AssetFactory/PROVENANCE/oss_dependencies.json` (OSI licences only).

## Gates (report each honestly; UNKNOWN is never PASS)
- `python3 Tools/regression/check_oss_dependencies.py` passes.
- Every rig JSON loads (write a small Python check: all part files exist, joints present, pivots inside part bounds).
- If you have Xcode/simulator: build `App/SWAY.xcodeproj` scheme SWAY for iphonesimulator and screenshot `-SWAYAvatarGallery`. If not, say BUILD UNKNOWN.
- Evidence ladder: GENERATED ≠ IMPLEMENTED ≠ BUILT ≠ TESTED ≠ VERIFIED.

## Delivery (important — previous large diffs could not be downloaded)
- Commit in small, per-character commits.
- If your environment can push: `git push origin HEAD:swaycore-puppets-codex6-20261008`. State clearly whether the push succeeded.
- Keep each PNG part ≤ 1024 px on its long side; no duplicate copies of source boards; no temp/debug images outside `evidence/`.
- Final message: table of characters × views × state, defects remaining, gates results.
