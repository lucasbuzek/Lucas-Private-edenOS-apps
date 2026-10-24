#!/bin/zsh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is not installed. Install it from the official Homebrew site, then rerun this script."
  exit 2
fi
if ! command -v blender >/dev/null 2>&1; then
  echo "Optional 3D experiment: installing Blender with Homebrew cask..."
  brew install --cask blender
fi
BLENDER="$(command -v blender || true)"
if [[ -z "$BLENDER" && -x /Applications/Blender.app/Contents/MacOS/Blender ]]; then BLENDER=/Applications/Blender.app/Contents/MacOS/Blender; fi
[[ -x "$BLENDER" ]] || { echo "Blender installed but CLI executable was not found."; exit 3; }
"$BLENDER" --background --python "$ROOT/AssetPipeline/blender/generate_sway_alpha_character.py"
echo "Optional Blender 3D proof completed. This is NOT required by the 2.5D Alpha pipeline."
