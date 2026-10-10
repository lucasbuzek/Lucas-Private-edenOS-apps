# BIFROST — macOS native menu-bar repair

Date: 2026-10-09. Current App: BIFROST.
Status: IMPLEMENTED / STATIC PASS / XCODE BUILD PASS / PROCESS LAUNCH PASS / PHYSICAL MENU ACCEPTANCE UNVERIFIED.

## Problem / acceptance

User reported dark-on-dark unreadable menu popover, missing or invisible macOS status-bar identity, and a quit action that did not stop or control Headless. This **supersedes** earlier menu UI acceptance assumptions.

The macOS menu must be OS-legible and usable with:
- visible BIFROST title + system-drawn network icon in menu bar, regardless of window visibility
- visible Headless and RavenNest status; mobile pairing explicitly unverified
- direct Headless Start, Stop and Web actions (not buried under disclosure)
- Quit Interface · Keep Headless and Stop Headless & Quit Interface as distinct actions
- verified launchd bootout before combined stop-and-quit terminates the native GUI
- user-controlled external Caffeinate untouched, RavenNest independent
- reliable keyboard/contrast through system-native menu appearance, not forced dark-on-dark SwiftUI rendering.

## Repaired sources

Sources/BIFROSTApp.swift: macOS MenuBarExtra(BIFROST, network SF Symbol) with native .menu style and no forced dark appearance in this menu. The full native App retains the approved spectral BIFROST branding.

Sources/StatusMenu.swift: native one-column status/action menu, direct Headless controls, readable system contrast and modal NSAlert confirmation before stopping Headless; navigation to Overview, Devices, Connections, Capabilities, JANITOR and Settings.

Sources/HeadlessClient.swift: Headless stop returns Bool only after bootout success and no remaining launchd job; registered-but-API-unreachable Headless can still be stopped; start checks launchd registration before touching runtime; external Caffeinate is observation only. Raven remains separate.

tests/test_status_menu_contract.py: 11 static safety, navigation, visibility and action regression checks.

## Existing LKG preserved

Before-fix source backup:
~/edenOS/AppDev/#App Backups/Apps/BIFROST/BIFROST_MENUBAR_PRE_FIX_20261009/

Intermediate native-menu source backup:
~/edenOS/AppDev/#App Backups/Apps/BIFROST/BIFROST_MENUBAR_NATIVE_MENU_PREFINAL_20261009/

Previous test candidate unchanged:
~/edenOS/Releases/BIFROST-20261009-macOS-TestCandidate.app

New ad-hoc signed test candidate:
~/edenOS/Releases/BIFROST-20261009-macOS-NativeMenu-TestCandidate.app

New candidate has Finder tags @App macOS / §Built / §Test / §Unverified and is indexed by AppTest. It is not a production release. Six older superseded candidates remain under Backups.

## Evidence observed on Mac

- XcodeGen PASS; Xcode 27 Debug no-sign build PASS.
- 68/68 current BIFROST Python tests PASS, including 11 native-menu contract tests.
- Strict ad-hoc signature verification, Info.plist syntax and bundled Headless/core resources PASS.
- New App process launched from the staged Releases candidate.
- AppTest Spotlight result includes tagged new candidate.
- Existing independent Headless PID 39009 and RavenNest launchd PID 845 remained unchanged after App launch.
- External Caffeinate PID 28636 remained active and untouched.
- Existing Headless API health PASS.
- macOS System Events assistive access denied (-25211), so on-screen readability, status bar layout, click navigation, and Stop/Start physical actions are NOT VERIFIED.
- No destructive stop/start operations were executed against the live Headless, RavenNest or external Caffeinate services.

## Pending physical gates

1. Verify the BIFROST icon/title appears in macOS system menu bar with the main window open and closed.
2. Verify text contrast on menu under system light/dark appearance and menu bar crowding.
3. Verify menu navigation to native App sections; Headless status truthfulness.
4. Verify Open Headless Web action and accurate UI feedback.
5. In an approved safe test window, verify Stop Headless confirmation, launchd bootout, RavenNest/external Caffeinate continuity, Headless restart and Quit Interface separately.
6. Verify Stop Headless & Quit Interface only quits when Headless shutdown succeeds, including a negative test.
7. Verify VoiceOver and keyboard menu operation.

## Wider canon unchanged

BIFROST remains CONNECT · KEEP · RESOLVE with portable shared core, macOS/Windows/Linux native+Headless variants and PWA interconnect. Windows/Linux builds, secure mobile pairing, full DP0.1 and final production gates are not accepted by this focused repair. Source authority remains ~/edenOS/Software Development/BIFROST with existing compatibility symlinks.
