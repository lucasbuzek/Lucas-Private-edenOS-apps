# EDENOS Universal PWA Deployment — 0.2.0-dev.3

**Status: engineering candidate / not deployed / no LKG promotion.** Current source authority is the standalone project at `/Users/lucas/edenOS/Software Development/Online Plugins & Connectors/EDENOS-PWA-Deployment`. Local Git `main` remains the preservation baseline. Candidate changes belong only on the project feature branch.

This is reusable **deployment tooling**, not a combined EDENOS app. Every hosted PWA remains its own full standalone product, with separate URLs, authentication audience, user permissions, data, capabilities and deployment. HERMES and CRESUS are two independent relaunch pilots.

## Current reusable modules

- `scripts/validate-manifest.mjs`: app-owned deployment manifest validation and mandatory hosted authentication declarations.
- `scripts/validate-fleet.mjs`: reject collisions between app identities, hosting targets and HTTPS origins.
- `scripts/readiness.mjs`: read-only source, host-credential and physical-gate readiness; never invent credentials, deployed URLs or verified sign-in.
- `scripts/deploy.mjs`: disposable source-stage install/test/build/auth-test preflight, unchanged canonical app source, and opt-in protected preview publishing for verified existing Netlify/Cloudflare Pages targets only.
- `deployment/verify-target.mjs`: read-only authenticated host API confirmation of exact existing site/project identity, expected name and HTTPS origin before any preview build/upload.
- `authentication/jwt.mjs`: signed, issuer/audience-scoped Cloudflare Access and Supabase asymmetric JWT verifiers based on `jose` (MIT). Membership is independently authorized by each app.
- `closed-testing/gateway.mjs`: reusable per-app *owner-approved email waitlist* and private-host gate. Every private page, service worker, asset and API requires verified identity plus approved membership. Public waitlist is confined to a separate hostname.
- `closed-testing/turnstile.mjs`: server-side Turnstile Siteverify with expected hostname and action; no unverified submission.
- `closed-testing/d1.mjs` and `schema.sql`: HERMES-specific dedicated waitlist database.
- `closed-testing/cresus-store.mjs`: reuses CRESUS **existing** D1 users table and pending/active/disabled membership states without a duplicate ledger.
- `closed-testing/cloudflare.mjs`: separate Cloudflare Worker adapter for each app. HERMES may use protected `ASSETS` with `run_worker_first=true`; CRESUS uses internal service binding `APP` to preserve its existing Worker.
- `intelligence/core.mjs`, `worker.mjs`, `providers.mjs`, `openai-compatible.mjs`: per-app signed-in provider routing; no default Workers AI, no silent fallback, per-user provider consent and provider secret isolation. App-specific required capabilities now also require an explicitly recorded live acceptance.
- `intelligence/qualification.mjs`: app-specific automated screening for eligibility, consent, arithmetic and fabricated market facts. A mock passing does NOT certify a real model; actual source evidence, research tools, cost/terms, privacy and real model performance still need human and physical gates.

## Cloudflare closed-testing relaunch

Read **`CLOUDFLARE_CLOSED_TEST_RELAUNCH.md`** before any hosting setup. It contains separate HERMES and CRESUS pilot boundaries, exact stage/Access/D1/Turnstile/direct-origin requirements, and STOP/UNKNOWN conditions.

- `examples/hermes.cloudflare.closed.manifest.json` — Cloudflare candidate for HERMES hosted-auth source. The current Mac HERMES `pwa/` and separate remote `web/` branch are **not interchangeable**. Hosted authentication and account data isolation are not yet physically accepted.
- `examples/cresus.worker.manifest.json` — CRESUS existing Worker PWA source (read-only preflight). Its existing D1 and Admin functionality remain app-owned and authoritative.
- `examples/cloudflare/*.wrangler.template.toml` — intentionally **not deployable** until separate per-app hostnames, Access audiences, D1 bindings, owner identity, Turnstile and private origins are verified. `workers_dev=false`; no guessed URLs/IDs or production routes.
- `examples/cloudflare/*.worker.mjs` — separate app identity entrypoints using the shared closed-testing library.

CRESUS existing `ACCESS_TEAM_DOMAIN`, `ACCESS_AUD` and D1 identifiers are present in its source. Its public Access signing-key endpoint was reachable and returned two keys. That is **not** evidence that its Access policy, user login, group membership, direct-origin containment or deployment is correct. No authorized Cloudflare deployment token/account and no active capable remote model credentials were found in the Mac process environment. No live deployment occurred.

## Developer commands

```bash
npm ci
npm run validate
npm test
node scripts/readiness.mjs --manifest examples/hermes.cloudflare.closed.manifest.json --app-root /path/to/HERMES
node scripts/readiness.mjs --manifest examples/cresus.worker.manifest.json --app-root /path/to/CRESUS
node scripts/deploy.mjs --manifest examples/cresus.worker.manifest.json --app-root /path/to/CRESUS
npm pack --dry-run
```

The readiness command is read-only. The deploy command *without* `--publish-preview` stages and builds in a temporary project copy. **Worker PWA publishing is intentionally blocked** until an independently protected candidate Worker/D1/Access combination is verified. Netlify/Cloudflare Pages preview publishing requires explicit existing per-app targets, identity verification, configured auth, host CLI and authorized credentials. No production-release command exists.

These engineering scripts do not constitute an OS sandbox; review source-defined build commands before running untrusted apps. The CLI exposes `edenos-pwa`, `edenos-pwa-check`, `edenos-pwa-fleet` and `edenos-pwa-readiness`. Npm registry publication is disabled; use locally packed, inspected artifacts.

## Dependency and evidence state

The universal package last passed its own dependency audit with zero advisories. The physical CRESUS lockfile had three high-severity development-tool advisories (Wrangler 4.147.0, Miniflare, Sharp). A **disposable copied lockfile** repaired them using Wrangler 4.151.1, after which `npm audit` reported zero; this does **not** change the CRESUS original and is not a verified promoted patch.

Source/test passing is not user login, model capability, online deployment or release acceptance. The required sequence is AUTHORITY → REFERENCE → BASELINE/LKG → IMPLEMENT → VERIFY → REGRESSION → PACKAGE → PACKAGE VERIFY → PHYSICAL GATE → PROMOTE. Unknown remains UNKNOWN. Existing app LKGs, backing data, passwords, production routes and project folders are not altered by this candidate.

## Private Pages namespace — owner and future environment placeholders

Established intended names (all DNS lowercase; availability and ownership UNVERIFIED):

| Purpose | Intended Pages URL | Intended access |
|---|---|---|
| Lucas — administrator | `https://lucas.edenosprivate.pages.dev` | Verified owner ONLY |
| HERMES — standalone pilot | `https://hermes.edenosprivate.pages.dev` | App-specific approved testers |
| CRESUS — standalone pilot | `https://cresus.edenosprivate.pages.dev` | App-specific approved testers |
| Elysium — future | `https://elysium.edenosprivate.pages.dev` | Owner-only placeholder |
| Slindokuhle — future | `https://slindokuhle.edenosprivate.pages.dev` | Owner-only placeholder |
| LucasTesting — future | `https://lucastesting.edenosprivate.pages.dev` | Owner-only placeholder |
| Future unified portal | `https://edenosportal.pages.dev` | Separate Pages project, never auto-published |

**Important Cloudflare behavior:** `<branch>.edenosprivate.pages.dev` is a Pages **branch-preview alias**, not a separate project or automatically reserved DNS name. All such aliases require a real existing Pages project `edenosprivate`, the corresponding successfully deployed preview branch, and verified Access protection on the project root, branch aliases **and immutable hash preview URLs**. These aliases must not be treated as separate app backends: HERMES/CRESUS retain independent deployments, data and authorization. The `edenosportal` project is a distinct future root hostname and is not created or published by this code. No Cloudflare project, branch, URL or Access rule has been activated.

The prepared artifacts are in `examples/private-pages/`. They are **inert unpublished placeholders** with no functional login, no app data and no claimed protection. `scripts/prepare-private-pages.mjs` generates them into a new destination only, and its default mode prints the desired plan without writing anything.

`closed-testing/owner-hub.mjs` contains a test-backed *owner-only* administration composition surface for the intended Lucas host. It requires a separate verified `lucas-admin` Cloudflare Access audience and independently scoped HERMES and CRESUS admin service adapters. It cannot inherit family/friend permissions or merge databases, and it does not sync Access policies automatically. There is no live bound owner hub, authenticated owner account or published admin page yet.

The public email waitlist origin is **not specified** by this namespace; it must remain separate from the protected private owner and app origins, with Cloudflare Turnstile and the established approval/denial flow. Do not assume a Pages preview wildcard Access policy can securely distinguish owner-only branches from approved-user app branches; prove exact per-host policies and all alternate-origin denials physically before publication.

Cloudflare documentation: [Pages preview aliases](https://developers.cloudflare.com/pages/configuration/preview-deployments/), [Pages Access known issues](https://developers.cloudflare.com/pages/platform/known-issues/).


## Private owner-approved software sharing and family suite boundaries

The reusable private sharing backend is in software-sharing/. Request-only public catalog entries are curated from Software Development project candidates, NEVER automatically made downloadable from a directory scan. It supports server-side Cloudflare Turnstile, honeypot, per-IP/per-email hashed D1 rate limits and a dedicated D1 approval queue. No public software download, owner email, file-system path or developer credential is returned by the request form. Optional owner notification can use a private queue; the approval process does not depend on paid outbound email.

The Lucas owner hub optionally accepts a separate software-sharing service, displays requests beside (but not merged with) HERMES and CRESUS app access, and issues app-scoped approve/deny decisions. These decisions never silently modify Cloudflare Access policies. Private R2 downloads require BOTH verified Access app entitlement AND explicit sharing approval, a physically accepted release registry and matching object checksum. A private R2 bucket with public access disabled and physical identity tests is still required. Current downloadable release registry is intentionally EMPTY; software download functionality is an implemented integration candidate, NOT an operational hosted release.

The ELYSIUM and Slindokuhle full-functionality requirements are preserved in environments/private-suite-contract.json: ELYSIUM Personal and Business for approved family members, and Slindokuhle parent-household versus transport-business, farm, finance, garage and maintenance contexts. Separate user/tenant membership and explicit consent for BIFROST-local, BIFROST-online and WORKinCODEX are enforced by the tested adapter contracts. Do not claim full PWA functionality until the original domain apps, authoritative data, identity and actual connectors have been integrated and physically accepted. The source for ELYSIUM/Slindokuhle is NOT created or replaced by a contract file.

The separate EDEN Web Portal is authoritative under Software Development/EDEN Web Portal. Its public concept copy now accurately describes the private programme and not-yet-open invitation service without exposing private family/owner URLs. This reusable package does not deploy or replace that portal.


## EDEN Web Portal private GitHub release hosting and email links

The ORIGINAL public portal is at /Users/lucas/edenOS/Projects/EDEN Web Portal (a verified symlink to the canonical master in Software Development/EDEN Web Portal). Its interactive Atlas still runs locally as static HTML/CSS/JS. Optional Cloudflare Pages Functions enable a request button ONLY when the independent private sharing Worker reports a functioning form. Non-software routes always retain static behavior.

New reusable backends:
- software-sharing/github-release.mjs: metadata-pinned, read-only, exact GitHub Releases asset adapter, private server-side Contents-read token, allowed repo list, controlled GitHub signed CDN redirects, byte-verified SHA256, bounded 64-MiB maximum per on-demand artifact. Larger artifacts require a separately verified private R2 mirror or other memory-safe backend.
- software-sharing/email-tickets.sql and email-tickets.mjs: separate D1 queue of SHA-256 token hashes, single-use atomic redemption, 15-minute expiry by default, invalidation of older links to the same app/email and explicit revocation.
- software-sharing/email-links.mjs and cloudflare-email-download.mjs: user must first be approved by Lucas in the separate software-sharing queue; the owner must intentionally enable an already verified release and send the specific link. The browser receives ONLY a short-lived email capability; it never sees private GitHub credentials or asset URLs. GET never consumes the link, preventing ordinary email-scanner prefetching. Link is passed in URL fragment and only submitted on explicit button press.
- software-sharing/release-controls.mjs: owner-controlled D1 enable/disable for physically accepted immutable packages only. Disabling revokes unconsumed email-link access; approving a request does NOT automatically authorize a release.
- software-sharing/owner-adapter.mjs: injects trusted private email/release services into the existing Lucas Access-gated admin hub; no unauthenticated HTTP link issuance route is introduced.
- EDEN Web Portal/functions/[[path]].js: optional Pages Functions bridge to SOFTWARE_REQUEST_GATE and EMAIL_DOWNLOAD_GATE service bindings; fails with 503 if not configured. No public GitHub browser download URLs.
Cloudflare Email Service sender requires a properly onboarded DNS/email domain and private sender binding; no verified sender, domain or recipient delivery exists in current physical evidence. No paid service is mandatory in code, but free sending to arbitrary new recipients is NOT assumed until terms and account acceptance are checked.
Currently the private GitHub repository had ZERO Releases at the last authenticated check. accepted-releases.json is [] and all distribution controls default disabled. No file downloads, email link deliveries, portal deployment or public launch have been physically accepted.
