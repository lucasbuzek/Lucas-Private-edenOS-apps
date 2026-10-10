# BIFROST — canonical cross-platform product and delivery contract

**Status:** scope/requirements RECONCILED to AppDevRules and BIFROST Bible; implementation evidence remains separately gated.  
**Reconciled:** 2026-10-09. This is a durable per-App execution contract, **not** a replacement Project Bible, release declaration, or assertion that absent binaries exist.

## Canonical authorities (read in priority order)

1. Newest explicit user decision: **macOS, Windows and Linux**, each with **native desktop** and **independent Headless** variant. Six product delivery targets; actual evidence must be tracked separately.
2. `~/edenOS/AppDev/#appDev Bible/APPDEV_BIBLE.md` and `APPDEV_BIBLE.txt`: project scope comes from user/project canon; a Mac/PC is a toolchain and incomplete source never narrows scope. One workspace, recover before rewriting, evidence-gated release and no premature AUTO stop.
3. `~/edenOS/AppDev/#appDev Bible/AppDevRules/UNIVERSAL_APP_INTEGRATION_HIERARCHY_RULE.md`: integratable Apps are standalone owners; hosting is transferable, domain ownership is not.
4. `docs/BIFROST_CAPABILITY_ARCHITECTURE_RECOVERY_2026-10-07.txt`: §§1–5 identity/scope/contracts/representations, §7 transferable Headless, §§14–18 ZERO/LOCAL/ALPHA/BETA, §§22–26 one portable core, server/desktop roles, installers and native Apple mechanisms.
5. Recovered `BIFROST_BIBLE_v1.0_EN.txt` within edenOS EDEN Initiative: durable identity, relationships, metadata, provenance, provider registries, canonical schema, backup/restore and migration. This is historical canon, reconciled to newer decisions.
6. `BIFROST_Project_Prompt_Package_v0.1/02_BIFROST_PROJECT_GOALS.txt`: durable information/interoperability kernel, local-first/open schema; initial DP0.1 directory-read/normalize/persist/index/API milestone.
7. `docs/BIFROST_FORGEMASTER_AUDIT_20261009.md` and current project source: implementation evidence only, not a substitute for scope.

## Product identity and architecture

BIFROST: **CONNECT · KEEP · RESOLVE**. The same universal BIFROST product has a **portable, versioned core** plus platform adapters, native desktop representations, independent Headless roles and optional Web/PWA/mobile representations.

Core purpose: identity, discovery, capability/provider selection, connections, durable user-owned connective state, metadata/relationships/provenance, generic service hosting, package lifecycle, authorization and presentation of actual capability/state. BIFROST is **not** the intelligence governor CONDUCTOR, HEIMDALL Workspace composer, JANITOR maintainer, or a specialist App domain owner.

**Core first:** shared schema, SQLite-first portable persistence for development, consistent manifest/capability/representation/permission contracts, provider registry/resolver, ChangeSet planner, job/event/results, transaction and recovery semantics. The shared core may be written once and exposed via a stable IPC/API; separate GUI builds consume that same interface. Do not fork business logic by OS.

**DP0.1 baseline remains mandatory:** arbitrary directory → discover → identify → read metadata (non-destructive) → normalize → classify → fingerprint/hash → relate → persist → index → expose through API. Current small Mac dashboard/launchd bridge does not demonstrate DP0.1.

Headless must work **without desktop GUI running** and without a mandatory Cloudflare, RavenNest, RDC, Siri, iCloud, paid provider or always-online dependency. A desktop App may manage/start/stop/connect to its Headless role, but not be its process parent in production. Service-only/server deployments are valid. When a desktop is installed, settings/state are synchronized through authorized common contracts, not two contradictory process owners.

Apps keep their own standalone Headless and domain data. BIFROST generic host handoff is opt-in, compatible, exclusive/leased, evidence-backed and reversible; fallback preserves identity, recovery, state and data. No mandatory monolithic migration.

## Six desktop/Headless delivery targets

| Target ID | Required product | Platform role, packaging and acceptance | Evidence on 2026-10-09 |
|---|---|---|---|
| `macos-native` | Native graphical macOS App **plus optional Menu Bar** | First-class macOS UI (SwiftUI/AppKit), BIFROST status, setup, provider/device management, lifecycle; signed/notarized production packaging after UI/permissions verification; runs without requiring the service to be bundled as the GUI's child process | **BUILT / PROCESS LAUNCHED** candidate; UI interactions, signing and release UNVERIFIED |
| `macos-headless` | Independent local service/API + CLI/Web | launchd (user agent/service scope explicitly chosen), localhost IPC, permissions, life-cycle/restart, Headless installer/capability contracts; user Keep Awake is real assertion; no GUI dependency | **RUNNING / TESTED** for limited Headless routes and setup import; shared core/full feature suite incomplete |
| `windows-native` | First-class Windows desktop App | Native OS-appropriate UI (WinUI 3 or evaluated mature native-quality toolkit), device/capability/setup controls, secure credential/IPC integration, Windows installer/uninstaller and update channel | **DESIGNED TARGET / NOT BUILT / UNVERIFIED** |
| `windows-headless` | Independent Windows background Node/API + CLI/Web | Windows Service Control Manager or justified user service; named pipe/localhost IPC; Windows credentials/ACL/OS privilege model; controlled installer adapters (winget/MSI where suitable), lifecycle and recovery | **DESIGNED TARGET / NOT BUILT / UNVERIFIED** |
| `linux-native` | First-class Linux graphical desktop App | Native-quality desktop UI (GTK/libadwaita or Qt or reviewed existing framework); Linux desktop permissions, file picker, notifications, setup/management; packaged for targeted desktop distributions | **REQUIRED BY MOST RECENT USER SCOPE / NOT BUILT / UNVERIFIED** |
| `linux-headless` | Independent Linux service/API + CLI/Web | systemd user/system service or equivalent, Linux permissions/polkit, Unix sockets/localhost, suitable package adapters (apt/dnf/etc. only where supported), server/headless install, update and rollback | **DESIGNED TARGET / NOT BUILT / UNVERIFIED** |

The Linux **native desktop** requirement is explicit in the newest user request; the older October 7 recovery explicitly cited Linux Headless + Web and did not independently demonstrate a Linux native implementation. Record this distinction instead of silently omitting Linux desktop or pretending it existed.

Native desktop ≠ web-only wrapper by default. Choose lowest sufficient OS-native or proven suitable toolkit while preserving expected native UX. Web/PWA remains an additional common control representation, not a replacement for required native targets.

The six targets are **six build/deployment variants, not six forked BIFROST cores**. Windows and Linux builds must be produced/tested on legitimate target environments. Source portability alone is not a Windows/Linux executable.

## Universal BIFROST PWA representation and interconnect (required)

The latest explicit requirement includes a **first-class installable PWA** acting as a **capability/representation and transport adapter**, shared logically across macOS, Windows, Linux and authorized mobile/browser access. It is **additional to** the six desktop/Headless delivery variants and **not** a seventh core product or a substitute for native Apps.

The existing Headless local dashboard is the LOCAL PWA and uses same-origin authenticated local API routes. The existing RavenNest Web source supplies an optional remote/ALPHA PWA. Both declare install manifests and anonymous offline/static shells; service workers must never cache authenticated data, actions or Node state. Direct authorized LAN and self-hosted remote/BETA are contract targets, **not verified**. Remote pairing, per-device grants and mobile installation remain **UNVERIFIED**.

**Project-specific authoritative addendum:** `docs/BIFROST_PWA_INTERCONNECT_CONTRACT.md`. Machine-readable evidence: `docs/bifrost.platform-targets.json` `web_pwa`. Native/Headless requirements and independently usable Headless lifecycle remain unchanged.

## Platform adapter boundaries — implementation specifications, not completed implementations

| Contract | macOS | Windows | Linux |
|---|---|---|---|
| Services/lifecycle | launchd / native process APIs | Windows Service/SCM | systemd user/system or equivalent |
| Local IPC | XPC/Unix-domain socket/localhost | Named pipe/localhost | Unix-domain socket/localhost |
| Discovery/LAN | Network.framework, Bonjour/DNS-SD | Supported DNS-SD/mDNS/discovery facilities | Avahi/DNS-SD or other supported mechanism |
| Secrets/trust | Keychain, LocalAuthentication, TCC | Windows Credential Manager/DPAPI, ACL, platform consent | OS keyring/Secret Service when suitable, filesystem ACL, polkit when required |
| Power inhibitors (only with user approval) | macOS assertion / caffeinate | Windows supported power requests | logind inhibitors or supported desktop APIs |
| Packaging (evaluate, choose, test) | .app/.pkg, macOS signing/notarization | MSIX/MSI/EXE or appropriate signed packaging | distro formats/portable packages with verifiable lifecycle |
| UI | SwiftUI/AppKit | WinUI/appropriate native UI | GTK/libadwaita, Qt or suitable native UI |

These names are candidate native mechanisms, not claims that the adapters exist. Canonical capability API must report `unsupported`/unavailable when a platform cannot provide a capability safely; do not fake platform parity.

## One product; distributions/profiles rather than product forks

**Lucas Private/Custom:** Apple-centric defaults and Garden of EDEN branding, local-first, native Siri/Shortcuts where supported, developer/experimental adapters and explicit device configuration. Does not hard-wire private identities into portable core.

**Slindokuhle Private organizational:** same core with separate organizational users, roles, permissions, policies and operational integrations. No hidden fork from Lucas Private.

**Family/Friends and Official/Public:** same portable core and contracts with appropriate onboarding, provider choice, language, privacy and platform adapters; no Lucas paths, credentials, mandatory Apple services or private branding assumptions.

Deployment/control profiles:
- `INSTALL / RECOMMENDED`: balanced device-aware essentials; desktop+Headless only where appropriate.
- `LEAN`: smallest sufficient role, including service-only systems.
- `FULL`: broad suitable coverage without unnecessary duplications or forced downloads.
- `CUSTOM`: explicit components/provider/connection/distribution/roles.
- UI disclosure: Simple / Advanced / Expert, Essentials default.

## Shared functional contracts and requirements (apply to every applicable platform)

1. **Identity/registry:** typed Node/Device/App/Capability/Provider/Instance/Representation/Location identity, version/compatibility, bounded health and uptime; discovered ≠ trusted, available ≠ installed, installed ≠ verified.
2. **Persistent kernel:** SQLite/schema migration, normalized metadata/provenance/relationships, filesystem-first read-only ingestion; export/import/recovery, stable identities across moves and provider replacements.
3. **Provider-independent resolution:** native OS → installed capability → small library/CLI → user-authorized provider; offline local fallback and truthful degraded states.
4. **Installation/setup:** discover → import → inspect/unpack safely → verify provenance → dependency/compatibility resolution → user-visible ChangeSet/dry-run → authorize → execute only approved operations → verify → register → repair/rollback/uninstall with receipts. Never execute downloaded scripts solely because a ZIP was added.
5. **Headless lifecycle:** independent start/stop/restart, owner-verified process/port lease, crash recovery and config persistence; GUI closure must not stop Headless. No duplicate services during optional shared-host adoption.
6. **Control representations:** native desktop and shared responsive Web/API display one authoritative state and actionable permission-gated functions; mobile/Raven an optional transport/provider, not another core or mandatory online service.
7. **Trust:** device enrollment, revocation, role/operation/target-scoped grants, session/nonce/CSRF safeguards where appropriate, audit logs, consequence-aware confirmation, OS permissions, no public unauthenticated local Headless endpoint.
8. **Operational state:** jobs/events/results, errors, progress/cancellation, explicit UNVERIFIED/UNKNOWN/DEGRADED, accurate provider/Node reachability and approvals.
9. **Data/safety:** user owns data; specialist owns domain; platform isolation, privacy, offline mode, integrity checks, backup-before-mutation and tested restore. Never silently discard history or migrate a specialist database.
10. **Documentation:** universal architecture, user quick-start, Admin/Headless CLI, platform provisioning/uninstall, provider SDK, troubleshooting and signed release records in durable workspace.

## Portable source/deployment organization (logical only; do not relocate current LKG)

```text
BIFROST/
  core/                # future portable kernel/contracts/SQLite/ChangeSet (UNIMPLEMENTED)
  adapters/            # future macos/windows/linux OS bridges (only Mac features exist)
  Sources/             # current Swift macOS native candidate
  headless/            # current Mac-bound Python Headless/API/Web implementation
  web/                 # BIFROST and Raven Web/PWA surfaces, not an independent core
  docs/                # this contract, canonical reference links, per-variant evidence
  tests/               # shared/spec + available platform-specific checks
```

Do not fabricate the not-yet-implemented directories or six empty releases merely to make the tree look complete. Implement the common core and verified adapters through the existing project root, preserve Git/source path LKG, and package only real artifacts.

## Per-platform evidence gate and acceptance

**For each of six variant IDs individually:** REFERENCE/CANON → BASELINE/LKG → IMPLEMENT → STATIC VERIFY → ENVIRONMENT VERIFY → REGRESSION VERIFY → PACKAGE → PACKAGE VERIFY → PHYSICAL/OS ACCEPTANCE → PROMOTE.

Minimum acceptance:
- Genuine build/artifact for target OS/architecture, exact source/build version, packaging/install/uninstall proof.
- Independent service process life-cycle and crash/restart; preserve active user-owned jobs/power assertions during upgrades.
- Native App launch/UI workflow and true API↔UI state agreement; actual install/setup job with user consent + after-state verified + rollback proof.
- Core DP0.1 read-only directory ingest, persistence/restart, query/search API and move/provider-swap consistency test.
- Device trust/permission-denial tests; offline local path; remote pathway only when authorized.
- Apps remain standalone when BIFROST stops; shared-host delegation/retake tested.
- Windows/Linux require CI or genuine Windows/Linux test environments; macOS success cannot promote them.

**Evidence at reconciliation:** macOS native = BUILT/PROCESS-LAUNCHED candidate; macOS Headless = RUNNING/PARTIALLY TESTED candidate; Windows native/headless and Linux native/headless = SPECIFIED ONLY, not developed or verified. The central kernel DP0.1 = NOT IMPLEMENTED/NOT VERIFIED. No six-platform product release exists.

## No-loss recovery requirement

Every BIFROST backup/release/handoff must contain or reference this contract and the **six-target matrix**, including targets with no current source. Backup manifests must declare (a) what the archive really contains, (b) planned but missing outputs, (c) tested/untested variants, and (d) exact authority/provenance. **A backup of actual Mac files must never redefine BIFROST to a macOS-only product.** Keep historical archives and LKG immutable; recovery addenda must carry missing scope forward.

### Next engineering gate

Port/codify a single common kernel contract and cross-platform Headless startup/config/IPC interfaces, using mature OS facilities and tested libraries before replacing them. Implement per-target adapters incrementally while retaining current macOS Headless and Raven running state. Validate native Windows/Linux designs using real OS toolchains; no invented binaries or deployments.

## October 9 DP0.1 source implementation addendum
All six desktop/Headless targets and the PWA remain mandatory. The new portable Python/SQLite filesystem DP0.1 slice is implemented, with native macOS, Headless and local PWA source interfaces; richer metadata/providers, Windows/Linux releases and mobile grants remain outstanding. See the separate DP0.1 evidence document.
