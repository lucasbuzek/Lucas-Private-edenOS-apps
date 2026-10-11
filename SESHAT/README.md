# SESHAT

**SESHAT — Stock Entry, Storage, Handling & Tracking — v0.1.0 (design baseline)**

Functional descriptor: small-business stock and inventory management.

Status: design baseline and first inventory-ledger domain prototype written; 13 automated tests pass on the Mac. UI, durable persistence, server, OAuth and release remain unimplemented/unverified. SESHAT is the small-business stock/inventory specialist. NOSTOS remains household-only. ARGOS remains the EDEN search/research identity.

Canonical source: ~/edenOS/Software Development/SESHAT/
User-facing index: ~/edenOS/Projects/SESHAT (relative symlink to canonical source).
In-chat assistant: ~/edenOS/AppDev/#app-assistants/SESHAT/SESHAT_IN_CHAT_ASSISTANT.md

Read PROJECT_BIBLE.md, PROJECT_STATE.md and docs/RESEARCH_DECISIONS.md before implementation. Google service constraints are in docs/GOOGLE_SERVICES_INTEGRATION.md.

The domain-core tests run with `npm test` using Node's built-in test runner; no third-party packages are required. No Google OAuth connection, live Google account access, UI build, server runtime, multi-user verification or release is claimed.