#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"
ROOT="$PWD"
BUILD="$(awk '/CURRENT_PROJECT_VERSION:/ {print $2; exit}' project.yml)"
echo "SWAYcore Build $BUILD — ONE CLICK"
echo "================================"
BLENDER="/Applications/Blender.app/Contents/MacOS/Blender"
[[ -x "$BLENDER" ]] || BLENDER="$(command -v blender 2>/dev/null || true)"
[[ -x "$BLENDER" ]] || { echo "✗ Blender not found"; exit 2; }
XCB="/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild"
DEVICECTL="/Applications/Xcode.app/Contents/Developer/usr/bin/devicectl"
[[ -x "$XCB" ]] || { echo "✗ Xcode not found"; exit 2; }
echo "[1/5] Generate DÜRER preview assets (production integration remains gated)"
BLENDER="$BLENDER" AssetPipeline/BUILD_ALPHA_ASSET.command
echo "[2/5] Regenerate Xcode project"
xcodegen generate
echo "[3/5] Verify source/contracts"
python3 AssetPipeline/validate_contract.py
python3 AssetPipeline/validate_reality_character_contract.py SWAY/Resources/Characters/Lucia/lucia.character.json
/bin/bash VERIFY_SWIFT_SOURCE_HAZARDS.command
echo "[4/5] Build + sign"
DERIVED="$ROOT/.build/OneClickDerivedData"
"$XCB" -project SWAY.xcodeproj -scheme SWAY -configuration Debug \
  -destination 'generic/platform=iOS' -derivedDataPath "$DERIVED" \
  -allowProvisioningUpdates build
APP="$DERIVED/Build/Products/Debug-iphoneos/SWAY.app"
[[ -d "$APP" ]] || { echo "✗ SWAY.app missing after build"; exit 3; }
echo "[5/5] Install + launch when one connected iPhone/iPad is available"
DEVICE_ID="$("$DEVICECTL" list devices 2>/dev/null | awk '/connected|available/ && /iPhone|iPad/ {for(i=1;i<=NF;i++) if($i ~ /^[0-9A-Fa-f-]{20,}$/){print $i; exit}}' || true)"
if [[ -n "$DEVICE_ID" ]]; then
  "$DEVICECTL" device install app --device "$DEVICE_ID" "$APP"
  "$DEVICECTL" device process launch --device "$DEVICE_ID" --terminate-existing com.lucasbuzek.private.sway
  echo "✓ Installed and launched on $DEVICE_ID"
else
  echo "✓ Build complete. No unambiguous connected iPhone/iPad detected; opening Xcode."
  open -a Xcode "$ROOT/SWAY.xcodeproj"
fi
echo "✓ SWAYcore Build $BUILD one-click pipeline complete"
