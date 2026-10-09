#!/bin/zsh
# Authoritative JANITOR native macOS builder. Reuses existing actual SwiftUI source;
# never generates a replacement / placeholder application.
set -euo pipefail
PROJECT="$(cd "$(dirname "$0")/../.." && pwd)"
EDEN_ROOT="$(cd "$PROJECT/../.." && pwd)"
NATIVE="$PROJECT/native"
ENGINE="$PROJECT/builders/v2/macos-app/Build-JANITOR-macOS.command"
[[ -f "$NATIVE/Package.swift" && -f "$ENGINE" ]] || { print -u2 "Missing current native source or builder"; exit 1; }
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$NATIVE/Resources/Info.plist")"
[[ -n "$VERSION" ]] || { print -u2 "Missing version"; exit 1; }
ARCHS="${JANITOR_ARCHS:-arm64 x86_64}"
ARCH_LABEL="${ARCHS// /-}"
OUT="${JANITOR_OUT:-$EDEN_ROOT/Releases/JANITOR/$VERSION-native-$ARCH_LABEL}"
[[ ! -e "$OUT" ]] || { print -u2 "Refusing to replace existing release: $OUT"; exit 2; }
mkdir -p "$EDEN_ROOT/Temporary/JANITOR" "$(dirname "$OUT")"
STAGE="$(mktemp -d "$EDEN_ROOT/Temporary/JANITOR/native-build.XXXXXXXX")"
trap 'rm -rf "$STAGE"' EXIT
cp "$ENGINE" "$STAGE/Build-JANITOR-macOS.command"
ditto "$NATIVE" "$STAGE/src"
JANITOR_ARCHS="$ARCHS" JANITOR_OUT="$OUT" JANITOR_NOPAUSE=1 /bin/bash "$STAGE/Build-JANITOR-macOS.command"
ZIP="$OUT/JANITOR-$VERSION-macOS.zip"
[[ -s "$ZIP" && -x "$OUT/JANITOR.app/Contents/MacOS/JANITOR" ]] || { print -u2 "Missing built app or archive"; exit 3; }
for arch in ${=ARCHS}; do
  lipo -archs "$OUT/JANITOR.app/Contents/MacOS/JANITOR" | grep -qw "$arch" || { print -u2 "Requested architecture absent: $arch"; exit 4; }
done
codesign --verify --deep --strict "$OUT/JANITOR.app"
( cd "$OUT" && shasum -a 256 -c SHA256SUMS.txt )
print "JANITOR authoritative native source package: $ZIP"
print "EVIDENCE: built, package verified. UI/physical acceptance remains separate."
