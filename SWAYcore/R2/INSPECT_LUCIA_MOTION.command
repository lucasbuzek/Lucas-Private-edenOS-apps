#!/bin/bash
# Immutable inspection: no candidate promotion, source writes, or runtime integration.
set -u
ROOT="$(cd "$(dirname "$0")" && pwd -P)"
cd "$ROOT" || exit 2
source Scripts/factory_lib.sh
fx_init "$ROOT"
CANDIDATE="${1:-$ROOT/Build/experiments/girush_sway_alpha_repaired/lucia_production_retarget.blend}"
[ -f "$CANDIDATE" ] || { echo "Missing candidate: $CANDIDATE"; exit 2; }
fx_need "Blender availability" pf_blender
# fx_gate executes in a subshell; resolve the executable again in this shell.
find_blender || exit 2
DEST="$FX_BUILD/motion-evidence/$FX_STAMP"
mkdir -p "$DEST"
shasum -a 256 "$CANDIDATE" > "$DEST/input.sha256"
fx_gate "production candidate structural validation" "$FX_BLENDER" --background --factory-startup --python-exit-code 3 "$CANDIDATE" --python AssetFactory/blender/sway_validate_character.py -- --clips AssetFactory/data/clip_manifest.json --report "$DEST/structural.json"
fx_gate "all clips anatomical transfer and rendered extremes" "$FX_BLENDER" --background --factory-startup --python-exit-code 3 "$CANDIDATE" --python AssetFactory/blender/sway_inspect_motion.py -- --report "$DEST/motion.json" --renders "$DEST/renders"
fx_unknown "human visual motion review" "review every clip front/side against source and authored pose; this builder cannot approve"
fx_finish "Inspection evidence: $DEST. No source or app resources changed."
fx_exit
