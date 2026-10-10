# Lucas Raven authenticated enrollment — implementation contract
Status: DESIGN VERIFIED AGAINST CURRENT EDGE; NOT IMPLEMENTED
Date: 2026-10-08
Governor: ForgeMASTER; BIFROST owns connection/capability resolution.

## Recovered baseline
- CRESUS-PWA uses Cloudflare Access for approved-email web login.
- Raven Pages API currently uses one operator bearer credential and one Mac node credential, stored as SHA-256 hashes at the edge. This is single-operator compatibility mode, NOT per-user authentication.
- BIFROST ZERO closed testing begins with five users; no application-enforced five-user cap.
- Each user may enroll multiple devices and multiple independently authenticated accounts per provider.
- Codex Cloud, Claude and ChatGPT account integrations must use supported authentication surfaces, not assume consumer web login grants API access.
- Paid AI, IAP and organizational billing belong to later distribution profiles; recover HERMES/CRESUS contracts before implementation.

## Target identity model
User (stable subject from verified identity assertion) -> membership/role -> device grants -> provider-account connections -> bounded capability grants -> action/audit.
Users, devices, provider accounts and grants are many-to-many. Provider accounts are isolated by owner and storage namespace; do not overwrite an existing provider login.
Device identity is independent of a user's browser session; each enrolled node has its own credential and revocation state.
Use a server-verified Cloudflare Access JWT with audience/issuer validation for web requests; NEVER trust client-supplied email or unverified CF-Access headers.
Use explicit Access policy for the human portal; the outbound bridge must retain separately authenticated machine-only API access, with an appropriate service policy/route so Access cannot accidentally block it.
Authorize every action on the server by verified subject, node, capability, and grant. Filter state and action history by authorization. Audit subject and node without storing raw credentials.
One-time enrollment challenge is short-lived, single-use, device-bound, and completed only after explicit approval. Never expose enrollment secrets in URL query strings, logs, commits or browser bundles.
Revocation terminates affected sessions/grants; unrelated users and devices remain functional.

## Migration and verification gates
1. Capture the current Pages/Access configuration and D1 schema, without printing secrets.
2. Establish separate machine API Access route/policy; prove existing bridge connectivity survives Access enablement.
3. Add additive D1 users, memberships, devices, grants, provider-account references and audit records. No destructive rewrite of existing node_state/actions.
4. Implement JWT verification and user-specific authorization behind an opt-in test path, retaining legacy operator mode only for existing private testing.
5. Implement device enrollment/revocation and browser sign-in/out, then migrate the Mac node.
6. Verify two independent test identities cannot read/control one another's nodes, including direct API requests; verify node A cannot claim/complete node B actions.
7. Verify browser + Mac + iPhone end-to-end; only then retire shared operator key and promote.
8. Implement Windows credential/service adapter and clean installer; verify on actual Windows.
9. Integrate supported multi-account provider adapters and recover commercial entitlement contracts.

Evidence ladder: source changed -> unit tested -> edge deployed -> authenticated E2E -> physical verified. Do not promote across missing gates.

## Gate evidence update — 2026-10-08 edge candidate
- Gate 1: UNKNOWN for current Cloudflare state; no remote access was attempted.
- Gate 2: GENERATED instructions only; the narrow `/api/node/*` bypass requires Lucas and is not verified.
- Gate 3: IMPLEMENTED and TESTED offline (additive/idempotent SQL); remote D1 is UNKNOWN.
- Gate 4: IMPLEMENTED and TESTED offline for cryptographic JWT rejection cases and legacy node isolation. Full authorization integration remains IMPLEMENTED, with physical/remote verification UNKNOWN.
- Gate 5: IMPLEMENTED; enrollment/revocation and browser sign-in are not remotely or physically verified.
- Gate 6: partial TESTED offline only. JWT and node identity isolation have automated coverage; full two-user D1 integration is deferred and must not be treated as PASS.
- Gates 7–9: UNKNOWN / not performed.
