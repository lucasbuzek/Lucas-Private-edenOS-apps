# SESHAT — Delivery Specification
Stable ID: seshat | Updated: 2026-11-21

## Repositories and paths
**New portfolio app home:** GitHub lucasravensnest-star/RAVEN-apps, folder SESHAT/ on main (one app per folder; no app files at repository root). Required files: SESHAT/SCOPE.md, SESHAT/buildorder.md, SESHAT/DELIVERY.md.

**Existing donor/LKG:** lucasbuzek/Lucas-Private-edenOS-apps; newer candidate branch seshat/pwa-recovery-20261029, HEAD 0c0b89ce6899726c7bd1e567777303ac4e336981; preserved original branch seshat/bootstrap-20261011. Do not rewrite/merge during docs migration. Migrate source only after file-level reconciliation and test parity.

**Dropbox canonical:** /lucasSoftware/EDEN app/SESHAT/. Duplicate family-tree copy: /lucasPersonal& Family/family-extended/SlindokuhleCouncil/Slindokuhle/Specialists/SESHAT/; stop updating, preserve pending authorized non-destructive consolidation.

**Local requested path:** /Users/lucas/SoftwareDev/SESHAT/. Historical path: /Users/lucas/edenOS/Software Development/SESHAT/. Historical index: /Users/lucas/edenOS/Projects/SESHAT. AppleRAVEN currently permits Desktop, Documents, Downloads and iCloud Drive only; neither source path is authorized. No terminal tool was registered. Do not claim local writes/tests. Found Downloads archive THEMBI_SESHAT_existing_v0.1.1.zip (2026-11-09); bytes not inspected.

## Platform order
1. Cloud web app + installable PWA.
2. Native macOS.
3. Native iOS/iPadOS.
4. Native Android.
5. Windows/Linux installable PWA; native shell only if justified.
All clients share one platform-neutral domain/API/schema and tenant authorization model.

## Web/PWA toolchain — preserve candidate
Existing browser-native ES modules, HTML/CSS, service worker, Web App Manifest and IndexedDB. Node built-in test runner; npm test; npm run check:web; npm run build:web; Playwright browser tests; Node static server. Publish only allowlisted dist/ output, never repository root, private docs, tests, fixtures or secrets. Keep zero-runtime-dependency domain core unless measured need requires a change. IndexedDB is single-device local cache/draft/offline storage, not shared SaaS authority.

## Cloud architecture
- Cloudflare Pages/Workers is primary frontend/API; Workers validate sessions, tenant, role, scopes, request schemas, idempotency, versions and provider calls.
- Netlify and Vercel remain interchangeable preview/deployment alternatives, not separate product sources of truth.
- Required targets: https://lucasbuzek.pages.dev/app/seshat and https://RAVENaIntelligence.pages.dev/ravenapp/seshat. Targets only; no deployment claimed without receipt/live acceptance.
- Recommended MVP persistence: Cloudflare D1 behind a Workers repository adapter for tenant-aware relational data and transactional events; enforce unique idempotency constraints and optimistic version checks.
- Alternative: managed PostgreSQL adapter (e.g. Neon/compatible service) for portability, but recheck current free/no-card eligibility. D1 is RECOMMENDED to minimize providers and keep the first proof Cloudflare-native.
- R2 for backups/documents only if free quota/account eligibility is verified. Durable Objects/Queues only for demonstrated coordination/async needs.
- No AWS paid risk, Oracle dependency, card-required service or silent spend.

## Identity and authorization
Standalone account/session service; optional email/passkey and configured Google/Apple login. Model user → memberships → business tenants → teams/locations/resources. Owner, Administrator, Manager, Staff, Accountant/Auditor and Viewer roles; backend enforces each resource/action. Agent credentials are delegated capabilities, not user identity. Audit, revocation, export and deletion required.

## Agentic providers
Provider-neutral adapters for supported ChatGPT/OpenAI, Claude/Anthropic, Gemini/Google, Codex, Claude Code and future providers. Official APIs or supported user login/connector mechanisms only. AG-UI for agent↔UI events where appropriate; MCP for agent-to-tool; A2A for supported agent-to-agent; web2api only via documented permission-scoped adapters. Credentials server-side or secure native storage, never browser bundle/Git/logs. Independent connect/disconnect, scoped permissions, visible status and deterministic fallback. Unsupported API/login parity must be marked unsupported, not fabricated.

## Non-AI service adapters
Google Drive/Sheets/Docs/Gmail/Calendar/Contacts, Dropbox, Microsoft 365, POS/orders, accounting, WebDAV, NAS and local files. Drive/Dropbox/Sheets are not the transactional ledger. Recovered SESHAT docs record Google connectors unavailable; no Google OAuth credentials were verified.

## Native toolchains
- macOS: Swift + SwiftUI, AppKit where needed, Xcode/SwiftPM, Keychain, native menus/settings/notifications/accessibility. Same API/domain; no thin web wrapper.
- iOS/iPadOS: Swift + SwiftUI, Xcode, Keychain, camera/barcode and safe sync.
- Android: Kotlin + Jetpack Compose, Android Studio/Gradle, Android Keystore, camera/barcode.
- Windows/Linux: installable PWA first.

## Release acceptance
Private preview; real login/logout; tenant and role denial; atomic/idempotent stock operations; concurrency; backup/restore; offline/reconnect/conflict; provider disconnect; accessibility; representative customer workflow; immutable commit/build/deployment receipt. Customer invitations, billing and public launch require owner authorization. Test envelope remains always-free/no-card and limited-user; recheck quotas before provisioning. Paid transition is opt-in and visible.

## Source donors
1. 2026-10-29 SESHAT PWA branch — primary implementation donor.
2. 2026-10-11 bootstrap branch — preserved baseline.
3. Dropbox LucasSoftware/EDEN app/SESHAT — project docs and source mirror.
4. Private seshat-stock skill package — in-chat workflow support only.
5. SESHAT Project Bible, state and acceptance matrix — domain/release authority.
6. RAVEN-apps root AGENTS.md — one-app-per-folder and AG-UI interaction standard.
No NOSTOS or unrelated inventory product is a donor.

## Current state / blockers
Recovered: Project Bible, product docs, acceptance matrix, in-chat contract, GitHub branches, Dropbox copies, skills and PWA candidate tree.
Historical CI: 49 Node + 4 Chromium tests and static PWA build on run 40835282434; not rerun in this task.
Not verified: live deployment, SaaS login, shared transactional backend, provider connections, native app, physical-device acceptance.
Local write blocked by AppleRAVEN allowed roots; /Users/lucas/SoftwareDev is not exposed. Dropbox direct .md upload is not exposed through the current text-file API; Dropbox Paper can hold a native mirror but is not a literal .md file.
Chromium count discrepancy: candidate source says four; one memory summary said six. Verify from CI before changing the record.
