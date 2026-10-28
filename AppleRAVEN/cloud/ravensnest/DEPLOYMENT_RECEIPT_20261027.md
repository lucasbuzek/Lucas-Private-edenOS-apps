# AppleRAVEN — actual separate Cloudflare account provisioning receipt (2026-10-27)

## Identity and scope
- Cloudflare connected account: **ravensnest** (`lucasravensnest@gmail.com`), account ID `d468143e61d414b11fed13f133732964`.
- Original primary-account `raven-cloud-node` and `lucas-raven` Pages production deployment: **NOT MODIFIED**.
- Existing ravensnest `publisher-preview-candidate` Worker: **NOT MODIFIED**.
- AppleRAVEN is Lucas-private dark Apple/Raven, NOT an official EDEN-branded product; one reusable runtime with separately authorized profiles.

## Actual provider resources created (not speculative)
- D1 database `appleraven-private`, UUID `740671f7-8671-44b3-83bb-69572ffc7d28`. Created in this account; not a copy of original primary-account private records.
- Original Raven Pages `schema.sql` applied directly from private GitHub `bifrost/cloud-ai-provider-20261009`, blob `b07c004d1ce7f2107117f08ef31186d32bcee72c`; Cloudflare D1 API reported 17 successful statements. Tables read back: `actions`, `audit`, `chat_audit`, `chat_daily`, `chat_user_minute`, `device_enrollments`, `devices`, `grants`, `node_state`, `users` (plus Cloudflare internal `_cf_KV`). Counts 0 users / 0 devices / 0 grants / 0 actions.
- New Worker `appleraven-private` uploaded/deployed in ravensnest. Worker source private GitHub `AppleRAVEN/cloud/ravensnest/worker.mjs`, blob `ef288f22eb0739a11bb81c67b5b566cced69fc8a`. Account-specific config `AppleRAVEN/cloud/ravensnest/wrangler.jsonc`, blob `be76be5a86c8923f351104ca163b5633ad489726`. Verified live Worker binding `DB` is type `d1` pointing exactly to database UUID above.
- Cloudflare deployment UUID `6a0e8b17-5003-4c57-bb70-763aa53beae5`, version UUID `47c342e9-1e6a-4de5-bf36-6008185333f6`, 100% deployed. Date shown by Cloudflare `2026-10-27T06:55:24.185356Z`.
- workers.dev route `appleraven-private.lucasravensnest.workers.dev` enabled, preview URLs disabled. Exact externally verified GET `https://appleraven-private.lucasravensnest.workers.dev/health`: JSON `{"service":"AppleRAVEN","environment":"ravensnest","stage":"account_provisioned","transport":"mcp_locked","protocol_target":"2026-07-28","identity":"not_configured","mac_agent":"not_paired"}`. Externally verified GET `/mcp` returned HTTP **503**.
- Isolated source checks: 7/7 PASS (health with/without DB, GET/POST MCP deny, admin deny, unknown path deny); external health and negative MCP check PASS. No credentials or private file data transferred.

## Mandatory deployment boundary
**Provisioned LIVE HTTPS infrastructure IS NOT a functional AppleRAVEN remote MCP.** Worker intentionally denies all `/mcp`, `/api/mcp` and `/api/*` calls until proper identity authorization is established; anonymous health is metadata-only. No OAuth server, login, AI client, paired Mac, native Apple capability, TCC approval, Tailscale relation, AI provider account/session or paid API invocation has been configured. Cloudflare Access was previously not enabled in ravensnest. Do not treat `account_provisioned` health as device online or MCP operational.

## Next deployment gates
1. Recover owner-approved original Raven/CROWnest device/identity contracts and exact local LKG; reuse original Cloudflare Access/Pages logic where suitable, without creating a competing user model.
2. Implement and authorize MCP-compliant OAuth 2.1 with separate user/client/profile/device scopes. Verified owner sign-in and token revocation must precede accepting remote MCP calls. Do not authorize a consumer login by assuming an API key; do not silently enable cross-tenant access.
3. Integrate approved original Raven Pages MCP route from draft PR #18, built against complete original API and original D1 schema, after auth and grant isolation tests.
4. Install paired Mac agent independently of RDC/BIFROST using proven Apple MCPs and native permissions; run real ChatGPT/Claude/etc remote client calls to permitted target actions.
5. Retain original Cloudflare Workers/Pages and historical Git branch, no overwrite. Review quota/billing before exceeding free allowances.

**Release stage:** ACCOUNT PROVISIONED; SOURCE READBACK VERIFIED; PUBLIC HEALTH LIVE; MCP LOCKED; PRODUCT INCOMPLETE.
