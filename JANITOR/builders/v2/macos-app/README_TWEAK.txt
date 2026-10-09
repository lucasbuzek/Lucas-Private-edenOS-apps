JANITOR native macOS app - builder package
Double-click Build-JANITOR-macOS.command (right-click, Open the first time). Output goes to output/ : JANITOR.app, a zip, checksums, build record.
Needs the free Xcode Command Line Tools (xcode-select --install). The app itself needs macOS 13 or newer.
For macOS older than 13 use the terminal edition (janitor.sh) instead.
Source: src/ (SwiftUI + Swift Package Manager). Main files: Sources/JANITOR/Core.swift (engine and safety rules), Model.swift, Views.swift, Levels.swift (Simple/Advanced/Expert + Favorites).
Tweaks: top of the .command (architectures, signing identity), Resources/Info.plist (version, name).
Contract to keep: UNKNOWN is not JUNK; cloud and Photos are never traversed; quarantine with manifest and restore; nothing is deleted without confirmation.
Status: builds verified by running this builder; the app UI itself has not been click-tested.
