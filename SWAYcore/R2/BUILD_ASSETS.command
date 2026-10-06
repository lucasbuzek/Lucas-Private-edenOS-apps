#!/bin/bash
# SWAYcore one-click entry point: SWAYcore ASSET FACTORY (Blender -> SWAYHumanoid-v1 -> USD runtime)
# Double-click, or run from Terminal. Safe to re-run: idempotent, installs only missing declared tools, never deletes user data.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd -P)"
. "$HERE/Scripts/factory_lib.sh" || { echo "FAIL: cannot load Scripts/factory_lib.sh"; exit 2; }
fx_init "$HERE"

MODE="production"; BASE=""; LEDGER=""; RELEASE_SCOPE="alpha"
while [ $# -gt 0 ]; do case "$1" in --include-beta) RELEASE_SCOPE="all";; --technical-proof) MODE="technical";; --base) BASE="$2"; shift;; --ledger-id) LEDGER="$2"; shift;; esac; shift; done
# If production is invoked with no explicit base, reuse a previously registered ACQUIRED ADAPT/ADOPT model.
# This makes BUILD_ASSETS/BUILD_ALL genuinely one-click after the one-time provenance gate.
if [ "$MODE" = production ] && [ -z "$BASE" ]; then
  AUTO="$(python3 - "$FX_ROOT" <<'PYAUTO'
import json,os,sys
r=sys.argv[1]; x=json.load(open(os.path.join(r,'AssetFactory','PROVENANCE','ledger.json')))
for e in x.get('sources',[]):
    if e.get('status')=='ACQUIRED' and e.get('decision') in ('ADAPT','ADOPT'):
        for f in e.get('files',[]):
            p=f.get('path','')
            if os.path.splitext(p)[1].lower() in ('.glb','.gltf','.fbx','.blend') and os.path.isfile(os.path.join(r,p)):
                print(p+'|'+e['id']); raise SystemExit
PYAUTO
)"
  if [ -n "$AUTO" ]; then BASE="${AUTO%%|*}"; LEDGER="${AUTO##*|}"; echo "production base: reusing registered $LEDGER -> $BASE"; fi
fi

fx_gate "asset-factory unit tests (retarget math, provenance, clip periods, validators)" py_suite discover -s AssetFactory/tests
fx_gate "preflight: disk >= 8 GB" pf_disk 8 "asset generation"
if [ "$MODE" = production ] && [ -z "$BASE" ]; then
  # Blender is not needed (and is not installed) until there is something to convert.
  fx_unknown "production: legal base model acquired" "BLOCKED: no base supplied. Acquire a CC0 humanoid base (candidate: Quaternius Universal Base Characters), save it under AssetFactory/sources/, save the licence text beside it, register it with AssetFactory/python/register_source.py (requires explicit rights confirmation), then run: BUILD_ASSETS.command --base AssetFactory/sources/<file> --ledger-id <id>.  To prove the Blender tooling first, run: BUILD_ASSETS.command --technical-proof"
  fx_finish "Production asset generation is waiting on an external, human-confirmed licensing step (not a tooling failure)."; fx_exit; exit
fi
fx_gate "preflight: Blender (find, install only if missing, version)" pf_blender || { fx_finish "Blender unavailable"; fx_exit; exit; }
WORK="$FX_BUILD/work"; mkdir -p "$WORK"
CLIPS="$FX_ROOT/AssetFactory/data/clip_manifest.json"; BL="$FX_ROOT/AssetFactory/blender"
run_blender() { [ -n "$FX_BLENDER" ] || find_blender || { echo "Blender executable not found"; return 1; }; "$FX_BLENDER" --background --factory-startup --python-exit-code 3 "$@"; }
if [ "$MODE" = technical ]; then
  # Proves bake/validate/export with REAL Blender on the Build 153 stepping-stone rig. NOT a production character; NOT copied into app resources.
  SRC="$FX_ROOT/App/AssetPipeline/output/SWAYAlpha_BUILD153.blend"; T="$WORK/technical"; mkdir -p "$T"
  fx_gate "technical: copy Build153 blend (original untouched)" cp "$SRC" "$T/lucia_alpha.blend"
  fx_gate "technical: bake 21 coach clips from SwayCoachPoseEngine port" run_blender "$T/lucia_alpha.blend" --python "$BL/sway_bake_clips.py" -- --clips "$CLIPS" --out-blend "$T/lucia_alpha.blend"
  fx_gate "technical: structural validation + deformation sanity" run_blender "$T/lucia_alpha.blend" --python "$BL/sway_validate_character.py" -- --clips "$CLIPS" --report "$FX_REPORT/character_technical.json"
  fx_gate "technical: export USD base + 21 clips" run_blender "$T/lucia_alpha.blend" --python "$BL/sway_export_runtime.py" -- --id lucia --display-name Lucia --clips "$CLIPS" --out "$T/Runtime/Characters/Lucia"
  fx_gate "technical: validate exported runtime set (structural)" python3 "$FX_ROOT/AssetFactory/python/validate_runtime_assets.py" "$T/Runtime/Characters" "$CLIPS" --require Lucia
  fx_unknown "technical: visual quality" "Build153 avatar appearance is REJECTED by authority; this run proves tooling only"
  fx_finish "TECHNICAL PROOF complete (tooling evidence only). Production characters need a legally acquired base model: see the production-mode instructions."
else
  CHARS="$FX_ROOT/AssetFactory/data/characters.json"
  if [ "$LEDGER" = girush-human-yw-cc0 ]; then
    # Girush must keep its native skin/helper rig. The generic UE conversion
    # below is not a valid adapter, and cloning Lucia is not YOUR DANCER.
    NATIVE_SOURCE="$FX_ROOT/Build/experiments/girush_sway_alpha_repaired/lucia_source_meter.blend"
    fx_gate "Girush: proven native candidate pipeline" bash "$FX_ROOT/BUILD_LUCIA_CANDIDATE.command" "$NATIVE_SOURCE"
    fx_unknown "YOUR DANCER native variants" "creator appearance chain is unpassed; Girush Lucia is not duplicated as YOUR DANCER"
    fx_unknown "production runtime integration" "native candidate requires motion/readability repair, human visual gate and RealityKit verification"
    fx_finish "Native Girush evidence only. No production asset approval, Alpha package or LKG."
    fx_exit
    exit
  fi
  if [ -z "$BASE" ]; then
    fx_unknown "production: legal base model acquired" "BLOCKED: no base supplied. Acquire a CC0 humanoid base (candidate: Quaternius Universal Base Characters), save it under AssetFactory/sources/, save the licence text beside it, register it with AssetFactory/python/register_source.py (requires explicit rights confirmation), then run: BUILD_ASSETS.command --base AssetFactory/sources/<file> --ledger-id <id>"
    fx_finish "Production asset generation is waiting on an external, human-confirmed licensing step (not a tooling failure)."; fx_exit; exit
  fi
  OUT="$FX_ROOT/Assets/Runtime/Characters"; BLENDDIR="$FX_ROOT/Assets/Blend"; mkdir -p "$OUT" "$BLENDDIR"
  fx_preserve_recovery "Assets" "$FX_ROOT/Assets/Runtime" "$FX_ROOT/Assets/Blend"
  PAIRS="$(asset_pairs "$RELEASE_SCOPE")"
  REQUIRED="$(printf '%s\n' "$PAIRS" | cut -d: -f2 | paste -sd, -)"
  for pair in $PAIRS; do
    id="${pair%%:*}"; dir="${pair##*:}"; B="$BLENDDIR/$id.blend"
    fx_gate "$id: convert base -> SWAYHumanoid-v1" run_blender --python "$BL/sway_convert_base.py" -- --base "$BASE" --map "$FX_ROOT/AssetFactory/data/retarget_map_ue_mannequin.json" --character "$CHARS" --id "$id" --ledger-id "$LEDGER" --out "$B" || continue
    fx_gate "$id: bake coach clips" run_blender "$B" --python "$BL/sway_bake_clips.py" -- --clips "$CLIPS" --out-blend "$B" || continue
    # Validation failure is evidence and prevents approval, but does not prevent generation of an explicitly
    # runtimeApproved=false development candidate for inspection/engine integration testing.
    fx_gate "$id: validate (structure + deformation sanity)" run_blender "$B" --python "$BL/sway_validate_character.py" -- --clips "$CLIPS" --report "$FX_REPORT/character_$id.json" || true
    fx_gate "$id: export UNAPPROVED runtime USD candidate" run_blender "$B" --python "$BL/sway_export_runtime.py" -- --id "$id" --display-name "$dir" --clips "$CLIPS" --out "$OUT/$dir"
  done
  fx_gate "validate runtime set (structural only)" python3 "$FX_ROOT/AssetFactory/python/validate_runtime_assets.py" "$OUT" "$CLIPS" --require "$REQUIRED" --only-required --report "$FX_REPORT/runtime_assets.json"
  fx_unknown "production: character visual quality + silhouette" "REQUIRES HUMAN REVIEW (open Assets/Blend/*.blend); manifests stay runtimeApproved=false until a human approves"
  fx_finish "Production asset run complete. Nothing is auto-approved or auto-integrated into app resources."
fi

fx_exit
