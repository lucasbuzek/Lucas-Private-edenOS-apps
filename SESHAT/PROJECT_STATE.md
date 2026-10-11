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
- APP DEVELOPMENT RESEARCH / DECISIONS: WRITTEN in docs/RESEARCH_DECISIONS.md.
- IN-CHAT ASSISTANT CONTRACT: WRITTEN.
- PROJECT INDEX: symlink created; verify resolution.
- IMPLEMENTATION: FIRST DOMAIN-CORE PROTOTYPE WRITTEN (src/domain/ledger.mjs); not a complete app.
- TEST: 13/13 Node tests PASS on Mac (receipts/issues/transfers, idempotency, quantity precision, stock guards, reversal and immutability).
- UI/PWA, durable database, server, auth and multi-user runtime: NOT IMPLEMENTED / UNKNOWN.
- GOOGLE OAUTH/API: NOT CONNECTED; no credentials created or inspected.
- GITHUB: initial SESHAT baseline, research, assistant contract, package, ledger and tests committed to branch `seshat/bootstrap-20261011` in `lucasbuzek/Lucas-Private-edenOS-apps`; branch is not merged to main. Remote file-content verification is the next gate.
- Trademark/domain/store clearance: NOT CHECKED.

## Google connector availability
ChatGPT Google Drive, Gmail, Google Calendar and Google Contacts connectors returned DISABLED_BY_ADMIN / NOT_AVAILABLE. They cannot be enabled by this task, so this conversation has no verified live access to those accounts. Direct Google API integration in SESHAT remains feasible after user-controlled Google Cloud configuration, OAuth consent, enabled APIs, redirect URIs and credentials.

## Next gate
1. Reconcile any newly recovered historical SESHAT source if found.
2. Establish canonical GitHub persistence without overwriting unrelated repositories.
3. Test the in-chat assistant using supplied/sample inventory data; keep external writes disabled.
4. Define schema/API and deterministic stock-ledger tests.
5. Implement PWA and Google adapters after auth/configuration are available.
6. Record build, tests, provider verification and physical/browser gates separately. No LKG until acceptance.