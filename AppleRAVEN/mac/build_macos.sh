#!/bin/bash
# macOS-only release build: original AppleRAVEN agent + first-run local pairing installer.
# Produces an unsigned test DMG. Never claims Developer ID signing/notarization.
set -euo pipefail
[[ "$(uname -s)" == Darwin ]] || { echo 'macOS runner required'; exit 1; }
ROOT="$(cd "$(dirname "$0")" && pwd -P)"
OUT="$ROOT/dist"
APP="$OUT/AppleRAVEN.app"
[[ ! -e "$OUT" ]] || { echo "Existing build output retained; choose a clean checkout for this build." >&2; exit 1; }
mkdir -p "$OUT"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/launcher.applescript" <<'APPLESCRIPT'
on run
    set appRoot to POSIX path of (path to me)
    set setupFile to appRoot & "Contents/Resources/Install.command"
    tell application "Terminal"
        activate
        do script "/bin/bash " & quoted form of setupFile
    end tell
end run
APPLESCRIPT

/usr/bin/osacompile -o "$APP" "$TMP/launcher.applescript"
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.lucasbuzek.appleraven" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleName AppleRAVEN" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString 0.1.0" "$APP/Contents/Info.plist" ||
  /usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string 0.1.0" "$APP/Contents/Info.plist"
/usr/bin/plutil -lint "$APP/Contents/Info.plist"
/bin/cp "$ROOT/Install.command" "$ROOT/appleraven_agent.py" "$APP/Contents/Resources/"
/bin/chmod 755 "$APP/Contents/Resources/Install.command"
/bin/chmod 644 "$APP/Contents/Resources/appleraven_agent.py"
/bin/bash -n "$APP/Contents/Resources/Install.command"
"/bin/bash" "$APP/Contents/Resources/Install.command" --dry-run
python3 -m py_compile "$APP/Contents/Resources/appleraven_agent.py"

ARCH_INFO="$(/usr/bin/lipo -info "$APP/Contents/MacOS/applet")"
printf 'Mac executable architecture: %s\n' "$ARCH_INFO"
/usr/bin/lipo -verify_arch arm64 "$APP/Contents/MacOS/applet"

# An AppleScript wrapper is the macOS desktop launcher; the native device
# execution runs in user-context Python. The app requests no admin permission.
/usr/bin/codesign --force --deep --sign - "$APP"
STAGING="$TMP/image"
mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/AppleRAVEN.app"
ln -s /Applications "$STAGING/Applications"
/usr/bin/hdiutil create -srcfolder "$STAGING" -volname AppleRAVEN -ov -format UDZO "$OUT/AppleRAVEN-Mac-M1-0.1.0-UNNOTARIZED.dmg"
/usr/bin/hdiutil verify "$OUT/AppleRAVEN-Mac-M1-0.1.0-UNNOTARIZED.dmg"
(cd "$OUT" && /usr/bin/shasum -a 256 "AppleRAVEN-Mac-M1-0.1.0-UNNOTARIZED.dmg" > SHA256SUMS.txt)
printf '\nBuild artifact: %s\n' "$OUT/AppleRAVEN-Mac-M1-0.1.0-UNNOTARIZED.dmg"
printf 'TEST RELEASE: ad-hoc signed only; NOT notarized and NOT a production Installer.\n'

