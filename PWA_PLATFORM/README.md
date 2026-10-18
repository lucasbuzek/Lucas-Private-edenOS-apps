# EDENOS Universal Authenticated PWA Platform — candidate 0.1.0

Status: independent source/CLI package candidate with isolated functional tests. Neither deployed nor promoted; account acceptance remains UNKNOWN.

## Purpose

Provide one reusable deployment contract for standalone browser PWAs derived from EDENOS apps. Each app keeps its own domain logic, UI, data authority, permissions and product identity. The platform standardizes deployment metadata, mandatory hosted-login requirements, provider-neutral intelligence integration and verification expectations; it does not turn apps into one generic shell.

## Current implementation

- `scripts/validate-manifest.mjs` validates the shared deployment manifest.
- `scripts/deploy.mjs` installs dependencies, runs app tests, builds the standalone PWA, verifies expected output and runs the hosted-login browser smoke test. With `--publish-preview`, it publishes a non-production Netlify or Cloudflare Pages preview and reruns the auth smoke test against that URL.
- `intelligence/core.mjs` provides authenticated app-aware provider routing, app-owned prompts, explicit provider choice and no silent fallback.
- `intelligence/worker.mjs` exposes a no-store HTTP endpoint that requires a verified principal from a hosting-specific authentication adapter.
- `intelligence/providers.mjs` provides server-side Cloudflare Workers AI and optional Gemini adapters; provider credentials never belong in the PWA bundle.
- `examples/hermes.manifest.json` records HERMES as the initial Netlify-oriented pilot.
- Tests cover manifest policy, cross-app authorization, provider failure, secret separation, body limits and provider request normalization.
- Run with Node 20+: `npm test` and `npm run validate`.

This is an independently tested development candidate, not a release. Example preflight: `node scripts/deploy.mjs --manifest examples/hermes.manifest.json --app-root /path/to/HERMES`. To publish a preview, add `--publish-preview`; this requires the corresponding host CLI credentials and a working app-specific browser-auth smoke test. Production promotion is deliberately excluded. No live deployment, identity provider, database isolation, or model route is certified by a valid manifest.

## Hosted authentication

Every deployed PWA must require login. A client-side login screen alone is insufficient: every protected API/data operation must authorize the authenticated principal on the server or at the trusted edge. Identity configuration and host secrets must be provisioned outside the repository. The existing native/local app may retain its own offline access policy; this rule applies to the hosted PWA deployment.

Supported contract identities: Supabase Auth, Cloudflare Access, or an OIDC provider. Each adapter must have an app-level regression suite for signed-out access, invalid/expired sessions, user A data isolation from user B, and sign-out/session revocation.

## Deployment profiles

- Netlify: static app deployment; auth can be app-level (e.g. Supabase/OIDC) or enforced at a trusted edge. Netlify hosting alone is not proof of authentication.
- Cloudflare Pages/Workers: static app delivery plus a Worker/edge gate where configured. Cloudflare hosting alone is not proof of authentication.
- A deployment is not complete until the deployed URL is tested from an unauthenticated browser context and an authenticated account, including protected API calls.

## Reusable intelligent core

Apps may use the reusable intelligence protocol and adapter library inside their own independently authenticated deployments. No combined application or cross-app data store is created. App-specific deterministic functions remain authoritative. The core must:
- route only to authorized provider adapters;
- require explicit selection of a capable and authorized provider; do not default to Workers AI or equate edge compute with intelligence;
- never require a paid API key as the default path;
- keep provider credentials server-side;
- expose provider, quota, unavailable and fallback state explicitly;
- never silently switch models/providers when that changes privacy, quality or terms;
- scope conversations and preferences to the authenticated user;
- support app-specific prompts and tools without transferring domain authority.

CRESUS remains an entirely separate application and Cloudflare deployment. Its existing Worker candidate contains Access JWT verification, per-user conversation ownership and provider adapters. It is a reuse candidate, not yet a verified universal core. Gemini/Anthropic paths require credentials and are not included in the no-paid-API baseline; Workers AI availability is subject to Cloudflare's current plan/quota.

## Pilot selection and known gaps

HERMES is the initial deployment-contract pilot because the authoritative HERMES repository contains a Vite PWA, a Netlify build profile and Supabase Auth integration. Current source also contains an offline/local workspace escape and starts in local-only mode; that behavior must be explicitly disabled for the hosted deployment without removing local/native functionality. Supabase server-side policies and account-isolated local state require review before the hosted PWA can be called secure.

CRESUS is the shared-intelligence reuse candidate. Its branch `dev/cresus-cloudflare-intelligence-bridge` has a Worker that rejects unauthenticated API calls via Cloudflare Access JWT validation and isolates conversations by email. Its `wrangler.toml` still has replacement Access domain/audience values. Provider-choice code and its regression tests must be reviewed and run before the Worker is accepted as a reusable core. The current branch is not a verified deployment.

## Release gates

AUTHORITY -> REFERENCE -> BASELINE/LKG -> IMPLEMENT -> VERIFY -> REGRESSION -> PACKAGE -> PACKAGE VERIFY -> PHYSICAL/DEPLOYMENT GATE -> PROMOTE.

A candidate manifest passing tests does not establish that a site is deployed or protected. Unknown gates stay UNKNOWN.

## Deployment separation and safety

HERMES and CRESUS each remain independently deployable and individually authenticated. This package is reusable development/deployment tooling, not their shared runtime or a replacement for either product. It does not merge data, users, auth sessions, host credentials, URLs, or AI policies. Netlify and Cloudflare hosting are possible adapters. Cloudflare edge routing does not imply that Workers AI is fit to perform reliable reasoning or autonomous work.

Publishing a preview requires a verified, explicit existing per-app deployment target identifier; if it is missing, publishing fails closed. Cloudflare Worker-style PWA deployment is not yet enabled because a separately verified candidate Wrangler profile is necessary to avoid changing a production Worker. No source branch or existing LKG is promoted by this package.


## Independently deployable apps

HERMES and CRESUS remain entirely separate products, deployments, URLs, sessions, account policies, data and provider settings. This package is reusable tooling for their independently run application projects. Fleet validation rejects reused app identities, hosting targets and origins.

The HERMES profile describes the remote HERMES web/ candidate, which is not the same physical source layout as the current Mac HERMES pwa/ project. Do not apply that profile to the Mac HERMES working copy without confirming the correct source, build scripts and hosted-login test. The CRESUS profile describes the actual CRESUS platforms/web Worker PWA and has passed isolated build and JWT/API mock regressions.

## Reusable CLI, authentication and model adapters

From this standalone project, install with npm ci, then run npm run validate and npm test. The source is configured to produce a local npm package with npm pack. No account/registry publishing is required. CLI entry points: edenos-pwa, edenos-pwa-check and edenos-pwa-fleet. The package exports its routing, hosting, intelligence, openai-compatible and authentication adapters.

The deployer copies only selected project source into a disposable isolated staging folder and runs declared install/test/build/auth commands there. It excludes secrets, dependencies, caches, Git metadata and symlinks. This prevents modifications to the app's working tree, but DOES NOT create a security sandbox: never run commands from untrusted code without review.

All hosted PWAs must require sign-in. The jose-based Cloudflare Access and Supabase JWT adapters verify signature, issuer, audience, expiry and token purpose; an application-specific membership function must independently authorize each user. The worker HTTP endpoint is pinned to the configured app ID. Asymmetric Supabase JWTs are supported; legacy HS256 sessions require provider-side verification before they can be enabled.

The shared intelligent core never defaults to Workers AI. It requires an explicit provider choice, account-specific approval for user-connected providers, and actual accepted capabilities for workloads requiring them. Local and provider-configured HTTPS OpenAI-compatible endpoints are supported; neither a provider URL nor a model name proves real reasoning quality or free-tier availability.

## Hosting and evidence gates

Preview publishing is only permitted with a verified target ID, allowed host credentials, and manifest-declared auth configuration. Netlify uses a draft deploy; Cloudflare Pages uses an explicit non-production preview branch. Worker PWA publishing is blocked until it has its own independently accepted preview Worker, database and Access application. Production promotion is not implemented.

Actual OAuth login, independent cross-user isolation in real accounts, revocation, model reasoning/task execution, upstream provider quota, and public URL protection still require live verification. A passing local mock or build does not prove those states.

The CRESUS staged dependency installation reported three high-severity advisories that are a CRESUS release gate. The universal platform package's own dependency audit reported zero vulnerabilities at the last check. Keep these evidence states separate.
