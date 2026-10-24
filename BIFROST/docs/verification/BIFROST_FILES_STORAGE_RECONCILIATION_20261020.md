# BIFROST Files & Storage — 2026-10-20 source and integration evidence

Scope: ONLY the BIFROST Files & Storage capability. Current BIFROST native, Menu, Headless owner, legacy Core, BIFROSTcore bridge, PENELOPE, JANITOR and Dropbox Lite are not replaced or migrated. Canonical source: /Users/lucas/edenOS/Software Development/BIFROST/. Verified on Lucas-MacBook.local, macOS Darwin 27.0.1, Xcode 27.0, Python 3 stdlib, Node. Status: SOURCE TESTED + INTERNAL DEBUG BUILDS, installed runtime/physical acceptance UNKNOWN. No accepted storage LKG.

## Recovered boundaries

- BIFROST and BIFROSTcore remain one application family and connection/capability owner; Headless is the existing localhost authority on port 8798 when installed and independently running. Historical Core on 8090 and older DB are NOT started/merged.
- Files & Storage is a BIFROSTcore feature. Existing Dropbox Lite v0.4.2 macOS Custom is still a separate, signed, unaccepted provider-oriented application candidate; its sources, rollback, user accounts and releases were not changed.
- Existing BIFROST portable kernel DP0.1 and Headless state are preserved. New storage profile metadata is non-secret, manual --apply only; not an alternate BIFROSTcore process or canonical unified provider database.
- Optional PENELOPE and JANITOR retain independent authorized file-organization and maintenance roles. No delegation was executed. Cloud providers remain opt-in; no forced Chrome, no Dropbox AppDev work, no automatic whole-disk scan, credential export, deletion, cloud transfer or new background daemon.

## Actual implementation

- core/storage_capability.py: 11 provider options; independent Rclone remote config section metadata for Dropbox, Google Drive, OneDrive, etc., while never returning tokens; one-level selected local/iCloud Drive metadata without file hydration; safe nonrecursive scope/secret and symlink denial; local profile metadata preview and explicit apply; automatic sync Off.
- tools/bifrost_storage.py: on-demand terminal status, providers, accounts, profiles and selected local/iCloud list.
- headless/storage_adapter.py (new): loads existing same-product core module on demand from current source folder or already existing bundled core/ folder. Missing/nonregular module => unavailable, never synthetic success. No startup scan.
- headless/server.py (bounded change): two read-only routes GET /api/storage/v1 and GET /api/storage/v1/accounts, using the existing local token, Host and Origin checks; arbitrary query parameters return 400; POST writes unimplemented/404. Route metadata is advertised in the existing PWA capability catalog, requiring local session. The generic status route must not fetch account credentials or directory contents.
- docs/integrations/files-storage-capability.v1.json: versioned single-owner capability with SOURCE_TESTED_NOT_DEPLOYED routes and installed/ChatGPT bridge explicitly false.
- tests/test_storage_capability.py and tests/test_headless.py: synthetic privacy/permission, unauthenticated and malicious-Origin route requests, query/write denial, module unavailable behavior, empty and multi-account cases.

## Verified checks

1. Before editing Headless server and shared tests, seven relevant source/contract files were snapshotted into the established BIFROST_REBUILD_BACKUP set, SHA-256 9e4262fb0fc9e234794bcb8242293c97597cd56ac1e84e14f5cdfaed5bc9eb62. Extracted copies exactly matched original files.
2. Focused isolated HTTP tests: 29 Headless tests PASS; 17 storage-core tests PASS before one additional PWA catalog test.
3. After the full source/descriptor test additions, full BIFROST regression: PYTHONDONTWRITEBYTECODE=1 python3 -B -m unittest discover -s tests -q => 174 tests, OK; node --test tests/*.mjs => 16/16 PASS. The test Headless server bound an isolated temporary localhost port and used a temporary support directory.
4. Native test build 1: existing canonical BIFROSTMenu scheme, unsigned Debug => BUILD SUCCEEDED. Contents/Resources/core/storage_capability.py, headless/storage_adapter.py and headless/server.py compared byte-for-byte with current source and matched.
5. Native test build 2: existing canonical BIFROST scheme initially FAILED because checked-in BIFROST.xcodeproj lacked references to BifrostPermissionCenter.swift and BifrostRDCManagerReadOnlyView.swift, although those files are present in Sources. This is NOT a storage-code test failure. The canonical .xcodeproj remains unchanged (observed prior mtime 2026-10-19 17:01:17).
6. Generated a separate project in /Users/lucas/edenOS/Temporary/BIFROST/storage-reconcile-20261020/isolated-xcodegen from the same canonical project.yml and existing source/resource tree. The first isolated attempt failed due to missing relative source paths in Temporary; linking only temporary source/resource references fixed that verified cause. Final separate full-App Debug build => BUILD SUCCEEDED. The resulting BIFROST.app contained byte-identical three storage modules, Info.plist bundle ID eden.private.bifrost. The existing shared BIFROST Xcode project was NOT regenerated or overwritten.
7. The previously packaged Dropbox Lite v0.4.2 macOS Custom signed test candidate passed deep strict code-signature verification and is not replaced.
8. No active Rclone daemon/sync/mount, no configured Mac Rclone accounts discovered, no profile changes, installed BIFROST Headless update or OAuth authorization. This run did not transfer, mutate, delete or hydrate user files.

## Current capabilities and acceptance

- SOURCE TESTED: terminal CLI, metadata catalog, bounded account names/types, local/iCloud selected-folder list in synthetic fixtures, dry-run profiles, explicit no-auto transfer state, BIFROST Headless source-level authenticated catalog/accounts routes.
- BUILD TESTED: unsigned Debug BIFROST App and Menu resources. This does NOT establish GUI, code-signed release, installation, default-browser Dropbox OAuth or live Headless acceptance.
- SERVICE DEPLOYMENT UNKNOWN: the installed Headless service still runs its earlier source and does not prove these new GET routes exist until explicitly deployed and verified. No BIFROST port/service/launchd config changed.
- CHATGPT PLUGIN: private bifrost-files-storage plugin ID plugins_6ad72129c6e48191bafd954db7256386 v0.1.1, stored package at Software Development/#in chat/Plugin ChatGPT/BIFROST_Files_Storage_ChatGPT_Plugin_v0.1.1.zip, provider registration verified in preceding turn; skills-only, no real authenticated ChatGPT-to-BIFROST dispatcher or live device action embedded in plugin. Do not confuse RDC availability with the dedicated BIFROSTcore bridge.
- FUTURE: user-authorized provider OAuth for each identity, supported provider-specific file checksums and export semantics, exact-folder manual transfer and cancellation, opt-in sync scheduling, File Provider-safe iCloud offload, provider grant/revocation, self-hosting, Windows/Linux/server releases. All remain UNVERIFIED/UNIMPLEMENTED.
- REMOTE SOURCE: GitHub repository lucasbuzek/Lucas-Private-edenOS-apps exists as a separate private store, but Mac BIFROST working copy has NO local Git metadata; no GitHub reconciliation/push/merge/branch update performed. Avoid claiming remote source parity.

## Safe continuation (Files & Storage chat only)

1. Maintain one BIFROST source of truth and leave unrelated BIFROST native/server workflow changes to their current project authority. Integrate only the typed storage adapter via the established verified service release procedure once BIFROST permits an installed Headless update.
2. In an isolated user-approved setup, verify the candidate /api/storage/v1 and /api/storage/v1/accounts against the exact running Headless identity, permission denial, actual account readback with no token exposure, and fallback after service stop. Do not authorize cloud storage actions solely from an API status 200.
3. Build provider-specific opt-in account pairing and safe read/preview actions, using proven Rclone/OS-native adapters. Never directly let a ChatGPT-generated textual request execute a transfer, delete or mount; require typed scope and a witnessed verified receipt.
4. Only after actual BIFROST core↔ChatGPT transport is demonstrably authenticated should plugin direct actions become enabled. Keep the existing standalone terminal and the lightweight admin UI optional, not dependent on any cloud or AI.
5. Preserve source, rollback, evidence and prior accepted BIFROST/Dropbox candidates. Do not promote to Products until physical acceptance. UNKNOWN != PASS.

This evidence file is within the established BIFROST docs/verification hierarchy and is an additive storage feature record, not a new BIFROST Project Bible or LKG claim.


## 2026-10-20 · scoped account browsing AUTO completion (source-only)

Source scope: ONLY BIFROST Files & Storage in the current authoritative BIFROST master. Mandatory projectlocal.py discover found this exact master; verify returned NOT INDEXED (no PROJECTLOCAL_INDEX.json), hence NO IMPORT/SAVE NEEDED. Existing BIFROST master is not a local Git worktree; no Git changes were made or claimed. All services, providers, OS sessions, Headless runtime, native LKG, Releases and Products are preserved.

Source changes: New core/storage_preview.py, optional remote_root and account_config_digest in core/storage_capability.py, extended tools/bifrost_storage.py, headless/storage_adapter.py, and authenticated POST /api/storage/v1/preview in the existing headless/server.py. Existing GET storage catalog and account metadata routes remain. Single owner BIFROSTcore; no parallel engine/daemon, installed route or credential store created. Descriptor docs/integrations/files-storage-capability.v1.json is v0.1.1 candidate, source tested, NOT DEPLOYED.

Functional source: Select an exact saved profile and relative child. Local/iCloud preview uses at most one directory level, never opens file content or hydrates cloud placeholders; rejects protected paths, symlink traversal, invalid selectors and excess entries. Remote root is a mandatory non-root selection before any account browse; older rootless profiles fail closed. A cloud preview without --read-remote sends zero cloud requests. When explicitly requested, Rclone lsjson supports one-level metadata only, bounded timeout/output, --disable ListR, no hash/MIME/mtime query, sanitized errors, no copy/sync/delete/mount. OAuth, cloud writes, auto schedule OFF, and real cloud provider acceptance remain UNKNOWN.

Account isolation: Profiles match configuration source, remote alias and provider; grant includes the exact remote folder and an opaque SHA256 digest of that one configuration section. Credentials are used only in-memory as digest input; no tokens/client secrets returned. If the same alias redirects to another account (even same provider), or OAuth refresh changes that section, preview fails CLOSED pending explicit owner review. This is NOT independent vendor identity verification; provider-specific OAuth still requires real acceptance.

Verification on Lucas-MacBook.local:
- PYTHONDONTWRITEBYTECODE=1 python3 -B -m unittest discover -s tests -q: 220 tests, OK; real command exit 0. Includes 11 new synthetic account/preview safety tests and Headless isolated HTTP denial/integration tests.
- node --test tests/*.mjs: 22 tests passed, 0 failed; real command exit 0.
- Existing installed Headless loopback GET /api/health remained runtimeId fb7c5b677c245cd5, sourceSha256 c5ca0312349db036d398b672c17496bc440bf65f7ee440a6d07fda691e84e3ab. This installed service was not redeployed/restarted. The new POST route is SOURCE_TESTED_NOT_DEPLOYED.
- Rclone v1.75.2 present. Current existing configured account metadata read returned []; no real provider login or network file browse performed. Synthetic Rclone subprocess checks used patched executable, not a vendor API.
- Existing BIFROSTMenu Xcode scheme built with CODE_SIGNING_ALLOWED=NO as isolated internal Debug; Contents/Resources/core/storage_capability.py, core/storage_preview.py, headless/storage_adapter.py and headless/server.py compared byte-identical with latest current source after final build. No installed native App/LKG affected.
- Prechange exact-source archive #Backups/BIFROST_REBUILD_BACKUP/BIFROST_FILES_STORAGE_BROWSE_PRECHANGE_20261020.tar.gz clean-extracted and byte-verified; SHA256 74418835be4eba162930a2557f1914b89fe5e4ca02c85ceea3fb8afa725bf400.
- Early test failures were test-fixture formatting and independent Python module exception-class identity, repaired without weakening production guards. Final suites PASS.
- This addendum is SOURCE EVIDENCE, not physical installed service acceptance or authorized cloud data read. Final scoped source backup archive, extraction manifest and scratch cleanup verified independently after this addendum.

Remaining gates: Registered BIFROST ChatGPT plugin v0.1.1 remains skills-only with no live authenticated storage-action bridge; no plugin update was performed. Real user-selected provider account authentication, actual multi-login vendor identity attestation, remote metadata response from Google Drive/OneDrive/Dropbox, iCloud File Provider runtime and real service deployment must be separately approved/tested. Windows/Linux/server targets, live transfers, safe conflicts, cancellation, hosting and LKG promotion are outside this source increment. UNKNOWN != PASS.
