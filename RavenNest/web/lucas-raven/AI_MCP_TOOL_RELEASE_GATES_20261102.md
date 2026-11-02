# AI MCP TOOL — source-first launch gates (2026-11-02)

Status: RECONCILIATION / NOT PRODUCTION ACCEPTED. This record is additive on the protected RAVENsNEST candidate. No LKG replacement, production migration, credential transfer, or deployment is authorized by this file.

## Canon and interfaces
Owner access point: https://lucas-raven.pages.dev (NOT a knowledge demo).
Existing original source branch: ravennest/consolidated-20261010, RavenNest/.
Protected candidate: candidate/ravennest-universal-files-20261029.
Owner portal: human browser files, devices and services, compact mobile UI, one approved sign-in.
Browser WebMCP: optional tools on a browser page; never substituted for a persistent MCP server.
Remote MCP: independently authenticated Streamable HTTP endpoint with per-user grants, not yet present in this candidate.
BIFROST: independent CONNECT · KEEP · RESOLVE capability/transport/router. No mandatory RDC or local Mac dependency for cloud-origin files.
ELYSIUM/HEIMDALL: independent presentation/workspaces; knowledge portal, HERMES and downloader are distinct products.
Provider accounts: Dropbox, Google Drive and later cloud/local sources require separate, explicit authorization; never silently merge identities or use a ChatGPT connector's OAuth token on the hosted portal.
Protected app owner role is NOT blanket access to other peoples' storage grants.

## Observed 2026-11-02 code evidence
functions/api/files.js: Cloudflare Access JWT, exact user enrollment match, D1 source grants, path-scoped Dropbox / parent-scoped Drive listing and download, fail-closed unconfigured secrets.
functions/api/file-cursor.js: HMAC-signed and expiration-bound pagination tokens; user/source/path/provider bindings.
migrations/0003_files_readonly.sql: additive provider/source/grant tables.
public/files.html, public/files.js: human-first responsive file browser, optional two read-only WebMCP tools.
Source candidate lacks provider OAuth onboarding flow, full search, write/recovery workflow, cloud-to-local file synchronization, complete device-file access and authenticated server-side remote MCP.
Raven API [[path]].js includes historical legacy operator code. Production security review must confirm no bypass, and enforce disabled legacy access on release.
The independent isolated ZIP had 19 synthetic tests; NEVER claim these test the GitHub candidate, OAuth, browsers, network or production. 

## Release acceptance in one controlled transaction (no speculative migration)
1. Check current source/LKG, branch comparison, actual Cloudflare Access policy, owner/council isolation and D1 users/grants/backups. Do not destructively overwrite or silently bootstrap roles.
2. Add account-linking to the existing project with Google/Apple owner login choices where supported and explicit separate provider OAuth. Tokens server-side, only approved scopes, immediate revocation; never password scraping.
3. Implement secured remote MCP HTTP tools from the existing server-side authorization service; bind per-user capability grants; preserve browser WebMCP as optional enhancement.
4. For providers and devices: use original BIFROST/AppleRAVEN permissions with connection state; cloud files work without Macs, offline device-local files are unavailable unless explicitly synchronized.
5. Test real approved provider list, nested directory, pagination, downloads, revoked access, cross-tenant denial, expired JWT, invalid cursor/path, origin policy, offline states, iOS Safari and desktop; verify auth and actual MCP client invocation.
6. Deploy first to an owner-only protected preview, run tests, retain rollback and LKG. Promote only after verification; log real evidence to original Asana task 1219926638219011.

## Verified blockers
- No demonstrated first-use OAuth linking flow in candidate; signed-in identity is not provider consent.
- No live credentialed Dropbox/Drive end-to-end acceptance.
- No server remote MCP endpoint in candidate; browser-only WebMCP insufficient.
- No demonstrated authenticated live device/local-files end-to-end acceptance.
- Production Access coverage, D1 migrations/backup, provider secrets, browser testing and rollback have not been verified in this record.
- Full inspection of binary .webarchive content and original screenshots has not been completed; inventory of filenames alone is NOT a full content audit.

Do not select OpenList-Worker, Filestash, or other replacement software without documenting a measured gap in original source and tenant isolation/license acceptance.
