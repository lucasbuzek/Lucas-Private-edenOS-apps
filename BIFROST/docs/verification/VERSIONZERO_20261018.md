# BIFROST Version Zero — macOS Custom test candidate
Date: 2026-10-18 · macOS 27.0.1 · MacBook Air M1 8 GB · Xcode 27.0
Canonical source: `/Users/lucas/edenOS/Software Development/BIFROST/`
Milestone: Version Zero, NOT an invented new semantic version or full Alpha.
Flavour: @Custom. No online provider / cloud execution. Not promoted to Products.

## Implementation incorporated into current local source
- `Sources/AppRegistry.swift`: real LaunchServices-backed known EDEN list plus valid user-owned macOS Applications bundles, including AppleScript applets without CFBundleIdentifier; explicit Open with result/error feedback, no startup side effects.
- `Sources/CapabilityRegistry.swift`: native Shortcuts CLI inventory queried asynchronously with 8-second bounded timeout, no blocking the main UI or false success.
- `Sources/BifrostLocalIntelligence.swift`: opt-in Foundation Models local explanation, available-state gating, cancellation, short bounded non-sensitive capability summary; no model-to-command execution and zero online provider dependency.
- `Sources/SecondaryViews.swift`: optional AI panel, native app-open status feedback, honest representations empty state and user-directed Refresh, real Finder navigation in Development & Releases.
- `Sources/DiscoveryService.swift`: native Bonjour network state/errors and explicit refresh, passive observation only.
- `Sources/Views.swift`: native Devices refresh and honest empty/error/status.
- `Sources/BifrostSystem.swift`: user interface complexity selection persisted through UserDefaults.
- Existing macOS native multi-workspace spectral visual identity, App Intents, Headless, local PWA, safe setup importer and receipts retained.

## Completed source / runtime gates
- XcodeGen project generation: PASS.
- Xcode macOS Debug app build (unsigned engineering output): PASS 2026-10-18.
- Python regression suite: 96/96 PASS.
- Node JavaScript regression suite: 13/13 PASS.
- `Info.plist` lint: PASS; bundle identifier `eden.private.bifrost`.
- Actual native app from isolated derived-data bundle: `open -g -j -n` process launch PASS, controlled stop PASS, did not auto-start Headless PASS. This is a hidden process-launch test, not a visual/click test.
- AppRegistry real macOS smoke: recognized all four original named entries and one valid user AppleScript bundle (`Ask CONDUCTOR`) in `~/Applications`; no application was launched by that read-only test.
- Bundled Headless server in isolated temporary HOME/loopback port: identity/auth checks PASS; unauthorized access rejected; idempotent local observation receipt saved; exact receipt recovered after actual process termination/restart; SQLite mode 0600; clean shutdown PASS. Real compiled bundle resources, no mock providers.
- Apple Foundation Models: runtime availability `available`; actual offline/on-device language-model inference returned `Ready.` in ~12 seconds. This is CLI environment acceptance only; Capabilities panel click/cancel still needs GUI acceptance.
- Current installed app / user data / production Headless were not overwritten or started by engineering tests.
- Pre-VersionZero canonical source archive and checksum in the existing `BACKUFULL_20261014/evidence/` backup set; verified 120 archive entries and SHA-256.

## VZ01–VZ10 evidence state
| Gate | State | Basis / remaining work |
|---|---|---|
| VZ01 identity | PASS | canonical existing BIFROST source, macOS Custom, no new master |
| VZ02 UI visual/navigation | UNKNOWN | all original primary views retained and compile, but real GUI visual/click acceptance not available without Accessibility UI testing |
| VZ03 controls/state | PARTIAL | genuine native controls/feedback implemented and compiled; physical clicking across views outstanding |
| VZ04 representative end-to-end task | PASS | actual bundled Headless local observation → SQLite receipt → restart → exact retrieval |
| VZ05 local configuration | PASS for minimum | no cloud/provider dependency, explicit Headless start, local native capability checks; local first-run GUI acceptance pending |
| VZ06 persistence | PASS for Headless; UNKNOWN for preference UI | actual SQLite saved/reopened; new complexity UserDefaults code compiled but GUI preference selection not physically verified |
| VZ07 failures | PASS for API; UNKNOWN for physical dialogs | rejected unauthorized requests, wrong host and invalid action; runtime failures physically pending |
| VZ08 quality | PARTIAL | compile + 109 regression tests + hidden native launch + bundled Headless lifecycle + local model smoke passed; physical GUI/visual/accessibility still unknown |
| VZ09 continuity | PASS for source rollback | pre-change archive verified; older LKG identity unknown; installed app untouched |
| VZ10 state | VERSIONZERO CANDIDATE | not full physically verified; not a Product, not Alpha |

## Intentionally deferred / omissions
- Apple native AI is advisory only. Do not use generated plans to execute tools or change file permissions.
- Install & Setup currently imports/stages validated local archives; installer execution gates 2–6 are deliberately not implemented. Do not label staged items installed.
- No automatic local app installation, source replacement, cloud execution, RavenNest, WORKinCODEX, online model provider or privileged remote control.
- Discovered Bonjour endpoints are observed but not automatically trusted or controllable.
- Version/marketing metadata is absent from the inherited project.yml/Info.plist; Version Zero is a milestone, not a new semver. Do not assign a semantic version without source authority.
- Windows/Linux/iPhone implementations, physical Siri/App Shortcut invocation, interactive macOS GUI/accessibility, model cancellation and real app-open click require separate acceptance.
- Exact historical released LKG not confirmed; keep existing project backup and installed/accepted products unchanged.

## Tonight's physical acceptance in the test app
1. Open the explicitly labeled BIFROST Version Zero **test** application from the flat Releases launchpad. Do not replace an installed BIFROST.
2. Check its full spectral dashboard and each sidebar workspace: Overview, Headless, Devices, App Management, Install & Setup, Index & Identity, JANITOR, Connections, Capabilities, Representations, Settings and Advanced/Expert Development & Releases.
3. In App Management, confirm Ask CONDUCTOR appears; open it only if desired, and verify BIFROST reports launch success/failure.
4. In Devices/Representations, use Refresh Bonjour; verify empty/denied/observed feedback without assuming trust.
5. In Capabilities, confirm Shortcuts refresh does not freeze UI; click on-device Explain once; optionally exercise Cancel, confirm no external service started.
6. Change complexity to Advanced then quit and reopen BIFROST; verify selection persists. Restore Simple as desired.
7. Optionally start Headless explicitly in the UI, inspect local dashboard, Record local check, stop/restart and verify receipt persists. Headless is OFF by default and never silently autostarts.
8. Quit app; ensure no unexpected background processes, other apps or online plugins were launched. Record actual failed controls/screens, native permission prompts and visual defects.

## Release gate
A local test candidate can enter Releases with `@Custom`, `@App macOS` and `§Test` when signed/test-launched and with this evidence and known limitations; this only means ready for Lucas's physical testing. Products / §Working / VersionZero VERIFIED require the unknown GUI/permission/feature gates above to be accepted. No automatic user-facing app launch.


## Purposeful user-test candidate packaged — 2026-10-18 21:55 SAST

- Flat Releases artifact: `/Users/lucas/edenOS/Releases/BIFROST_VersionZero_20261018_macOS_Custom_TEST.app`.
- Ad-hoc locally signed only (not Developer ID/notarized/distributable), native macOS bundle verification `codesign --verify --deep --strict` PASS, `Info.plist` lint PASS.
- Canonical metadata writer wrote/read back `@Custom`, `@App macOS`, `§Test` Finder tags with this existing evidence file.
- Test artifact measured approximately 3.9 MB; main executable SHA256 `5b71f9cc22834302ac26fc8aa35e221f5e8f6862e8ab1482aad54db7d882c0ba`.
- Actual signed **Releases artifact** hidden process launch via `open -g -j -n`: PASS (PID 33337), independent Headless remained stopped, controlled candidate termination PASS. The candidate was not left running.
- Final Xcode macOS Debug build: PASS after all source changes; Python 96/96 PASS, Node 13/13 PASS; genuine installed-bundle Headless lifecycle/data/security PASS; real Apple on-device inference PASS; real AppRegistry smoke PASS.
- Existing installed app remains unchanged; no provider plugins, online services, account or production Headless instance started. No Products promotion.
- Post-change source archive preserved in SAME existing BIFROST BACKUFULL_20261014 set: `evidence/BIFROST_VERSIONZERO_CANDIDATE_SOURCE_20261018.tar.gz` (122 entries, SHA256 `d0d21c6e5cb121a5d6c2c658c23217b3395b59f4a77a2f384f6c56718a43b0d9`), archive listing/readback/hash verified. Pre-change archive separately preserved in that set.
- App bundle does not declare a semantic marketing version, following inherited project metadata. Version Zero remains a milestone and the test package is date-distinguished. Physical human GUI, all navigation clicks, TCC prompts, user-triggered app launching, live Headless start from GUI, on-device Cancel and UI preference persistence remain UNKNOWN until user tests. Do not mark VersionZero VERIFIED or move to Products.

## Final native Shortcuts smoke — 2026-10-18
Compiled CapabilityRegistry.swift into an isolated macOS command-line harness. `refresh()` returned in 0.007 seconds on the test Mac; the first state was `Checking installed Shortcuts…`, and the asynchronous query subsequently reported `Query succeeded · 33 shortcuts`. Native capabilities count was 3. This verifies the async no-main-thread-blocking read path and honest result on the target Mac; it does NOT prove Siri/App Intents registration or the physical Capabilities screen interaction.


## 2026-10-20 — BIFROSTzero / VersionZero resumed on RDC6

- Scope: recovered both October 20 BIFROSTzero/Bridge and ForgeMASTER VersionZero/ONE-GO continuations; checked live canonical first procedure, AppDev Bible, versionZero rule, existing source, independent installed Headless and original v0.9 recovery. BIFROST project master is not a Git worktree; no Git revision is claimed.
- Existing source candidate's new owner-private Siri/App Intent for Messages, Music and TV failed Xcode 27 Swift 6 compilation because `BifrostOwnerAppleApplication.typeDisplayRepresentation` was a mutable static property. In the canonical `Sources/BifrostAppIntents.swift`, changed only `typeDisplayRepresentation` and `caseDisplayRepresentations` from `static var` to immutable `static let`; verified current source SHA256 `15524a1228039d6bfac050f85226c32b8a90298719132df9cd164a38323a0e4f`.
- Existing `tests/test_apple_intents_contract.py` retained seven original window-opening shortcuts and expanded explicit registration contract from nine to ten for the owner-directed `OpenApprovedAppleApplicationIntent`, with three `openAppWhenRun = false` cases. Updated test SHA256 `4715fb66ef84aa9054f56e28e28388daeddce78b175fb70f32bd9710e6dd3ff9`. No implicit Messages reading/sending, Music or TV playback, provider access or permissions were added.
- Current standalone mobile menu is a dynamically generated JS element; the concurrent current test fix now recognizes runtime-created IDs, and no conflicting edit was applied by this session. Existing JS and Python regression suites on RDC6: **252/252 Python PASS** and **45/45 Node PASS** on final rerun.
- Current native Xcode 27 macOS arm64 BIFROST Debug unsigned build **PASS** after the Swift 6 repair, and independently `BIFROSTMenu` Debug unsigned build **PASS**, using the already existing `~/edenOS/Temporary/BIFROST/VersionZeroDerivedData` and `MenuControllerDerivedData`. No app or service was installed, restarted, user-launched or signed for release.
- Prechange source/test snapshots are stored in the ONE existing `Software Development/#Backups/BIFROST_REBUILD_BACKUP/` set, original bytes SHA-verified; no new master or backup set. The independent installed Headless remains verified at localhost:8798, `runtimeId fb7c5b677c245cd5`, source SHA256 `c5ca0312349db036d398b672c17496bc440bf65f7ee440a6d07fda691e84e3ab`. Existing signed `Releases/BIFROST_VersionZero_20261018_macOS_Custom_TEST.app` untouched. Current source Web UI preview at localhost:8799 and original v0.9 WebApp recovery preserved.
- **LCAS:** SOURCE REPAIRED / NATIVE+MENU COMPILE PASS / AUTOMATED REGRESSION PASS; physical native/Safari visual+interaction, genuine Siri invocations, owner account/pairing, registered direct ChatGPT BIFROST Bridge and protected authenticated task receipt remain UNKNOWN. VersionZero remains a **candidate**, not VERIFIED/Products; no LKG promotion or external/public deployment.
