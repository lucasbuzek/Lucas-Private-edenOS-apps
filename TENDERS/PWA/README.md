# TENDERS PWA

A responsive, installable, local-first procurement workspace. UI patterns are informed by the existing HERMES web PWA and CRESUS web PWA source code; TENDERS uses its own data model, identity and implementation.

## Current functional starter
- Responsive navigation and compact status panel with AUTO/TINY/COMPACT/FULL modes.
- Local opportunity record creation, search, workflow status history and organisation profile.
- JSON export/import for recovery.
- Online/offline indicator and service-worker app-shell caching.
- Integration overview for Gmail, Google Drive, Google Calendar, tender portals and MCP/connectors, clearly marked as not connected.
- Reproducible Vite production build, manifest, app icon, static-host redirects/headers and smoke tests.

## Not implemented yet
Official provider-specific source adapters and live requests against those providers, independent verification, requirement extraction, compliance matrices, bid/document assembly, server-side persistence/multi-device sync, authentication, verified Google OAuth/API calls, external submissions and post-award contract operations. The generic live-feed adapter is implemented, but provider-specific access remains unverified.

See [DEPLOYMENT.md](DEPLOYMENT.md), [../PWA/UX/REFERENCE_IMPLEMENTATIONS_AND_DEPLOYMENT.md](../PWA/UX/REFERENCE_IMPLEMENTATIONS_AND_DEPLOYMENT.md), and [../PWA/Verification/DEPLOYMENT_READINESS_CHECKLIST.md](../PWA/Verification/DEPLOYMENT_READINESS_CHECKLIST.md).

## Evidence, workflow and live-source status (2026-10-15)
- Schema v2 migration preserves legacy records, evidence and history while keeping rollback-compatible storage keys.
- Named qualification/submission approval ledger, explicit transition rules, required evidence types, blocked/hold recovery limits and submission-approval revocation on return to preparation are implemented and tested.
- Evidence records preserve source URL/reference, verifier attestation, recording time and source provenance. Public-feed imports also store source feed/item identity, publication timestamp, fetch timestamp and feed-body SHA-256 when Web Crypto is available.
- Discovery parses RSS, Atom, generic JSON and representative OCDS JSON releases/records. Official source candidates and their verification status are documented in Integrations/TENDER_DISCOVERY_SOURCES.md.
- Google client-side OAuth/API wrappers are implemented but not connected: no OAuth client ID is configured and no real-account test has passed.
- Audit events are append-only through the application API, but browser-local storage is user-editable and is not a tamper-proof audit ledger. A trusted multi-user audit service requires backend persistence and access control.

## 0.1.3 — Work-mode/local-context development candidate (2026-10-24)
Seven work modes and local preparatory checklists are implemented with schema v3, selected-context views/import/export and private-only rollback keys. Legacy ON_HOLD states are retained. Separate browser profiles are local and NOT secure multi-tenant authorization. No client-sharing, independent audit, actual procurement award/submission, authenticated Google tenant integration or public deployment is implied. Detailed scope: ../Shared/Product/TENDERS_WORK_MODES_EXTENSION_2026-10-23.md.

