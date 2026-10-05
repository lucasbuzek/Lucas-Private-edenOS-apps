# BIFROST recovered implementation inventory

Inspection date: 2026-10-02

## Project shape

- **Target:** one native macOS application target, `BIFROST`, in
  `BIFROST.xcodeproj`; one implicit `BIFROST` scheme.
- **Platform:** macOS 15.0 minimum; Swift 6.0 target language mode in the
  generated project; SwiftUI application.
- **Bundle ID:** `eden.private.bifrost`.
- **Version/build identity:** no marketing version or build number is set in
  the project. The built Info.plist has no `CFBundleShortVersionString` or
  `CFBundleVersion`. Xcode 27 / macOS 27 SDK are build-environment details, not
  BIFROST product version identity.
- **Configuration:** `project.yml` is an XcodeGen input; XcodeGen is installed.
  The checked-in Xcode project is usable directly. Generated Info.plist.
- **Dependencies:** SwiftUI, AppKit, Foundation, and Network SDK frameworks.
  No Swift Package dependencies or vendored libraries are declared. The Remote
  Desktop Commander integration attempts to use `npx` and the unpinned npm
  package `@wonderwhy-er/desktop-commander@latest` at runtime.
- **Resources / assets:** no asset catalog, bundled resource, or non-source
  resource is referenced by the target.
- **Entitlements / sandbox:** no entitlements file or `CODE_SIGN_ENTITLEMENTS`
  setting is present. The inspected target has no configured App Sandbox
  entitlement. The Debug app was ad-hoc linker signed without a Team ID.
- **Tests:** no test target, test source, or test plan was found.
- **Scripts:** `project.yml` supports XcodeGen. No project build, test, or package
  scripts are present.
- **Persistence:** no database, file store, UserDefaults use, app group, schema,
  or migration code exists in BIFROST source. The displayed state is in memory.

## Source files and evidence classification

| Source | Classification | Demonstrated behavior / limit |
| --- | --- | --- |
| `Sources/BIFROSTApp.swift` | IMPLEMENTED | Creates the main window, menu bar extra, settings scene, and shared system model. |
| `Sources/BifrostSystem.swift` | IMPLEMENTED / PARTIAL | Starts discovery, refreshes providers, and owns a `caffeinate` process for Keep Awake. State is in memory; there is no persistence or app-termination cleanup hook. |
| `Sources/DiscoveryService.swift` | PARTIAL | Native `NWBrowser` Bonjour browsing for AirPlay, RAOP, Companion Link, and SSH. Observations are volatile; no trust, pairing, control, durable identity, or persistent connection state. |
| `Sources/RemoteDesktopProvider.swift` | PARTIAL | Checks for a matching process, starts/stops only a process it launched, and observes external sessions without stopping them. It starts an unpinned npm package and marks the provider Running on process launch/liveness without a protocol health check. No port/ownership lease or BIFROST/App handoff exists. |
| `Sources/CapabilityRegistry.swift` | PARTIAL | Enumerates a fixed set of native, automation, bridge, and named EDEN capabilities. Availability is shallow. Shortcuts query status and stderr are now retained for display; the registry view observes this model. |
| `Sources/AppRegistry.swift` | PARTIAL | Detects four fixed bundle IDs (`janitor`, `lingua`, `lector`, `heimdall`) and opens discovered applications. No general discovery, compatibility check, adoption, service handoff, or state migration. |
| `Sources/JanitorProvider.swift` | PARTIAL | Looks at two hard-coded JANITOR launcher paths, captures `--version`, opens JANITOR, launches Quick / Developer Quick / Full in Terminal, and opens reports. JANITOR remains an external standalone owner. |
| `Sources/RootView.swift` | IMPLEMENTED UI | Navigation and Simple / Advanced / Expert disclosure. Selecting advanced pages exposes the management views. |
| `Sources/Views.swift` | IMPLEMENTED UI / PARTIAL capability | Overview renders current provider state and controls; Devices displays Bonjour observations, not a trusted device inventory. |
| `Sources/SecondaryViews.swift` | IMPLEMENTED UI / STUB | Connections and capability/representation lists render existing models. App Management opens the four fixed apps. Development & Releases is informational text only; it has no build/release implementation. Settings exposes in-memory controls. |
| `Sources/StatusMenu.swift` | IMPLEMENTED UI | Menu bar controls for refresh, Keep Awake, remote provider, opening the main window, and quitting. |
| `Sources/JanitorView.swift` | IMPLEMENTED UI / PARTIAL capability | Calls the external JANITOR launcher and opens reports. The actual scan/maintenance logic belongs to JANITOR. |
| `Sources/VisualIdentity.swift` | IMPLEMENTED presentation | Header and gradient treatment; no domain functionality. |

## Data models, APIs, networking, and integration contracts

- In-memory models: `NearbyService`, `BifrostCapability`, and
  `EdenAppRecord`; none is persisted.
- **Networking:** `DiscoveryService` is the only native network code and only
  browses Bonjour services. No BIFROST listener, HTTP API, RPC endpoint, or
  network service host was found.
- **App APIs/contracts:** no BIFROST runtime manifest, XPC protocol, service
  lease, adoption API, compatibility declaration, health contract, or
  standalone fallback protocol exists.
- **JANITOR integration:** fixed executable paths and command arguments; no
  transfer of JANITOR identity/data/domain responsibility.
- **Remote Desktop Commander:** external process wrapper; unrelated to generic
  EDEN App runtime delegation.

## Established architecture comparison

- **CONNECT:** partially represented by Bonjour browsing, fixed app opening,
  and one external remote-tool wrapper. There is no general connection manager
  or persistent connection state.
- **KEEP:** partially represented by an in-memory Keep Awake process control.
  There is no persistent connective state implementation.
- **RESOLVE:** partially represented by fixed capability enumeration. It does
  not establish identity, compatibility, ownership, or provider selection.
- **Standalone Apps remain independent:** JANITOR integration leaves execution
  to the standalone JANITOR scripts. Other fixed Apps are opened directly.
- **BIFROST runtime delegation/adoption:** absent.
- **Reversibility / standalone fallback:** absent as a BIFROST/App contract.
- **Duplicate service protection:** the remote-tool wrapper avoids starting if
  its process signature is observed and does not stop external sessions. This
  is provider-specific and is not a generic EDEN service ownership guarantee.
- **Data preservation:** BIFROST has no domain-data migration or destructive
  data operations. It also has no adoption/state-preservation mechanism.

## Safe functional checks performed

- Both source-referenced JANITOR launchers were run with `--version`; outputs
  were `0.7.5-developer-quarantine-verified-candidate` and
  `0.9.0-mode-separation-cloud-photos-candidate`. The BIFROST provider selects
  the first path. No scan/clean operation was invoked.
- `/usr/bin/caffeinate -dimsu -t 1` exited 0; these are the same assertion
  flags used by BIFROST with a one-second bound. This verifies the native
  executable, not BIFROST's UI toggle or its process cleanup behavior.
- `/usr/bin/osascript -e 'return "automation-ok"'` succeeded.
- `/usr/bin/shortcuts list` failed with “Couldn’t communicate with a helper
  application.” The source repair exposes the captured failure status in the
  Capabilities view. The rebuilt GUI process was launched, but the message was
  not visually inspected.
- The built app was opened with `open -n`; a live BIFROST process was observed.
  That exact test process was then sent SIGTERM and was confirmed absent. GUI
  controls and Bonjour results were not inspected, so those functions remain
  unverified at runtime.
- The Remote Desktop Commander start action was not invoked: it may fetch and
  execute an unpinned package from npm. No existing process or readiness
  behavior was tested.

## Static review findings

- All target source references resolve and all 13 Swift source files compile in
  the successful build. No missing resource reference was found.
- The project is a limited UI/control layer, not the shared headless host
  described by established BIFROST architecture.
- Provider launch is treated as “Running” without an application-level health
  confirmation. The `npx @latest` runtime dependency is mutable and not pinned.
- Shortcuts failures are now retained and rendered in the Capabilities view.
  Bonjour observations are correctly labeled as observed/discovered in views,
  but remain volatile and unauthenticated.
- BIFROST itself does not contain destructive data cleanup or migration code.
  JANITOR has maintenance actions behind its own menus; BIFROST only invokes
  them through the standalone JANITOR interface.
- No assumptions force installation of BIFROST for the fixed Apps shown. No
  source code offers an App runtime delegation path either.
