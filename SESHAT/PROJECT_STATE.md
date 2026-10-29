# SESHAT — Current Project State

Updated: 2026-10-11.

## Active context
- Identity: SESHAT — Stock Entry, Storage, Handling & Tracking. Functional descriptor: small-business stock and inventory management.
- User decision: SESHAT is the business stock/inventory product; NOSTOS is household-only; ARGOS is search/research-only.
- Authority read: namingRules.txt; APPDEV_BIBLE.md; UNIVERSAL_APP_INTEGRATION_HIERARCHY_RULE.md; UNIVERSAL_PROJECT_STORAGE_RULE.md; ForgeMASTER v1.0 governor/routing/evidence records; ELYSIUM in-chat suite canon; EDEN PWA cloud/access/identity canon.
- Recovery search found no SESHAT-named local folder/file/content match in searched /Users/lucas paths and no SESHAT workspace/index before initialization. This does not prove every external or archived source is clear.
- NOSTOS Android candidate inspected. Its acceptance matrix leaves the headless service/shared database/Web server, persistence, authentication and backup/restore unverified. It is household scope and must not be repurposed as SESHAT.
- ELYSIUM Business is the in-chat business suite; SESHAT should be an independently useful stock specialist, not a replacement for the suite.

## Evidence
- DESIGN BASELINE: WRITTEN.
- APP DEVELOPMENT RESEARCH / DECISIONS: WRITTEN in docs/RESEARCH_DECISIONS.md and docs/APP_DEVELOPMENT_RESEARCH.md (IndexedDB, offline-first PWA, OAuth scopes, inventory concurrency and persistence strategy).
- IN-CHAT ASSISTANT CONTRACT: WRITTEN.
- PROJECT INDEX: symlink target verified (`~/edenOS/Projects/SESHAT` -> `../Software Development/SESHAT`). No broken symlinks found in the scanned Projects, AppDev/Projects or Software Development trees.
- IMPLEMENTATION: INVENTORY LEDGER + CHECKSUM-PROTECTED JSON SNAPSHOT PROTOTYPES WRITTEN (src/domain/ledger.mjs, src/persistence/snapshot.mjs); not a complete app.
- TEST: 18/18 Node tests PASS on Mac; node --check PASS for all source/test modules. Coverage includes ledger arithmetic, idempotency, quantity precision, stock guards, compensating reversal, immutability, snapshot round-trip, SHA-256 tamper detection, schema-version rejection, invalid-history rejection after recomputed checksum, and duplicate-location rejection.
- Snapshot serialization/import/export with SHA-256 integrity: PROTOTYPE IMPLEMENTED AND TESTED.
- Durable database, file-system backup/restore, UI/PWA, server, auth and multi-user runtime: NOT IMPLEMENTED / UNKNOWN.
- GOOGLE OAUTH/API: NOT CONNECTED; no credentials created or inspected.
- GITHUB: all 14 current SESHAT project/source/test/evidence files matched the Mac workspace byte-for-byte after syncing the latest snapshot tests. Branch `seshat/bootstrap-20261011` in `lucasbuzek/Lucas-Private-edenOS-apps` remains separate and is not merged to main. [Open branch](https://github.com/lucasbuzek/Lucas-Private-edenOS-apps/tree/seshat/bootstrap-20261011).
- Trademark/domain/store clearance: NOT CHECKED.

## Google connector availability
ChatGPT Google Drive, Gmail, Google Calendar and Google Contacts connectors returned DISABLED_BY_ADMIN / NOT_AVAILABLE. They cannot be enabled by this task, so this conversation has no verified live access to those accounts. Direct Google API integration in SESHAT remains feasible after user-controlled Google Cloud configuration, OAuth consent, enabled APIs, redirect URIs and credentials.

## Next gate
1. Exercise the in-chat assistant against clearly labelled fixture data; keep external writes disabled.
2. Add reservation and stocktake workflows with deterministic event-ordering tests.
3. Implement durable local storage and actual file-based backup/restore tests before shared-server work.
4. Build the responsive PWA and explicit offline/conflict states.
5. Add Google adapters only after authorized OAuth configuration; connector access is currently unavailable.
6. Verify remote branch/source hashes on every sync; do not merge to main until project acceptance.
7. Record build, tests, provider verification and physical/browser gates separately. No LKG until acceptance.
## Continuation receipt — 2026-10-29

This section is additive; the prior 2026-10-11 source and its evidence remain historically accurate.

- Protected continuation branch: `seshat/pwa-recovery-20261029`; original `seshat/bootstrap-20261011` and `main` not mutated by this work.
- Reconciled and recovered the seven later query, reservation, stocktake, snapshot, fixture and test files from two identical Dropbox SESHAT source copies.
- IMPLEMENTED_CANDIDATE: validated catalogue/locations, local IndexedDB persistence with stale-revision rejection, responsive standalone PWA, receipt/issue/return/transfer/adjustment movement confirmation, live stock queries, CSV catalogue dry-run/import with row errors, explicit backup export and validated restore, service worker offline shell.
- TESTED_CI: **49 Node tests pass, 4 Chromium browser tests pass**, static build/syntax and allowlisted publication checks pass on GitHub Actions run [40835282434](https://github.com/lucasbuzek/Lucas-Private-edenOS-apps/actions/runs/40835282434) at commit `158474c76d7d91930454865e9b6f86e9152f125b`.
- Cloudflare inspected READ ONLY: SlindokuhleCouncil account has no Pages projects or D1 databases in inspected lists and Access is not enabled (403). No SESHAT deployment created; do not mix with separate RAVENnest Access apps and their D1 data.
- NOT VERIFIED/NOT IMPLEMENTED: authenticated multi-user stock posting, server transactional ledger, remote MCP, supplier/PO UI, durable stocktake/reservation UI, Google OAuth/provider adapters, authenticated hosted preview, physical-device acceptance, user acceptance/release.
- Additional coverage: see `docs/PWA_CANDIDATE_20261029.md`. A browser-local working application does not prove remote multi-user consistency. Do not promote to Products or merge to main.
