#!/bin/bash
# JANITOR native macOS app - ONE-CLICK BUILDER.  Double-click, or run in Terminal.
# Builds a universal app (Apple Silicon + Intel), ad-hoc signs it, zips it, writes checksums.
# Needs: macOS 13+ to RUN the app; Xcode Command Line Tools (swift) to BUILD it. Nothing else, no network.
# Tweak: edit the TWEAKABLE block below. Source lives in ./src (SwiftUI + Swift Package Manager).
set -u

# ---- TWEAKABLE ----
ARCHS="${JANITOR_ARCHS:-arm64 x86_64}"      # e.g. JANITOR_ARCHS=arm64 for Apple Silicon only
MIN_MACOS="13.0"                            # must match Package.swift
SIGN_IDENTITY="${JANITOR_SIGN:--}"          # "-" = ad-hoc. Put a Developer ID here to sign for distribution.
# -------------------

HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/src"
OUT="${JANITOR_OUT:-$HERE/output}"
APP="$OUT/JANITOR.app"
say()   { printf '%s\n' "$*"; }
pause() { if [ -t 0 ] && [ -z "${JANITOR_NOPAUSE:-}" ]; then read -r -p "Press Return to close..." _; fi; }
fail()  { say ""; say "FAILED: $*"; pause; exit 1; }

[ -f "$SRC/Package.swift" ] || fail "src/Package.swift not found next to this script."
command -v swift >/dev/null 2>&1 || fail "Swift was not found. Install the free Xcode Command Line Tools: run  xcode-select --install  then double-click this again. Nothing was changed."
VER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$SRC/Resources/Info.plist" 2>/dev/null)
[ -n "$VER" ] || VER="unknown"
say "JANITOR native $VER - building for: $ARCHS"
say "Output: $OUT"
mkdir -p "$OUT" || fail "cannot create $OUT"

BINS=()
for A in $ARCHS; do
  say ""; say "== Building $A =="
  SCR="$OUT/.build-$A"
  if swift build -c release --package-path "$SRC" --triple "$A-apple-macosx$MIN_MACOS" --scratch-path "$SCR" > "$OUT/build-$A.log" 2>&1; then
    B="$(swift build -c release --package-path "$SRC" --triple "$A-apple-macosx$MIN_MACOS" --scratch-path "$SCR" --show-bin-path 2>/dev/null)/JANITOR"
    if [ -f "$B" ]; then say "   built $A"; BINS+=("$B"); else say "   $A: build reported success but binary not found (see build-$A.log)"; fi
  else
    say "   $A FAILED - see $OUT/build-$A.log"
  fi
done
[ ${#BINS[@]} -gt 0 ] || fail "no architecture built. See the build-*.log files in $OUT."

say ""; say "== Assembling JANITOR.app =="
rm -rf "$APP"; mkdir -p "$APP/Contents/MacOS" || fail "cannot create app folder"
set -- "${BINS[@]}"
if [ $# -gt 1 ]; then lipo -create "$@" -output "$APP/Contents/MacOS/JANITOR" || fail "lipo failed"; else cp "$1" "$APP/Contents/MacOS/JANITOR"; fi
chmod +x "$APP/Contents/MacOS/JANITOR"
cp "$SRC/Resources/Info.plist" "$APP/Contents/Info.plist" || fail "Info.plist missing"
codesign --force --deep --sign "$SIGN_IDENTITY" "$APP" >/dev/null 2>&1 || fail "codesign failed"
codesign --verify --deep --strict "$APP" 2>/dev/null && say "   signed and verified ($( [ "$SIGN_IDENTITY" = "-" ] && echo ad-hoc || echo "$SIGN_IDENTITY" ))" || fail "signature did not verify"
ARCH_INFO=$(lipo -archs "$APP/Contents/MacOS/JANITOR" 2>/dev/null)
say "   architectures: $ARCH_INFO"

ZIP="$OUT/JANITOR-$VER-macOS.zip"
rm -f "$ZIP"; ditto -c -k --keepParent "$APP" "$ZIP" || fail "zip failed"
( cd "$OUT" && shasum -a 256 "JANITOR-$VER-macOS.zip" "JANITOR.app/Contents/MacOS/JANITOR" > SHA256SUMS.txt )
cat > "$OUT/BUILD_RECORD.txt" <<EOF
JANITOR native $VER - macOS $MIN_MACOS or newer. Architectures: $ARCH_INFO. Signing: $SIGN_IDENTITY ("-" = ad-hoc).
Built on: $(sw_vers -productVersion 2>/dev/null) $(uname -m), $(date '+%Y-%m-%d %H:%M')
STATE: BUILT, UNVERIFIED. This builder does not launch or click through the app. Open it once and try Check my Mac before trusting it.
First launch of an ad-hoc signed app: right-click JANITOR.app, Open (Gatekeeper asks once).
EOF
rm -rf "$OUT"/.build-*
say ""; say "DONE."; say "  App: $APP"; say "  Zip: $ZIP"
pause
