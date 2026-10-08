# SWAYcore Task 5: produce all puppet assets (ARTEMIS + IRIS + DURER)

Date 2026-10-08. Requested by Lucas. Governor: ForgeMASTER. Base branch: `swaycore-puppet-rig-20261008`. Project root: `SWAYcore/R2`.
This task REPLACES the asset part of Tasks 1 and 4. Do not touch UI screens, the music clock, or camera code.

## 1. Goal
All six characters as working 2D cut-out puppets in the app, on iPhone and iPad:
Lucia, Nandi, Thabo, Zuri, Kyle (coaches) and YOUR DANCER (the user's avatar).
For each character: FRONT, SIDE and BACK views (side is mirrored for the other side). Same art style as the boards, nothing redrawn in a new style.

## 2. Use every tool you have
Use every plugin, skill, MCP server, CLI and library in your environment that helps (image tools, Python libs, Swift tooling, test runners, image-viewing tools for visual checks). Inspect your rendered images yourself before declaring anything done.
One limit: whatever ships in the app, or is needed to rebuild it, must be free and open-source (the Apple SDK is fine). No Spine, Rive, Live2D, Moho or paid generators.

## 3. Helpers to run (definitions in `Docs/release_tasks_20261008/helpers/`)
- **@ARTEMIS** (`ARTEMIS.claude.md`) is the asset orchestrator. Build the Asset Requirements Graph and Asset Bible, plus a manifest `AssetFactory/puppet/ASSET_MANIFEST.json` listing every part with its character, view, file, pivot, z, source crop and QA state. Follow its QA ladder: ASSET, then FAMILY, then PROJECT, then TARGET CONTEXT. "A generated asset is not a finished asset."
- **@IRIS** (`IRIS.claude.md`) owns visual fidelity. SCAN each source view, then VISUAL DNA, then FIDELITY LOCK: the board art is locked, so never repaint or "improve" faces, clothes or colours. Use COMPARE and FORENSIC QA on every contact sheet.
- **@DURER** owns the 2.5D character contract. No DURER role definition has been recovered: Lucas says one exists in ChatGPT, but it is not in the repo, the Mac canon or GitHub. Search this repo for one first; if you find it, follow it. Otherwise use DURER's recorded artefact, `SWAY-DURER-2.5D-v1` (copy in `helpers/DURER_2_5D_ASSET_CONTRACT.json`): illustrated 2.5D, joint overlap, directional variants, iPhone visual gate. Update it to `SWAY-DURER-2.5D-v2` so it describes this cut-out rig. Add "DURER definition missing" to `OPEN_ITEMS.md`, and do not invent DURER behaviour beyond that contract.

## 4. What already exists (start here; don't redo it)
- `AssetFactory/puppet/`
  - `matte.py`: rembg isnet-anime matte.
  - `cut.py`: config-driven part cutter.
  - `pose.py`: reference compositor with six test poses.
  - `grid.py`: grid overlay for picking joints.
- `configs/lucia_front.json` and `configs/lucia_back.json` are worked examples. Read them: they use every feature (cuts, groups with reach/skinBelowY, colour force rules, auto caps, erase boxes, open/main).
- `mattes/lucia_{front,back,side}_rgba.png` are finished mattes.
- `Reference/ArtDirection/upscaled_x4/`: boards 125 and 136, upscaled 4× with Real-ESRGAN (BSD-3, `realesrgan-x4plus-anime`). Crop from these, never from the 1× boards.
- App, `App/SWAY/Resources/Puppets/LuciaRig/`: Lucia front and back parts plus `lucia_{view}_rig.json`.
- `App/SWAY/Avatar/SWAYRigPuppet.swift`: loader plus angle-retarget solver plus Canvas renderer. Only bone directions come from the clips or Vision; bone lengths come from the art, chained from the hips, so parts never separate.
- `SWAYPuppetRenderer` uses the rig when one exists, otherwise its legacy path.
- Evidence: `AssetFactory/puppet/evidence/lucia_{front,back}_poses.png`.

Matting note: rembg needs to download its model. If you have no network, board 136 has a flat light background (about RGB 196,173,162). Key it with a flood fill from the crop edges through background-like pixels; `cut.py`'s despill already does this, so reuse it.

## 5. Source art (where each view comes from)
- Board 136 (`136-SWAY_BUILD110_CHARACTER_ASSET_DIRECTION`) is the canonical look.
  - Top row: per coach, FRONT, SIDE (facing right), BACK, SIDE (facing left).
  - Order: Lucia, Nandi, Thabo, Zuri, Kyle.
  - Row 2: expression heads (neutral, wink, laugh, "oh"); use them as face swaps for the head part.
  - Bottom rows: a parts kit (hand poses, hair, tops, bottoms, shoes).
- Board 125 is a second parts kit (hands, arms, legs, shoes) for fills and for YOUR DANCER options.
- Board 141 is silhouettes only (do not use its anime look).
- Final UI board: `FINAL_UI_DIRECTION_SWAY_UI_TARGET_BUILD122.jpeg`.
- Use the two side views consistently. Lucia's right-facing side has a ponytail and her left-facing side has a bun. Front and back show a bun, so use the left-facing side and mirror it.
- **No brand logos.** If any shoe or garment shows a swoosh or wordmark (board 125 shoes do), paint it out with a plain fill in the shoe colour.

## 6. Work order
1. **Fix Lucia's back view** (two known defects, both visible in `evidence/lucia_back_poses.png`):
   - Black crescents beside the hips when the arms move. The hands overlap the trouser sides in the source, so the hip outline behind them is missing. Reconstruct the hip outline behind the hands and forearms (fill under the arms, hidden at rest).
   - Thin black slivers trail the raised hands. The arm group's `outline` dilation (4) grabs trouser pixels. Use a smaller dilation, or keep only outline pixels connected to the hand.
2. **Lucia SIDE view** (source: board 136, top row, 4th figure; matte done). This is the hard one:
   - The near arm (her right) lies over the torso with no gap. Add polygon groups to `cut.py` and mask the arm with a polygon.
   - Fill the torso area hidden behind the arm from the surrounding colours (hidden at rest).
   - Far arm and far leg: duplicate the near ones, darken about 15%, and draw them behind the body (TV-style).
   - Use one shoe per leg.
   - Mirror the art for the other side. The renderer must flip each part, mirror its rest angles, and choose the mirrored view from the yaw selector.
3. **The other four coaches** (Nandi, Thabo, Zuri, Kyle), in that order. For each: front, back and side, using the same pipeline.
   - Long braids (Nandi) and big curls (Zuri) are part of the head layer. Hair hanging over the shoulders must stay with the head and must not be cut into the arms.
4. **YOUR DANCER.** Lucas's stylised reference photo is not in the repo yet. Build the customisable base from the board-125/136 kits: body type, skin tone, hair, top, bottoms, shoes, as `SWAYAvatarCatalog` already defines. Skin tones should be palette swaps of the skin parts. Leave a clearly marked slot for his custom face/hair when the photo arrives. **Do not invent his likeness.**
5. **Wire everything into the app.** Replace the hard-coded `"lucia"` in `SWAYPuppetRenderer`: route `SWAYCharacterStage` per `SWAYCharacterID` to that character's rig. Keep the frozen contract signatures unchanged.

## 7. Acceptance (each must actually run; UNKNOWN is never PASS)
- **Rest reconstruction:** for every character and view, composite the rest pose and compare it to the source matte. Mean absolute error under 3/255 inside the silhouette, and no visible seams. Add this as a script in `Tools/regression/`.
- **Pose sheets:** `pose.py` sheets for all six test poses, per character and view, in `AssetFactory/puppet/evidence/`. Inspect each one yourself. There must be no gaps at joints, no floating slivers, no background specks and no parts from the wrong group. Remember to negate pose angles for the back view (already handled in `pose.py`).
- **Rig validation:** every JSON part file exists, pivots lie inside part bounds, and every joint the solver needs is present. Add an XCTest that loads each rig from the bundle and runs `SWAYRigSolver.solve` on the rest pose. The result must match the rest joints within 1 pt.
- **Build:** `xcodegen generate`, then the simulator build, then `./RUN_R2_REGRESSION.command` (baseline 12 PASS / 0 FAIL / 2 UNKNOWN; it must not get worse). Then run the three state checks in `Tools/regression/run_*_state.py`.
- **Size:** keep parts at their 4× crop resolution, with each character's total under 8 MB (ARTEMIS Optimization Specialist). Measure it; don't guess.
- **Physical iPhone/iPad visual test** stays UNKNOWN. Lucas does it.

## 8. Rules
- Work only on branch `swaycore-puppet-rig-20261008`, or a child branch of it. Never push to main. No LKG promotion.
- Evidence ladder: GENERATED != IMPLEMENTED != BUILT != TESTED != VERIFIED != RELEASED.
- **Final report (short):**
  - per character and view: state, plus the paths to its evidence;
  - what failed or is still UNKNOWN;
  - open items.
