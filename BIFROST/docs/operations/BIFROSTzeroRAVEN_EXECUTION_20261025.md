# BIFROSTzeroRAVEN — execution and acceptance

Owner instruction: 2026-10-25. This is one testing variant of the COMPLETE
existing BIFROST platform, not an Intelligence-only product or another master.

## Mission and device identities

Use and improve the complete platform while preserving canon, standalone app
ownership, offline operation, privacy boundaries and the actual accepted LKG.
RavenAirM1 is the MacBook Air M1; RavenNestM3 is the MacBook Pro M3 Pro;
RAVENnest is the future personal central server, with hosting unspecified.
The iPhone remains the universal control surface. Names are owner decisions;
no hostnames have been changed by this candidate.

## Complete scope, preserved

- Independent edenOS Installer exposed through BIFROST: onboarding, setup,
  dependency checks, staging, installation, update, repair, rollback and verify.
- Inspector, Discovery, device/account identities, trust, connections, network,
  capability resolution, permissions, application/service lifecycle.
- Representations and existing HEIMDALL workspace composition; ELYSIUM Home,
  personal/shared contexts and connected specialist apps retain their owners.
- Files/Online Storage Manager, authorized provider references and operations,
  PENELOPE file/backup ownership and JANITOR on-demand maintenance.
- Existing EXECUTOR, shortNameCall and workflows, task receipts and continuity.
- Intelligence, AI TOOLKIT, Siri/Shortcuts/silentChatGPT, Apple-native models,
  optional other providers; SNOOPY evidence-based correction and regression.
- Native app, menu, headless and web representations; offline/restart/recovery.

## Authority and execution order

CONDUCTOR coordinates; ForgeMASTER integrates and verifies; ForgeAPPLE leads
Apple-platform engineering. Reuse domain owners and existing contracts.
GitHub and approved documents support cloud development independently of Mac
availability. Reconcile Mac-only changes before device deployment. Historical
README paths/roles do not supersede newer owner decisions or dated contracts.

- [x] Recover complete requirements from the current conversation and history.
- [x] Recover all 192 BIFROST files at GitHub commit
  `7fd9e155282a2bf733052d8d1ba05fd51437d66f`; verify Git blob hashes.
- [x] Read existing executor contract, project state, relevant implementation
  and tests. No root/BIFROST AGENTS.md or #common Bible in the recovered tree;
  live Mac rules remain unavailable, not presumed absent globally.
- [x] Run the complete recovered Python suite; reproduce baseline failures.
- [x] Repair bounded status/test defects and reuse the existing icon generator.
- [x] Run Python and JavaScript regressions; preserve existing host guards.
- [ ] Reconcile remaining branches, current rules, Project Bible and installed
  source/LKG; inventory functional gaps across every scope area above.
- [ ] Integrate confirmed missing functions through existing owners/adapters;
  test installer, storage, app access, HEIMDALL and ELYSIUM end-to-end.
- [ ] Verify Apple models/Siri, cross-device execution and SNOOPY correction
  replay against actual permitted device capabilities.
- [ ] Verify offline, restart/resume, cancellation, permission denial, rollback
  and physical daily use; promote only after acceptance.

## This implementation receipt

The original full run collected 288 Python tests with failures/errors and two
skips. Missing generated PWA icons caused asset failures; the existing generator
restores them. The native-launch test incorrectly assumed a macOS host and now
mocks that host for its unit contract; production host checks stay unchanged.

Two runtime fixes: absent local RDC manager now retains explicit unverified
authentication/transport fields; explicit provider stop persists across reload,
and a subsequent start clears that marker. A stale PID still reports stale.
This does not prove provider authentication, account loss, process termination
timing, or physical Mac behavior. No provider process was started in these tests.

Validation after fixes: 291 Python tests collected, 289 passed, 2 skipped;
49 JavaScript tests passed, including storage UI no-implicit-network, stale-result
invalidation and missing-session checks. Added regression cases cover absent manager metadata,
stopped-state reload/availability changes, restart and stale-PID precedence.
Repeat with `python3 -B tools/test_portable.py`; it prepares only missing icons
using the existing generator, leaves existing icons untouched, and fails if
Node.js is unavailable. No downloads or physical Apple actions are required.

The candidate registry has 48 actions, four mapped read-only adapters and
44 contract-only entries. This is dispatcher coverage, not an inventory of all
functionality elsewhere in BIFROST. Staging is not installation; an app contract
is not a working integration. Full platform readiness remains UNKNOWN.

Source lineage: PR #13 continues recovered source; PR #12 is historical and
must not be merged as-is. No merge, Mac installation, account re-pairing,
credential access, hostname change, public deployment or LKG promotion occurred.


## 2026-10-25 storage/installer research correction — additive candidate branch

Source lineage: PR #13 retained as the original draft; bounded safe hardening work is on `codex/bifrost-storage-installer-hardening-20261025`. **No Mac installation, provider authentication, source-LKG promotion, PR merge or Dropbox publication is inferred.**

Evidence-backed defects corrected in source:
- Original `Install-BIFROST.command` used `|| true`, masking Python installer failure as success; wrapper now propagates status.
- Original builder fixed port 8798 and unconditionally requested login autostart. New builder permits loopback port (1024–65535), explicit `startAtLogin` (OFF by default), and initial browser-open preference; boolean/int types and unknown/credential-like option keys fail closed.
- Options are embedded in `INSTALL-OPTIONS.json` **inside the generated candidate ZIP** and its SHA-256 is included in the verified install manifest; install rejects tampering/unknown options.
- Builder candidates and receipts now target established `~/edenOS/Releases/`, not the development directory as installed runtime. The installed app uses the existing verified BIFROST Application Support and LaunchAgent locations only after explicit user action; an existing service, port or runtime causes a hard stop.
- Headless is first delivery; native SwiftUI and menu bar remain second-stage, not prerequisites. No duplicate daemon or storage engine was created.

Critical security/research conclusions: Reuse the **existing** BIFROST storage core and profile-bound remote preview; do not expose rclone's full Remote Control API on a Web UI. Official rclone docs describe RC access as effectively shell + credential access without per-action scopes (https://rclone.org/rc/). Multi-account remotes are legitimate (https://rclone.org/docs/) but token-bearing config requires user-only protection and provider-specific credentials. Google Drive's shared rclone client is being retired during 2026; user-controlled OAuth app credentials may be required (https://rclone.org/drive/). Dropbox offline desktop consent should use authorization-code + PKCE and refresh tokens (https://dropbox.tech/developers/using-oauth-2-0-with-offline-access). A localhost Web UI still requires exact Host/Origin/CSRF checks, short-lived local sessions and bounded operations (https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html). Apple iCloud Drive is a distinct Apple-managed local/Files provider; do not imply an iCloud OAuth password is available to BIFROST.

Important remaining implementation gaps:
1. Web UI account onboarding and credential storage: RDCravensnest existing profile recovery, Google Drive OAuth using a real desktop client and provider-verified subject ID, multiple independent Dropbox/Google accounts. Previous ChatGPT account grants are NOT BIFROST-native grants.
2. Reconciliation must separate account registered, authenticated, provider-device paired, device online, quota available, metadata readable and grant revoked; emails alone cannot prove identity. RDC7 is reserved for another future account.
3. Credentials must not appear in browser storage, URL query strings, BIFROST logs, ZIP, GitHub or Dropbox. Work toward Apple Keychain integration; rclone may maintain its own protected config file, which is NOT equivalent to Keychain.
4. No automatic cross-account transfers/sync/backup: stage an explicit dry-run copy plan with destination/source, collision policy, provenance, hashes where supported, independent readback and rollback before any write adapter.
5. Negative tests still required: wrong RDC6 identity; future RDC7 reuse; expired/revoked OAuth; iCloud dataless placeholders; malicious path traversal, symlinks and DNS rebinding; service upgrade and port conflicts; offline/restart; multi-tenant metadata isolation; refusal to overwrite existing installer/LKG.
6. One-click installer Apple acceptance remains blocked without a Mac: verify launchctl bootstrap/kickstart semantics, RunAtLoad OFF default, exact HTTP identity/port, physical browser, signing/notarization later. Local option-logic smoke is NOT a full macOS test.

## Owner priority: connect the whole platform

First use case: fully functional headless service with Web UI. Native macOS app
is the second use case, sharing the same services and data. The current candidate
is an incremental integration, not completion of that first milestone.

Online Storage Manager now exposes the existing profile-bound folder preview
through the Web UI Index & Identity page. Local preview defaults to no remote
read; a distinct explicit action enables the existing bounded remote reader.
Results clear on selection changes or connection loss; stale responses cannot
restore results. Existing saved profiles are required. No account secrets are
sent to the browser. Provisioning, transfers, conflict resolution and sync still
need implementation and live-provider acceptance.

EXECUTOR remains connected through the existing authenticated orchestration API
and Apple workflow controls. Storage links to that interface, recorded checks,
and setup. This does not automatically execute a workflow on selected storage,
and recorded checks do not constitute a durable general-purpose job queue.

Acceptance checklist for complete integration:
- [x] Connect storage preview to the existing Web UI and backend.
- [x] Preserve existing EXECUTOR workflow route and explicit confirmation.
- [ ] Add profile/account onboarding and scoped transfer plans with receipts.
- [ ] Implement durable general execution lifecycle, cancellation and recovery.
- [ ] Resolve HEIMDALL/ELYSIUM/specialist capability contracts to live adapters.
- [ ] Verify installer lifecycle, all denied/offline cases and device restart.
- [ ] Verify end-to-end on RavenAirM1, then RavenNestM3 and iPhone access.
- [ ] Complete native macOS companion after headless/Web UI acceptance.
