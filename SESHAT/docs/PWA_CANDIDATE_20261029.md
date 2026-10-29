# SESHAT — local-first browser candidate (2026-10-29)

## Provenance and preservation

- Product: SESHAT — Stock Entry, Storage, Handling & Tracking, stable ID `seshat`; independently useful small-business inventory management.
- Source recovery: the 2026-10-11 GitHub branch `seshat/bootstrap-20261011` is preserved. Seven later source, fixture and test files were reconciled byte-for-byte between the two Dropbox SESHAT copies and committed on the **separate** `seshat/pwa-recovery-20261029` branch.
- Current local source authority was not silently overwritten. The original Mac worktree and both Dropbox copies were NOT modified.
- EDEN integrations remain optional; SESHAT does not become AGORA, NOSTOS, BIFROST or a new project.
- Public AI MCP reference archive is treated as untrusted; the shared Dropbox AI MCP tool link was observed public/edit and needs an owner-controlled permission review.

## Implemented in this continuation branch

- Existing append-only movement engine, source-backed query module, reservations and stocktake in-memory prototypes, SHA-256 checksum snapshots and fixture-provenance controls.
- Product/location creation and validation, SKU/barcode uniqueness, reorder thresholds.
- Responsive installable static PWA: overview, search, low-stock indicators, movement history, explicit local receipt/issue/return/transfer/adjustment previews and confirmation.
- One-device IndexedDB storage with atomic revision comparison on each save. Stale-tab writes are rejected with a visible conflict instead of overwriting new stock events.
- CSV catalogue import (1 MB/1,000-row bound), headers, row errors, dry run and explicit confirmed all-or-nothing catalogue addition. This does NOT silently insert stock quantities or overwrite existing records.
- Portable JSON catalogue+ledger export, SHA-256 validated ledger restore and destructive replacement confirmation; offline app shell after successful service worker installation.
- A scoped static build allowlist to exclude private project docs, tests and credentials from publication.

## Verified evidence

- Commit source is visible on GitHub branch `seshat/pwa-recovery-20261029`.
- GitHub Actions run 40835282434: https://github.com/lucasbuzek/Lucas-Private-edenOS-apps/actions/runs/40835282434
- On that exact run, **49/49 Node tests pass**, **4/4 Chromium Playwright browser tests pass**, JavaScript syntax checks pass, static PWA build passes, publication allowlist safety checks pass.
- Browser checks cover local product creation, receipt preview/post, page reload persistence, stale-tab write conflict, offline reload and CSV preview/confirmed import.
- This is **CI on an Ubuntu GitHub Actions runner, not real iPhone/macOS/Android acceptance**.

## Run / inspect (from SESHAT/)

```sh
npm test
npm run check:web
# Serve dist/ over HTTPS or localhost; the CI browser harness uses node scripts/serve-web.mjs
```

No hosted URL or production authentication is claimed. Never host `SESHAT/` itself as a public directory; publish **only** allowlisted `dist/` contents.

## Release blockers / remaining work

1. Dedicated business identity and per-tenant server-side authentication/authorization, audit, append-only event persistence, server-side idempotency, version/transaction locks and backup/restore drills for genuinely shared inventory.
2. Secure hosting on the correct user-authorized Cloudflare account, with per-product access policies and verified login/logout/role denial. SlindokuhleCouncil Cloudflare Access returned `access.api.error.not_enabled` on 2026-10-29; the account currently had no Pages project or D1 database in the inspected scope. RAVENnest resources must not be conflated with Slindokuhle resources.
3. Suppliers, purchase orders/partial receipts, barcode camera capture, stocktake/reservation UI and durable workflows, document references, full CSV/XLSX mapping/import, offline action sync/conflict queue, provider consent and per-service Google integrations.
4. Physical/device tests, additional backup restore verification (including catalogue metadata tampering: the ledger checksum does not authenticate a complete portable archive), accessibility, operational security and acceptance before release.

Current stage: **SOURCE_COMMITTED + TESTED_CI_NODE + TESTED_CI_CHROMIUM**. The product is NOT DEPLOYED, PAIRED, ACCEPTED or RELEASED. No sample fixture is a real business stock record.
