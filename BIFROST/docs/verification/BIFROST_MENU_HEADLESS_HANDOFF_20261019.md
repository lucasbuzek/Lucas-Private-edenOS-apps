# BIFROST · Independent Menu + Headless native handoff
Date: 2026-10-19 · Lucas-MacBook.local
Scope: canonical `~/edenOS/Software Development/BIFROST/`.
Milestone: macOS Custom Version Zero **isolated test candidate**; not Products, not LKG, not general plugin completion.

## Three independently owned processes
1. **BIFROST App**, bundle ID `eden.private.bifrost`: full SwiftUI windows, native Headless status/start/stop and existing App Intents. No status icon duplication.
2. **BIFROST Menu**, bundle ID `eden.private.bifrost.menu`, `LSUIElement=true`: independently quit-able native macOS MenuBarExtra. Reuses a small HeadlessClient, bridge SVG-like native mark, native preference toggles, optional Keep Awake, Open BIFROST App and approved bundle selector.
3. **BIFROST Headless**, independent `eden.bifrost.headless` user launchd job: explicitly started, `RunAtLoad=false`, `KeepAlive=false`, `127.0.0.1:8798` HTTP + protected local SQLite. Closing either app leaves Headless alone; a registered/unreachable Headless remains stoppable.

This two-app packaging is a **separation of interface processes**, not replacement of BIFROSTcore or a separate specialist product. Both interfaces share the existing locally managed Headless runtime without an additional always-running service.

## New implementation
- `MenuController/BIFROSTMenuControllerApp.swift`: own NSApplication/status extra, `LSUIElement`, persistent title and verified Headless indicator toggles.
- `MenuController/BIFROSTMenuControllerView.swift`: menu UI, explicit start/stop, stop confirmation, localized status, local dashboard, Keep Awake, controlled BIFROST launch; exact dated release partner selected before any installed App fallback. User-selected app must resolve to the fixed `eden.private.bifrost` bundle ID.
- `project.yml`: separate `BIFROST` and `BIFROSTMenu` targets. Shared Headless source/runtime and visual bridge source. No broad BIFROST source duplicated in the menu target.
- `Sources/BIFROSTApp.swift`: main app retains Settings and WindowGroup but no longer owns MenuBarExtra.
- `headless/server.py`: fixed `app.open` action via macOS `/usr/bin/open -b eden.private.bifrost`; token/origin and host gates inherited from existing local control API, rejects client-supplied paths or arguments, reports only OS request acceptance.
- `headless/index.html`, `headless/dashboard.js`: explicit Open BIFROST button; disabled until a valid local session; no app launch on page load.
- `tests/test_status_menu_contract.py`, `tests/test_headless_native_uix.py`, `tests/test_headless.py`: updated static and mocked authenticated-launch tests. Testing does not mean interactive UI accepted.
- `tools/smoke_pwa.py`: updated obsolete optionalRemoteProvider assertion to the existing local-only contract, **no remote provider introduced**.

## Verified current gates
- Mac Xcode Debug build `BIFROST`: PASS.
- Mac Xcode Debug build `BIFROSTMenu`: PASS.
- Python suite: 89 tests PASS.
- JavaScript suite: 13 tests PASS.
- `tools/smoke_pwa.py` isolated service and PWA: PASS. HTTP static serving, local adapter, unauthorized mutation denial, malicious host rejection, no arbitrary proxy, and isolated shutdown.
- Headless `app.open` tests mock `/usr/bin/open`; no system BIFROST app was actually launched by those API tests.
- Previous 18 Oct Custom candidate and installed BIFROST are preserved unchanged. No cloud/online services were configured or started.

## Manual testing gates / known limitations
- Physical status-bar mark, all menu clicks, stop-confirmation sheet, App/Headless handoffs, Finder picker, and user interface accessibility are **not verified** from command-line tests.
- Browser Headless-to-app action needs a registered native BIFROST bundle for `open -b` to succeed. An arbitrary app path is deliberately forbidden; if unregistered, the API returns 409 rather than guessing.
- Menu App -> full App works through exact matching test-pair name, then authorized system-registered identity, then an explicit user-selected path; in ambiguous directories it does not select a random historical release.
- No launch-at-login configuration is enabled. The separate menu app is started explicitly by the user.
- No production Headless service lifecycle changes or actual Keep Awake sessions performed.
- Existing JANITOR/PENELOPE and app-toolkit integration remain independently owned and are not implied complete by this UI split.
- No Windows/Linux native menu integration is claimed.

## Version Zero physical check sequence
1. Open the **BIFROST Menu** TEST application. Confirm the BIFROST spectral icon appears in macOS menu bar (without opening the full GUI).
2. Use **Open BIFROST App**. Confirm the dated matching full test app opens; quit full app and verify menu still remains available.
3. From menu explicitly select **Start Headless**. Inspect local dashboard and local identity status; close full app and verify Headless remains alive. Do not enable login startup.
4. Select **Stop Headless**; verify an explicit confirmation and that only the exact BIFROST launchd label is stopped.
5. Choose optional indicator/title/Keep Awake menu items and verify persistence after restarting the menu controller.
6. Start Headless again through the full app's existing Headless page, then return to the menu and confirm shared status; stop explicitly afterward.
7. Check Headless dashboard **Open BIFROST Native App** with approved local session; note actual macOS launch result. This requires registered app ID and may show 409 in isolated test setup.
8. Confirm JANITOR and PENELOPE are not started as side effects; confirm no unexpected local services remain.

## Acceptance policy
Physical GUI state remains **UNVERIFIED**. `§Test` signifies engineering test candidate, never `§Working`, `§LKG` or Product promotion. Do not replace installed/accepted apps, remove earlier test builds, or claim full Headless/GUI/Apple AI acceptance from this report alone.

## R2 isolated Custom candidates — 2026-10-19
- Prior 18 October and 19 October test candidates remain untouched. New paired, date-distinguished R2 artifacts were created because the first 19 October copies predate the subsequent reviewed source and Headless bridge changes.
- `~/edenOS/Releases/BIFROST_VersionZero_20261019_R2_macOS_Custom_TEST.app` — ~3.8 MB; bundle `eden.private.bifrost`; ad-hoc signed, strict code-signature verification PASS, `Info.plist` PASS; main executable SHA256 `fcca3d3ae99e4a3d9841d100c15bb04b6a8fe7a260f617ce2218310ae8353da8`.
- `~/edenOS/Releases/BIFROST_Menu_20261019_R2_macOS_Custom_TEST.app` — ~1.0 MB; bundle `eden.private.bifrost.menu`; `LSUIElement=true`; ad-hoc signed, strict code-signature verification PASS, `Info.plist` PASS; main executable SHA256 `0600e07e64ca721c4533cc834280579379d8104186f74249a5dfb7c210d9352d`.
- Both artifacts use canonical Finder tags `@Custom`, `@App macOS`, `§Test` with this evidence file as the tag gate.
- The exact release pair selection is deterministic: the Menu R2 build can locate the full GUI R2 file by matching its own dated filename; if moved/installed elsewhere, it uses an existing explicit user selection or verified LaunchServices bundle registration, not a guessed new version.

## Live native process independence — verified
- Physical **process launch** of the signed R2 menu test via `open -g -j -n`: PASS, dedicated menu PID 53671.
- Physical **process launch** of the signed R2 full app test via `open -g -j -n`: PASS, separate full-app PID 53683.
- Test terminated **only the just-launched full app** and verified that the Menu process remained active: PASS.
- Test then terminated **only the just-launched Menu** and verified it exited: PASS.
- Before and after test, Headless local health was not running: no implicit Headless start PASS.
- No test candidate was left running. The test did **not** perform a physical menu click or positive `app.open` Headless request: those are still UNKNOWN, not claimed PASS.
- The 89 Python tests and 13 Node tests pass; isolated `tools/smoke_pwa.py` now passes against local-first Headless and its static PWA contract, including unauthorized mutations and hostile-host rejection.

## Compiled bundle Headless lifecycle — both R2 packages
The same independent bounded test used **each actual signed R2 release bundle** as its source: isolated temporary HOME, randomized loopback port, no production launchd. Both packages passed verified Headless identity, unauthenticated-path denial, local receipt idempotency, exact receipt retrieval after a real process restart, 0600 SQLite permissions and clean termination. This is executable bundle evidence, not proof of physical menu click or production launchd management.

## Recovered legacy regression protection — final pass 2026-10-19
Compared the preserved pre-refactor status-menu test file in `BACKUFULL_20261014/evidence/BIFROST_BEFORE_CORE_PLUGIN_EXTENSION_20261019.tar.gz` against current tests. The first separate-process refactor had unintentionally dropped checks. Added `tests/test_status_menu_recovered_guards.py` with **13 adapted guards** (menu contrast, original destinations, stop-vs-quit, launchd verification, no overwriting live runtime, portable-kernel packaging, identity checks, plugin/Caffeinate ownership, registered-unreachable service, local-only PWA, DOM references, JANITOR canonical launch path and six target contract). No tests were disabled to obtain PASS. Latest complete Python regression is **102/102 PASS**, replacing the preliminary 89-test count above. JavaScript remains **13/13 PASS**, both native builds PASS, isolated PWA smoke PASS, and real signed R2 pair independence and both bundled Headless lifecycle checks PASS. These static/source checks do not certify physical menu clicking.


## 2026-10-19 — BIFROST local browser + Apple workflow private test candidate

New narrowly scoped source:
- Sources/BifrostLocalDashboardWebView.swift: WebKit, ephemeral data store,
  pinned localhost 127.0.0.1:8798: rejects external schemes/hosts/ports,
  credentialed URLs and pop-up navigation. Local dashboard only. OAuth must
  use supported external authentication; not a generic internet browser.
- Sources/BifrostNativeWorkflowRunner.swift: exact discovered Shortcuts name
  and listed Automator workflow, native macOS CLI, no shell interpolation.
  Explicit confirmation per execution; no automatic startup or scheduler.
  Automator directories limited to user Library/Services and Finder workflows.
  Run output not captured; provider exit status is not task verification.
- Sources/SecondaryViews.swift: in-app local-dashboard sheet and manually
  confirmed Shortcuts/Automator selection. No service auto-start.
- Sources/HeadlessClient.swift: external fallback deliberately opens Apple
  Safari by bundle ID, not the system default browser.
- tests/NativeAutomationSmoke.swift: positive local and saved workflow cases,
  forged/unlisted workflow rejection, external-URL rejection.

2026-10-19 verified on authorized Mac:
- xcodegen generate: PASS.
- BIFROST native xcodebuild Debug CODE_SIGNING_ALLOWED=NO: PASS.
- BIFROSTMenu same build: PASS.
- Full Python suite: 102/102 PASS.
- Node test suite: 13/13 PASS.
- Native Swift compiled test harness + smoke: PASS.
- New test candidate signatures: ad-hoc codesign --verify --strict PASS.
- Clean ZIP extract re-verification: signatures PASS, executable + Info.plist
  SHA-256 match exact test app copies.
- Prior running native GUI, menu and Headless were not stopped, replaced or
  modified; Headless health returned ok: true.

PACKAGED PRIVATE TEST CANDIDATES, NOT INSTALLED OR PROMOTED:
Releases/BIFROST_Automation_20261019_macOS_Custom_TEST.app
Executable SHA-256 1780088f6f8c926048bb1bc8588a7476cd78aee027a5772405ed57afbae6bf2e
Releases/BIFROST_Menu_Automation_20261019_macOS_Custom_TEST.app
Executable SHA-256 3bd24cd8d4f4b9770def76a776f27fb6d5020155297f8cdeabeb45991ec4278e

PRECHANGE RECOVERY:
BIFROST/BACKUFULL_20261014/evidence/BIFROST_native_automation_prechange_20261019.zip
BIFROST/BACKUFULL_20261014/evidence/BIFROST_pre_Safari_dashboard_20261019.zip
Both backup ZIP structures checked; original BIFROST LKG preserved.
Temporary clean extraction in Temporary/BIFROST/AutomationPackageVerification.

UNKNOWN physical acceptance: new GUI clicks, WebKit session/browser rendering,
real user workflow outcomes, Apple TCC prompts, Siri/App Intents device tests,
HEIMDALL/iPhone handoff, unattended scheduling, external provider OAuth and
Cloudflare remote trust. No online provider or RDC account was switched.
Physical test: open labeled TEST app, verify local dashboard, then choose a
harmless saved Shortcuts or Automator action and explicitly confirm it.


## 2026-10-19 — Native Folder Actions and local browser orchestration

Scope: continuation of existing local BIFROST. No RavenNest or ZERO Connections
ownership change and no new standalone product.

Implemented:
- headless/orchestration.py: opt-in one-folder shallow monitor, five-second
  metadata polling, maximum 500 direct items and 30-second trigger debounce.
  New actions only, with an initial baseline to ignore pre-existing files.
  Disabled until the native Mac app approves an exact folder plus installed
  Shortcut via private 0600 manifest; hidden/Library/symlink/protected
  edenOS/Projects scopes excluded. Only the existing explicitly started
  BIFROST Headless process owns this optional watch. No GUI autostart.
- headless/server.py: same-origin authenticated loopback
  /api/orchestration/v1 (GET catalog/status; POST confirmed execution). Exact
  installed Shortcuts and saved Automator only; no arbitrary script, URL,
  provider account or shell interpolation. 60-second execution limit,
  one at a time, no output/secret capture; private JSONL receipts
  always explicitly report effectsVerified false.
- Sources/BifrostFolderActionApproval.swift and Sources/SecondaryViews.swift:
  system folder picker, reviewed saved-Shortcut selection, disabled/enabled
  approval, fail-safe disable even if source folder or Shortcut disappears.
  User-clicked open of Apple's native Folder Actions Setup and Automator.
- headless/index.html, headless/dashboard.js, headless/sw.js: browser-local
  workflow discovery and confirmed manual run, user-refreshable catalog,
  separate native permission boundary, updated safe static PWA cache.
- tests/test_orchestration.py: six positive/negative security and behavior tests.

Actual gates:
- xcodegen generated project: PASS.
- Xcode BIFROST native Debug build: PASS after all Swift changes.
- Xcode BIFROSTMenu separate Debug build: PASS after final web resource change.
- Python regression: 108/108 PASS; six new orchestration tests.
  One initial test failed on the macOS /var temporary-home symlink;
  temporary test path was canonicalized and all six pass.
- JavaScript regressions: 13/13 PASS.
- Real isolated Headless source runtime on temporary loopback port/HOME:
  PASS. No rule present, unauthorized endpoint denied, absent workflow
  rejected, controlled shutdown PASS. No real personal automation executed.
- Both TEST bundles ad-hoc signed, strict codesign verified, bundle ID
  verified, clean ZIP extraction and binary/Info.plist SHA verified.
  BIFROST and Menu contain byte-identical final daemon and dashboard assets.
  Unaccepted stale Menu TEST copy was replaced only after verifying final
  replacement and clean extraction.

Flat Releases private manual TEST candidates:
- BIFROST_Orchestration_20261019_macOS_Custom_TEST.app
  BIFROST executable SHA-256:
  16584dbeb3c2393b9c4eccd6cd47c75b4f804ea192a5053d3346585ac37843b3
- BIFROST_Menu_Orchestration_20261019_macOS_Custom_TEST.app
  BIFROSTMenu executable SHA-256:
  683e27e17653b8029d323f9442d752a18d4286d11f4b467bdcf35cc446deea9d

Source preservation:
- BACKUFULL_20261014/evidence/BIFROST_pre_orchestration_20261019.zip
  integrity PASS, SHA-256:
  f1c9f2fa86067e70fe46e24aba09676179accc96a26bbd2ea4397a053b6a16ef

No installed app replacement, running service restart, Mac folder grant,
personal workflow execution, login or external service activation occurred.
Products/LKG unchanged. UNKNOWN physical acceptance: GUI and native Folder
Actions clicks, Automation/TCC entitlements, independently launched
Headless file access to user-selected folder, real new-file trigger,
sleep/resume, user workflow side effects, separately sandboxed secure
bookmarks, broader app Accessibility, external website orchestration,
Siri/HEIMDALL and cross-device workflows.

For physical test, select a disposable test folder and a harmless reviewed
Shortcut. Start the new exact Headless revision only after intentionally
stopping the previously running verified BIFROST Headless service via its
own native controls; never force-replace a live/unknown listener.


### Final post-package regression and original LKG observation (2026-10-19)

- Re-executed after final source/UI changes: Python 108/108 PASS,
  Node JavaScript 13/13 PASS.
- Launched the actual Contents/Resources/headless/server.py from EACH of
  the TWO signed TEST app packages on an isolated random loopback port
  and temporary HOME. Verified authenticated orchestration GET, no default
  folder grant, active independent daemon, no external provider access,
  and orderly stop of each independent test process: both PASS.
- The original production-local Headless listener at 127.0.0.1:8798
  remained healthy and unchanged. Observed exact sourceSha256:
  c5ca0312349db036d398b672c17496bc440bf65f7ee440a6d07fda691e84e3ab.
- Canonical Finder metadata tool returned FINDER_TAGS_VERIFIED for both
  new flat Releases candidates: @App macOS, @Custom, §Test.
- Still no human/physical workflow test, daemon macOS TCC permission grant,
  installed-app replacement, daemon restart or LKG promotion.


## 2026-10-19 — Native/Web Simple-Advanced-Expert UX and original bridge menu

Authoritative recovered identity: BIFROST arch/bridge vector symbol,
distinct native Mac Menu controller with existing controls, local-first
CONNECT · KEEP · RESOLVE. User explicitly requested different behavior per
complexity level, not merely varying sidebar row counts.

Source changes:
- Sources/BifrostExperienceViews.swift: task-based Simple native home:
  bridge mark, verified Headless state, explicit Manage Bridge navigation
  (never autostarts Headless), Find Devices, My Apps, Find File and
  Automations (explicit promotion to Advanced configuration).
  Expert Diagnostics adds read-only verified native Headless status,
  launchd registration, observed local service identity/source digest,
  Caffeinate ownership and private saved-folder rule permission review.
- Sources/RootView.swift: independent task home for Simple; established
  dashboard/configuration for Advanced; Expert operations/diagnostic
  workbench in addition to all original advanced capability destinations.
  Switching back to Simple clears inaccessible navigation selection.
- Sources/BifrostDashboardView.swift: dedicated Expert overview service
  evidence panel with active Inspect Diagnostics navigation.
- MenuController/BIFROSTMenuControllerView.swift: repairs deterministic
  pairing of current BIFROST_Menu_Experience date/flavor test artifact
  to BIFROST_Experience exact app, while retaining legacy VersionZero
  date/flavor match. Original menu symbol and all menu controls retained.
  MenuControllerApp and original VisualIdentity symbol unchanged.
- headless/index.html, dashboard.js, dashboard.css, sw.js: distinct Web
  Simple local status, Advanced task orchestration/receipts/index/setup
  and Expert read-only runtime SHA/identity inspection. Real DOM and
  navigation visibility changes, no expanded execution authority.
  Public static PWA cache version updated, no session secrets saved.
- headless/orchestration.py: a five-second idle-folder watch no longer
  executes /usr/bin/shortcuts list each tick; exact installed Shortcut
  still verified at execution time, with no additional folder grants.
- Tests: 5 new native experience and menu source regression checks,
  3 new executable JavaScript-level mode/visibility checks, plus one
  new idle Shortcut catalog behavior security regression.

Verified:
- xcodegen project generation PASS.
- Both native Xcode Debug schemes compile PASS (BIFROST, BIFROSTMenu).
- All Python tests: 114/114 PASS. Node tests: 16/16 PASS.
- Actual new signed private TEST pair in flat Releases:
  BIFROST_Experience_20261019_macOS_Custom_TEST.app
    executable SHA256 933e70162355cfec6eb243ac011e91bc9a2d96866a97fa0e253348a8fe31c031
  BIFROST_Menu_Experience_20261019_macOS_Custom_TEST.app
    executable SHA256 9f9f402dd73b00c4cc46595c283c13ae77298d8aeeacf70ff2068d92abe1742e
  Both ad hoc signed, deep/strict codesign PASS, bundle IDs checked,
  ZIP clean extraction code sign and executable/Info.plist SHA PASS.
  Embedded Python/JS resources byte-identical between both bundles.
- Real isolated Headless runtime launched from EACH signed TEST bundle
  with disposable HOME and random loopback port; local session/catalog,
  no default folder rule, independent start/stop PASS. No personal
  workflow executed. At six-second idle sample BIFROST-bundled Python
  RSS 23584 KiB CPU 0.0%, Menu-bundled RSS 29520 KiB CPU 0.0%;
  single point samples only, not sustained energy or GUI benchmarks.
- Source backup member integrity PASS:
  BACKUFULL_20261014/evidence/BIFROST_pre_UXtiers_20261019.zip
  SHA256 1491727f16b6f9571e6bdffd4cf79560e0ab7e722e476c3db3980f762af021f3
  BACKUFULL_20261014/evidence/BIFROST_pre_webUX_20261019.zip
  SHA256 0c14bb9e22984df6f70c74075279046e7cb22e7aa8ec8ee4064bd5fddb0d1772

Physical acceptance gates UNKNOWN:
1. Launch only new Menu TEST, close any older candidate first to avoid
   duplicate status item; visually confirm the spectral arch in
   light/dark menu bar with keyboard/VoiceOver accessibility.
2. From Menu Open BIFROST confirm exact paired Experience TEST app,
   never accidental older VersionZero or Orchestration candidate.
   Confirm customization and independently running Menu and GUI.
3. Check Simple native task home, Advanced full management, Expert
   read-only evidence views, screen resizing and persisted mode.
4. Test local browser Simple/Advanced/Expert user mode switching,
   and verify Expert diagnostics never grants additional file/app control.
5. Physically approve a disposable local folder plus harmless reviewed
   Shortcut. Test separate Headless macOS TCC/sandbox access, real
   new-file trigger, dedupe and disable/revocation. No personal
   workflow without explicit authorization.
6. Explicitly stop currently running Headless by its own native controls
   BEFORE user-controlled test start of a new bundled runtime. Never
   force-replace an unknown or running localhost listener.
7. Measure steady-state GUI/Menu/Headless CPU, RSS, wakeups, energy,
   login lifecycle and user-facing effects before any Products promotion.

All original installed Mac apps and live Headless LKG preserved. NO
physical permission changes, personal workflow runs, cross-account
switches, online connector use, production service replacement or
Products/LKG promotion. User approval and GUI acceptance UNKNOWN.


## RDC6 verification — independently owned peer-Headless Menu
Time: 2026-10-19 ~16:45 local macOS. Connection: verified separate RDC6
account/device d5aaa02a-2b4b-4e9a-b3a3-be476270a733, ping PASS.
Established RDC5 exhausted quota is NOT being reused or reset.

LIVE authority reread from #common canonical first, APPDEV_BIBLE,
appXP, storage, procedural LKG, external-boundary and LCAS rules.
Canonical BIFROST master verified at Software Development/BIFROST;
the working source directory is not itself a Git repository, so no Git
HEAD was claimed. Canonical source and installed Headless health
independently inspected. Running installed 127.0.0.1:8798 service still
reports original eden.bifrost.headless identity, runtimeId
fb7c5b677c245cd5 and sourceSha256
c5ca0312349db036d398b672c17496bc440bf65f7ee440a6d07fda691e84e3ab.
It was NOT stopped, restarted, migrated or replaced.

Exact read-only Mac launch-agent discovery:
- eden.bifrost.raven-bridge, owner in existing Online Plugins &
  Connectors / RavenNest; plist configured, launchctl running state
  not observed; NO BIFROST control permission.
- org.eden.bifrost.core, separate BIFROSTcore; plist configured,
  running state not observed; NO BIFROST control permission.
- org.eden.heimdall.headless, separate HEIMDALL Headless; plist
  configured, running state not observed; NO BIFROST control permission.
  The core and HEIMDALL plists both reference port 8090; that is
  not a confirmed simultaneous operability test; NO attempted start.
Only eden.bifrost.headless appeared as active in launchctl list
during the scoped query. Plist presence and a PID are NOT an authenticated
health check, trusted owner adapter, or permission to start/stop.

Incremental native source:
- MenuController/BifrostObservedPeerRegistry.swift (NEW): exact
  recovered owners/launch labels/main-script path matching for only
  three observed peers, read-only launchctl list on MENU OPEN or
  explicit REFRESH, automatic 45s stale-to-UNKNOWN bound, configured /
  loaded / process-observed / unavailable / changed states.
  No peer start/stop/shell, no background polling, no vendor takeover.
- MenuController/BifrostPeerMenu.swift (NEW): Advanced and Expert
  peer-status menus, Expert identity, freshness/owner warnings.
  Peer Start/Stop is intentionally UNAVAILABLE: exact owner-bound
  authorized adapters have NOT passed governance+permission review.
- MenuController/BIFROSTMenuControllerApp.swift: PRESERVED original
  vector BifrostBridgeSymbol, existing service status/title and
  independent MenuBarExtra. Subtle 3s opacity pulse opt-in when
  own verified BIFROST Headless is running, never on low-power/
  accessibilityReduceMotion, no per-frame renderer.
  Optional observed peer process count in Advanced/Expert Menubar
  only when fresh, explicitly NOT peer service health.
- MenuController/BIFROSTMenuControllerView.swift: retains existing
  Open BIFROST, independent Headless start/stop and confirmation,
  Keep Awake, customizations, local dashboard, quitting Menu without
  stopping Headless. Added Simple/Advanced/Expert Menu level control,
  peer menu and explicit manual status refresh.
- tests/test_peer_menu_safety.py (NEW): 8 source guards for bounded
  owner labels, no peer execution, preservation, state/low-power/
  reduced-motion behavior, on-demand observation.

Evidence:
- Prechange backup inside existing BACKUFULL set:
  BACKUFULL_20261014/evidence/BIFROST_pre_RDC6_peer_menu_20261019.zip
  ZIP integrity PASS; SHA256
  7e1c6055761ee33c34b47b5c166305e4fb03b65aad6383ff03bab0b69636dda0.
- First Xcode menu compile hit SwiftUI typechecking limit on combined
  nested menu body; repair moved peer view into its own file.
  Subsequent final native BIFROSTMenu and BIFROST Debug targets
  CODE_SIGNING_ALLOWED=NO PASS. XcodeGen regeneration PASS.
- Python regression 122/122 PASS; JavaScript 16/16 PASS.
- Separate new signed private test pair in flat Releases:
  BIFROST_PeerMenu_RDC6_20261019_macOS_Custom_TEST.app
    executable SHA256
    933e70162355cfec6eb243ac011e91bc9a2d96866a97fa0e253348a8fe31c031
  BIFROST_Menu_PeerMenu_RDC6_20261019_macOS_Custom_TEST.app
    executable SHA256
    d75411abe5d42929a4e6f6366cdb55bb49dff99cf58cd1316c8b458f18b5afa0
  Both ad hoc signed, codesign --verify --deep --strict PASS,
  exact bundle identifiers PASS, ZIP clean extraction and executable
  byte-for-byte checks PASS, shared bundled Headless resources match
  exactly between pair. Clean-extract archive SHA256:
  full.zip 56c077ba81b9f366cf36e2b6191b412d0803159e1debe8e15c4ea7f0bf4d3f54;
  menu.zip 3516e74c4a376600fbb04ef772ca0e02d0ced69a9ba42c420d569a1bf637e35d.
  Archive verification data is regenerable in Temporary/BIFROST;
  Releases apps remain uninstalled private TEST candidates.

Remaining physical / functional gates UNKNOWN:
1. Visually confirm one original arch/bridge menu (no duplicate older
   menu), subtle running pulse in normal mode, no animation with
   Reduce Motion/Low Power, legibility/VoiceOver and status colors.
2. Verify Simple/Advanced/Expert peer list and stale/manual-refresh
   behavior, actual running state vs process observation.
3. Recover owner-provided authenticated status/control adapters with
   explicit individual user approval. Never generic launchctl stop/start
   or infer permissions from plist/PID. Confirm owner receipt and
   observed postcondition before claiming control works.
4. Apple in-chat workflow creator remains the separately verified
   portable R2 candidate, NOT an installed BIFROST ChatGPT plugin or
   integrated native automation execution. Recover actual BIFROST plugin
   identity/release and callable BIFROSTcore transport before installing
   or enabling device automation; no personal workflow executed.
5. macOS TCC physical folder picker, local Shortcuts workflow effects,
   energy/wakeups, GUI interaction and full user acceptance UNKNOWN.

No personal workflow, Mac permission change, HEIMDALL/RavenNest control
or provider login, installed Headless or Products/LKG replacement occurred.
