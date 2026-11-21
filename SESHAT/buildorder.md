# SESHAT — Build Order
Stable ID: seshat | Execute against SCOPE.md.

## Execution rules
Reuse current source/LKG; build only unmet acceptance criteria. Do not restart recovery, repeat unchanged tests, create duplicate apps or ship placeholders. Preserve deterministic non-AI workflows. Each component is a bounded future conversation; continue sequentially without unnecessary gates.

### 01 — Source promotion and LKG
Acceptance: reconcile 2026-10-29 PWA branch with 2026-10-11 baseline; establish one approved working copy and preserve provenance.
Handoff: “ForgeMASTER: continue SESHAT using SCOPE.md. Inspect lucasbuzek/Lucas-Private-edenOS-apps branches seshat/pwa-recovery-20261029 and seshat/bootstrap-20261011. Reconcile actual source/tests and establish verified LKG. Do not recreate or overwrite either branch. Prepare migration into lucasravensnest-star/RAVEN-apps/SESHAT/ with file-level provenance and test parity.”

### 02 — Domain core and invariants
Acceptance: safe product IDs, quantity precision, append-only ledger, idempotency, reversals, atomic transfer, concurrency, tenant/actor metadata and durable reservation/stocktake semantics.
Handoff: “ForgeMASTER: close SESHAT domain-core gaps in SCOPE.md. Reuse existing ledger, queries, catalogue and workflow modules. Add only missing implementation/tests for unsafe IDs, unit precision, atomic transfers, stale versions, tenant/actor/audit metadata and durable workflows. Preserve event history and fixture provenance.”

### 03 — In-chat assistant
Acceptance: actual host workflows for catalogue, stock, low-stock, movements, count reconciliation, import validation and action previews; no fabricated data/actions.
Handoff: “ForgeMASTER: finish SESHAT in-chat from SCOPE.md. Reuse in-chat/SESHAT_IN_CHAT_ASSISTANT.md and installed seshat-stock skills. Prove real invocation, fixture/source provenance, confirmation gates and no-data/no-connector failure. A prompt or skill registration alone is not acceptance.”

### 04 — Existing PWA UI
Acceptance: preserve responsive PWA and complete functional product screens/actions for locations, stocktakes, reservations, purchasing, reports, agent workspace, teams, connections and settings.
Handoff: “ForgeMASTER: continue existing SESHAT PWA using SCOPE.md. Preserve IndexedDB, service worker, movement preview/post, catalogue, CSV dry-run and backup flows. Complete missing product views and real controls; unsupported cloud features must be unavailable, never faked. Verify responsive UI and relevant Playwright flows.”

### 05 — Standalone identity and tenancy
Acceptance: user accounts, personal workspaces, business tenants, teams/orgs, memberships, invitations, roles, revocation and audit; positive and denied cross-tenant tests.
Handoff: “ForgeMASTER: implement SESHAT independent USER/TEAM/ORG identity and authorization from SCOPE.md. Enforce tenant/resource/action permissions server-side. Support multiple business memberships and invitations. Do not require EDEN or AI connectors. Add positive and permission-negative tests.”

### 06 — Transactional cloud inventory backend
Acceptance: durable append-only shared ledger, atomic transfer, idempotency, version locks, audit and tested backup/restore.
Handoff: “ForgeMASTER: build SESHAT cloud inventory API/repository from SCOPE.md and DELIVERY.md. Keep storage behind an adapter. Use approved Cloudflare Workers baseline and tenant-aware transactional database. Prove concurrent issue/transfer rejection, restart durability, audit and clean restore. IndexedDB remains local-only.”

### 07 — PWA cloud sync
Acceptance: authenticated client, tenant switching, safe offline drafts, visible queue, idempotent retry and conflict resolution.
Handoff: “ForgeMASTER: connect SESHAT PWA to cloud API in SCOPE.md. Implement sessions, tenant/role UI, local drafts, sync queue, stale labels, retries and conflict UX. Test two users, separate tenants, denied access, offline/reconnect and partial failures. No silent overwrite.”

### 08 — Inventory operations completion
Acceptance: supplier/PO/partial receiving, durable stocktakes/reservations, barcode capture and CSV/XLSX mapping.
Handoff: “ForgeMASTER: complete SESHAT inventory verticals in SCOPE.md using existing ledger/API. Every write creates idempotent ledger/audit records and follows approval policy. Keep accounting/POS ownership external.”

### 09 — Agentic provider framework
Acceptance: optional provider adapters, typed tool capabilities, AG-UI events, supported MCP/A2A/web2api paths, credential safety and deterministic fallback.
Handoff: “ForgeMASTER: implement SESHAT provider-neutral agent integration in SCOPE.md. Support verified official APIs/login mechanisms for ChatGPT/OpenAI, Claude, Gemini, Codex, Claude Code and future providers. Use AG-UI where appropriate, MCP for tools, A2A only where supported. Enforce tenant/resource scopes server-side; preserve non-AI workflows and honest unsupported-provider states.”

### 10 — Business/service adapters
Acceptance: optional Google, Microsoft, Dropbox, POS, accounting, WebDAV/NAS and local-file connections with independent consent/revocation.
Handoff: “ForgeMASTER: implement optional SESHAT service adapters from SCOPE.md. Keep stock ledger authoritative. Show AVAILABLE/CONNECTED/AUTHORIZED/VERIFIED separately, require consent and confirmation for external writes, and test disconnect, expiry, rate limits and partial failures.”

### 11 — Reports, security and recovery
Acceptance: reporting, alerts, audit, diagnostics, export/deletion, tenant isolation, accessibility, backup/restore and failure recovery.
Handoff: “ForgeMASTER: harden SESHAT to SCOPE.md. Complete reports/alerts, audit, privacy controls, monitoring and restore drills. Run tenant isolation, permission-negative, secret, accessibility and retry/restart tests. Fix defects rather than returning another audit-only report.”

### 12 — SaaS MVP deployment
Acceptance: private Cloudflare-first web/PWA deployment, verified login/logout, tenant/role isolation and representative customer workflow.
Handoff: “ForgeMASTER: deliver SESHAT SaaS MVP using SCOPE.md and DELIVERY.md. Deploy to owner-controlled always-free/no-card test envelope. Verify auth, tenant isolation, inventory transactions, restore, provider disconnection, responsive UI and customer workflow. Record immutable revision and live URL. No public launch/invites without approval.”

### 13 — Native macOS
Acceptance: real SwiftUI/AppKit app, shared API/domain, Keychain, native UX, build/launch/persistence/offline/accessibility/update/rollback tests.
Handoff: “ForgeMASTER: build native macOS SESHAT after PWA/SaaS contracts pass, following SCOPE.md and DELIVERY.md. Use SwiftUI/AppKit and native controls; do not wrap the web page and call it native. Reuse API/domain contracts and verify on actual Mac.”

### 14 — iOS/iPadOS
Acceptance: native mobile/tablet client, barcode capture, field stocktake and safe offline sync.
Handoff: “ForgeMASTER: extend accepted SESHAT contracts to iOS/iPadOS using SCOPE.md and DELIVERY.md. Reuse compatible SwiftUI; implement camera/barcode, field counts and sync conflict UX. Verify physical devices, permissions and tenant isolation.”

### 15 — Android
Acceptance: native Android client on same API/schema, secure storage, camera/barcode, offline and conflict handling.
Handoff: “ForgeMASTER: implement Android SESHAT from SCOPE.md and DELIVERY.md using Kotlin/Jetpack Compose and stable API. Verify physical devices, permission denial, restart/recovery and tenant isolation.”

### 16 — Windows/Linux
Acceptance: installable PWA on supported browsers; native shell only if a concrete capability gap is proven.
Handoff: “ForgeMASTER: complete Windows/Linux SESHAT using SCOPE.md and DELIVERY.md. Verify PWA installation first. Add desktop packaging only for demonstrated need; preserve shared backend/security contracts.”

### 17 — Release and lifecycle
Acceptance: schema migration, signing, install/update/uninstall, backup/restore, rollback and release record across platforms.
Handoff: “ForgeMASTER: complete SESHAT release acceptance from SCOPE.md and DELIVERY.md. Reconcile platform artifacts to one source revision/schema; verify migrations, restore, signing, updates, rollback and privacy. Preserve LKG and customer data. Distinguish deployed, installed, accepted and released.”

## Next executable component
01 — Source promotion and LKG reconciliation. Candidate branch and HEAD are already known; continue from that source, not general rediscovery.
