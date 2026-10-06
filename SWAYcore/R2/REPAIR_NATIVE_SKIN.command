#!/bin/bash
# Candidate-only weight repair. Does not overwrite input or approve visuals.
ROOT="$(cd "$(dirname "$0")" && pwd -P)"
cd "$ROOT" || exit 2
source Scripts/factory_lib.sh
fx_init "$ROOT"
SOURCE="${1:-$ROOT/Build/experiments/girush_sway_alpha_repaired/lucia_production_retarget.blend}"
[ -f "$SOURCE" ] || { echo "Missing source $SOURCE"; exit 2; }
fx_need "Blender availability" pf_blender
find_blender || exit 2
DEST="$FX_BUILD/native-skin-repair/$FX_STAMP"; mkdir -p "$DEST"
shasum -a 256 "$SOURCE" > "$DEST/input.sha256"
if fx_gate "native hidden-safe weights <=4 normalized" "$FX_BLENDER" --background --factory-startup --python-exit-code 3 "$SOURCE" --python AssetFactory/blender/sway_limit_native_weights.py -- --out "$DEST/candidate.blend" --report "$DEST/weights.json"; then
  fx_gate "strict candidate structure and deformation" "$FX_BLENDER" --background --factory-startup --python-exit-code 3 "$DEST/candidate.blend" --python AssetFactory/blender/sway_validate_character.py -- --clips AssetFactory/data/clip_manifest.json --report "$DEST/strict.json"
fi
fx_unknown "visual gate" "weight limiting can alter deformation; run all-clip inspection and human review before integration"
fx_finish "Unapproved isolated candidate: $DEST; input preserved"
fx_exit
