# EDENOS Universal Authenticated PWA Platform — candidate 0.1.0

Status: isolated implementation candidate. Not yet promoted, deployed, or integrated into app releases.

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

This is an isolated deployment candidate, not a release. Example preflight: `node scripts/deploy.mjs --manifest examples/hermes.manifest.json --app-root /path/to/HERMES`. To publish a preview, add `--publish-preview`; this requires the corresponding host CLI credentials and a working app-specific browser-auth smoke test. Production promotion is deliberately excluded. No live deployment, identity provider, database isolation, or model route is certified by a valid manifest.

## Hosted authentication

Every deployed PWA must require login. A client-side login screen alone is insufficient: every protected API/data operation must authorize the authenticated principal on the server or at the trusted edge. Identity configuration and host secrets must be provisioned outside the repository. The existing native/local app may retain its own offline access policy; this rule applies to the hosted PWA deployment.

Supported contract identities: Supabase Auth, Cloudflare Access, or an OIDC provider. Each adapter must have an app-level regression suite for signed-out access, invalid/expired sessions, user A data isolation from user B, and sign-out/session revocation.

## Deployment profiles

- Netlify: static app deployment; auth can be app-level (e.g. Supabase/OIDC) or enforced at a trusted edge. Netlify hosting alone is not proof of authentication.
- Cloudflare Pages/Workers: static app delivery plus a Worker/edge gate where configured. Cloudflare hosting alone is not proof of authentication.
- A deployment is not complete until the deployed URL is tested from an unauthenticated browser context and an authenticated account, including protected API calls.

## Reusable intelligent core

Apps use a small adapter contract to call a shared intelligence service. App-specific deterministic functions remain authoritative. The core must:
- route only to authorized provider adapters;
- prefer genuinely free/locally available routes where capable;
- never require a paid API key as the default path;
- keep provider credentials server-side;
- expose provider, quota, unavailable and fallback state explicitly;
- never silently switch models/providers when that changes privacy, quality or terms;
- scope conversations and preferences to the authenticated user;
- support app-specific prompts and tools without transferring domain authority.

The CRESUS Cloudflare Worker candidate already contains Access JWT verification, per-user conversation ownership and Workers AI/Gemini/Anthropic adapters. It is a reuse candidate, not yet a verified universal core. Gemini/Anthropic paths require credentials and are not included in the no-paid-API baseline; Workers AI availability is subject to Cloudflare's current plan/quota.

## Pilot selection and known gaps

HERMES is the initial deployment-contract pilot because the authoritative HERMES repository contains a Vite PWA, a Netlify build profile and Supabase Auth integration. Current source also contains an offline/local workspace escape and starts in local-only mode; that behavior must be explicitly disabled for the hosted deployment without removing local/native functionality. Supabase server-side policies and account-isolated local state require review before the hosted PWA can be called secure.

CRESUS is the shared-intelligence reuse candidate. Its branch `dev/cresus-cloudflare-intelligence-bridge` has a Worker that rejects unauthenticated API calls via Cloudflare Access JWT validation and isolates conversations by email. Its `wrangler.toml` still has replacement Access domain/audience values. Provider-choice code and its regression tests must be reviewed and run before the Worker is accepted as a reusable core. The current branch is not a verified deployment.

## Release gates

AUTHORITY -> REFERENCE -> BASELINE/LKG -> IMPLEMENT -> VERIFY -> REGRESSION -> PACKAGE -> PACKAGE VERIFY -> PHYSICAL/DEPLOYMENT GATE -> PROMOTE.

A candidate manifest passing tests does not establish that a site is deployed or protected. Unknown gates stay UNKNOWN.
