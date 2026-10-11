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