# BIFROST Files & Storage — universal storage capability
Date: 2026-10-20. Owner: BIFROST / BIFROSTcore. Status: ENGINEERING CANDIDATE, not an accepted product or installed Headless/plugin runtime.

## Current directive — 2026-10-20 16:35 · STANDALONE FIRST

**Newest explicit decision: Keep Files & Storage standalone for now.** This supersedes the earlier priority to connect or deploy its BIFROSTcore/Headless/ChatGPT bridge immediately. The independently runnable storage terminal/core is the current executable surface, with future standalone admin UI subject to separate implementation/acceptance. Do not install, restart, reconfigure, enable, deploy, or add live BIFROST Headless routes for Files & Storage during this standalone phase. Existing source-level adapter and HTTP route experiments remain uninstalled/inert in the live service; preserve them only as historical tested integration candidates, not active product functionality.

The shared BIFROST project source location is an established working master; it does not imply that using the standalone CLI requires BIFROST Headless, ChatGPT, PENELOPE, JANITOR, any cloud account, or any running service. Reconsider integration ONLY on a later explicit user direction. Automatic sync stays Off. No Files & Storage LKG/product promotion or new parallel governor is authorized by this decision.

## Earlier product direction (retained for future integration reference)
This is **BIFROST → Files & Storage**, not a separate platform/governor or a duplicate BIFROSTcore runtime.
The **terminal core + BIFROSTcore capability/plugin + private ChatGPT plugin** are the primary goal. The standalone/native app is a lean administration surface for first-run setup, accounts, profiles, grants, storage hierarchy and job controls, not an independent source of truth. Lucas macOS is the first physical target. Windows, Linux, server, NAS and independently hosted deployments remain intended targets subject to separate physical evidence.

One universal architecture covers local files, removable drives, network mounts, iCloud Drive, Dropbox, Google Drive, OneDrive/SharePoint, Box, WebDAV/Nextcloud, S3/MinIO, SFTP, SMB/NAS and optional existing Syncthing peers. These are user-selectable OPTIONS. Not all options have verified executable transfers. No global sync root and no automatic credential imports.
BIFROSTcore owns provider discovery, identity, account selection, permissioning and receipts. Provider-specific engines (the established Rclone/Dropbox Lite implementation, OS-native File Provider/iCloud, or independently opted-in open-source utilities) retain credential and transfer ownership.
PENELOPE can organize authorized user files and JANITOR can inspect/clean through separate opt-in typed actions ONLY when truly connected. They do not become default dependencies or AppDev/file sync owners.

## Adopt / Adapt / Reference / Reject
- **ADOPT** Python 3 standard library for lean portable terminal metadata catalog and BIFROST's existing portable core and versioned capability contracts; no always-running process.
- **ADAPT** existing Rclone binary, per-account remotes and Dropbox Lite direct-file staging/hash/cancel/permission semantics for future provider adapters. Its v0.4.2 macOS bundle remains the sole old-purpose test candidate; the original source and its verified backup MUST remain intact.
- **REFERENCE / optional, not bundled** native macOS Finder, File Provider and iCloud coordination, Syncthing (peer sync), Nextcloud (WebDAV or native client), restic/Borg (versioned backup rather than sync), SFTP/SMB mounts, S3/MinIO object stores. Only an explicitly selected user profile may enable a suitable optional provider/engine.
- **REJECT** a second standalone BIFROST bridge/daemon, silent recursive sync, global all-account scanning, universal cross-cloud hash claims, reading/hydrating iCloud file contents during metadata listing, replacing native cloud provider storage with raw Rclone folder mirrors, deleting local files to simulate iCloud offload, cloud storage for AppDev source/backups, a mandatory paid API, Chrome, startup jobs by default, or unverified cross-account mixing.

## Technical boundaries and provider differences
- **Local:** named user-selected folder and external device only. One-level stat/list, no symlink traversal; no file contents read, copied, deleted, uploaded or moved. User controls path and permission.
- **iCloud Drive:** select existing Apple-managed `~/Library/Mobile Documents/com~apple~CloudDocs` subfolder. Read metadata without forcing placeholder hydration. Apple File Provider / NSFileCoordinator and entitlements may be required for approved downloads/offload and version conflicts. One active Apple ID per OS session; independent Apple-account multi-login must NOT be claimed.
- **Dropbox:** independent existing Dropbox Lite direct-file safety/DropboxHash adapter; NOT integrated into the universal module for transfers yet.
- **Google Drive:** user-specific Google OAuth client ID is required as Rclone's shared client is being retired during 2026. Google-native Docs files need explicit export semantics; MD5/SHA1/SHA256 may be missing or unsuitable. No user authentication performed by metadata module.
- **OneDrive:** OneDrive home and work/school accounts are separate identities; SharePoint drive IDs and permissions are distinct. QuickXorHash is provider-specific (not DropboxHash). Do not re-use Dropbox checksum verifier.
- **WebDAV/Nextcloud/S3/SFTP/SMB:** user-controlled hosting and access policies; WebDAV/S3 object semantics, conflict/ETag/checksum, encryption, offline state and legal permissions must be verified by provider, not assumed.
- **Cross-platform:** terminal core uses Python3.9+ stdlib today; **only macOS** local access has test/device evidence. Windows path/DPAPI/service and Linux mounts/permissions/systemd are future platform gates, not completed delivery.

## Implemented source and truthful capability boundary
- `core/storage_capability.py`: versioned provider catalog, read-only status, multiple preconfigured Rclone section names/backend types (never OAuth tokens or client secrets), one-level bounded selected local and iCloud folder metadata, isolated local profile metadata preview and explicit --apply.
- `tools/bifrost_storage.py`: terminal CLI, status/providers/accounts/list-local/list-icloud/profiles list|add.
- `docs/integrations/files-storage-capability.v1.json`: typed capability and consequence catalog for *future* BIFROSTcore Headless/ChatGPT adapters. No route installed into the live Headless and no bridge claim.
- `tests/test_storage_capability.py`: negative paths, account metadata privacy, no recursion, iCloud scope, no global startup, profile prevention without --apply.
- Existing BIFROST native app/Menu/Headless, tokens, DBs, launchd, credentials, provider clients and source backups are untouched.

## Terminal examples (user directed)
```
cd "$HOME/edenOS/Software Development/BIFROST"
python3 -B tools/bifrost_storage.py status
python3 -B tools/bifrost_storage.py providers
python3 -B tools/bifrost_storage.py accounts
python3 -B tools/bifrost_storage.py list-local --path "$HOME/Documents"
python3 -B tools/bifrost_storage.py list-icloud --path "$HOME/Library/Mobile Documents/com~apple~CloudDocs"
python3 -B tools/bifrost_storage.py profiles list
# Profiles add is DRY-RUN by default; --apply saves just metadata; sync stays OFF
python3 -B tools/bifrost_storage.py profiles add --name MyLocal --provider local \
  --source native-local --local-root "$HOME/Documents"
```

## Integration/acceptance sequence
1. Verify bounded CLI, user selected directories and zero token exposure on real Mac; full BIFROST regressions independent from incumbent Headless. Preserve verified BIFROST source/backup evidence.
2. Add typed authenticated adapter route using BIFROST's **existing** Headless/Bridge after source/identity/version authorization, without changing live token/port/service. Test mismatch and service absent.
3. Publish the private ChatGPT BIFROST Files & Storage plugin **skills capability** (not a second BIFROST governor), label live device access NOT CONNECTED unless an authorized tool actually exists; verify installed plugin metadata. No phantom action implementations.
4. Lightweight native App management screen after core acceptance. No mandatory daemon. Profiles configured per provider/account, identity, scope, local root, manual/schedule setting and conflict baseline, each OFF by default.
5. Provider-specific OAuth, exact-folder download, safe transfer and hash/verification, per-file cancellation, offline handling, opt-in schedule, conflict and restore tests before any cloud write. No automatic cloud migration or source/offload deletion.
6. Windows/Linux/server builds and independent hosts only after live target toolchains and host acceptance. Never label a design as shipped.

## Research pointers verified 2026-10-20
- https://rclone.org/drive/ (shared Google Drive client retirement in 2026 and custom OAuth client).
- https://rclone.org/onedrive/ (QuickXorHash and OneDrive differences).
- https://learn.microsoft.com/en-us/onedrive/developer/rest-api/resources/hashes (cloud hashing constraints).
- https://developer.apple.com/documentation/appkit/nsopenpanel/candownloadubiquitouscontents (iCloud placeholder and download semantics).
- Existing BIFROST `docs/architecture/BIFROSTCORE_RUNTIME_RECONCILIATION_20261020.md` remains runtime authority. This file is an additive feature contract, not a new BIFROST master.

## 2026-10-20 — storage-specific Headless reconciliation

BIFROST main product and its existing BIFROSTcore runtime reconciliation remain
authoritative. This storage feature has ONE logical domain identity
bifrost.files-storage. Nothing here creates a new BIFROSTcore, second Headless
service, external browser bridge, credential store or provider sync engine.

- New additive headless/storage_adapter.py loads canonical core/storage_capability.py
  from source or the already established core/ app resource folder
  on an explicit API call. No import-time scan, network connection, provider
  authentication, source migration or background poll. Missing or nonregular
  module => 503 with no fabricated capability.
- Existing headless/server.py has candidate GET /api/storage/v1 (metadata
  catalog; does NOT read accounts) and GET /api/storage/v1/accounts (only existing
  Rclone config section names and provider types). Both reuse the existing
  BIFROST Headless authentication, Host and Origin gates. No path/query
  parameters or POST writes accepted. Public PWA adapter advertises only
  these source-implemented read-only routes with local-session requirement.
  Actual installed BIFROST native App/Menu/Headless remains UNCHANGED.
- Local terminal tools/bifrost_storage.py stays independently useful without
  BIFROST Headless, BIFROST native UI, ChatGPT or the internet. Explicit
  local/iCloud file listing remains terminal-only; a broad filesystem HTTP
  endpoint was deliberately NOT introduced. Profile metadata --apply is
  explicit, sync Off and no live cloud credentials were created.
- Existing BIFROST project.yml already packs headless/ and core/ as
  distinct resource folders; no new project spec or second resource copy.
  Both target unsigned Debug builds have been verified in isolated temporary
  build contexts; resulting bundles contain byte-for-byte identical storage
  adapter, Headless route and core module files.
- The canonical BIFROST.xcodeproj on Mac predates Swift source and misses
  PermissionCenter and RDC Manager view file references. Building it
  directly fails with unrelated missing Swift symbols. A regenerated project
  in disposable Temporary using the SAME project.yml and symlinked existing
  source/resource paths succeeds. Do not replace canonical project without
  separate BIFROST-source reconciliation.
- Source-level auth/negative tests include missing token/host mismatch/origin,
  forbidden POST, query rejection, missing adapter fallback and avoidance of
  unrequested account scans. Evidence:
  docs/verification/BIFROST_FILES_STORAGE_RECONCILIATION_20261020.md.
- STILL UNKNOWN: physical installed Headless route, native GUI interaction,
  live paired ChatGPT connector/MCP dispatch, user OAuth approval, folder
  transfers, provider-native checksums, live permission revocation, hosting,
  Windows/Linux builds, and any synchronization. No LKG or Products promotion.
- The registered private ChatGPT plugin bifrost-files-storage release 0.1.1
  is a skill interface, NOT a BIFROST Headless transport. Actual authorized
  RDC/provider connectors may be used only under exact approved scope.
  PENELOPE and JANITOR remain separate optional specialists.


## 2026-10-20 — profile-scoped local/cloud metadata previews

This increment is part of the EXISTING BIFROST Files & Storage capability. Source modules: core/storage_preview.py, extended core/storage_capability.py, CLI tools/bifrost_storage.py, existing Headless adapter/routes, and versioned capability descriptor 0.1.1. It is not a new daemon, database, BIFROST governor or replacement cloud driver.

- A profile grants precisely one named source and local root. For Rclone-backed clouds the owner must also select a non-root remote_root when saving the profile; old profiles with no approved remote_root cannot browse cloud data. Two remote names are independent by configuration source + name + provider + an opaque SHA256 fingerprint of that EXACT config section (including token fields only in-memory as fingerprint input; never printed). Changed provider identity, credential refresh, or a reassigned remote name invalidates the stored grant and requires deliberate review. This is a conservative fail-closed SOURCE identity check, NOT independent provider identity verification.
- CLI: profiles add --remote-root EXACT_FOLDER defaults to preview; --apply saves metadata only; sync remains Off and transfers_authorized false. preview --name PROFILE --folder OPTIONAL_RELATIVE previews only the scoped folder. Cloud preview without --read-remote displays approved identity/path but makes NO provider request. --read-remote explicitly permits only one metadata listing; no uploads/downloads, delete, mount, hash, or continuous polling.
- The bounded Rclone metadata adapter uses installed rclone lsjson with --max-depth 1, --disable ListR, no modification-time/MIME/hash lookup, single retry, short connection/I/O/process timeouts and bounded JSON output. Stderr is never surfaced. It refuses unavailable/insecure configs, wrong provider, malformed responses and excessive entries. Real cloud behavior awaits account-specific user authorization/physical verification.
- Local folders are inspected one level at a time without reading file contents; symlink traversal, nonrelative child selections, percent-encoding ambiguity, protected AppDev directories and large directory listings are denied. iCloud remains OS-owned and may include placeholder metadata without forcing downloads.
- Existing BIFROST Headless source adds POST /api/storage/v1/preview with JSON profile/folder/readRemote selections. It inherits the existing authenticated localhost token, Host, Origin, bounded JSON body and sanitized rejection semantics. A new API route in source DOES NOT mean it has been installed in the running service; it is explicitly SOURCE_TESTED_NOT_DEPLOYED.
- No standalone cloud authentication, credential vault, token export, PENELOPE/JANITOR dispatch, native storage admin screen, installed Headless service update or private ChatGPT direct-action bridge was performed. Independent BIFROST runtime canon and existing native/Headless service remain authoritative.

Recovery and exact test evidence are appended to docs/verification/BIFROST_FILES_STORAGE_RECONCILIATION_20261020.md in the same BIFROST project. Do not promote to Products/LKG.
