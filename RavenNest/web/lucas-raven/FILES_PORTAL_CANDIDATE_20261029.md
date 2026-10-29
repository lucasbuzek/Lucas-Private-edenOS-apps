# RAVENsNEST Online Storage Manager — protected source candidate (2026-10-29)

## Source authority and limits
Original authority: RavenNest/ in branch ravennest/consolidated-20261010. This additive branch is candidate/ravennest-universal-files-20261029. Original index.html, original app.js and existing Pages API [[path]].js are unchanged. This release has NOT been deployed, tested against real Cloudflare Access or provider accounts, or accepted. Do not merge without security/QA.

## Added
- functions/api/files.js: read-only Dropbox/Google Drive folder list and file download via per-source grants from D1, original RavenNest verifyAccessJwt RS256 validation, provider-scoped credentials in Cloudflare secrets; errors fail closed. No Mac required.
- migrations/0003_files_readonly.sql: additive source/grant tables, no existing table change. Run only on a backed-up, known correct D1.
- public/files.html and public/files.js: responsive human file browser at /files.html. Optional read-only WebMCP providers/list actions are progressive enhancement; mobile Safari uses normal buttons.
- This GitHub source supports only first 100 results per provider folder, no global search, no first-use OAuth pairing screen, no write API, and no own server-side remote MCP endpoint.

## Configuration and physical gates
1. Protect all portal hostnames, aliases, preview origins and /api/files with a verified Cloudflare Access application. Verify Access JWT issuer, audience, expiration and original user enrollment before exposing any private filename.
2. Consent Dropbox/Google Drive OAuth independently per provider/account. A ChatGPT plugin connection does not grant Cloudflare Worker provider credentials. Never commit token, refresh token, password, private key or customer file.
3. Provider source rows must use a correct grant-scoped root (Dropbox path, or Google Drive folder ID), a Cloudflare secret reference RAVEN_FILE_* and enabled=1 only after acceptance. Add explicit user-file grants with can_list/can_download and revocation. No universal-owner bypass.
4. Prove authenticated listing of selected root, nested browse, file download, cross-tenant denials, invalid paths, unauthenticated and expired JWT, revoked grant, missing provider OAuth and provider cursor/pagination handling. Test Safari/Chrome/iPhone, offline truth and rollback.
5. Do not alter old RavenNest/Knowledge/AppleRAVEN/ELYSIUM services or the public Dropbox archive. No production release/promotion on this branch.

## External REUSE prospect — researched, not installed
Official OpenList Worker Cloudflare port: https://github.com/OpenListTeam/OpenList-Worker and https://doc.oplist.org/guide/installation/worker — existing browser UI, 81 storage drivers, D1/KV, remote MCP, RBAC, AGPL-3.0; review license, own hosting, auth and source maintenance before more custom work. Filestash https://www.filestash.app/ — external browser file-manager / MCP server with separate hosting. SILO https://github.com/gouthamkallempudi/silo-mcp — external OS-keyring subprocess MCP multi-cloud transport, not directly a Workers runtime.

## Isolated local ZIP differs
An isolated source candidate ZIP RAVENsNEST_Universal_Files_WebMCP_Additive_20261029.zip also contains a richer cursor-bound list implementation and 19 mocked Node tests. Those tests were run with an EPHEMERAL synthetic JWT verifier outside the ZIP, to stand in for the original RavenNest verifier available in the canonical repo. Do not conflate tested local ZIP with shorter GitHub candidate commits or real provider auth/Cloudflare end-to-end tests.