#!/bin/bash
set -u
cd "$(dirname "$0")" || exit 1

echo "SWAYcore 0.9 Build 149 — iOS DEVELOPMENT INSTALLER"
echo "=============================="
echo "Build 149 scalable workout avatar: protected tracking recovery, scalable COACH/YOU stage, distance-readable workout UI."
echo

DEV="/Applications/Xcode.app/Contents/Developer"
XCB="$DEV/usr/bin/xcodebuild"
DEVICETCTL="$DEV/usr/bin/devicectl"
DEVICE_ID="00008130-000A71383A0B803A"
BUNDLE_ID="com.lucasbuzek.private.sway"
DERIVED="$PWD/.build/DerivedData"
APP="$DERIVED/Build/Products/Debug-iphoneos/SWAY.app"
LOG="$PWD/build.log"

[ -x "$XCB" ] || { echo "✗ Xcode not found."; exit 1; }

# Package identity preflight: never install a stale/mixed build.
EXPECTED_BUILD="149"
grep -q "CURRENT_PROJECT_VERSION = $EXPECTED_BUILD" "$PWD/SWAY.xcodeproj/project.pbxproj" || { echo "✗ Build identity mismatch in Xcode project."; exit 3; }
grep -q "CURRENT_PROJECT_VERSION: $EXPECTED_BUILD" "$PWD/project.yml" || { echo "✗ Build identity mismatch in project.yml."; exit 3; }
grep -q "SWAYcore 0.9 Build $EXPECTED_BUILD" "$PWD/BUILD_INFO.txt" || { echo "✗ Build identity mismatch in BUILD_INFO.txt."; exit 3; }

# Recover team ONLY from an existing SWAY provisioning profile.
TEAM_ID=""
for DIR in "$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles" "$HOME/Library/MobileDevice/Provisioning Profiles"; do
  [ -d "$DIR" ] || continue
  while IFS= read -r PROFILE; do
    TMP="$(mktemp -t swayprofile)"
    if security cms -D -i "$PROFILE" > "$TMP" 2>/dev/null; then
      APP_ID="$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:application-identifier' "$TMP" 2>/dev/null || true)"
      case "$APP_ID" in
        *."$BUNDLE_ID")
          TEAM_ID="$(/usr/libexec/PlistBuddy -c 'Print :TeamIdentifier:0' "$TMP" 2>/dev/null || true)"
          rm -f "$TMP"
          [ -n "$TEAM_ID" ] && break 2
          ;;
      esac
    fi
    rm -f "$TMP"
  done < <(find "$DIR" -maxdepth 1 -type f \( -name '*.mobileprovision' -o -name '*.provisionprofile' \) -print 2>/dev/null)
done

if [ -z "$TEAM_ID" ]; then
  echo "✗ Existing SWAY Personal Team profile not found."
  echo "One Apple approval is required: open SWAY.xcodeproj, select your Personal Team once, then Run."
  echo "After Xcode creates the profile, this installer becomes one-click."
  open -a /Applications/Xcode.app "$PWD/SWAY.xcodeproj"
  exit 2
fi

echo "✓ Existing SWAY provisioning team recovered: $TEAM_ID"
echo "✓ Physical iPhone: $DEVICE_ID"
echo
echo "[1/2] Build + sign"

"$XCB" \
  -project "$PWD/SWAY.xcodeproj" \
  -scheme SWAY \
  -configuration Debug \
  -destination "platform=iOS,id=$DEVICE_ID" \
  -derivedDataPath "$DERIVED" \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  build 2>&1 | tee "$LOG"
STATUS=${PIPESTATUS[0]}

if [ "$STATUS" -ne 0 ]; then
  echo
  echo "✗ BUILD FAILED — exact Xcode error above."
  exit "$STATUS"
fi

[ -d "$APP" ] || { echo "✗ SWAY.app not found after successful build."; exit 1; }

echo
echo "[2/2] Install + launch"
"$DEVICETCTL" device install app --device "$DEVICE_ID" "$APP" || exit 1
"$DEVICETCTL" device process launch --device "$DEVICE_ID" --terminate-existing "$BUNDLE_ID" || exit 1
echo
echo "✓ SWAYcore Build 149 installed and launched."
