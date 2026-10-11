# SESHAT — Google Services Integration Plan

## Availability boundary
ChatGPT's Google Drive, Gmail, Calendar and Contacts connectors currently report DISABLED_BY_ADMIN / NOT_AVAILABLE. This prevents direct account operations through those connectors here. No account is connected and no credentials are present. Direct API adapters may be implemented in SESHAT after authorized configuration.

## Capability mapping
- Drive API: select business-approved files, link delivery notes/invoices/product documents, import/export and optional encrypted backup artifacts.
- Sheets API: validated product/stocktake imports and report exports; never the authoritative concurrent stock ledger.
- Docs API: generate purchase orders, stocktake sheets and reports.
- Gmail API: draft supplier email; send only after explicit confirmation and with a narrow mail scope.
- Calendar API: optional delivery, reorder and stocktake reminders.
- Google Contacts/People API: optional supplier/customer lookup; preserve provider IDs and do not silently merge contacts.
- Google identity: sign-in does not automatically grant Drive/Gmail/Calendar data access; request each permission separately.

## Architecture and security
1. Define provider-neutral capabilities such as files.read/write, sheets.import/export, docs.generate, mail.draft/send, calendar.read/write and contacts.read.
2. Implement each Google service behind an optional adapter. Show AVAILABLE, CONNECTED, AUTHORIZED and VERIFIED as distinct states.
3. Use authorization-code flow with PKCE for public clients where appropriate; server-side token exchange/storage for confidential services. Validate state, issuer/audience and redirect URI.
4. Use incremental scopes, explicit consent, revocation/disconnect, secure token storage, server-side authorization and an audit trail.
5. Keep file references where sufficient; encrypt sensitive backup contents before upload and verify hashes plus an actual restore.
6. Make retries idempotent; reconcile file revision/etag and SESHAT version before writes. Queue only safe work while offline.
7. Keep the core provider-neutral for later Microsoft 365, Dropbox, WebDAV, NAS and local-file adapters.

## Chat-first fallback
Until live OAuth is verified, the in-chat assistant may work on user-provided attachments, validate CSV/XLSX, draft reports and create exportable outputs. It must not claim to inspect live Google accounts. External writes stay disabled until a verified provider connection and per-action confirmation exist.

## Verification gates
OAuth state/PKCE and token storage; least-privilege scopes; disconnect/revocation; tenant isolation; Drive fixture read/write; Sheets preview/error report/dry-run/idempotent commit; Docs field mapping; Gmail draft and confirmation-gated send; Calendar duplicate retry; Contacts ID reconciliation; expired/revoked token, outage, rate-limit and partial-failure handling; no secrets in bundles/logs/Git; backup hash and actual restore.