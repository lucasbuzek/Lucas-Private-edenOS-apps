# BIFROST — FORGEMASTER AUTO Scope Audit & Evidence (2026-10-09)

## Actual current baseline
Role: CONNECT · KEEP · RESOLVE. BIFROST is optional connective infrastructure, never HEIMDALL or specialist App domain authority.
Surfaces: independent Headless, native macOS menu bar, full macOS App, compact local web. Future authorized mobile/cross-platform representations reuse the same capability contracts.
LCAS FULL is only persistent in-chat presentation; not a BIFROST runtime.

## Verified evidence
- Native SwiftUI/XcodeGen candidate builds under Xcode 27, Swift 6, macOS 15 minimum, arm64 with code signing disabled.
- Latest test App was started successfully from Releases/Testing/BIFROST. Visual/keyboard/mouse physical acceptance remains pending.
- BIFROST Headless per-user launchd service running on 127.0.0.1:8798; RavenNest separate launchd service still running.
- Live Headless health, compact Web UI, package discovery and mobile-bridge status routes responded.
- AI Toolkit and Project Workspace originals were copied unchanged to BIFROST's private Incoming directory; both are AVAILABLE, not installed.
- Real archive isolated smoke: secure discovery, token rejection, safe stage-only extraction and idempotence passed; no installer executed.
- Native Headless setup/unit suite: 21 tests passed; JS syntax passed; Xcode app build passed.
- Raven integrated branch (5364be0) isolated: 23 Python + 28 Edge + 3 Worker tests passed.
- New LOCAL read-only Raven Headless observation branch (37208da): 27 Python + 28 Edge + 3 Worker tests passed. No deployment/push.
- UIX uses approved spectral mark, dark surfaces and feature color distinct from operational health; menu bar, full app, Headless Web.

## Important recovery assets
- Pre-UIX ZIP: ~/edenOS/AppDev/#App Backups/Apps/BIFROST/BIFROST_UIX_PRE_CHANGE_20261009.zip
  SHA256 73e454d0c5ac2f50e2459406c60ccd7e8ba8eaa5b22d60eab3945e8b4de6b072
- Pre-Headless-setup runtime ZIP: ~/edenOS/AppDev/#App Backups/Apps/BIFROST/BIFROST_HEADLESS_PRE_SETUP_RUNTIME_20261009.zip
  SHA256 34e8dbb4cec20726f58fcae19a8cfda2e26b98aed8f764e271146eba52c8e395
- Test binary: ~/edenOS/Releases/Testing/BIFROST/BIFROST-UIX-Setup-Bridge-Candidate-20261009.app
  arm64 executable SHA256 e1d8c34d517219e984b64a5528e3349fe0d09c473c3878b74517c21960a361f7
- Original native October 5 archive/backup retained. Raven ZERO/integration branches preserved.

## Prioritized gaps and omissions

| Priority | Requirement | Gap and evidence gate |
|---|---|---|
| P0 | Secure online mobile enrollment | Deployed Raven is ZERO 0.1.0. Current pairing uses a master operator key in a URL fragment, retained in browser localStorage. That is NOT unique per-device identity or revocable scoped grant. Do not enable mobile setup execution until Cloudflare Access or equivalent per-device keys, user grants, rotation/revocation, audit, and iPhone proof pass. |
| P0 | Installation execution | Headless only discovers, validates and stages ZIPs. Actual INSTALL/RECOMMENDED, LEAN, FULL and CUSTOM plan resolution, authorization, idempotent operations, progress, cancellation, verification and recovery receipts are NOT implemented. AI Toolkit installer may invoke brew/winget and mostly offers links for advanced items. |
| P0 | Independent Cloud Codex control | Native Headless only reads task counts. Integrated Raven codex.cloud.submit remains device-executed; a Mac-independent cloud-hosted connector, identity routing, verified cloud task IDs and monitoring are missing. |
| P0 | Unified trust/authz | Local Headless GET session token is a CSRF deterrent, not Internet authentication and not protection from other local accounts/processes. Never bind local API to non-loopback or relay arbitrary POST. Setup mutation endpoints must require verified scoped capabilities for remote use. |
| P1 | Cross-App capability manifests | Native AppRegistry is a fixed list, not manifest discovery. EDEN Apps/helpers/services have no general install/update/ownership/health contract. Speciality apps must stay standalone; BIFROST may host generic services reversibly only after a verified lease/handoff. |
| P1 | Shared runtime state | Native, Raven bridge and Headless have separate remote/caffeinate/state paths. Raven Keep Awake and Headless Caffeinate are separate assertion owners, risking conflicting UI/status. Shared service contract, lease and reconciliation needed. |
| P1 | Headless lifecycle | Current Headless is a user LaunchAgent, not a boot-before-login LaunchDaemon; no multiuser host authority, per-device trust store, crash-state recovery or post-logout service gate. |
| P1 | Remote setup protocol | Sanitized Headless status candidate is local-branch-only; no deployed Raven integration, paired iPhone capability catalogue, secure approved setup actions, results or rollback proven. |
| P1 | AI/provider routing | Auto mode currently only saves preference. Raven provider fallback work is branch code, not verified live in Headless. Need policies, consent/privacy, model capability tests, offline fallback, cost/availability and provider credentials isolated. |
| P1 | Installation provenance | ZIP SHA and traversal defenses established. Missing trusted publisher/signatures/licensing, installed artifact verification, package receipts, operation audit, recovery/rollback and supported tool/model mapping. |
| P2 | Universal Project Workspace | Imported and safe-staged, but no native project initializer, metadata editing, indexing workflow, collision-safe import to canonical edenOS structure, or restore/index verification. |
| P2 | macOS UI physical acceptance | Native app compiles and process launches, but each menu action, dark-mode contrast, accessibility/VoiceOver, responsiveness, launchd Start/Stop, permissions and closing native UI while Headless remains must be exercised. |
| P2 | Production packaging | Candidate lacks signed/notarized distribution version identity, installer/update/rollback workflow, packaging tests, minimum hardware/dependency matrix, source release authority. Windows/Linux unverified. |
| P2 | Helpers/agent orchestration | Helper identities are not runnable BIFROST executables. Their contracts and provider bindings need discovery; CONDUCTOR/FORGE retain development evidence governance, HEIMDALL retains Workspace composition. |
| P2 | Current status evidence | Historical October 2 recovery inventory is stale and should remain archival. Create active tracker with CANDIDATE, VERIFIED/UNVERIFIED, BLOCKERS, NEXT GATE, and evidence dates. |

## Safety remediation completed
- Removed duplicate BifrostFeatureIcon SwiftUI type by retaining existing original and renaming new color treatment.
- Created native Install & Setup and live Web catalogue; reviewed file import restricted to user-picked ZIPs, with private managed Incoming.
- Background Headless's direct Downloads scan caused a live catalogue hang; private Incoming path fixed it, and live GET catalogue now returns both validated packages promptly.
- Kept stage-only endpoint authenticated and restricted to known IDs; mobile status is explicitly read-only and reports unverified pairing.
- Added read-only sanitized Headless node-state observation in a separate local Raven branch, without modifying deployed edge or master keys.

## Evidence gates
REFERENCE: Approved spectral mark/color mockup.
BASELINE: Recovery ZIP checksums verified; Raven ZERO retained.
IMPLEMENT: Native UIX + Headless Web + setup importer + separate local Raven status branch.
STATIC: Native build, Python and JS syntax pass.
ENVIRONMENT: Local Mac Headless and live package catalogue pass, native App process launch pass.
REGRESSION: BIFROST 21 tests pass; Raven observation branch 58 offline tests pass.
PACKAGE: Unsigned test app staged in Releases/Testing; not in Products.
PACKAGE VERIFY: Info.plist lint, arm64 binary SHA and Headless resources checked.
PHYSICAL GATE: iPhone pairing, remote permissions and interactive macOS actions NOT VERIFIED.
PROMOTE: NOT AUTHORIZED. Separate feature states from deployment/readiness assertions.

## Next safe implementation order
1. Harden the mobile authentication design: do not distribute a shared operator credential as device pairing.
2. Reconcile new Raven status branch with the four real plugin variants after authoritative identification; verify per-device scoped grants and cloud independence.
3. Implement Headless setup planning/jobs and scoped install adapters; never execute downloaded scripts implicitly.
4. Normalize EDEN App manifests, provider capability registry and reversible shared hosting.
5. Integrate a secure Mac-independent Codex Cloud task provider, with task ID/progress/result evidence.
6. Perform macOS UIX/accessibility regression and iPhone physical gate, then signed release.

## No false promotions
A source file, staged ZIP, imported archive, successful compilation, process liveness, or public Cloudflare health check does not prove an installed capability, remote pairing, authenticated user, successful Codex task or released product.

## Canon recovery addendum — cross-platform scope, 2026-10-09

**This audit's macOS-only built/source inventory must NOT be mistaken for the BIFROST product scope.**

The canonical, current specification is:
- `docs/BIFROST_CROSS_PLATFORM_PRODUCT_CONTRACT.md`
- `docs/bifrost.platform-targets.json`

Six required delivery targets: macOS native, macOS independent Headless, Windows native, Windows independent Headless, Linux native, Linux independent Headless. Native and Headless share ONE portable BIFROST core and OS-specific adapters; there must be no domain/product fork. Common Web/PWA and authorized mobile are additional representations.

Mac native: built/process-launched; Mac Headless: running/partially tested. All Windows and Linux target variants are specified only; no binary, installation or target-OS runtime acceptance was demonstrated. Linux native requirement is explicit in the newest user decision; older recovered architecture names Linux Headless and Web.

The DP0.1 persistent identity/metadata/interoperability kernel is ALSO in recovered project goals and is not demonstrated by the current Mac UI/controller. Do not drop it because implementation is currently absent.

AppDev Bible canon: development machine/source files are implementation evidence and cannot redefine scope; authority and evidence distinctions apply to every target. Never label the six-target product complete from a one-platform archive.

## Superseding DP0.1 implementation status addendum
The earlier NOT IMPLEMENTED core gap described the old baseline. The current portable filesystem kernel is now a tested source candidate with native macOS/Headless/PWA interfaces. Full kernel and six-platform release acceptance remain unverified. See BIFROST_DP01_PORTABLE_KERNEL_CANDIDATE_20261009.md.
