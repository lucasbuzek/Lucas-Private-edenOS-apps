# BIFROST Headless, Menu Bar, Compact Dashboard — 2026-10-09

## Scope and candidate status
Additive macOS implementation. The pre-change ZIP and existing RavenNest remain preserved. No GitHub or Cloudflare production modifications.

## Implemented
- Independent Python-standard-library Headless local service at 127.0.0.1:8798, independent of SwiftUI, RavenNest, Cloudflare or RDC.
- Compact Headless web dashboard with real service state, task status, Caffeinate, Raven bridge status and settings.
- Shared per-user JSON preferences in ~/Library/Application Support/BIFROST/settings.json: Headless and Active Tasks menu indicators, automatic AI routing preference, default Caffeinate 60 minutes, selectable dashboard rows.
- SwiftUI HeadlessClient starts/stops an independently managed per-user launchd agent eden.bifrost.headless and opens its local web UI.
- Full native Overview uses compact status rows; the previous Overview remains in a disclosure group for compatibility.
- Menu bar opens Web, full macOS App and Preferences; manages Headless service and timed Caffeinate; Quitting GUI does not quit Headless.
- Caffeinate is owned by Headless instead of a GUI process, with 30/60/120-minute and until-stopped choices.
- Read-only Codex Cloud task-count collector; status UNKNOWN if Codex or network unavailable. No task submission or apply.
- RavenNest remains a separate, untouched capability provider.
- Stored AI routing auto preference does NOT mean a working AI provider or automatic model execution.
- Web controls use loopback-only binding plus Host/Origin validation and local token to reduce CSRF. This is NOT a remote multiuser authentication boundary.

## Lifecycle limitations
- Headless currently runs as a per-user macOS LaunchAgent, not a boot-before-login LaunchDaemon.
- Independent from the GUI and Menu Bar when logged in; user starts or stops the service explicitly.
- Local web dashboard is not published over the Internet. No cross-device auth is implied.
- Specialist EDEN Apps retain their own ownership; not absorbed into BIFROST.
- App built and offline-tested is not a release until Mac UI and full Headless physical gates pass.

## Recovery
Prechange backup ZIP:
~/edenOS/AppDev/#App Backups/Apps/BIFROST/BIFROST_NATIVE_PRE_HEADLESS_20261009_0831.zip
SHA256 7698df1d355bede2c33aa5d679273bbcc74d72143742e8266e89e59cc68fadbc
ZIP integrity verified. October 5 recovery copies retained. RavenNest Git branches and launch agent unchanged.

## Verification
Run from the native BIFROST project root:
- python3 -B -m unittest discover -s tests -v
- node --check headless/dashboard.js
- xcodegen generate --spec project.yml
- xcodebuild -project BIFROST.xcodeproj -scheme BIFROST -configuration Debug -derivedDataPath /private/tmp/BIFROST_HEADLESS_BUILD_20261009 CODE_SIGNING_ALLOWED=NO build

Acceptance to finish before promotion:
1. Physically start Headless from the macOS Menu Bar and verify local /api/health.
2. Open the web dashboard, close native app, verify the web dashboard still works.
3. Verify default status indicators Headless+Active Tasks, AI preference auto, Caffeinate default 60 min.
4. Confirm Caffeinate start and stop and independent RavenNest lifecycle.
5. Verify Headless Stop disables relaunch; Start re-enables; Quit Menu Bar keeps Headless running.
6. Test Mac permissions, keyboard/VoiceOver, reduced motion and process restarts.
7. Keep all source, ZERO integration, backups and Git LKG unmodified until verification/acceptance.

## Evidence rule
Generated != Built != Offline TESTED != Physical VERIFIED != Released. Record failed/unknown gates honestly.
