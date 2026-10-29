# TENDERS PWA — Reference Implementations and Deployment Contract

Date: 2026-10-14. Sources were inspected from the local Mac filesystem. This is a reference/adaptation record, not a claim that TENDERS has implemented these features.

## Authoritative UI references

### HERMES
Local source: `/Users/lucas/edenOS/Software Development/HERMES/web/src/App.jsx`, `web/src/styles.css`, `web/package.json`, `DEPLOYMENT_GUIDE.txt`.

Observed patterns suitable for adaptation:
- Responsive application shell with desktop side navigation and mobile bottom navigation.
- Compact, collapsible status panel with AUTO/TINY/COMPACT/FULL display modes.
- Home summary, searchable opportunities, workspace, profile, documents, activity and settings.
- Clear local/browser-only vs headless persistence state; visible sync errors and revision-conflict handling.
- Local export/import and backup behaviour.
- Reduced-motion and small-screen CSS treatment.
- Existing build flow using Vite and static deployment output in `web/dist`.

TENDERS adaptation: retain the compact, operational, evidence-aware interface; replace HERMES-specific opportunity/job model with procurement lifecycle records. Do not copy HERMES business logic wholesale or expose HERMES as a runtime dependency.

HERMES deployment guide documents static HTTPS deployment to Cloudflare Pages, Netlify or compatible hosts, and optional self-hosted headless persistence. It explicitly says deployment and physical Safari/iPhone install still need their own evidence. TENDERS must produce its own verified deployment artifact and cannot inherit HERMES's test claims.

### CRESUS
Local source: `/Users/lucas/edenOS/Software Development/CRESUS/platforms/web/public/index.html`, `public/manifest.webmanifest`, `public/sw.js`, `public/styles.css`, `package.json`, `wrangler.toml`.

Observed patterns suitable for adaptation:
- Installable PWA metadata, web manifest, Apple touch icon and safe-area viewport support.
- Chat-first workspace, mobile drawer, previous-work navigation, responsive message/composer surface.
- Explicit offline/network state, export, accessible labels and confirmation dialogs.
- Existing Cloudflare-oriented build/deploy configuration and service-worker implementation.

TENDERS adaptation: use a procurement workspace rather than a financial chat UI. Adopt the compact, mobile-first, installable PWA discipline and clear online/offline feedback. Do not copy CRESUS financial workflows or identity/branding.

CRESUS is not automatically the TENDERS deployment baseline: its own project state identifies incomplete native/product areas, so only directly inspected web UI/PWA implementation patterns are referenced here.

## In-chat assistant workspace requirements

The in-chat TENDERS experience must help the user discover and use available capabilities rather than pretending all tools are native. Offer relevant options at the point of need:
- Installed plugins/connectors and their actual supported actions.
- MCP servers/tools and available Remote Desktop Commander (RDC) devices/actions.
- WORKinCODEX and equivalent authorised cloud/local coding handoff workflows.
- GitHub/repository operations, local laptop execution, file/document workflows, Google services, research and other tools when available.

Rules:
- Discover current capabilities before offering a connector as available; distinguish installed, connected, authorised, supported and verified.
- Do not fabricate tool names, account access, credentials, cloud environment IDs, jobs, or successful operations.
- If a connector is unavailable, offer a real available alternative or record the dependency as unavailable.
- Before external side effects, show what will be changed and require the appropriate user approval.
- Keep user-facing capability discovery compact, with Simple/Advanced/Expert disclosure.

## Conversation-capacity handoff at approximately 98%

When the active conversation approaches the platform's context/length limit (target trigger: approximately 98% when that measurement is available), TENDERS must prepare a continuation package before context is lost. The package should include:
1. Current authority/canon and any changed decisions.
2. Current milestone, verified evidence, FAIL/UNKNOWN gates and blockers.
3. Exact project paths, repositories, branches, commits and LKG identifiers where verified.
4. Active tasks, completed tasks, pending tasks, next commands/actions and relevant outputs.
5. Required tool/connector permissions and unavailable dependencies.
6. Checksums/manifests for important deliverables where applicable.
7. A short continuation prompt suitable for the next TENDERS chat/workspace.

Save the handoff in the TENDERS project, and provide an explicit continuation option such as a new chat, a numbered MCP/RDC workspace (2, 3, 4, …) or WORKinCODEX where the destination exists and the user has authorised it. Do not automatically create remote chats, MCP servers, RDC devices or cloud workspaces unless the relevant tool supports creation and the user has authorised the side effect. If the platform does not expose a reliable context-percentage signal, use observed length/compaction warnings as a best-effort trigger and never claim an exact 98% reading without evidence.

## Deployable PWA contract

TENDERS must be a deployable, installable PWA—not merely a mockup, design specification, or development-only localhost page.

Minimum deliverables:
- Complete source tree and reproducible lockfile-backed build.
- Production build output and an explicit static-host deployment target, preferably provider-neutral static HTTPS plus an optional supported backend deployment.
- Valid web manifest, app icons, service worker, offline/fallback behaviour and safe update strategy.
- Correct relative/base paths for the selected host, HTTPS requirements documented, SPA routing fallback where needed, and no secrets in the client bundle.
- Clear configuration example for optional backend and Google OAuth/API services.
- Install/test instructions for desktop and mobile, including iOS Safari Add to Home Screen limitations.
- Smoke tests against the production build, manifest/icon/service-worker checks, route checks, offline/reconnect tests and package checksum/manifest.
- A deployable ZIP or equivalent package verified after clean extraction.
- Hosting deployment status reported separately from package readiness; never claim public deployment without a confirmed provider result and live URL test.

A static PWA can be deployed independently, but multi-device sync, authenticated accounts, Google integrations, server-side discovery and durable shared data require a real configured backend/provider. Local-only mode must say that records are local to that browser/device. PWA installation is not proof of secure cloud sync.

