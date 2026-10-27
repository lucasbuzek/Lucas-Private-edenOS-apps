# AppleRAVEN — hosting and remote MCP architecture decision
Research date: 2026-10-27 | Scope: Lucas-private AppleRAVEN, **not EDEN** | Stage: RESEARCHED, NOT DEPLOYED

## Decision
Host AppleRAVEN's user-authenticated remote MCP **gateway** in the existing *ravensnest* Cloudflare account, initially at a named workers.dev endpoint (proposed `https://appleraven.lucasravensnest.workers.dev/mcp`, **NOT LIVE**). Keep Apple-native operations on an authorized, separately installed Mac agent and expose them through an outbound connection. Retain optional local/offline stdio MCP mode and Bonjour/mDNS LAN discovery. Neither BIFROST nor RDC is an installation dependency.

## Verified Cloudflare inventory 2026-10-27 (authenticated, read-only)
- *ravensnest*: Workers subdomain `lucasravensnest`, existing Worker `publisher-preview-candidate`, no registered Cloudflare Tunnels, no managed zones/domains. Access API returned HTTP 403 `access.api.error.not_enabled`. **Do not claim Access protection exists.**
- *primary*: Workers subdomain `lucasbuzek`, seven Workers including `raven-cloud-node`, no registered Cloudflare Tunnels or managed domains. Cloudflare Access applications already exist for unrelated apps. Existing `raven-cloud-node` deployed 2026-10-10 with D1 binding; its script exposes AI inference features but no MCP `/mcp` endpoint, persistent paired Mac agent or AppleRAVEN transport. **Preserve it untouched; name is not proof of compatibility.**
- No AppleRAVEN Worker, OAuth application, registered hostname or connected Mac agent was found/created in this research.

## Required components and connection
1. **Remote MCP resource server**: Cloudflare Worker, standard *stateless Streamable HTTP* `/mcp`, `createMcpHandler` / current MCP SDK. Not the deprecated SSE-only `McpAgent` for new deployments.
2. **Authorization server**: Cloudflare Workers OAuth Provider v1 (Oct 2026) with OAuth 2.1 / MCP 2026-07-28 support, GitHub or Google owner login, owner identity allowlist, user+client+device scopes, token audience validation, revocation, consent. No `ravensnest` Cloudflare Access prerequisite; Access managed OAuth is an *alternative* after separately enabling it, not assumed today. ChatGPT does not accept arbitrary bearer-key sign-in in place of OAuth.
3. **Device relay/presence**: Cloudflare Durable Objects with *incoming hibernatable WebSocket* from each Mac agent, per-device registration, presence, request IDs, expiry, command timeouts, replay protection and rejection when disconnected. Register no unapproved devices. Initial lightweight deployment can use Cloudflare Tunnel to a local origin but depends on an awake Mac and has a domain prerequisite for stable public tunnel hostname.
4. **Native Mac agent**: separately install a signed/notarized native helper or approved package-manager CLI on user's M1/M3; authenticate by browser-based one-time pairing, store per-device credentials in Keychain, run as explicit launchd user agent, offer stop/revoke; invoke preinstalled licensed existing MCPs and native Apple Shortcuts, AppleScript, Photos, iCloud File Provider, Messages with per-domain macOS TCC consent. mDNS/Bonjour is LAN discovery, not Internet transport or remote authorization.
5. **Storage**: DO state or separate D1 (per account) for pairing metadata, user/client IDs, expiration, grants and audit *metadata*; avoid copying iMessage, photos, Apple credentials or entire files into the cloud. Use Cloudflare Worker encrypted Secrets for server signing keys, not GitHub files, logs or plaintext vars. Full payload retention OFF by default.
6. **AI clients**: ChatGPT private plugin, Codex, Claude, Gemini CLI, Cursor, VS Code etc register the same OAuth-protected Streamable HTTP endpoint according to *each client's* MCP capabilities. Client registration != model API login. Avoid one pooled identity or cross-provider unrestricted privileges.
7. **Offline**: Mac agent and installed local donor MCP remain usable offline; cloud endpoint remains reachable but marks disconnected Mac UNAVAILABLE. Never queue irreversible actions offline without separate owner confirmation.

## Compared hosting options (2026-10-27)
| Option | Remote client endpoint | Mac awake? | Authentication work | Cost/assessment |
| --- | --- | --- | --- | --- |
| Cloudflare Worker + OAuth + DO relay (recommended) | Stable workers.dev HTTPS | Only for native execution | OAuth 2.1 + device pairing | Workers Free and DO Free viable at small scale subject to 100,000 Worker requests/day and 10ms CPU cap; Paid starts $5/mo if usage or CPU needs exceed; separate AI model API billing |
| Cloudflare Tunnel directly to Mac MCP | Requires public hostname/domain route | Yes | Need full MCP OAuth independently | No extra VPS; current ravensnest account has no Cloudflare zone/domain; simpler proof-of-concept, not reliable multi-device cloud control |
| Tailscale Funnel / Serve | Funnel public HTTPS / Serve tailnet-only | Yes | Funnel is public; MCP OAuth still necessary | Lower setup for private testing; no independent cloud availability; Funnel beta and host restrictions |
| VPS (Hetzner/DigitalOcean/etc) | User-managed HTTPS host | Only for native actions | Must maintain TLS, OAuth, patching, backups, relay security | Additional recurring cost/admin, no advantage at current scope |
| Render free web service | HTTPS but spins down after idle | Only for native actions | MCP OAuth still required | Idle spin-down (~15min) disrupts persistent relay; unsuitable |
| ChatGPT Secure MCP Tunnel | ChatGPT-specific private connector | Yes when local | Host-specific linking | Useful test route, NOT universal Claude/Gemini/other provider host |
| Pure local stdio server | None for remote web/mobile | Yes | Local host configuration | Good offline fallback only, not remote AppleRAVEN |

## Security / implementation gates (all NOT YET PASSED)
- Confirm owner-approved `ravensnest` account for a new *separate* Worker, without overwriting `publisher-preview-candidate`.
- Establish OAuth client with GitHub/Google and protect-resource metadata; test unauthorized / expired / wrong-audience / wrong-scope and cross-client denial.
- Create stateless MCP `/mcp` with `tools/list` and a harmless device status tool; invoke from a *real external client*.
- Run independent Mac agent using already-existing verified MCP implementations; explicit pairing and grants. Verify approved native read and explicit write with TCC checks.
- Test M1/M3 online, asleep and offline behavior; device isolation, token revocation, audit metadata, idempotency, undo and no-cross-tenant behavior.
- Apply low-cost quota budgets before any paid hosting; preserve prior Git branch, Bible and physical LKG. No unapproved upload of private library content.
- Sync actual agent+gateway source to original GitHub candidate with verified commit and tests. Source adapters already staged in `candidate/appleraven-service-20261027` do not alone constitute a deployed service.

## Direct source references
- https://developers.cloudflare.com/agents/model-context-protocol/guides/remote-mcp-server/
- https://developers.cloudflare.com/agents/model-context-protocol/protocol/transport/
- https://developers.cloudflare.com/changelog/post/2026-10-01-workers-oauth-provider-1x/
- https://developers.cloudflare.com/durable-objects/best-practices/websockets/
- https://developers.cloudflare.com/workers/platform/pricing/
- https://developers.cloudflare.com/workers/configuration/secrets/
- https://developers.cloudflare.com/tunnel/get-started/
- https://developers.openai.com/plugins/build/auth
- https://developers.openai.com/plugins/deploy/connect-chatgpt
- https://github.com/desktop-commander/remote-desktop-commander/blob/main/docs/SETUP.md
- https://tailscale.com/docs/features/tailscale-funnel

**Evidence classification:** Cloudflare account inventory READ/VERIFIED 2026-10-27; original vendor documentation SOURCE READ; architectural design RECOMMENDED; no Worker writes, domain registrations, OAuth account mutations or local installs.
