# BIFROST First Use — Online Storage / RDC Recovery

**2026-10-25** · CONDUCTOR × SNOOPY × ARGOS × ForgeMASTER · SOURCE-ONLY DRAFT

## Recovered baseline

- Existing BIFROST project, not new app/service. Original authoritative working location when Mac verified: `~/edenOS/Software Development/BIFROST/` (SOURCE, not runtime).
- Native/headless separate representations; this milestone requires **existing** BIFROST Headless + its Web UI only.
- GitHub PR #13 already implements authenticated Headless `GET /api/storage/v1`, `GET /api/storage/v1/accounts`, `POST /api/storage/v1/preview` backed by `core/storage_capability.py` via `headless/storage_adapter.py`. No new file manager/daemon is needed.
- The successor hardening branch `codex/bifrost-storage-installer-hardening-20261025` already supports a configurable install port, opt-in start-at-login and optional browser launch. Do **not** reimplement this builder.
- Original Dropbox candidate ZIPs and their server-side receipt under `/edenOS apps/` are historical copy/evidence, NOT physical Mac verification; the receipt explicitly reports `macOSInstallation: not-verified`.
- RDC current alias **RDCravensnest**, previously called RDC7 in historical notes; RDC7 now reserved for a different future account. RDC1–RDC6 protected. Principal hint `lucasravensnest@gmail.com` is *not* proof of provider login.

## Evidence-backed security conclusions

1. [IETF RFC 8252](https://www.rfc-editor.org/rfc/rfc8252.html): native OAuth uses a system external user agent + PKCE; embedded WebKit login forms are not accepted. Credentials stay in approved provider and OS token stores. Headless may open a system browser + loopback callback after the owner explicitly requests it.
2. [Google Drive scopes](https://developers.google.com/workspace/drive/api/guides/api-specific-auth): `drive.file` is narrower for selected content, while whole-Drive read scopes can be restricted and involve verification and policy obligations. `drive.appdata` is configuration, not a universal user files scope.
3. [Dropbox OAuth reference](https://www.dropbox.com/developers/reference/oauth-guide): separate PKCE + offline refresh tokens and per-account scope. Multi-login identities must never inherit one token.
4. [rclone RC security](https://rclone.org/rc/): RC is effectively arbitrary shell/file and credential access; do NOT grant it as a general BIFROST UI API. Existing BIFROST storage preview's bounded `rclone lsjson` pattern is preferable.
5. [Apple SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice): optional service-at-login requires reviewed user consent, tested registration/unregistration, rollback and platform acceptance; don't silently install a new daemon.
6. [Desktop Commander remote setup](https://github.com/desktop-commander/remote-desktop-commander/blob/main/docs/SETUP.md): device pairing and ChatGPT connector authorization are separate acceptance gates.

## Implemented on protected source branch

- `headless/first_use_accounts.py`: reads RDC manager presence/profile directory **names**, reuses authenticated `storage_adapter.accounts()` for redacted, typed cloud *remote labels*, and does not open session/device config or credentials.
- `headless/server.py`: new `GET /api/connections/first-use/v1` reuses existing Headless Host/Origin/token auth; rejects query input; provider and service side effects NONE.
- `headless/index.html` + `dashboard.js`: Web UI **Discover existing account labels** action and graceful session-loss clearing; textContent only, never raw HTML.
- `tools/package_headless.py`: package allowlisted existing Headless runtime components instead of indiscriminately archiving entire source, exclusion of caches, secrets, private data and credentials.
- Tests: negative RDC7/RDC6 isolation, secret-field suppression, symlink protection, no cloud token exposure, packaging no-clobber & private-data exclusion. The tests are source-added; do not claim GitHub/Mac execution unless a tool receipt proves it.

## Missing implementation, ranked

**P0**: current Mac Project Bible/current dirty source/LKG comparison; existing accepted installed Headless identity and correct upgrade flow; actual RDCravensnest principal/device-ready readback; safe Google/Dropbox native OAuth + stable account IDs, tokens in Keychain/provider-secure store, OAuth denial/revocation; negative tenant tests; exact account-specific grant isolation.

**P1**: first real Google read-only selected-folder listing via BIFROST, second Dropbox account test, independent iCloud OS-managed provider, provider state cache/expiry, no-sync default, installation side-effects and rollback verified.

**P2**: Finder / File Provider, Apple Shortcuts, optional menu bar, additional cloud/NAS protocols, approved copies with checksum and conflict policy, DeLorean history integration, workAIcloud delegation with explicit grants.

## Acceptance / evidence

Current GitHub branch writes = source changes only, original source untouched by automatic Mac installer; no Google/Dropbox/RDC account authorized or paired; no Mac runtime overwritten; no Products promotion. Historical BIFROST build/test counts are not current test receipts. Package builder improvement and provider inventory must pass actual macOS test suites, source/runtime hash readback and representative restore before approval.

**SNOOPY corrective workflow:** RECOVER → DISCOVER → RECOGNIZE → REUSE → RECONCILE → INTEGRATE → BUILD ONLY THE GAP → VERIFY. Never treat source folder, installed executable, runtime session directory, Releases/Testing and Dropbox handoff as interchangeable.
