# PRIVATE edenOS — public portal and verified release hosting contract

Status: SOURCE PREPARED / LOCAL TESTED / NOT DEPLOYED / PHYSICAL GATES UNKNOWN
Authority: EDEN Web Portal canonical source, EDENOS-PWA-Deployment and the independent HERMES/CRESUS application canons.

## Canonical boundaries

- Original public portal: `/Users/lucas/edenOS/Projects/EDEN Web Portal` resolves to `/Users/lucas/edenOS/Software Development/EDEN Web Portal`. The public portal must remain operable as a static product atlas with no private account, Mac, BIFROST or AI-provider dependency.
- Planned public Pages project: `edenosportal`, base host `edenosportal.pages.dev`. **Not provisioned or deployed in verified evidence.**
- Confirmed existing PRIVATE Pages project: `edenosprivate`, with Lucas owner-only and separate ELYSIUM/Slindokuhle private preview intents. Private root, branch aliases, immutable preview hashes, custom routes and direct origins still require actual Access/security acceptance.
- HERMES and CRESUS are separate applications, database/permission owners and deployment candidates, not tenants sharing their business data with the public portal.
- Workers/Pages Functions do only secure routing, request queues, entitlement checks and exact asset verification. The actual intelligent model and WORKinCODEX/BIFROST capabilities remain separate native or authorized AI endpoints.

## Public portal deployment layout (never deploy the raw source directory)

`EDEN Web Portal/scripts/prepare_pages.py --output <NEW_TEMP_DIRECTORY>` creates:
`public/`: ONLY `index.html`, `app.js`, `preview-data.js`, `private-download.js`, `style.css`, `_routes.json` and two approved public screenshot assets.
`functions/`: ONLY `[[path]].js`.
The exact Pages `_routes.json` invokes Functions on `/software`, `/api/software-sharing/*` and `/download/*`. Unrelated atlas routes never invoke Functions. This is a static-cost/privacy performance protection.

## Service binding to private request Worker

The Pages Function expects `SOFTWARE_REQUEST_GATE` (Worker service binding). The target Worker must not have a public workers.dev origin. The public portal sends a request as-is; consequently its Worker must be configured with:
- `SOFTWARE_REQUEST_HOST=edenosportal.pages.dev`
- `SOFTWARE_TURNSTILE_SITE_KEY` provisioned for the portal hostname, and a private `SOFTWARE_TURNSTILE_SECRET`; action `software-share`.
- `SOFTWARE_QUEUE_DB` dedicated D1 with `software-sharing/schema.sql`; not CRESUS/HERMES production D1.
- Cloudflare edge source-IP and Turnstile verification. Requests stay pending until owner approval; no email-link or PWA authorization is granted by signup.
- An optional private owner alert channel. A separate inbound address is useful for spam separation but is not required to accept requests; never publish the owner's personal address.

The portal checks `/api/software-sharing/status` before enabling **Request download link by email**. Without a correctly bound and ready Worker, it stays disabled, and static product exploration remains available.

## Single-file download by email

The Pages Function expects `EMAIL_DOWNLOAD_GATE`, another private Worker service binding. Required secret/configuration:
- `TICKET_DB` with `software-sharing/email-tickets.sql`: hashes, atomic one-use tickets, expiry and per-release enabling ledger. Do not use application databases.
- `SHARING_DB` (read-only entitlement to approved sharing queue), `OWNER_EMAIL` (server secret), `GITHUB_READ_TOKEN` (repo-scoped server-side, read-only, never public), `EMAIL_FROM` (verified sender at an onboarded owned DNS domain), `EMAIL` native Cloudflare Email Service binding. Outbound sending to arbitrary recipients remains subject to Cloudflare account/domain/plan verification.
- An **accepted release manifest** with application identity, physically verified package, exact GitHub private release repository/asset ID, accepted file name/size/SHA256. Initially `accepted-releases.json` is `[]` and the checked GitHub repository had zero Releases.
- Lucas owner-only Access JWT/login and per-app approved request required to issue; the owner must explicitly enable that already accepted release. Email link is a one-use, short-lived bearer token for **one file only**, not an app login.
- A private GitHub asset is fetched on the server over authenticated GitHub API, allowed signed GitHub CDN redirect only, with no credential forwarded to CDN, bounded to 64 MiB and independently byte-hash verified. Large files need a verified private R2 mirror or other bounded streaming adapter.
- An owner can immediately disable a release; outstanding unused links stop working. Never infer successful recipient delivery from a provider-accepted `messageId`; verify real deliverability.
- No GitHub release/public browser link, token, email, source path, cloud secret or private app data can be embedded in the public portal HTML, JavaScript or package.

## Physical gates before enabling

1. Owner confirms Cloudflare account, `edenosportal` project, deployment route, owned email DNS/sender and binding permissions. Do not create/recreate ambiguously existing projects without a read-only check.
2. Verify that the private service Workers cannot be reached through any separate public `workers.dev` or direct URL; verify binding request origins match `edenosportal.pages.dev`.
3. Run actual D1 migrations on **dedicated** new queues, check repository read-token scope and GitHub accepted binary/release provenance.
4. Sign in as Lucas to the protected owner page and approve/deny a real test email; try non-owner, cross-app, malicious and expired requests.
5. Send one trial link to a controlled recipient and verify receipt, one-use/expiry/revocation, checksum and browser/phone downloading without credential leakage.
6. Verify the product portal's full interactive Atlas and static behavior with Pages Functions absent, disabled and configured; ensure no accidental permission to ELYSIUM, Slindokuhle, HERMES or CRESUS domain APIs.
7. Only then enable the live public software request path and manually promote an independently verified artifact. The owner-approved request and download subsystem does **not** imply any private PWA or AI capability is release-ready.

No Cloudflare deployment or domain/email configuration has been performed by this file.
