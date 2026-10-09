#!/bin/zsh
set -euo pipefail
ROOT="${0:A:h}"; OUT="$ROOT/output"; APP="$OUT/JANITOR.app"; SRC="$OUT/src"
rm -rf "$OUT"; mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$SRC"
cat > "$SRC/main.swift" <<'SWIFT'
import SwiftUI
@main struct JanitorApp: App { var body: some Scene { WindowGroup { ContentView() } } }
struct ContentView: View {
 @State private var section="Overview"
 let sections=["Overview","Standard","Developer","Media","Full Crew","Quarantine"]
 var body: some View { NavigationView { List(sections,id:\.self,selection:$section){ Text($0) }.frame(minWidth:190); VStack(alignment:.leading,spacing:16){ Text(section).font(.largeTitle.bold()); Text("JANITOR — Justified Analysis, Navigation, Inspection, Tidying, Optimization & Recovery").foregroundStyle(.secondary); GroupBox { VStack(alignment:.leading,spacing:10){ Label("Ready",systemImage:"checkmark.circle"); Text(section == "Full Crew" ? "Processes and services: inspect; identified user/third-party services may Start, Stop, Restart, Enable or Disable. Apple system services remain protected." : "Self-contained baseline. Capability-first; installed compatible tools are optional accelerators.") } }.frame(maxWidth:.infinity,alignment:.leading); Spacer() }.padding(28) }.frame(minWidth:860,minHeight:600) }
}
SWIFT
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"><plist version="1.0"><dict><key>CFBundleExecutable</key><string>JANITOR</string><key>CFBundleIdentifier</key><string>com.eden.janitor</string><key>CFBundleName</key><string>JANITOR</string><key>CFBundlePackageType</key><string>APPL</string><key>CFBundleShortVersionString</key><string>0.14.0</string><key>LSMinimumSystemVersion</key><string>11.0</string><key>CFBundleDevelopmentRegion</key><string>en</string><key>CFBundleLocalizations</key><array><string>en</string><string>sk</string><string>af</string><string>zu</string></array><key>NSHighResolutionCapable</key><true/></dict></plist>
PLIST
SDK="$(xcrun --sdk macosx --show-sdk-path)"; SWIFTC="$(xcrun -f swiftc)"; BUILT=()
for A in arm64 x86_64; do "$SWIFTC" -parse-as-library -O -sdk "$SDK" -target "$A-apple-macos11.0" "$SRC/main.swift" -o "$OUT/JANITOR-$A" 2>"$OUT/$A.log" && BUILT+=("$A") || true; done
(( ${#BUILT[@]} > 0 )) || { echo 'Build failed'; exit 1; }
if (( ${#BUILT[@]} == 2 )); then lipo -create "$OUT/JANITOR-arm64" "$OUT/JANITOR-x86_64" -output "$APP/Contents/MacOS/JANITOR"; else cp "$OUT/JANITOR-${BUILT[1]}" "$APP/Contents/MacOS/JANITOR"; fi
chmod +x "$APP/Contents/MacOS/JANITOR"; codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true
echo "BUILT: $APP"
