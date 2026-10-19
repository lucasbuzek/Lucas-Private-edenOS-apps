# EDENOS Cloudflare closed-testing relaunch — candidate

**Scope:** two independent standalone application pilots, HERMES and CRESUS. This document belongs to the universal deployment *tooling* project. It does not transfer ownership of either app, create a shared app database, or authorize live production changes.

**Evidence:** local gateway, Turnstile decision logic, D1-compatible SQL, independent app JWT validation, provider routing and staged builds have automated regression tests. None of the live Cloudflare-hosted closed-testing instances has been provisioned or authenticated against a real account yet.

## Closed-testing experience

- Public separate waitlist host: email form plus Cloudflare Turnstile with mandatory server-side Siteverify. Submission creates a pending application only, **not** an account and not an approval.
- Private application host: Cloudflare Access sign-in and a second app-specific approved-member check **before any HTML, JS, service-worker, static asset or API response**.
- Only the verified owner's Access JWT may view the private `/admin` page, list requests and click Approve/Deny. Approved users pass the member gate; denied/pending users cannot.
- Email ownership is verified at Cloudflare Access identity sign-in, not by the public waitlist form. Approving a typed address does not prove that applicant owns it.
- If Cloudflare Access policy still excludes an approved email, the application reports `REQUIRES_VERIFICATION` for Access policy synchronization. **Database approval alone does not guarantee an Access login.**
- The public waitlist domain must NOT be covered by the private Access rule; the private app domain must ALWAYS be covered. The direct Workers/Pages origin must not remain a bypass.
- Every application gets distinct deployment hostname(s), Access audience and product/source/UI. No application may use another app's membership approval.

## Pilot A — HERMES (separate Cloudflare-hosted PWA)

- Candidate entry: `examples/cloudflare/hermes.worker.mjs`.
- Static assets: existing HERMES Vite SPA, built from **the verified hosted-authentication source**; NOT automatically from the current Mac `HERMES/pwa` version, which still has a local-workspace escape and unscoped browser state.
- Worker hosting: `ASSETS` binding and **`run_worker_first=true` for all paths**, otherwise static assets may bypass authentication. `workers_dev=false`; private hostname must be behind its own Access application.
- Access: verified HERMES-specific AUD, owner identity and login, per-user permissions; any Supabase business-data flow remains app-owned and must separately pass tenant isolation.
- Waitlist: new dedicated HERMES D1 ledger using `closed-testing/schema.sql`. Never reuse CRESUS D1.
- Reference-only configuration: `examples/cloudflare/hermes.wrangler.template.toml` (not deployable until all REPLACE entries, routes and bindings verified).
- **BLOCKED** until hosted HERMES source integration, official domain+Access setup, real OAuth and storage-isolation acceptance.

## Pilot B — CRESUS (separate Cloudflare Worker PWA)

- Candidate entry: `examples/cloudflare/cresus.worker.mjs`.
- Worker gateway: `APP` service binding to existing `cresus-agent` original Worker; **do not overwrite** original production Worker or its `wrangler.toml`.
- Waitlist: CRESUS adapter reuses its *existing* D1 `users` table (pending/active/disabled), established `OWNER_EMAIL`, admin functions, chats and data ownership. This avoids a second CRESUS membership ledger and requires no schema migration for the user table.
- The original `cresus-agent` worker's direct `workers.dev` / custom hostname access MUST be confirmed protected or disabled before its gateway can be considered secure. The existing Access group membership and any optional group synchronization must be verified end to end; do not silently broaden Access policies.
- Reference-only configuration: `examples/cloudflare/cresus.wrangler.template.toml`. Existing CRESUS D1 identifiers must be verified against the Cloudflare account, not guessed from source.
- **BLOCKED** until separate candidate Worker, Access policy, Turnstile, verified owner identity, safe direct-origin containment and database backup/rollback gate.

## Proper AI intelligence — independent of hosting

Cloudflare is hosting/routing/identity; **Workers AI is not the default intelligence**. HERMES and CRESUS select a capable server-side provider only after a real evidence-gated acceptance test. The toolkit supports authorized provider-bound Gemini/free-tier when actually available, other user-connected compliant HTTPS OpenAI-compatible endpoints, and a local model for genuine local execution. No paid API dependency may become mandatory; no subscription access is represented as a transferable API key.

Run the two app-specific model probes from `intelligence/qualification.mjs`. They check eligibility reasoning, consent, arithmetic and avoidance of invented market facts. These are *screening tests only*; real evidence-source retrieval, tool calls, privacy controls, quota reliability and human visual/output acceptance are separate mandatory gates. No attached real AI provider has passed those gates. Provider credentials stay in host secrets, not browser assets or source.

## Deployment and physical acceptance pipeline

1. **AUTHORITY/REFERENCE:** Recheck the current AppDev Bible and each app's independent product canon, code, Git branch and LKG.
2. **BASELINE/RECOVERY:** Snapshot or verify the original source, existing D1 contents, permissions, Access apps/groups and current deployed URLs; do not change them on a candidate.
3. **CLOUDFLARE INVENTORY:** Read-only API verification of the exact account, project, DNS hostnames, Access app/audience, D1 binding, Turnstile widget, original service Worker and billable plans/quotas. Never infer availability from a TOML value or DNS alone.
4. **PREVIEW PREPARE:** Stage source into an isolated directory. Create separately named *candidate* resources only after verification and the required authorization/configuration are available. Use existing approved resources where possible. Do not create new sites automatically without exact identity and custody checks.
5. **AUTHORITY GATES:** Protect the private hostname with Access; public waitlist hostname exposes only the Turnstile form. Configure dedicated HERMES waitlist D1, verified CRESUS existing users-table binding and owner-only administration. Ensure `workers_dev=false` and no other direct-origin bypass.
6. **FUNCTIONAL TEST:** Verify submission (Turnstile success/failure), pending state, owner sign-in, approve and deny decisions, existing approved user, non-owner admin denial, per-app segregation, and direct origin rejection using *real separate test accounts*.
7. **INTELLIGENCE TEST:** Connect an authorized capable model provider with no mandatory paid API. Run live application tasks with real research evidence/tool routing and inspect actual outputs. Workers AI/HTTP 200 cannot establish reasoning capability.
8. **REGRESSION/PACKAGE:** Recheck full app functionality, service worker/installability, export/backup, account isolation, security headers, CSP, D1 recovery, checksum, recovery process and no cross-project regression.
9. **PHYSICAL GATE:** Test on iPhone Safari as Home Screen PWA, login renewal, denial after revocation, mobile network and unexpected-origin accesses. UNKNOWN is not PASS.
10. **PROMOTE:** Only after exact explicit release approval and all required gates passed. No production promotion is part of this candidate.

### Current genuine external blockers

Netlify/Cloudflare deployment API tokens and Cloudflare account ID are not present in the inspected Mac deployment environment; the CLI is also not installed. HERMES Supabase client configuration is absent. The existing CRESUS Access JWKS endpoint is reachable but Access app policies, ownership and end-user authorization remain unverified. No actual supported remote AI provider credentials/capacity have been confirmed. Consequently **no HERMES/CRESUS Cloudflare relaunch has occurred** and no candidate preview has been published.


## Engineering acceptance evidence (2026-10-18)

The universal candidate completed **96 tests PASS, 0 FAIL** on the authorized Mac; manifests for the two **separate Cloudflare** app pilots validated, and an inspected npm 0.2.0-dev.0 package passed clean extraction/installation/import/CLI checks. Test package archive SHA256: `d400635c847a35a176f8d4663f75217cb4ae747f91cbb7982ebb7a337e56a639` (ephemeral verification archive was removed; not a promoted or delivered release). Universal package `npm audit --omit=dev`: zero advisories.

The unchanged CRESUS Worker source passed an isolated staged preflight including existing JWT/API regression tests and PWA asset build. Its original Wrangler 4.147.0 lockfile retains three high-severity development-tool advisories. An **independent temporary copied lockfile** using `npm audit fix --package-lock-only` resolved all three with Wrangler **4.151.1**, and a second audit returned zero. This did not alter, build-test or promote the fixed lockfile within the authoritative CRESUS repository. The patch requires app-specific regression testing before any CRESUS release.

Cloudflare Access certificate endpoint for the configured CRESUS team returned HTTP 200 with two public signing keys. This is **not** user login acceptance or validation of Access policy and existing Worker direct-origin security.

Both Cloudflare closed-testing pilots remain blocked from preview/relaunch because account-authorized deployment credentials, two verified independent Access applications/hostnames/audiences, Turnstile secrets, D1/APP bindings, verified origin containment, owner/admin physical browser acceptance, and live capable no-paid-API model acceptance were not available in this execution environment. No public deployment has been claimed or performed.

## User-selected namespace for owner/admin, apps and future environments — 2026-10-19

Use `lucas.edenosprivate.pages.dev` as the desired owner-admin Pages branch-preview alias. Pilot app URLs are `hermes.edenosprivate.pages.dev` and `cresus.edenosprivate.pages.dev`, but **their app runtimes, backend data, Access audiences, releases, ownership and D1 remain separate**. Keep the planned `elysium.edenosprivate.pages.dev`, `slindokuhle.edenosprivate.pages.dev` and `lucastesting.edenosprivate.pages.dev` as owner-only **unpublished placeholders** for future unified environments. Reserve `edenosportal.pages.dev` as an independent future portal *project intent*, not a live site.

These labels only resolve as Cloudflare Pages branch aliases after a verified `edenosprivate` Pages project and successful branch preview deployments. None are reserved merely by writing a configuration. Branch previews also have immutable hash aliases; **all** such endpoints must be protected and checked against direct-source bypass. Pages' default shared preview Access setting is not proof of the required separate owner/tester authorization. The user-supplied casing is normalized to lowercase by DNS/Pages aliases.

Source candidates: `deployment/private-pages-namespace.mjs`, `closed-testing/owner-hub.mjs`, the app manifest desired-pages-intent fields and `examples/private-pages/`. These are safe local materials only. No Cloudflare Pages project, admin account, Pages branch or portal has been published. No app deployment method has been replaced by Pages; the aliases are a potential protected entry/UX layer pending verified integration with each app's existing standalone runtime and authentication.

### Private Pages namespace engineering evidence — 2026-10-19

The independently staged Pages branch-alias plan contains exact requested lowercase DNS names for Lucas admin, HERMES, CRESUS, Elysium, Slindokuhle, LucasTesting, and distinct edenOSportal root project intent. All six branch placeholders and the future portal placeholder are materialized as INERT files beneath examples/private-pages/; no Pages project, DNS record, Access application, branch or public deployment was created. The plan validates canonical names, per-app identity, owner vs tester access, no false deployed status and future app extensibility.

The Lucas owner-hub adapter was implemented with separate HERMES and CRESUS administration service interfaces. Local tests require a verified lucas-admin identity and owner email, enforce same-origin decisions, and prove one app's approval does not change the other's membership. It has NO connected live Access audience, provider or app services; therefore it is not an operating admin console.

New candidate package 0.2.0-dev.1: 109 tests passed, zero failed; independent HERMES/CRESUS manifest/fleet validation passed, npm dependency audit passed, and clean temporary package extraction/import/CLI acceptance passed. Verification-only tarball SHA256: c3ac11b0ed6971bf2595a69391ddc03848f929ced8acb8c218d463d593e90e77. The disposable tarball was removed after verification and is not a release or shipped artifact.

**Cloudflare URL feasibility:** A branch alias like lucas.edenosprivate.pages.dev exists only once an actual Pages project edenosprivate and a successfully deployed branch named lucas exist. All hash deployment URLs must be gated too. Users cannot 'reserve' these URLs merely via manifest JSON. Distinct HERMES/CRESUS app backends and independent audiences remain mandatory. edenosportal.pages.dev would be an entirely separate Pages project requiring explicit setup and user approval. These are intentions only; external account and physical acceptance gates remain UNKNOWN.
