# EDENOS Universal PWA Deployment — 0.2.0-dev.0

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
