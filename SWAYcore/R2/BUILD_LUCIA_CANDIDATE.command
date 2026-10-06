#!/bin/bash
# Isolated diagnostic candidate only. Never integrates or approves runtime resources.
set -u
ROOT="$(cd "$(dirname "$0")" && pwd -P)"
cd "$ROOT" || exit 2
source Scripts/factory_lib.sh
fx_init "$ROOT"
find_blender || exit 2
SOURCE="${1:-Build/experiments/girush_sway_alpha_repaired/lucia_source_meter.blend}"
DEST="$FX_BUILD/lucia_candidate"
mkdir -p "$DEST"
BL="AssetFactory/blender"
run_blender() { "$FX_BLENDER" --background --factory-startup --python-exit-code 3 "$@"; }
fx_gate "native driver and full rest basis" run_blender "$SOURCE" --python "$BL/sway_add_native_driver.py" -- --map AssetFactory/data/retarget_map_girush.json --ledger-id girush-human-yw-cc0 --out "$DEST/driver.blend" || exit 1
fx_gate "actual native rest contract" run_blender "$DEST/driver.blend" --python AssetFactory/tests/blender_native_rest_contract.py || exit 1
fx_gate "native skin budget with archived orphan groups" run_blender "$DEST/driver.blend" --python "$BL/sway_limit_native_weights.py" -- --out "$DEST/weights.blend" --report "$DEST/weights.json" || exit 1
fx_gate "original licensed material textures" run_blender "$DEST/weights.blend" --python "$BL/sway_restore_girush_materials.py" -- --out "$DEST/materials.blend" --report "$DEST/materials.json" || exit 1
fx_gate "existing R2 native attire palette" run_blender "$DEST/materials.blend" --python "$BL/sway_apply_native_attire.py" -- --id lucia --out "$DEST/attire.blend" --report "$DEST/attire.json" || exit 1
fx_gate "actual portable material contract" run_blender "$DEST/attire.blend" --python AssetFactory/tests/blender_material_contract.py || exit 1
fx_gate "all 21 authored clips" run_blender "$DEST/attire.blend" --python "$BL/sway_bake_clips.py" -- --clips AssetFactory/data/clip_manifest.json --out-blend "$DEST/authored.blend" || exit 1
fx_gate "Blender native connected-limb IK" run_blender "$DEST/authored.blend" --python "$BL/sway_bake_native_ik.py" -- --clips AssetFactory/data/clip_manifest.json --out "$DEST/candidate.blend" || exit 1
fx_gate "unchanged structural and deformation gates" run_blender "$DEST/candidate.blend" --python "$BL/sway_validate_character.py" -- --clips AssetFactory/data/clip_manifest.json --report "$DEST/structural.json"
fx_gate "all-frame transfer and rendered evidence" run_blender "$DEST/candidate.blend" --python "$BL/sway_inspect_motion.py" -- --map AssetFactory/data/retarget_map_girush.json --clips AssetFactory/data/clip_manifest.json --report "$DEST/motion.json" --renders "$DEST/renders"
fx_unknown "production visual, attire and RealityKit gates" "human review and actual native playback required; no approval or app integration performed"
fx_finish "Lucia candidate evidence only. No Alpha package or LKG."
fx_exit
