# SESHAT — Product Scope
Stable ID: seshat | Updated: 2026-11-21

## Purpose
SESHAT (Stock Entry, Storage, Handling & Tracking) is an independent small-business inventory and stock-operations product for shops, workshops, farms and organizations. It provides traceable stock visibility: what exists, where it is, what moved, what is reserved/incoming, what needs replenishment and which records support each change.

One product, multiple surfaces: in-chat assistant, cloud web app, installable PWA, native macOS first, then additional platforms. SESHAT must work without any AI provider, connector, EDEN orchestrator or external service. Deterministic inventory workflows remain available when all AI providers are disconnected.

SESHAT owns inventory facts. NOSTOS remains household-only; ARGOS remains search/research-only; accounting interpretation belongs to MONETA/LEDGER or the appropriate finance system. Do not recreate full POS, ecommerce, CRM, payroll or accounting suites.

## Full feature scope
1. Catalogue: products, SKU, barcode, name, description, category, brand, variants, units, configurable precision/conversions, optional cost/price, images, status, duplicate detection and preserved provider IDs.
2. Locations: multiple shops, warehouses, rooms, shelves/bins, vehicles, consignment and custom locations; hierarchy and location-specific reorder thresholds.
3. Append-only ledger: receipts, issues/sales, returns, transfers, reservations, releases, commits, stocktakes, adjustments and compensating reversals. Stable IDs, idempotency keys, actor, tenant, product, quantity/unit, timestamp, reason, source/reference, location and reversal links. Posted movements are immutable.
4. Availability: on-hand, reserved, available, incoming, reorder thresholds, low/out-of-stock/overstock indicators and explicit UNKNOWN when evidence is absent.
5. Purchasing: suppliers, draft purchase orders, expected dates, lead-time notes, partial receiving and supplier references. Receiving creates stock events only after confirmation.
6. Sales/issues: stock leaving the business, returns and optional POS/order/ecommerce integrations. Never infer stock movement from an invoice/payment alone.
7. Stocktakes/reservations: count sessions, recounts, variance review, authorized adjustment, reservation lifecycle, expiry/release/commit, stale-session detection and durable concurrency handling.
8. Import/export: CSV/XLSX templates, column mapping, validation, duplicate detection, row errors, dry run, explicit all-or-nothing commit, JSON/CSV/XLSX export and portable backup/restore.
9. Reports/alerts: stock summary, movement history, low stock/reorder, variance, purchasing, ageing where supported, valuation with explicit basis, exports and configurable alerts/reminders.
10. Documents: product photos, invoices, delivery notes, supplier documents, count sheets and purchase orders by authorized file reference.
11. Agentic assistance: natural-language lookup, stock questions, count reconciliation, import validation, purchase-order drafting and reports; typed plans/tools, scoped context, progress, approvals, source attribution and result record IDs.
12. Administration: onboarding, account/profile, business settings, teams, roles, integrations, audit, backups, notifications, privacy/export/deletion, diagnostics and support.

## USER / TEAM / ORG and permissions
These are product usage scopes, not development blockers.
- A user can own a personal workspace and belong to multiple business tenants.
- Organizations contain business units, teams, locations and resources. Each tenant's data is isolated.
- Roles: Owner, Administrator, Manager, Staff/Operator, Accountant/Auditor (read-only by default), Viewer and delegated Integration/Agent capability.
- Permissions are enforced server-side per tenant, resource and action. UI visibility is not authorization.
- Invitations, sharing, role changes and revocation are explicit, scoped and audited. Email equality never silently merges identities.
- High-impact permissions (post adjustments, approve imports, send supplier messages, export all data, manage members) can be separately granted.
- Every write records actor, tenant, capability, action, affected records, time and result.

## UI/UX surfaces
SESHAT is a structured inventory application with agentic assistance—not a generic chatbot or dashboard-of-lists.
- Home/Overview: business/location selector, stock health, low stock, recent movement, approvals and sync state.
- Catalogue: searchable/filterable table, product detail, barcode/SKU, variants, stock by location and timeline.
- Locations: hierarchy and stock by shelf/bin/vehicle/warehouse.
- Stock operations: receive, issue, return, transfer, reserve/release/commit and adjustment with review/confirmation.
- Stocktake: guided counts, barcode capture, recount and variance review.
- Purchasing: suppliers, purchase orders and partial receiving.
- Imports: file selection, mapping, validation, dry-run and explicit commit.
- Reports, contextual Agent Workspace, Team & Access, Connections, Settings & Diagnostics.
- Responsive phone/tablet/desktop layouts; keyboard/touch/VoiceOver/accessibility, light/dark mode, scalable type and reduced motion.
- Clear empty/loading/offline/stale/conflict/denied/partial-failure/recovery states. No inert buttons. Simple/Advanced/Expert modes may change density, never authority.

## AI and external provider integrations
Provider-neutral, optional and interchangeable. Support official APIs or supported login/connector paths for ChatGPT/OpenAI, Codex, Claude/Anthropic, Claude Code, Gemini/Google and future providers. Include AG-UI, MCP, A2A and web2api where supported, ordinary user-controlled account logins and local/on-device models.
- AG-UI is the agent↔UI event boundary where appropriate; MCP is agent-to-tool access; A2A is agent-to-agent exchange. None replaces SESHAT API, authorization, ledger or database.
- Adapter contract: provider identity/capabilities, tool schemas, scopes, streaming, cancellation, timeout, health and usage.
- Credentials stay server-side or in secure native storage, never client bundles, Git or logs.
- Each user separately grants provider and inventory permissions. Provider failure never disables core stock workflows.
- Do not claim API/login parity for a provider unless it actually supports it.
- Optional non-AI adapters: Google Drive/Sheets/Docs/Gmail/Calendar/Contacts, Dropbox, Microsoft 365, POS/orders, accounting, WebDAV, NAS and local files. File stores are not the stock ledger.

## Data integrity and security
Platform-neutral domain core and schemas; append-only ledger as source of truth; balances derived from events. Local IndexedDB is single-device offline/cache/draft storage, not shared SaaS authority. Cloud API validates identity, tenant, role, idempotency, versions and transaction invariants. Atomic transfers, concurrency checks, audit, migration, encryption, revocation, export/deletion and tested restore are required.

## Recovered implementation and evidence
Source-present: domain ledger, queries, workflows, catalogue, CSV import; snapshot and browser IndexedDB persistence; PWA web UI, service worker, manifest, static allowlist build, Node and Playwright tests.
Historical tests: 36/36 domain tests passed in the October baseline. GitHub Actions run 40835282434 checked out commit 158474c76d7d91930454865e9b6f86e9152f125b: 49/49 Node tests and 4/4 Chromium tests passed; static build, syntax and publication allowlist checks also passed. Current branch HEAD is later commit 0c0b89ce6899726c7bd1e567777303ac4e336981, which adds tests-browser/pwa.spec.mjs. No CI receipt for that later HEAD was found. Therefore 49+4 is verified for 158474, not yet for current HEAD. A separate context summary said six Chromium tests; the actual run log confirms four. This is CI evidence, not physical device, hosted SaaS or native acceptance.
Private in-chat seshat-stock skills are workflow/prompt support, not a standalone cloud runtime or native app.

Missing/unverified: authenticated shared backend; tenant/role enforcement; server-authoritative transactions; multi-user concurrency; production login/deployment; actual in-chat host acceptance; durable reservation/stocktake UI; supplier/PO UI; barcode capture; full XLSX mapping; offline write queue/sync/conflict resolution; provider adapters; native macOS; physical-device, accessibility, security and restore acceptance.

## Priority roadmap
1. Preserve and promote the 2026-10-29 PWA candidate; do not recreate it.
2. Prove in-chat workflows and finish PWA functional screens/actions.
3. Build standalone identity, USER/TEAM/ORG tenant model and server authorization.
4. Add transactional cloud ledger, audit, idempotency, concurrency and backup/restore.
5. Connect PWA to cloud API with safe offline cache/queue/conflict UX.
6. Finish purchasing, stocktakes, reservations, barcode, XLSX, reports and documents.
7. Add optional AI and non-AI provider adapters.
8. Security, accessibility, tenant-isolation and SaaS MVP acceptance.
9. Native macOS; then iOS/iPadOS, Android; retain Windows/Linux PWA.

## Deduplication and source lineage
- Legacy source repo: lucasbuzek/Lucas-Private-edenOS-apps; preserved branches seshat/bootstrap-20261011 and newer seshat/pwa-recovery-20261029.
- New portfolio app home: lucasravensnest-star/RAVEN-apps/SESHAT/ on main; folder did not exist when inspected. The legacy repo remains donor/LKG until source migration and parity are verified.
- Dropbox canonical mirror: /lucasSoftware/EDEN app/SESHAT/.
- Duplicate Dropbox copy: /lucasPersonal& Family/family-extended/SlindokuhleCouncil/Slindokuhle/Specialists/SESHAT/; stop updating it; preserve pending explicit non-destructive consolidation.
- Historical local source: /Users/lucas/edenOS/Software Development/SESHAT/; requested consolidated destination: /Users/lucas/SoftwareDev/SESHAT/. Current AppleRAVEN roots exclude both. Only THEMBI_SESHAT_existing_v0.1.1.zip was found in allowed Downloads scope; archive bytes not inspected.
