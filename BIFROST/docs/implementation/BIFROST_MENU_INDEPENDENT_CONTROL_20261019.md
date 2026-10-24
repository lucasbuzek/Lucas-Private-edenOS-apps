# BIFROST Headless ↔ Menu Controller ↔ Native App
Date: 19 October 2026 · Canonical BIFROST source
Decision: three independent process lifecycles; one local Headless authority.

## Canonical architecture

- `BIFROST.app` (`eden.private.bifrost`): complete user interface. Provides its existing explicit Headless start, stop, health, local dashboard, receipt and Keep Awake controls; offers an explicit button to open the BIFROST Menu controller. Quitting this app must not stop the menu or Headless.
- `BIFROST Menu.app` (`eden.private.bifrost.menu`, LSUIElement): dedicated independent native menu bar app, no full BIFROST system startup or workspace data. Reuses `HeadlessClient.swift` and existing BIFROST spectral bridge vector. Provides Open BIFROST, selective/headless start/stop with confirmation, local dashboard, BIFROST-only Keep Awake, refresh, customization and Quit Menu (keeps Headless). Launch and login auto-start require explicit user choice; no automatic service activation.
- `BIFROST Headless` (`eden.bifrost.headless`): existing independent loopback-only Python service under its existing launchd identity and private state/receipt ledger. Can continue without either App. Local web dashboard includes a user-activated Open BIFROST Native App action requiring an authenticated local session, valid Host/Origin, and an exact approved native app path recorded through the independent menu's picker or full app Settings. A request success is not proof a visible window was accepted by the user.

## Shared authority / security
- Both native applications share only the existing validated `HeadlessClient` and explicit settings/launchd/loopback contracts; no duplicate Python service, database or listener.
- Both bundle validated `headless/` and `core/` runtime resources so either can start Headless when explicitly requested, retaining prior-runtime preservation and exact launchd label.
- Full App does not include a MenuBarExtra; no duplicate status menu from two currently running new versions. Older test candidate dated October 18 still has a menu; do not launch that candidate together with the new dedicated Menu until it has been replaced after physical acceptance.
- `BIFROST Menu` launches only a verified `eden.private.bifrost` bundle; the user can explicitly select it. Priority: owner-approved private app record, exact partner of the dated testing menu, registered LaunchServices bundle, uniquely verified sibling testing candidate. Multiple ambiguous candidates are never chosen based on version order. Never launch arbitrary paths, apps or scripts. The native app can open a verified `eden.private.bifrost.menu` helper via explicit Settings button; detection supports embedded future helper or the approved adjacent test release.
- The web dashboard action uses `POST /api/control`, exactly `{"action":"app.open"}`, requiring the Headless local token and allowed Host/Origin. The command is the fixed executable `/usr/bin/open -a <the validated pre-approved BIFROST.app path>`; the request cannot supply any app path, shell, URL or optional arguments. A 0600 user-owned approval record prevents the service from inadvertently opening an older LaunchServices-registered build. Returns HTTP 409 when not installed; only confirms macOS accepted a launch request, not physical UI interaction.
- `Quit Menu Controller` never calls Headless.stop; `Stop Headless` requires a confirmation alert and does not stop other apps or external caffeinate.
- Menu customization is opt-in UserDefaults: title, Headless indicator, dashboard action, Keep Awake submenu and location selector. The native bridge mark persists even with title hidden. Headless-owned duration settings continue using the private shared Headless preferences.
- No online plugin or remote execution starts or ships with this local core.

## Source changes
- `project.yml`: two explicit macOS app targets, full native UI + separate LSUIElement menu, both linking shared Headless and resources.
- `MenuController/BIFROSTMenuControllerApp.swift`
- `MenuController/BIFROSTMenuControllerView.swift`
- `Sources/BIFROSTApp.swift`: native GUI without its former menu-bar ownership.
- `Sources/BIFROSTNativeAppLocation.swift`: private explicit native-app approval/validation shared by the native app and menu controller.
- `Sources/SecondaryViews.swift`: Settings can launch menu controller explicitly.
- `headless/server.py`: fixed, authenticated local native-app LaunchServices action.
- `headless/index.html`, `headless/dashboard.js`: visible user-initiated Open BIFROST control.
- `tests/test_status_menu_contract.py`, `tests/test_headless_native_uix.py`, `tests/test_headless.py`: revised independent-lifecycle, UI and authenticated-launch contracts.
- The obsolete `Sources/StatusMenu.swift` was removed from active source; its exact pre-change bytes remain in the verified 2026-10-19 BIFROST source archive.

## Engineering evidence (19 October 2026)
- XcodeGen generation: PASS.
- Native `BIFROST` target macOS Debug build: PASS.
- Native `BIFROSTMenu` target macOS Debug build: PASS.
- Python isolated regression: 102/102 PASS, including authenticated exact-path handoff, invalid app bundle identity, unauthorized and bad-origin rejection and independent menu contracts.
- JavaScript regression: 13/13 PASS.
- Both built applications include real local Headless resources and each independently passed bundled Headless HTTP identity, authenticated negative paths, exact local receipts, persistence across process restart, private SQLite 0600 and clean shutdown in a disposable HOME.
- BIFROSTMenu Info.plist identity: `eden.private.bifrost.menu`; `LSUIElement=true`.
- Port 8798 remained inactive throughout the isolated tests; production Headless untouched.
- Actual authenticated Headless-to-native launch: PASS in isolated disposable HOME using exact approved October 19 R3 BIFROST app, with observed process. Unauthorized/no-token and path injection rejected. Full app and independent Menu both real process-launched: after full app termination Menu remained running, and Headless remained stopped. Mouse-driven menu-bar actions, launch-at-login, visual status icon, human GUI interaction and TCC remain UNKNOWN until hands-on acceptance.
- The actual installed-app scanner identified 136 Mac app bundle entries (including Safari, Finder, Blender, Xcode and Logic Pro) without launching them; Chrome is restricted by established policy. App Intents/Shortcuts readiness for third-party apps is not inferred.

## Physical acceptance checklist
1. Launch the R3 dated native BIFROST Menu test candidate (`~/edenOS/Releases/BIFROST_Menu_20261019_macOS_Custom_TEST_R3.app`). Verify one spectral bridge menu icon and NO Dock icon. If the old October 18 candidate is still open, close it first to avoid duplicate legacy menus.
2. From menu, choose Open BIFROST App. For Headless web launching, choose Locate Existing BIFROST App and explicitly approve the matching full R3 test candidate; alternatively in native app Settings choose Approve This BIFROST App for Headless Open. Confirm that the private approved location is retained and the older October 18 test app is not selected.
3. With the full app open, visit Settings → Menu Bar · Independent Controller, verify it can open the existing menu helper without spawning a duplicate.
4. Quit the native app. Confirm the menu remains, Headless state is accurately reported, and Open BIFROST relaunches the complete native interface.
5. Without Headless running, verify menu and GUI do not autostart it. Explicitly Start Headless through either interface and verify independent launchd ownership and local dashboard.
6. Via the local Headless web dashboard use Open BIFROST Native App. Verify BIFROST opens only after the user action.
7. Verify Keep Awake controls affect only the BIFROST-owned power assertion and menu stop Headless prompts for confirmation.
8. Customize menu title/status/options, quit/relaunch the helper and verify selections persist.
9. Quit menu (Keep Headless) and verify Headless stays running. Stop Headless explicitly afterward. Do not change any external EDEN plugins or installed products.
10. Confirm accessibility keyboard navigation, icon legibility, status colors, TCC and login-item behavior separately.

## Scope and promotion
- This is a VersionZero engineering candidate, not §Working, nor evidence of full macOS physical acceptance.
- No old releases, installed app, shared production Headless or LKG may be overwritten.
- No automatic login-item installation has been introduced. A separate explicit opt-in launch-at-login feature can follow only after tested user approval.
- Menu customization, plugins and BIFROSTcore updates should extend the same core contracts, not create another independent Headless.

## Final R3 test-pair checkpoint — 19 October 2026
- Latest tested and signed flat Releases candidates: `~/edenOS/Releases/BIFROST_VersionZero_20261019_macOS_Custom_TEST_R3.app` (3.8 MB) and `~/edenOS/Releases/BIFROST_Menu_20261019_macOS_Custom_TEST_R3.app` (1.0 MB). Both ad-hoc locally signed, `codesign --verify --deep --strict` PASS, `Info.plist` lint PASS, and `@Custom`, `@App macOS`, `§Test` Finder tags verified. Full-app executable SHA256 `5eb5d9d9bd668ef46c573c27aebd9c03cf8378bd478bef12963500cb64c91f3f`; Menu executable SHA256 `59eceec293e1d16653211b1d7ebb014f83af9997052a3c0942c22f4a7391326a`.
- Real macOS process test on **these exact R3 artifacts**: both launched; full app terminated; Menu survived and retained its own process; production Headless remained off; Menu terminated separately — PASS. The menu app is `LSUIElement=true` and carries `eden.private.bifrost.menu` bundle ID.
- Real isolated Headless from the **R3 signed application** accepted authenticated `app.open` against an exact user-approved BIFROST R3 bundle path and that exact native process was observed; unauthenticated and path-injection calls rejected; isolated service terminated — PASS. Bundled Headless identity, local receipt persistence, idempotency and 0600 SQLite tests passed separately from both R3 bundles.
- 102/102 current BIFROST Python tests and 13/13 JavaScript tests PASS; both native targets rebuilt from final source without errors. Read-only scanner found 136 installed macOS application bundle entries; per-app Shortcuts/App Intents support remains unverified, not automatically enabled.
- A source archive under the **same existing BACKUFULL backup set** preserves this R3 checkpoint: `BACKUFULL_20261014/evidence/BIFROST_CORE_MENU_HEADLESS_R3_FINAL_SOURCE_20261019.tar.gz` (125 tar entries, 237522 bytes, SHA256 `90be513a407acdc631f8ac1e3d7a1126adda37971d58e55f51b4afa6e47bcb09`). Four critical sources compared byte-for-byte against extracted archive entries; all matched. No separate backup tree created.
- The earlier October 18 release and other historical/overlapping 19 October test candidates were intentionally **not deleted** because release ownership/physical usage of contemporaneous alternatives is unverified. Do not claim R3 replaced or promoted those builds; further consolidation requires reconciliation against owners' acceptance and LKG.
- Physical mouse/keyboard menu interaction, TCC prompts, login-item setup, actual Headless lifecycle from GUI/menu, Keep Awake start/stop from menu, native approval picker, styling and accessibility remain **UNKNOWN**. All test services were stopped; no auto-login items created, no online providers or installed Products changed.
