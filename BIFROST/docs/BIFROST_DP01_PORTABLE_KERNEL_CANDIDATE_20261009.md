# BIFROST DP0.1 — Portable Kernel, Headless, Native and PWA candidate

Date: 2026-10-09. Status: CANDIDATE / STATIC AND ISOLATED ENVIRONMENT TESTED.
Canon: AppDev Bible, BIFROST Project Goals DP0.1, October 7 capability recovery,
BIFROST_CROSS_PLATFORM_PRODUCT_CONTRACT.md. Not a full BIFROST release.

## Identity and domain ownership

BIFROST = CONNECT · KEEP · RESOLVE. The portable kernel owns connective
identities, basic metadata, locations, relationships, provenance and search.
HEIMDALL owns Workspace composition; specialist Apps retain domain data and
their independent services. CONDUCTOR/FORGE retain development governance.
LCAS FULL is only in-chat presentation, not a runtime dependency.

## Current vertical slice

A Python 3.9+ standard-library core at core/portable_kernel.py, with SQLite3.
No Apple, Raven, Cloudflare, Codex, Homebrew, Internet or AI dependency in core.

- DISCOVER: enumerate explicitly chosen directory, no symlink traversal,
  hidden secrets or typical cache directories.
- IDENTIFY: SHA-256 content-based file identity, stable across file moves
  and roots when bytes are the same. Source-scoped directory identity.
- READ METADATA: filesystem bytes/mtime, suffix, canonical basic MIME.
  Embedded, sidecar and specialist metadata extraction NOT IMPLEMENTED.
- NORMALIZE: stable object/source/location IDs and relative locations.
- CLASSIFY: deterministic suffix groups with unknown fallback.
- HASH: SHA-256 streaming with before/after size/mtime/inode checks.
- RELATE: directory contains and file-version supersedes edges.
- PERSIST: SQLite v1, WAL, foreign keys, indexes and provenance ledger.
- INDEX: bounded case-insensitive SQL LIKE with escaped wildcards, not FTS.
- EXPOSE API: CLI scan/status/search/object, and Headless GET kernel/status
  plus local-session-protected kernel/search; no remote scan endpoint.

### Representations

Core: core/portable_kernel.py. Mac Headless: headless/kernel_adapter.py,
reading the same local SQLite database. Native macOS: Sources/KernelView.swift
(Index & Identity) with selected folder + confirmation before local scan,
through the embedded portable CLI. Local PWA: Index & Identity read/search,
using DOM textContent for untrusted filenames. Service worker never caches
private API responses. Raven remote PWA does not have this capability.

Windows/Linux core portability is a SOURCE DESIGN, not a verified OS
deployment. Six native/Headless variants remain mandatory. No remotely
authorized scanning or secure mobile pairing is asserted.

### User data, privacy and limits

Private index path for Lucas macOS:
~/Library/Application Support/BIFROST/kernel/index.sqlite
The SQLite DB includes absolute source roots, relative paths and hashes.
Back it up using SQLite's online backup API while running; do not copy only
the .sqlite file when WAL is in use. PENELOPE owns future automated backups.

Core default: <=2000 files, <=512 MiB/file, <=1 GiB total hash bytes.
Native App: <=250 files, <=32 MiB/file, <=256 MiB total, depth <=8.
On permission error or limit the result is PARTIAL; prior locations are not
pruned. Originals are never written, copied to cloud or auto-indexed.

The local Headless session is NOT network-grade identity. Search is local,
and remote scan actions are absent. Scanning is owner-authorized via native
file picker / CLI only. Secrets and hidden files are skipped by default.
Hashing and path metadata can still be sensitive.

### Limitations / acceptance boundary

Content-addressed identity treats equal bytes as one object at multiple
locations, even when the human regards them as distinct logical items.
Directory identities are path-scoped. Rich metadata, semantic identity,
full-text indexing, migration beyond SQLite v1, executable install manager,
resumable background jobs, mid-scan cancellation, provider selection,
cross-device grants and remote indexing remain outstanding.

Native has a bounded local process with no live cancel/progress or
resumable job receipts. Browser/Headless read from the shared DB, but
interactive UI/VoiceOver and real iPhone physical tests remain UNVERIFIED.
Windows/Linux service managers, desktop applications and packages are NOT BUILT.

## Evidence gates

REFERENCE: AppDev Bible / BIFROST Project Goals and October 7 recovery.
BASELINE: PWA full backup and Last Known Good runtime preserved.
IMPLEMENT: Portable kernel + Headless API + native UI + local PWA search.
STATIC: Python 3.9 unit regressions, Xcode/Swift build, JS syntax.
ENVIRONMENT: Isolated temporary directory/SQLite scan/move/search pass.
REGRESSION: Python/Node suites (see newest evidence report for exact counts).
PACKAGE: macOS test candidate ONLY.
PACKAGE VERIFY: app resource inclusion and recovery ZIP tests.
PHYSICAL: native picker, mobile access, Windows/Linux NOT VERIFIED.
PROMOTE: NOT ACCEPTED; no Products deployment, user personal data not scanned.

## Next EDCs

MICRO: package and verify candidate; snapshot exact evidence and restore test.
STANDARD: cancellable/resumable index jobs, extractor/provider interfaces,
SQLite online backup, manifest-driven App/Capability discovery.
CRITICAL: trusted mobile grants and remote interconnect, cross-OS Headless
service adapters, six native/Headless products, signing and physical gates.
