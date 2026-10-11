# SESHAT

**SESHAT — Stock Entry, Storage, Handling & Tracking — v0.1.0 (design baseline)**

Functional descriptor: small-business stock and inventory management.

Status: inventory-ledger and checksum-protected JSON snapshot prototypes written; 18 automated tests pass on the Mac. UI, durable database persistence, server, OAuth and release remain unimplemented/unverified. SESHAT is the small-business stock/inventory specialist. NOSTOS remains household-only. ARGOS remains the EDEN search/research identity.

Canonical source: ~/edenOS/Software Development/SESHAT/
User-facing index: ~/edenOS/Projects/SESHAT (relative symlink to canonical source).
In-chat assistant: ~/edenOS/AppDev/#app-assistants/SESHAT/SESHAT_IN_CHAT_ASSISTANT.md

Read PROJECT_BIBLE.md, PROJECT_STATE.md, docs/RESEARCH_DECISIONS.md and docs/APP_DEVELOPMENT_RESEARCH.md before implementation. Google service constraints are in docs/GOOGLE_SERVICES_INTEGRATION.md.

The domain-core and snapshot tests run with `npm test` using Node's built-in test runner; no third-party packages are required. Snapshot import/export validates SHA-256 integrity, schema version and replayable non-negative stock history, but is not a durable database or verified backup/restore system. Initial source and project docs are also committed to the private GitHub monorepo branch `seshat/bootstrap-20261011` (not merged to main). No Google OAuth connection, live Google account access, UI build, server runtime, multi-user verification or release is claimed.