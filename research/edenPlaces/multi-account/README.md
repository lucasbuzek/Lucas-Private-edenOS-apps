# edenPlaces — Multi-account folder-sync candidate (2026-10-30)

**Status:** isolated Swift implementation with **34/34 PASS** (`swift test` on Linux with synthetic provider adapters); **NOT** an installed Mac app, live Dropbox/Drive/OneDrive session, cross-provider production deployment, or complete recursive folder sync.

## Source continuity

Built as an **additive DropboxLiteCore candidate** for the existing Dropbox Lite v0.4.2 original code in the owner's connected `RAVENsNEST / AI MCP tool / #AI toolkit / Dropbox Lite` archive. The current authoritative Mac project resides under `~/edenOS/Software Development/Dropbox Lite` and is not accessible in this turn: Remote Desktop Commander `Lucas-MacBook.local` offline. No original Mac files or private provider secrets were changed.

New source files (to be staged only after Mac dirty-state/LKG review):
- `SyncProfiles.swift`: up to 32 separate provider accounts, owner-declared display names, system/managed Rclone remote refs, explicit local roots, per-folder permissions, independent schedules and persistence (0600); no tokens.
- `ProviderNeutralSync.swift`: provider-neutral direct-file plan and execution using **content SHA-256**, no overwrite or delete, staging + atomic local hard-link create, baseline tracking of deletions, remote mutation rejection and permission rechecks before each operation.
- `ProfileBatchRunner.swift`: one short-lived, lock-protected scheduled batch; registry reloaded before transfers; independently persisted ledger and schedule for each account; one failing account does not authorize another.
- Tests: `ProfileTests.swift`, `ProviderNeutralSyncTests.swift`, `BatchRunnerTests.swift`. `Models.swift` is an **unaltered fixture copy** from the original Dropbox Lite core and `RemoteSourceLinuxHarness.swift` exists **only to compile isolated Linux tests**; do NOT copy that shim into the macOS target.

## Supported architectural providers (not proven connected)
Dropbox, Google Drive, OneDrive, Box, WebDAV, S3, optional Cloudflare R2. The provider-neutral `PlacesSafeProvider` contract (including a `subfolders` method for explicit recursive grants) must be backed by a verified, authenticated real provider adapter before production. **Crucial requirement:** `createOnly` must be an atomic backend-native conditional-create operation; naive `rclone copyto --ignore-existing` is not guaranteed atomic against races. `snapshot` must report real content **SHA-256** or perform bounded streaming verification: DropboxHash, MD5, S3 ETag and file modification dates are NOT interchangeable SHA-256. An adapter lacking these capabilities MUST fail closed; never invent successful uploads.

This candidate processes direct files under exact granted folders. `recursive=true` explicitly opts into visiting descendant folders, with depth/entry limits; legacy grants default to `recursive=false`. **Live recursive provider adapter acceptance**, provider-specific auth, provider-native create-only semantics, multi-profile GUI editing, macOS scheduled-worker integration, real browser/ChatGPT remote MCP, and physical upload/download acceptance are **NOT yet implemented**. Do not treat the `PlacesProvider` enum, passing mock-adapter tests, or ZIP as evidence that these gates are complete.

## Cloudflare decision
Cloudflare is an OPTIONAL gateway/connector and optional R2 storage target, not the main Mac-local sync engine. Recommended roles: Workers/Access for authenticated browser APIs; D1/DO for scoped account metadata/coordination; optional Workflows/Queues for durable requested jobs; R2 only if explicitly enabled and selected as a separate storage account. At inspection the RAVENsNEST Cloudflare R2 API returned HTTP **403 / 10042 `Please enable R2`** — not enabled or ready. No Cloudflare account, Worker, OAuth token, R2 bucket, Asana content, Google Drive file, or Dropbox source was modified by these tests. The BIFROST v7 ZIP located in Google Drive `App Releases` is mostly a demo with hard-coded search/device/`Executed` success responses and permissive CORS; **do not deploy it as a trusted file gateway**.

## Verification
Run in this self-contained isolated harness:
```
swift test
```
Result: `34 tests; 0 failures`, original Linux Swift 6.2.1 compiler. Tests cover real temporary-local-file download/upload via fake cloud adapters; independent two-account scheduled batch; SHA-256 verification; tracked-deletion preservation; same-name conflict preservation; dry-run no side effects; safe root, filename and path handling; symlink-related checks; duplicate/overlap prevention; revocation; schedule, persistence, token exclusion and spoofing guards.

## Required production gates (BEFORE enabling live sync)
1. Physically verify the authoritative Mac's original project, current version, git dirty state, backup and known-good release; reconcile source by diff, no overwrite.
2. Integrate the new `DropboxLiteCore` files and design the native SwiftUI multi-profile controls; run full Mac Swift Package/Xcode tests and native UI acceptance, not only Linux harness.
3. Implement/validate per-provider OAuth account ownership, refresh, revocation, native conditional create, SHA-256 streaming, privacy scopes, quota/rate-limit and provider-specific failure recovery. Never reuse ChatGPT connector tokens as edenPlaces app credentials.
4. Integrate and physically test the implemented opt-in recursive exact-folder descendants plus conflict UI; verify offline -> online retries, concurrent remote changes, deletion/rename, restart, cancellation, disk-full, huge files and tenant/account isolation on real test accounts.
5. Enable original launchd scheduling only after signed worker and physical permission state are verified. Keep automatic sync OFF for all imported/new profiles. No unattended discovery or migration.
6. After verified native/cloud sync, build the authenticated Cloudflare browser gateway, then remote MCP and optional WebMCP (as the user explicitly requested).

Sources: `https://drive.google.com/drive/folders/144BxkjSl_hciXM0TjxPJtlhCVC4axKGr`, `https://drive.google.com/drive/folders/1qu9Gzx5C0reqzBwDnDgp4H0oHHSeEqW7`, `https://drive.google.com/drive/folders/1gKe0V_P352XJSHTb4NqvVOJ4-XuxINHH`; Cloudflare R2 getting-started and Workers/Workflows official docs.