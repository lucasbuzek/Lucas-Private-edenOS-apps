# RAVENsNEST current-project source recovery + external REUSE — 2026-10-29
**Classification:** actual original source read plus candidate-only safe supporting software; not a production deployment or completed application.

## 1. Exact source and product separation
Current project context includes distinct products which MUST NOT be silently replaced or merged:
- `CROWnest`: private LucasRAVEN personal organization and command experience, original master `~/edenOS/Software Development/CROWnest/`, verified cloud copy `/EDEN-lucas-family/RAVENsNEST/CROWnest/`. Project Bible read, 2026-10-21. Four equal presentation shells: lucasRAVEN, CROWnest, LucasCUCKOO, LucasPRO, with independently restricted account and actor data.
- `RAVENsNEST`: broader personally authorized online coordination/storage/portal capability; neither a CROWnest rename nor BIFROSTcore. Existing Asana portal task `1219926638219011` explicitly requires real owner/provider OAuth, per-provider browse/search/preview, source and replica status, consent/revoke tests, denial of cross-tenant access and independent launch from iPhone browser.
- `Online Plugins & Connectors/RavenNest`: separate local/cloud connector. `BIFROST` only optional transport; `ELYSIUM` independent product.
- `/EDEN-lucas-family/AI MCP tool`: a SOURCE RESEARCH COLLECTION, not the original runtime or a source master. First archive census 413 WebArchives from five website folders, original WebArchive bodies decoded still 0/413. Another historical `/edenOS apps/AI MCP tool` source collection is separate.
- 12 established EDEN web portals, with Online Storage Manager as a shared capability, NOT portal 13. The `EDEN_Webportals_Masterplan_R1_2026-10-25.md` is a coordination plan, not deployed release.

## 2. Actual original source read directly through connected Dropbox
`CROWnest/PROJECT_BIBLE.md`, `CROWnest/src/crownest.py`, `CROWnest/src/web_app.py`, `CROWnest/tests/test_crownest.py`, `CROWnest/web/{index.html,app.js,theme.js,style.css}`, `CROWnest/hosting/{LUCASRAVEN_HYBRID_APPLE_WEBKIT_PORTAL_20261021.md,ACCOUNT_CONNECTION_AUDIT_20261023.md,PRIVATE_LUCASRAVEN_CROWNEST_DEPLOYMENT_PLAN_20261021.json}`.
- Implemented original local core: selected-folder filename metadata only, no recursion/content reads/hydration/mutation, token-gated loopback, `GET /api/status`, `GET /api/preview`, `GET /api/catalog`, static Web UI, four shell profile selection and theme, no external credentials. The `CROWnest` browser profile selector does **not** grant independent server authorization.
- Original source history reported 16 Python tests pass on 2026-10-23; this read did NOT execute those exact original tests because the current original Mac host was offline. Browser original index HTML was text-stripped by the extraction backend; no source overwrite attempted.
- Local source still names no accepted LKG or public deployment; private account OAuth, native device, Chrome WebMCP and provider-backed live file browsing remain **unverified**.
- Repo `lucasbuzek/Lucas-Private-edenOS-apps` branch `candidate/raven-webmcp-readonly-20261027` contains `BIFROST/web/lucas-raven/public/webmcp.html` and other audited source, but **CROWnest source is not in that GitHub branch**. Don't create an alternate canonical CROWnest master there without explicit, source-verified migration.

## 3. Authenticated operations/permission gates
- Specific user-supplied Dropbox public link ending `rlkey=0rzp2...` now reports **public EDIT** audience and allow_download true, while another link to same folder previously reported public VIEW. `AI MCP tool` tree contains copied Chromium browser-profile database/cache/login/session paths. No secret file contents opened and no proven credential leak; do not expose to public or allow credential copies to be published. Existing Asana security task `1219955747892305` is OPEN; security review and link access restriction are important independent next action.
- RDC RAVENsNEST linked Lucas-MacBook.local reported OFFLINE this turn (device app 0.3.1); real native build/deployment unverified.
- Previous Cloudflare read found primary account lucas-raven Pages plus raven-cloud-node Worker; RavenNest account appleraven-private Worker but no Pages. Presence alone does NOT prove shared authorization or live cross-device files access.

## 4. External working code candidates — research, not installed
| Third-party | Actually supported per documentation | Relevant gap/limits |
| --- | --- | --- |
| [Filestash](https://github.com/mickael-kerjean/filestash) | Browser-based storage-agnostic file manager, storage auth plugins, SFTP/S3/WebDAV/SMB, gateways including MCP | Multi-user/account authorization, plugin licensing and hosting require verification; not a drop-in Cloudflare Worker |
| [FileBrowser Quantum](https://filebrowserquantum.com/en/docs/configuration/sources/) | Multiple host filesystem sources and responsive UI; OIDC/JWT/password auth and per-user source ACL | Host sources do not imply direct Dropbox/Drive connectors or no-Mac cloud; mounted/synced backends require separate verified infrastructure |
| [rclone](https://rclone.org/commands/rclone_serve_webdav/) | Authenticated remote storage backend and optional WebDAV serving | `serve webdav` may be unauthenticated by default; never expose an unprotected listener or merged rclone config |
| [Chrome WebMCP](https://developer.chrome.com/docs/ai/webmcp) | Browser-tab declarative/imperative tools in local Chrome trial | Not backend MCP, OAuth or independent access policy |
| [Cloudflare Access](https://developers.cloudflare.com/cloudflare-one/access-controls/applications/http-apps/authorization-cookie/validating-json/) | Signed Access JWT, cookie, application authorization | Must validate JWT cryptographically, claim issuer/audience/actor and protect direct origin |

Decision: Investigate Filestash and FileBrowser Quantum as complete external app/UX alternatives before writing any new file UI; use original CROWnest where its own current implementation is already accepted. Hosting and BIFROST are not assumed prerequisites to research itself. No third-party software installed or released.

## 5. Actual safe engineering performed
Built independent **EDEN_RAVENsNEST_WebArchive_Research_Utility_20261029.zip**, a standard-library Python offline `.webarchive` plist analyzer, metadata provenance JSON writer and separately opt-in allowlisted depth-2 crawler. It is a supporting tool, NOT the main RAVENsNEST app.
- Five archive unit tests plus four allowlisted-crawler tests **PASS 9/9** in a separate model container using synthetic binary Apple WebArchive fixtures and mocked crawler fetches.
- Safeguards: no automatic downloads or writes to original files; output must be outside source tree; no overwrites; no symbolically linked directories; excludes copied browser session/cookie profile directories; query secrets redacted; crawler HTTPS exact host allowlist, robots, no redirects, private-IP blocking, depth/page caps, no credentials.
- Package SHA256 `c261bce9accd20a058e09bdb0c9679e1b1f5925d2d73a523d6f7e71db847e15f`, 10,708 bytes, 5 packaged files, ZIP integrity verified. User-facing artifact is attached to the originating ChatGPT response; not a cloud-hosted install and not committed into protected original source.
- **UNKNOWN:** actual original WebArchive binary payload transfer (0/413), full primary/related website audits, CROWnest native physical tests, live Filestash/filebrowser deployment, production portal, host ACL and OAuth pairing. Never assert fullresearch complete or product launch.

## 6. No-clobber next executable gates
1. Protect exact Dropbox shares with the existing security task; preserve owner copy/backup, do not delete or publicize browser profile.
2. Obtain a functioning authorized binary transfer for .webarchive and original ZIP files; audit all 413 with the tested utility; follow official linked repos recursively under explicit research scope and record security/license/compatibility.
3. Use original CROWnest source and its own LKG; compare external alternatives and implement exact missing web portal capabilities in established source/target host after auth and permissions are verified.
4. Verify negative access for absent/other owner, stale/forged Access assertion, anonymous direct origin, unpaired devices; test mobile Safari UI and signed macOS/iOS separately.
5. Promotion only with actual end-to-end operational receipts and owner-approved hosting/account changes.
