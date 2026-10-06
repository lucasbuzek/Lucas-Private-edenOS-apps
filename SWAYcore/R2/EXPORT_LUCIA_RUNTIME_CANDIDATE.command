#!/bin/bash
# Exports isolated evidence only; never changes app resources or approves assets.
set -u
ROOT="$(cd "$(dirname "$0")" && pwd -P)"
cd "$ROOT" || exit 2
source Scripts/factory_lib.sh
fx_init "$ROOT"
find_blender || exit 2
SOURCE="${1:?Supply the reviewed numerical candidate .blend path}"
DEST="$FX_BUILD/lucia_runtime_candidate"
mkdir -p "$DEST"
run_blender() { "$FX_BLENDER" --background --factory-startup --python-exit-code 3 "$@"; }
fx_gate "native skin, helpers and texture export" run_blender "$SOURCE" --python AssetFactory/blender/sway_export_runtime.py -- --id lucia --display-name Lucia --clips AssetFactory/data/clip_manifest.json --out "$DEST/Lucia" || exit 1
fx_gate "actual binary USD contract" run_blender --python AssetFactory/blender/sway_verify_runtime_usd.py -- --root "$DEST/Lucia" --report "$DEST/usd_contract.json" || exit 1
fx_gate "every exported joint sample versus native pose" run_blender "$SOURCE" --python AssetFactory/blender/sway_verify_usd_motion.py -- --root "$DEST/Lucia" --report "$DEST/usd_motion.json" || exit 1
fx_gate "labelled corrupt USD rejection fixtures" run_blender --python AssetFactory/tests/blender_usd_negative_contract.py -- --root "$DEST/Lucia" || exit 1
fx_gate "clean-scene USD import and rendered evidence" run_blender --python AssetFactory/blender/sway_render_usd_roundtrip.py -- --root "$DEST/Lucia" --out "$DEST/roundtrip" || exit 1
fx_unknown "production visual and RealityKit gates" "human visual approval and native playback remain required"
fx_finish "Unapproved runtime evidence only. No app integration, Alpha package or LKG."
fx_exit
