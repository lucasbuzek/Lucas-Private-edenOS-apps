# EDEN / edenOS — Federated Files WebMCP Source Audit
**Date:** 2026-10-28 · **Status:** RESEARCH VERIFIED (bounded); IMPLEMENTATION / DEPLOYMENT / ACCEPTANCE OPEN  
**Owner mission:** Reuse the existing EDEN Universal Filesystem architecture and the original 12 separately governed portals. Add human-readable, permissioned browser file access and remote MCP functionality without duplicate source masters or a 13th portal.

## Authority and boundaries

Original existing mission: [Asana EDEN Universal Filesystem](https://app.asana.com/1/1219873107425826/project/1219864291600755/task/1219900290377206). Research source: [R3 Universal Storage Masterplan](https://chatgpt.com/library?file_id=libfile_bdce278f21dc8191a0ad6c22c741ac6b&account_id=personal), explicitly **research/candidate**, not an implemented replacement.

- edenOS **Online Storage Manager** owns the storage management user workflow.
- BIFROST owns approved provider identities, routing and capability/reference registry when authorized; HEIMDALL presents files/workspaces. ELYSIUM Personal exposes HOMEBASE/NOSTOS files only for explicitly granted personal sites/households.
- RAVENnest knowledge is a separate previously deployed *archive*, not a federated private file manager.
- Never merge private councils, spouse, family, businesses, sites, ELYSIUM Business, or Lucas's VAULT; no broad inherited admin access.
- Authoritative app/source files remain at established local/Git paths. A provider mount is a view/reference, not authority to bulk copy, overwrite, clean, rename or synchronize.

## Recovered live evidence

### Dropbox source and screenshots (read-only)

Root: `/EDEN-lucas-family/AI MCP tool`, root folder metadata size approximately 2.14 GB. On October 28, 2026, `list_folder(recursive=false)` returned **406 immediate entries / has_more=false**. These are not exhaustive recursive counts. `#webMCP` returned **41** immediate entries; `#screenshots` returned **27**; `#appleOS` **104**. Files include Chrome WebMCP specifications, GoogleChromeLabs source-page archives, bridges, demos, tests, 3 webMCP screenshots, BIFROST screenshots, Dropbox Lite screenshot, and an EDEN/RAVEN portal visual reference.

Accessible source folders: [AI MCP tool](https://www.dropbox.com/home/EDEN-lucas-family/AI%20MCP%20tool), [#webMCP](https://www.dropbox.com/home/EDEN-lucas-family/AI%20MCP%20tool/%23webMCP), [#screenshots](https://www.dropbox.com/home/EDEN-lucas-family/AI%20MCP%20tool/%23screenshots). Important screenshot files:
- [EDEN/RAVEN private portal reference](https://www.dropbox.com/preview/EDEN-lucas-family/AI%20MCP%20tool/%23webMCP/lucas%20EDEN%20EDEN%20Initiative%20RAVEN%20Private%20portal.jpg)
- [Dropbox Lite screen](https://www.dropbox.com/preview/EDEN-lucas-family/AI%20MCP%20tool/%23screenshots/dropbox%20lite.jpg)
- [BIFROST UI](https://www.dropbox.com/preview/EDEN-lucas-family/AI%20MCP%20tool/%23screenshots/bifrost%20ui.PNG)

The Dropbox connector resolved screenshot previews and original paths, but did NOT return the image pixels for rigorous visual interpretation. Test extraction of 3 binary `.webarchive` files failed. **Do not claim a complete per-snapshot visual/archive audit**. Previous Asana research recorded 497 webarchive entries and 495 HTML conversions in a separate RAVENnest knowledge archive; those results are historical production receipts, not an individual code/license review of every upstream project.

### Critical existing sharing exposure

`Dropbox.list_shared_links` on the original AI MCP tool root returned two public links: (1) **public view/download**; (2) **public edit**. Subfolder `#AI toolkit/websupport-chromium-private.H8C5I9` exists (approximately 13.9 MB metadata), suggestive of browser-profile data; contents were NOT inspected and no credential exposure is proven. **P0: restrict/revoke both public links and review descendants/private browser assets through Dropbox's sharing controls** before ingestion into a private portal. Do not copy browser session/token material, expose signed URLs or auto-revoke accounts without assessed evidence. Existing [security task](https://app.asana.com/1/1219873107425826/task/1219955747892305).

### Existing local and cloud implementations

- Dropbox Lite original native SwiftUI + rclone sources and tests exist at `#AI toolkit/Dropbox Lite`. README confirms explicit-folder manual OAuth, conservative additive sync, default OFF, candidate acceptance, **not browser server or public file access**.
- RavenNest canonical source: `RavenNest/` on [private repo branch ravennest/consolidated-20261010](https://github.com/lucasbuzek/Lucas-Private-edenOS-apps/tree/ravennest/consolidated-20261010/RavenNest). Optional Mac adapter manual/disabled; independent Cloudflare Worker deployed, newer Pages/mobile client not previously verified.
- EDENOS-PWA-Deployment reusable source under `#AI toolkit/Online Plugins & Connectors`: manifests, read-only host validation, isolated staging, Access JWT, per-app closed testing. Source is candidate not release LKG.
- Cloudflare RAVENsNEST account: **10 Workers, 1 Pages, 3 Access applications**, and **0 MCP portals / 0 registered MCP servers** at query time; `workaicloud-preview` Worker has AI + D1 bindings and a 2026-10-28 live deployment receipt, but is **not demonstrated as the universal file portal**. Account R2 bucket listing refused HTTP 403 with `10042 Please enable R2`; do not assume usable R2.
- Cloudflare Primary account: **8 Workers, 7 Pages, 9 Access apps**, **0 MCP portals / 0 MCP servers** at query time. Pages `edenosprivate` exists, but exact origin/preview Access and HOMEBASE / ELYSIUM Personal authorization are not verified.

## Primary-source implementation audit

### 1. OpenList-Worker — Cloudflare-native candidate

Source [OpenListTeam/OpenList-Worker](https://github.com/OpenListTeam/OpenList-Worker), docs [Cloudflare Worker installation](https://doc.oplist.org/ecosystem/official_worker/guide_cfw). Connected authenticated GitHub tool read `README.md`, `wrangler.jsonc`, `src/backend/server/mcp.ts`, `src/backend/internal/mcp/mcp.ts` and `src/backend/server/router.ts` from the repository's default branch.

- Existing Hono TypeScript Worker + SolidJS UI, multiple driver mounts including Dropbox/Google Drive/OneDrive/S3/R2, browser preview, files/search/sharing. README says 78 drivers; historically another research note claimed 81—**do not assert an exact driver count without version-pinned inventory**.
- Source `wrangler.jsonc`: `DB_CIPHER` defaults to **none**. A deployment handling provider secrets needs an explicit verified encryption strategy, protected secret/JWT storage, provider consent, permission checks and backups.
- README first-visit browser admin setup. **Cloudflare Access must be protected BEFORE initial external exposure**, including Worker development origin and preview URL; no public setup wizard.
- **Critical MCP gap**: current `src/backend/server/mcp.ts` explicitly describes the MCP endpoint as a placeholder/limited compatibility interface and gates all calls with `adminAuthMiddleware`. It provides GET `/api/mcp/sse`, POST `/api/mcp/messages` with legacy JSON-RPC. `src/backend/internal/mcp/mcp.ts` exposes just two tools, `list_files` and `get_system_info`. It has NOT been shown to provide end-user scoped modern Streamable HTTP MCP or least-privilege tool authorizations.
- Source `/health` is unconditional liveness only; `/healthz` checks actual storage persistence. Do not use HTTP 200 liveness as file operation acceptance.
- License [AGPL-3.0 source](https://github.com/OpenListTeam/OpenList-Worker/blob/main/LICENSE) needs obligations review for modifications/network use; choose exact accepted upstream commit after verification.

**Assessment:** strongest browser file viewer/storage mounting option for Cloudflare edge, but MCP requires a real secure adapter or upstream upgrade and per-user tests. No deployment authorized merely by this research.

### 2. filex — existing server + ready MCP candidate

Source [BRF-Tech/filex](https://github.com/BRF-Tech/filex) [MCP documentation](https://github.com/BRF-Tech/filex/blob/main/docs/MCP.md) read through authenticated GitHub tool.

- Go binary/container with browser UI, search, cloud/network storage (S3, FTP, SFTP, WebDAV, SMB), embeddable web component, multiuser RBAC, audit, versions and backup.
- Native `/api/ai/mcp` Streamable HTTP, token kind `app` vs `user`, scoped verbs and `root:` folder confinement; credentials may not mint wider credentials; documented `read,mcp` read-only grants.
- **Constraint:** requires a verified always-on Go/container host and service security; not a simple Cloudflare Worker. Its tenant claims need independent negative tests. MIT license: [LICENSE](https://github.com/BRF-Tech/filex/blob/main/LICENSE).

**Assessment:** more complete MCP out of source, but hosting/operations tradeoff versus OpenList-Worker. Do not silently deploy a second file store.

### 3. Cloudflare MCP server portals — managed gateway

[Cloudflare MCP Portals](https://developers.cloudflare.com/cloudflare-one/access-controls/ai-controls/mcp-portals/) (GA [2026-09-24](https://developers.cloudflare.com/changelog/post/2026-09-24-mcp-portals-ga/)). The product can aggregate server endpoints, offer Cloudflare Access, SaaS OAuth, tool selection/logging and machine-to-machine service tokens. **It is not a file explorer or storage backend**. Both verified connected accounts have zero registered portals/servers; no live client call, identity isolation, or capability receipt exists.

### 4. WebMCP — optional browser enhancement

[Chrome WebMCP](https://developer.chrome.com/docs/ai/webmcp), [GoogleChromeLabs reference tools](https://github.com/GoogleChromeLabs/webmcp-tools). Imperative and declarative APIs are experimental (Chrome 149 origin trial). WebMCP uses the already signed-in browser's contextual UI and **must not add broader file privileges**. A normal HTML/JS browser experience must remain fully functional in iOS Safari and browsers without WebMCP.

### 5. Tailscale and local files — optional online bridging

[Tailscale Serve / Taildrive](https://tailscale.com/docs/features/taildrive) can access local owner machines or folders over a private tailnet, subject to device enrollment and grants. Taildrive is alpha. It does not make a powered-off/offline Mac's files available and is not browser-universal without a tested HTTPS gateway. No Mac pairing accepted this turn.

## Recommended implementation relationship (without competing project)

```
Authorized Safari/Chrome/iPhone/browser
     │ secure login, per-workspace + per-file grant
     ▼
Existing HEIMDALL / ELYSIUM / edenOS browser portal
     │ same-origin consent-filtered Files UI (OpenList-Worker candidate or verified equivalent)
     ▼
Existing edenOS Online Storage Manager + provider registry
     ├─ separate Dropbox / Google Drive / other OAuth mounts (never copy-all)
     ├─ authorized cloud object storage if actually enabled
     ├─ selected local/NAS files through paired owner-operated gateway
     └─ specialist domain references; HOMEBASE/NOSTOS stay authoritative
     │
     ├─ Remote MCP: cloudflare MCP portal → tested tenant-scoped file MCP upstream
     └─ Optional WebMCP: register safe read actions only in compatible browsers
```

**Do not** use a shared backend admin token across independently logged-in councils/people; Cloudflare Access login is necessary but insufficient for per-file permission checks. Per-user upstream OAuth subject, workspace/role/site grants, negative tests, and independent audit must apply at every API/MCP action. No direct public desktop ports, no silent private content indexing, no secrets in URL or browser storage.

## Acceptance gates and current LCAS

1. **Source recovery** — PARTIAL: archive/catalog and major original source code read, but binary snapshots and screenshot pixel semantics not fully inspected; current authoritative Mac/ELYSIUM source remains unverified.
2. **Provider/identity** — BLOCKED: choose verified owner-scoped upstream credentials, direct-origin/preview Access, revoked member and cross-tenant tests. No implicit permission grants.
3. **Browser file operations** — NOT TESTED ON HOST: actual authorized list/search/open/preview/download/upload/copy/share from iPhone Safari on a disposable test file, denial for unrelated tenants.
4. **MCP** — NOT INSTALLED: one Cloudflare portal with a **real** Streamable HTTP upstream, `tools/list`, one granted read and one denied cross-user call, revocation and auditable receipt.
5. **Mobile/offline** — NOT TESTED: Safari UX, stale/offline file placeholders, gateway restart, Mac disabled, no user-data loss.
6. **Recovery/release** — HOLD: verified version/hash, provider token separation, backup + restore drill, deployment rollback and explicit owner promotion.

No original code, Dropbox shares, cloud Workers/Pages, identities, permissions, source masters, hardware or live user files were changed by the research. This file is an additive research receipt on an existing isolated candidate branch—not a deployed portal, app version, accepted LKG or replacement Project Bible.
