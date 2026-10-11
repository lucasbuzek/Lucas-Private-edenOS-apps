# SESHAT — App Development Research & Decisions

Updated: 2026-10-11
Status: research/design only; no application implementation has been started.

## Identity
- Stable machine identity: seshat.
- Display expansion accepted for this baseline: SESHAT — Stock Entry, Storage, Handling & Tracking — v0.1.0.
- Functional descriptor: small-business stock and inventory management.
- The expansion is a proposed backronym, not a claim about the historical meaning of Seshat.
- NOSTOS remains household-only. ARGOS remains search/research-only.

## Evidence reviewed
- Existing local web stack examples: HERMES uses Vite, React 19, Playwright and Node's test runner; CRESUS has a lightweight Node test contract. These are local precedent, not proof that either codebase should be copied.
- MDN IndexedDB documentation: IndexedDB supports structured persistent browser data and operation when network access is unavailable.
- MDN Service Worker/PWA documentation: service workers and Cache API can cache the application shell for offline launch; cached content can be stale and writes need explicit application logic.
- Google Drive/Sheets/Docs scope documentation: prefer narrow file-level access such as drive.file where the required workflow supports it; broad Drive scopes have higher verification/security implications.
- RFC 10017 and Google's web authorization guidance: browser public clients should use Authorization Code with PKCE; do not use the legacy implicit flow. Prefer a backend-for-frontend for long-lived provider credentials where architecture and hosting allow it.

## Architecture decisions
1. Keep one provider-neutral inventory domain model across the in-chat assistant and PWA.
2. In-chat assistant first: query only user-supplied or tool-verified inventory records. With no live inventory source, clearly label examples as sample data.
3. Cross-platform PWA next: responsive browser UI for macOS, Windows, Linux, iOS and Android; avoid native wrappers until evidence shows a concrete need.
4. Offline: service worker caches app assets; IndexedDB holds local working copies and explicitly queued drafts/events. UI must show data freshness, offline status, pending actions and conflicts. Browser storage is not a substitute for tested backups.
5. Ledger: immutable movement events with stable IDs, idempotency keys, actor, timestamp, business/location, product, quantity/unit, source and reversal/correction links. Correct mistakes with compensating events, not silent edits.
6. Server/API, when introduced, enforces authentication, business/tenant isolation, role permissions, idempotency and concurrency checks. A client-only prototype must not be represented as secure multi-user inventory.
7. Google services are optional adapters. Drive stores selected documents/exports/backups, Sheets supports import/export/reporting, Docs generates documents, Gmail drafts first, Calendar supports reminders, and Contacts maps provider IDs. None is the authoritative stock ledger.
8. Keep service permissions separate and incremental. Show AVAILABLE, CONNECTED, AUTHORIZED and VERIFIED as distinct states. Never store client secrets in a browser bundle or commit credentials.
9. Existing Capability First: inspect suitable installed libraries and established EDEN patterns before adding dependencies or building provider-specific features.
10. No Google OAuth, GitHub persistence, runtime behavior, build, or release is claimed until each has direct evidence.

## Recommended first vertical slice
- In-chat: product lookup, stock calculation from an explicit fixture/attached CSV, low-stock list, movement explanation, import validation and a proposed receipt/transfer preview.
- Deterministic domain module: product/location types, movement schema, on-hand calculation, duplicate/idempotency detection and compensating entries.
- PWA shell: catalogue, product detail, movement history and import preview; initially no live Google writes.
- Sample dataset clearly marked as fixture, not real business inventory.
- One exportable JSON/CSV backup plus a restore test before treating backup as complete.

## Required tests before claiming functional
- Ledger arithmetic: receipts, issues, returns, transfers between locations, reservations and stocktake variance.
- Reject zero/invalid quantities and incompatible units; define whether negative stock is allowed per business policy.
- Retry same idempotency key: exactly one movement.
- Concurrent version mismatch: conflict surfaced; no silent overwrite.
- Import: duplicate SKU/barcode, missing required fields, malformed quantities, partial-row errors, dry run and explicit commit.
- Offline: cold launch after prior installation, stale-data label, queued draft state, reconnect, retry and conflict handling.
- Restore: exported backup checksum and actual restore into a clean profile.
- Security: tenant isolation, server-side roles, secret scan, token revocation, provider outage and rate-limit behavior.
- Google: consent/scope review, PKCE/state validation, Drive selected-file fixture, Sheets import preview, Docs mapping, Gmail draft/confirmation gate, Calendar duplicate retry, Contacts provider-ID reconciliation.

## Open decisions / gates
- Recover and reconcile any newly found historical source before coding.
- Establish canonical GitHub repository/branch without overwriting unrelated work.
- Choose framework only after checking installed toolchain, existing reusable EDEN modules, offline needs and target deployment.
- Decide the first persistence mode (local-only single operator vs authenticated shared service) before designing sync semantics.
- Obtain user-controlled Google Cloud project, enabled APIs, consent configuration and redirect URIs before live integration.
- Trademark/domain/store clearance remains unchecked.
- No LKG, build, runtime test, or release exists at this stage.

## Sources
- MDN IndexedDB: https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API/Using_IndexedDB
- MDN Service Workers: https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API/Using_Service_Workers
- MDN PWA caching: https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps/Guides/Caching
- Google Drive scopes: https://developers.google.com/workspace/drive/api/guides/api-specific-auth
- Google Sheets scopes: https://developers.google.com/workspace/sheets/api/scopes
- Google web authorization: https://developers.google.com/identity/oauth2/web/guides/overview
- RFC 10017 browser-based OAuth: https://www.rfc-editor.org/rfc/rfc10017.html