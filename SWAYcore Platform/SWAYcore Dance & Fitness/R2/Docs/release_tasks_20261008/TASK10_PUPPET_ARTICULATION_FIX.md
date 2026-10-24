# TASK 10 — Fix puppet articulation (continuation of Task 6) — Codex cloud, environment lucas-Private-edenOS-apps

Branch: `swaycore-integration-20261008` (contains Task 6 + 8 + 9 results; whole-app typecheck PASS, core XCTest 34/34 PASS). Project root `SWAYcore/R2`.
Use EVERYTHING your environment offers (tools, skills, helpers, plugins, MCP connectors, image analysis). List what you found and used. @ARTEMIS = QA ladder, @IRIS = visual-fidelity lock (`Docs/release_tasks_20261008/helpers/`).
Evidence ladder GENERATED ≠ IMPLEMENTED ≠ BUILT ≠ TESTED ≠ VERIFIED; UNKNOWN is never PASS. No item may end "skipped for time": DONE (evidence) or BLOCKED (exact reason).

## Inspection of Task 6 (by Claude, from `AssetFactory/puppet/evidence/*_poses.png`)
- PASS: rest/front poses of Nandi, Thabo, Zuri, Kyle — on-model, board style.
- FAIL: in every non-rest pose (arms out, arms up, point+knee, squat, lean+hip) arms break into detached fragments; legs split in squat/lunge.
- FAIL: ALL side views (incl. new `lucia_side`) — parts scatter, white holes appear.
- FAIL: `yourDancer_*` is a copy of Kyle. It must be its own neutral base.
- `check_puppet_rigs.py` passes only because it checks files/joints exist; it does not check that poses hold together.
- Accepted quality bar: `lucia_front_poses.png`, `lucia_back_poses.png` (configs `AssetFactory/puppet/configs/lucia_front.json`, `lucia_back.json`).

## Likely causes to check first
Joint coordinates in the configs not sitting on the art's real shoulder/elbow/wrist/hip/knee/ankle centres; parts split into several islands (use `main: true` + `open`); caps missing at shoulders/elbows/hips/knees (`caps` with `"auto"`), cap pixels taken from other parts (`capFrom`); far-side limbs in side views not reconstructed (`fillPolys`) and wrong z-order; hand/foot terminal parts' pivots.

## Checklist
A1. **Objective articulation gate** — extend `Tools/regression/check_puppet_rigs.py` (Pillow allowed): render each rig in the same 6 test poses `pose.py` uses and FAIL if, in any pose: the composited alpha has more than 1 connected component (ignoring specks < 40 px), or an enclosed transparent hole > 60 px appears inside the silhouette, or opaque area drops below 85 % of the rest-pose area. Print per rig × pose results. This gate must FAIL on the current Task 6 rigs before you fix them (show that output).
A2. Fix Nandi, Thabo, Zuri, Kyle — front, back, side — until A1 passes for all poses. Regenerate parts + rig JSON + evidence sheets.
A3. Fix `lucia_side` until A1 passes. Do not change `lucia_front`/`lucia_back` (accepted).
A4. YOUR DANCER: distinct neutral base from the board parts kits (not Kyle, not Lucas's likeness, no brand logos), front/back/side, A1 passing, layer set mapped to `SWAYAvatarCatalog` options.
A5. Do not modify Swift renderer/rig code, UI views, or mechanics. Art, configs, `cut.py`/`pose.py` improvements and the checker only.

## Gates (paste result lines)
- `python3 Tools/regression/check_puppet_rigs.py` (A1 gate) — all 18 rigs × 6 poses PASS.
- `python3 Tools/regression/check_oss_dependencies.py`.
- `./RUN_R2_REGRESSION.command` if runnable; otherwise say which gates you could not run and why.

## Delivery
- One commit per checklist item/character (`A1:` … `A5:`).
- Try `git push origin HEAD:swaycore-puppets-codex10-20261008`; report success/failure.
- Final message: table rig × A1 result, tools found/used, gate lines, files changed.
