# SESHAT — App Development Research Decisions

Updated: 2026-10-11
Scope: research for a small-business stock/inventory specialist, offline-first, cross-platform, with in-chat assistant first and optional Google integrations.

## Architecture recommendation

### Product surfaces
1. **In-chat assistant first** for guided search, stock questions, low-stock checks, transaction previews, import validation and report generation. Use fixture/demo data until an authorized live data store exists. Mutations require explicit confirmation and a recorded result.
2. **Responsive PWA** as the first persistent cross-platform UI for macOS, Windows, Linux, iOS and Android. Keep the domain core platform-neutral. Do not build separate native apps before the PWA workflow and storage boundaries are proven.
3. **Local data layer first, shared server later.** A single-device/offline mode is valuable for unreliable internet. Shared multi-user inventory requires a server-authoritative transaction boundary and conflict policy; do not pretend browser-local storage alone synchronizes devices.
4. **Optional Google adapters** after core acceptance and user-authorized OAuth. Google Drive is a document/export/backup destination, not the inventory ledger. Sheets is import/export/reporting, not a concurrent transactional database.

## Persistence decision

- Keep append-only stock movements as the source of truth. Derive on-hand balances from validated movements; do not directly overwrite quantity fields as the primary record.
- Current prototype exports a versioned JSON snapshot with SHA-256 integrity checksum and replays events through domain validation on restore.
- Checksum protects against accidental/tampered content mismatch, not malicious forgery if an attacker can recompute the checksum. For authenticity, later add a trusted signature or authenticated backup manifest where the threat model warrants it.
- Snapshot import must reject unsupported schema versions, malformed event history, duplicate location IDs and stock-negative histories. Do not silently "repair" invalid inventory data.
- Next persistence implementation should use IndexedDB behind a small repository interface for the PWA, with explicit transaction completion/error/abort handling and schema migration. Browser persistence can be cleared/evicted and IndexedDB does not itself synchronize with a server, so backups/export and visible storage status remain required.

## Stock and concurrency decisions

- Quantities are currently represented in thousandths (up to three decimal places). This is suitable for many piece/weight/volume units but not universal; configurable unit precision and conversion rules must be decided before production.
- Every committed movement needs a unique ID, idempotency key, actor, timestamp, reason/reference and location. Current core covers event ID, idempotency, type, product, unit, quantity, time, reference and locations; actor/tenant/audit identity is not yet implemented.
- Use compensating movements for corrections/reversals; do not edit/delete posted movements.
- Transfers must be atomic across source and destination. Multi-user server implementation must lock or transactionally validate source availability to prevent simultaneous issues/transfers from overselling.
- Distinguish event append order from occurredAt time. Preserve original event order; flag suspicious future/backdated times rather than silently reordering the ledger.
- Reservations, purchase orders, stocktakes, lots/serial numbers, expiry dates, kits/bundles, multiple currencies and tax/accounting are not in the domain core yet. Discover business requirements before expanding the schema.

## Google integration decisions

- Use the official OAuth flow and least-privilege scopes; ask permission incrementally per connected service. Do not request broad Drive access when file-picker or narrower scopes suffice.
- Keep Google identity/login separate from each service's data permission. Show which account/service is connected and provide disconnect/revoke controls.
- Keep refresh tokens out of source control, client-side bundles, logs and backups that are not encrypted. A server-side OAuth client is preferred if persistent server-side access is required; a pure local PWA requires a carefully designed public-client flow and cannot protect a client secret.
- Drive: optional export/import files, attachments and backup copies.
- Sheets: controlled CSV/XLSX/Sheet import/export and reports, with preview/validation before writing.
- Docs: printable purchase orders and stocktake/report documents.
- Gmail: draft supplier messages; send only after explicit user confirmation.
- Calendar: reminders, deliveries and stocktake schedules.
- Contacts: supplier/customer reference lookup with explicit permission.
- No live Google connection is currently available or configured. Integration remains planned, not implemented.

## Research sources

- MDN, IndexedDB API overview: https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API — transactional client-side structured storage; suitable for offline-capable data but does not provide server synchronization.
- MDN, Using IndexedDB: https://developer.mozilla.org/en-US/docs/Web/API/IndexedDB_API/Using_IndexedDB — transactions and error/abort handling; explains why writes must be atomic and should not depend on page-unload handlers.
- MDN, IDBDatabase.transaction: https://developer.mozilla.org/en-US/docs/Web/API/IDBDatabase/transaction — documents durability options and their trade-offs.
- Google, OAuth 2.0 for Web Server Applications: https://developers.google.com/identity/protocols/oauth2/web-server — authorization-code flow, scopes, refresh tokens, offline access and secure client handling.

## Gates before calling this an app

- [x] Domain ledger prototype and 13 original movement tests.
- [x] Versioned JSON snapshot export/import with checksum.
- [x] Restore replays movements through validation; rejects negative-stock histories.
- [x] Tamper, schema-version, duplicate-location and round-trip tests.
- [ ] IndexedDB repository with atomic transactions and schema migrations.
- [ ] Browser UI/PWA install/offline tests on Mac and iPhone.
- [ ] Import pipeline with dry-run validation and row-level error report.
- [ ] Auth/roles/tenant boundaries and server-side concurrency controls before multi-user mode.
- [ ] Backup/restore drills against independent copies.
- [ ] OAuth configuration and per-service Google integration tests.
- [ ] Accessibility, security, recovery and release acceptance.