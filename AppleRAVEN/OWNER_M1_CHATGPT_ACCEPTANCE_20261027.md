# AppleRAVEN — owner's first working prototype / acceptance contract

**User correction, 2026-10-27. Supersedes any suggestion that all Council variants, users, devices, AI providers, media or EDEN/BIFROST applications are prerequisites.**

## Mission
Deliver exactly ONE real AppleRAVEN private MCP service, usable **from the user's current ChatGPT conversation**, securely connected to the user's **MacBook Air M1**, on which an approved original Apple-native MCP / Shortcuts operation actually executes and returns results. AppleRAVEN is a dark Apple + raven private identity, **not** an EDEN-branded application and **not** dependent on BIFROST, HEIMDALL, ELYSIUM, RDC or a second Mac.

## Four different security subjects

1. **Infrastructure administrator (Cloudflare ravensnest)** — connected Cloudflare account used to provision and maintain separate AppleRAVEN edge, auth/data storage, HTTPS, monitoring, revocation and backups. Cloudflare's admin API session is NOT an AppleRAVEN owner OAuth access token and must not be reused to authenticate ChatGPT.
2. **AppleRAVEN owner (one person, one initial application user)** — authenticates using a trusted OAuth 2.1 authorization flow; app identity keyed by immutable provider subject/issuer, not an email alias. Initially ONE owner and ONE default personal profile; account access is explicitly granted, not silently imported from Cloudflare/Gmail/iCloud. Owner can enroll/revoke a device and configure approved capabilities after authentication.
3. **ChatGPT (first AI/MCP client)** — separately identifies as an OAuth client, obtains a resource-audience-bound owner-authorized token via authorization-code + PKCE S256, and calls HTTPS Streamable HTTP MCP. It is not another AppleRAVEN "user", owner account, Mac device or general model-provider API. External clients are NOT required for v0 acceptance. The private ChatGPT plugin/client requires the actual registered remote MCP URL and working OAuth; plugin packaging without functional endpoint is NOT acceptance.
4. **MacBook Air M1 (first paired device)** — separate local agent/device credential, pairing enrollment, online/offline reporting, local macOS privacy approvals (TCC), native Shortcuts/AppleScript/Photos/iCloud operations mediated by explicitly authorized existing MCP implementations. An authorized owner ≠ a paired device ≠ permission to every Mac application. Pairing does not require RDC or unfinished BIFROST.

## iCloud email aliases
- Use existing owner-controlled iCloud Mail alias addresses as **email contact/routing identifiers and recognizable profile/account labels**, when explicitly confirmed. An iCloud Mail alias is not a separate Apple Account or secure login by itself. It must never imply a different principal, grant, Apple ID session, keychain access or private folder.
- No unknown alias address invented; none provisioned in this release. Do NOT create multiple users, roles, identity realms or independent tenant backends as an MVP requirement. Expand to others only after this owner's M1 ↔ ChatGPT acceptance.

## Exactly necessary FIRST release gates
0. Cloudflare infrastructure: separate `ravensnest` Worker `appleraven-private` and D1 `appleraven-private` already EXIST, source-backed and checked. HTTPS `/health` live. `/mcp` currently refuses HTTP 503. D1 records zero users/devices/grants. Existing `OAUTH_KV` binding may exist, but **a KV binding does not prove that OAuth, owner login, tokens or client registration work**.
1. **Owner authorization:** integrate a proven spec-compliant OAuth provider (e.g. `@cloudflare/workers-oauth-provider` v1) with a real trusted identity provider, protected resource metadata, PKCE S256, consent, token signature/issuer/audience/scope checks, revocation and narrow `appleraven:read` scope. No fake signup, password, alias-as-login, anonymous tool, blanket admin session or credential in repo. This may require owner-controlled identity-provider OAuth registration/consent; mark unknown until done.
2. **MCP exposed:** the existing original Raven read-only `server/discover`, `tools/list`, tool invocation source is integrated AFTER owner auth, and ChatGPT can connect through its **actual** private MCP/plugin UI. No cross-profile inheritance.
3. **M1 device:** install the independently functioning Mac agent via supported installer/provider tool from canonical source (NO generic ZIP-as-product), enroll it using an authenticated one-time device grant, and verify an approved local Apple action (first read-only status or `shortcuts list`).
4. **End-to-end ACCEPTANCE:** from **this ChatGPT conversation**, real authenticated AppleRAVEN `tools/call` reaches user's MacBook Air M1 and returns an actual result, plus negative checks for unauthenticated calls, wrong owner, unpaired device, offline device, expired credentials, revoked grant. Logs/receipts separate cloud versus actual Mac. Preserve LKG and backups. ONLY THEN call AppleRAVEN first prototype working.

## Explicit out of scope until after first working result
Other Councils (LucasRAVEN, LucasPRO, LucasCUCKOO, BUZEK, THEMBI, SLINDOKUHLE), other users, other Macs/iPhones, other hosted AI providers, broader cloud storage/media, EDENOS/BIFROST unification, consumer multi-tenancy, universal portal. Their historical code remains useful reference/reuse only; preserving their independent original identity/source is required.

## Primary references
- OpenAI Plugin MCP OAuth contract: https://developers.openai.com/plugins/build/auth
- OpenAI Plugin connection tests: https://developers.openai.com/plugins/deploy/connect-chatgpt
- Cloudflare Workers OAuth Provider v1 (Oct 2026): https://developers.cloudflare.com/changelog/post/2026-10-01-workers-oauth-provider-1x/
- Apple iCloud Mail aliases: https://support.apple.com/en-gb/guide/icloud/mm6b1a490a/1.0
- Original Raven integration draft: https://github.com/lucasbuzek/Lucas-Private-edenOS-apps/pull/18
- Live provisioned health (NOT a live MCP): https://appleraven-private.lucasravensnest.workers.dev/health

## Evidence / protection
New account's D1 had ZERO users, devices and grants at latest provider read. No AppleRAVEN user silently inserted. The live Worker currently has DB and OAUTH_KV bindings and still advertises `mcp_locked`; merely having OAuth KV is NOT owner login. Never overwrite deployed Worker, historical original Raven Worker/Pages, Mac LKG or prior identity registry without source diff, rollback and positive acceptance. This note is a scope correction/acceptance contract, NOT functionality or deployment by itself.
