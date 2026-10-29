# TENDERS PWA — Product Description

TENDERS is a local-first, installable procurement workspace governed by its own workflow rules. It is designed to grow from opportunity discovery into qualification, bid preparation, approvals, submission evidence, award, contract delivery, invoicing and closeout.

## Current verified starter capabilities
- Responsive PWA shell with desktop/mobile navigation and persistent in-app status panel.
- Local opportunity records, search, organisation profile, workflow history and JSON backup/restore.
- Evidence records with source URL/reference, verifier attestation, timestamps and audit events.
- Named qualification/submission approvals and evidence-gated workflow transitions.
- Recovery rules that prevent BLOCKED/ON_HOLD from bypassing required workflow stages.
- User-supplied RSS, Atom, JSON and representative OCDS JSON source parsing; deduplication and feed provenance.
- Feed fetch metadata and SHA-256 of the feed body where browser Web Crypto is available.
- PWA manifest, icons, service worker, static deployment configuration and reproducible production build.
- Google API wrappers for Gmail read-only search, Drive file metadata, Calendar event reads and event creation; actual account connection is not yet configured or verified.

## Important limitations
The current data store is browser-local, not a shared backend or tamper-proof audit ledger. Official live-source adapters have not yet been validated against real provider responses. Google OAuth client ID is not configured and real Gmail/Drive/Calendar API calls have not been tested. Multi-user identity, server-side audit integrity, bid-document assembly, external submission, award and contract lifecycle remain incomplete.

## UI and deployment
The PWA uses selected interaction patterns from the existing HERMES and CRESUS implementations as references, not runtime dependencies. Static candidate packages can be uploaded to a compatible HTTPS host; public deployment and physical device installation remain separate verification gates.

