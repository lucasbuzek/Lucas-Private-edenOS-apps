#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"
ROOT="$PWD"
BUILD=153
BUNDLE_ID="com.lucasbuzek.private.sway"
STAMP="$(date +%Y%m%d-%H%M%S)"
EVIDENCE="$ROOT/AlphaEvidence/$STAMP"
mkdir -p "$EVIDENCE"
exec > >(tee "$EVIDENCE/run.log") 2>&1

echo "SWAYcore Build $BUILD — FULL FEATURE ALPHA"
echo "Local-first / OFFLINE-capable build and test launcher"
echo "===================================================="

# No Internet fetches are performed by this launcher.
ONLINE=0
if /sbin/ping -c 1 -t 1 1.1.1 >/dev/null 2>&1; then ONLINE=1; fi
echo "Network: $([[ $ONLINE == 1 ]] && echo available || echo OFFLINE) — provider tests are non-blocking"

XCODE_DEV="/Applications/Xcode.app/Contents/Developer"
XCB="$XCODE_DEV/usr/bin/xcodebuild"
DEVICECTL="$XCODE_DEV/usr/bin/devicectl"
BLENDER="${BLENDER:-}"
[[ -x "$BLENDER" ]] || BLENDER="$(command -v blender 2>/dev/null || true)"
[[ -x "$BLENDER" ]] || BLENDER="/Applications/Blender.app/Contents/MacOS/Blender"

{
  echo "date=$(date -Iseconds)"
  echo "build=$BUILD"
  echo "network=$ONLINE"
  echo "xcode=$([[ -x "$XCB" ]] && echo yes || echo no)"
  echo "blender=$([[ -x "$BLENDER" ]] && echo yes || echo no)"
  uname -a
} > "$EVIDENCE/environment.txt"
cp "$ROOT/AlphaTest/physical_test_checklist.md" "$EVIDENCE/physical_test_checklist.md"

echo
echo "[1/7] Package identity + contracts"
grep -q "CURRENT_PROJECT_VERSION: $BUILD" project.yml
grep -q "INFOPLIST_KEY_CFBundleVersion: $BUILD" project.yml
grep -q "CURRENT_PROJECT_VERSION = $BUILD" SWAY.xcodeproj/project.pbxproj
grep -q "INFOPLIST_KEY_CFBundleVersion = $BUILD" SWAY.xcodeproj/project.pbxproj
python3 AssetPipeline/validate_contract.py
python3 AssetPipeline/validate_reality_character_contract.py SWAY/Resources/Characters/Lucia/lucia.character.json
python3 AssetPipeline/validate_reality_character_contract.py SWAY/Resources/Characters/UserAvatar/user.character.json
/bin/bash VERIFY_SWIFT_SOURCE_HAZARDS.command

echo
echo "[2/7] Blender / DÜRER"
if [[ -x "$BLENDER" ]]; then
  mkdir -p AssetPipeline/output
  set +e
  BLENDER="$BLENDER" AssetPipeline/BUILD_ALPHA_ASSET.command 2>&1 | tee "$EVIDENCE/blender.log"
  BLENDER_STATUS=${pipestatus[1]}
  set -e
  if [[ "$BLENDER_STATUS" -ne 0 ]]; then
    echo "FAIL: DÜRER asset generation/integration failed."
    echo "blender=FAIL" >> "$EVIDENCE/environment.txt"
    exit "$BLENDER_STATUS"
  fi
  echo "blender=PASS" >> "$EVIDENCE/environment.txt"
  xcodegen generate | tee "$EVIDENCE/xcodegen.log"
else
  echo "BLOCKER: Blender executable not found. Existing protected 2.5D runtime remains untouched."
  echo "Install/restore Blender locally; this launcher intentionally performs no network install."
fi

echo
echo "[3/7] Xcode"
if [[ ! -x "$XCB" ]]; then
  echo "BLOCKER: full Xcode is not available at /Applications/Xcode.app."
  echo "Apple's xcodebuild/devicectl require full Xcode. Source and evidence are preserved."
  exit 20
fi
export DEVELOPER_DIR="$XCODE_DEV"
"$XCB" -version | tee "$EVIDENCE/xcode-version.txt"
open -a Xcode "$ROOT/SWAY.xcodeproj" >/dev/null 2>&1 || true

echo
echo "[4/7] Swift/static verification"
for f in $(find SWAY -name '*.swift' -type f); do
  xcrun swiftc -frontend -parse "$f"
done
echo "Swift parse PASS"

echo
echo "[5/7] Build candidate"
DERIVED="$ROOT/.build/DerivedData"
set +e
"$XCB" -project "$ROOT/SWAY.xcodeproj" -scheme SWAY -configuration Debug \
  -destination "generic/platform=iOS" -derivedDataPath "$DERIVED" \
  -allowProvisioningUpdates build 2>&1 | tee "$EVIDENCE/xcodebuild.log"
BUILD_STATUS=${pipestatus[1]}
set -e
if [[ "$BUILD_STATUS" -ne 0 ]]; then
  echo "Xcode build did not pass. Xcode remains open for signing/build diagnosis."
  echo "build=FAIL" >> "$EVIDENCE/environment.txt"
  exit "$BUILD_STATUS"
fi
echo "build=PASS" >> "$EVIDENCE/environment.txt"

APP="$DERIVED/Build/Products/Debug-iphoneos/SWAY.app"
[[ -d "$APP" ]] || { echo "Build reported success but SWAY.app was not found."; exit 21; }

echo
echo "[6/7] Connected-device discovery"
"$DEVICECTL" list devices 2>&1 | tee "$EVIDENCE/devices.txt" || true
# Do not hard-code a device. If one physical device is connected, try it; otherwise leave selection to Xcode.
DEVICE_ID="$("$DEVICECTL" list devices 2>/dev/null | awk '/connected|available/ && /iPhone|iPad/ {for(i=1;i<=NF;i++) if($i ~ /^[0-9A-Fa-f-]{20,}$/){print $i; exit}}' || true)"
if [[ -n "$DEVICE_ID" ]]; then
  echo "Connected test device detected: $DEVICE_ID"
  if "$DEVICECTL" device install app --device "$DEVICE_ID" "$APP" | tee "$EVIDENCE/install.txt"; then
    "$DEVICECTL" device process launch --device "$DEVICE_ID" --terminate-existing "$BUNDLE_ID" | tee "$EVIDENCE/launch.txt" || true
  fi
else
  echo "No unambiguous connected iPhone/iPad was auto-selected."
  echo "Xcode is open: select your iPhone or iPad and press Run. No device identity is hard-coded."
fi

echo
echo "[7/7] Full Feature Alpha physical gate"
echo "Checklist: $EVIDENCE/physical_test_checklist.md"
echo "Evidence:  $EVIDENCE"
open "$EVIDENCE" >/dev/null 2>&1 || true
echo
echo "Build/static stages completed locally. Physical gates remain yours to mark PASS/FAIL on device."
