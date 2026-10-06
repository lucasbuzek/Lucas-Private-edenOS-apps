#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
BUILD="$(awk '/CURRENT_PROJECT_VERSION:/ {print $2; exit}' project.yml)"
echo "SWAYcore Build $BUILD — candidate verification"
plutil -lint SWAY.xcodeproj/project.pbxproj
if grep -q 'DesignReferences' SWAY.xcodeproj/project.pbxproj; then echo 'FAIL: DesignReferences is referenced by Xcode'; exit 2; fi
SWIFTC="$(command -v xcrun >/dev/null 2>&1 && echo 'xcrun swiftc -frontend -parse' || echo 'swiftc -parse')"
for f in $(find SWAY -name '*.swift' -type f); do eval "$SWIFTC \"$f\"" >/dev/null; done
echo "Swift parse: PASS"
if command -v xcodebuild >/dev/null 2>&1; then
  echo "Starting unsigned Xcode compile..."
  xcodebuild -project SWAY.xcodeproj -scheme SWAY -configuration Debug -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
  echo "Xcode compile: PASS"
else
  echo "ENVIRONMENT GATE: xcodebuild unavailable; compile remains pending on macOS/Xcode."
fi
