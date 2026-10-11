# SESHAT — Project Bible

## Identity
- Display: SESHAT — Stock Entry, Storage, Handling & Tracking — v0.1.0.
- Functional descriptor: small-business stock and inventory management.
- Stable machine identity: seshat.
- Domain: small-business inventory and stock operations.
- External trademark/product clearance remains open.
- NOSTOS = household only. ARGOS = search/research only. SESHAT does not own household management, general research or accounting.
- One product across in-chat, PWA, desktop/mobile representations and provider adapters.

## Goal
Give small businesses dependable stock visibility and traceable operations: what is stocked, where it is, what moved, what needs replenishment, and which records support each change. Start with the in-chat assistant, then prove the same domain capabilities through a cross-platform PWA before considering native shells.

## Authority
Follow ~/edenOS/AppDev/#appDev Bible/namingRules.txt, APPDEV_BIBLE.md, universal integration/storage rules and the ELYSIUM in-chat suite canon. Recover before recreating. Existing capability first. Preserve source/LKG. GENERATED != IMPLEMENTED != BUILT != TESTED != VERIFIED != RELEASED. UNKNOWN != PASS. SESHAT owns inventory facts; finance/accounting interpretation remains with MONETA/LEDGER or the appropriate specialist. Integration is additive; no mandatory CONDUCTOR, BIFROST or Google runtime dependency.

## Core scope
1. Product catalogue: SKU, barcode, name, description, unit, category, variants and optional cost/selling-price fields.
2. Locations: shop, warehouse, shelf/bin, vehicle, consignment and business-defined locations.
3. Stock ledger: receipts, issues/sales, returns, transfers, reservations, stocktakes and adjustments. Append events; corrections use compensating entries.
4. Availability: on-hand, reserved, available, incoming, reorder threshold and explicit UNKNOWN.
5. Purchasing: suppliers, draft purchase orders, partial receiving, supplier references and lead-time notes.
6. Sales/issues: record stock leaving the business; integrate existing POS/order sources where available rather than recreating a commerce platform by default.
7. Stocktake: count sessions, variance review, authorized adjustments and audit history.
8. Reports: low stock, movement history, clearly labelled valuation basis, ageing where supported, CSV/XLSX exports.
9. Import/export: validated templates, duplicate detection, mapping, preview, dry run, explicit commit and recovery path.
10. Documents: delivery notes, invoices, product photos and related files by authorized provider reference.
11. Roles: owner/admin, manager, staff, read-only/accountant; server-enforced least privilege and audit events.
12. Backup/recovery: portable export, tested restore and truthful last-success state.

## In-chat first
First intents: search product/SKU/barcode; check stock; list low-stock items; receive/transfer/issue stock; stocktake; draft purchase order; explain movement history; validate CSV/XLSX; prepare reports.
Return a concise answer with data provenance/freshness and source record. For writes, show affected records, quantity deltas, destination, warnings and reversal semantics. Require explicit confirmation before posting movements, committing imports, sending mail or writing external provider data. Never invent stock quantities, suppliers, live account access or completed actions.
Chat is the front door, not the only UI. Structured views remain necessary for bulk import, barcode capture, stocktake, reconciliation, settings, roles and diagnostics.

## Cross-platform
One responsive installable PWA first: modern browsers on macOS, Windows, Linux, iOS and Android. Keep domain logic/schema and API platform-neutral; isolate platform/provider SDKs behind adapters. Local-first viewing and safe drafts, visible cache/queue/sync status, stable IDs, idempotency and explicit conflict resolution. Never silently overwrite concurrent stock events. Native wrappers are later representations only when evidence justifies them. Do not claim full offline multi-user consistency until tested.

## Data and providers
SESHAT owns product catalogue, locations, stock ledger, stocktakes and purchasing state.
Google Drive: optional file/document/backup/import-export provider, not inventory database.
Google Sheets: import/export/reporting surface, not transactional ledger.
Google Docs: generate purchase orders, stocktake sheets and reports.
Gmail: draft supplier communications; sending requires explicit confirmation.
Google Calendar: optional delivery, reorder and stocktake reminders.
Google Contacts: optional supplier/customer references; preserve provider IDs and do not silently merge people.
Google identity and permission to access each service are separate grants. Use least-privilege scopes, revocable connections, secure token storage, audit events and no secrets in browser bundles or Git. Provider adapters remain optional.

## Security and integrity
Local profile may work without cloud login. Protected remote access requires verified authentication. Never merge identities solely because emails match. Isolate business/tenant data and enforce authorization server-side. Use append-only stock events, idempotency keys, version checks and audit history. Encrypt sensitive data in transit and as appropriate at rest. Confirm destructive imports, stock adjustments, external messages and bulk provider writes. Provide export, disconnect, revocation and deletion/retention controls.

## Delivery sequence
1. Recover and reconcile existing authority; establish baseline and assistant contract.
2. In-chat assistant with grounded query workflows, action previews and CSV/XLSX attachments where no provider is connected.
3. Domain schema/API and deterministic ledger tests.
4. Responsive PWA with explicit local/sync states.
5. Google OAuth and service adapters after consent configuration and credentials are available.
6. Cross-browser/device, offline/conflict, backup/restore and security tests.
7. Package candidate only after repeatable build and acceptance evidence.

## Exclusions for first milestone
Full accounting, payroll, tax filing, full CRM, full POS/storefront, warehouse robotics, smart-home control, mandatory Google dependency, fabricated AI stock facts, and unconfirmed external writes.