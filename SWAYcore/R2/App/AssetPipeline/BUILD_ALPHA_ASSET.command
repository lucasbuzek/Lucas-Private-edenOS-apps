#!/bin/zsh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
BLENDER="${BLENDER:-/Applications/Blender.app/Contents/MacOS/Blender}"
[[ -x "$BLENDER" ]] || BLENDER="$(command -v blender 2>/dev/null || true)"
[[ -x "$BLENDER" ]] || { echo "BLOCKED: Blender not found"; exit 2; }
python3 "$HERE/validate_contract.py"
OUT="$HERE/output"
CLIPS="$OUT/clips"
mkdir -p "$OUT" "$CLIPS"
rm -f "$CLIPS"/*.usdc(N)
"$BLENDER" --background --python "$HERE/blender/generate_sway_alpha_character.py" -- \
  --output "$OUT/SWAYAlpha_BUILD153.blend" --usd-dir "$CLIPS"
COUNT=$(find "$CLIPS" -name '*.usdc' -type f | wc -l | tr -d ' ')
[[ "$COUNT" == 10 ]] || { echo "FAIL: expected 10 authored runtime clips, got $COUNT"; exit 3; }
echo "PASS: generated $COUNT Blender preview clips under $CLIPS"
echo "NOT INTEGRATED: production rig/material/texture approval is required before app resources or character identities change."
