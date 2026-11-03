# AppleRAVEN — Cloudflare-first cloud deployment receipt (2026-11-03)

Mission correction: AppleRAVEN replaces inadequate Remote Desktop Commander with full, owner-authorized native task execution through existing upstream Apple MCP engines. Cloudflare Workers + the existing private ChatGPT plugin + Mac agent are the primary system. Oracle, Docker and RDC are NOT prerequisites; a native .app/DMG is optional.

## Live Cloudflare API receipts

- RAVENsNEST account (owner profile lucasravensnest@gmail.com), account ID d468143e61d414b11fed13f133732964.
- Unified staging Workers enabled and source bundles refreshed from the candidate branch: `appleraven-unified-staging` and `appleraven-device-unified-staging`, compiled and uploaded successfully on 2026-11-03.
- Existing production Worker `appleraven-device` deployed new module bundle 2026-11-03T14:44:20Z; deployment `99d0489b-8984-4ef7-ac8c-af174bd27111`; version `50f4236d-65a7-48fd-82c1-7dda36b6654e`.
- Existing production Worker `appleraven-private` deployed new module bundle 2026-11-03T14:44:23Z; deployment `aced9116-4aee-4174-b618-8811df4be8f0`; version `1794bc2c-5db3-456c-b873-389ee807f9b4`.
- Original production Worker names, domains, D1 and KV bindings remain unchanged; both uploads returned success via Cloudflare API.
- Preserved previous production versions for rollback:
  - `appleraven-device` version `6c3efb8d-8511-46a2-9bd0-4a905aa68e8b` (deployment `cf07f22c-0800-4dfb-9973-5957a24137df`).
  - `appleraven-private` version `2cbe574d-f13e-45f8-b750-4c2061c7a413` (deployment `b8fdb14a-0702-4c7f-8713-8b4f47f4833e`).
- Existing Cloudflare Access app `AppleRAVEN owner MCP` preserved; domain `appleraven-private.lucasravensnest.workers.dev`, audience `90f75e8cdcaa800f4dc2e2c08664ccdd16c1cff1116d0c18400b82be783b1be2`; owner-only allow policy for `lucasbuzek@gmail.com` verified. No credential content retrieved or changed.
- D1 read on 2026-11-03: active devices 0, provider tools 0, proxy commands 0. This proves that no native Mac operation occurred yet, not that backend is unavailable.

## Pages deployment

- The exact target's authoritative Pages project `ravensnest` is on the Primary RAVENnest account (lucasbuzek@gmail.com), account ID `6f3621435947217e678093872d37048c`.
- Preview deployment `da4a7376-ff1f-489b-8bff-a1abd43791fa` on branch `appleravenMCP` created by the Cloudflare Pages API; GET readback showed deploy success and alias `https://appleravenmcp.ravensnest.pages.dev`. This preserved existing `ravensnest.pages.dev` production.
- Hosted content is the GitHub candidate's `web/installer/index.html` and `bootstrap.command`, embedded in a Pages advanced-mode `_worker.js` handler. The bootstrap now launches the Mac installer directly, without Oracle or Docker.
- Cloudflare API confirms publication; external HTTP/browser content checks were unavailable from the current execution environment due to host egress restrictions. Do NOT claim public browser acceptance.

## ChatGPT identity and device agent

- Existing private Plugin Creator identity: `plugins_6ae05fb243a48191a7cd678e20ee608c`, version 0.1.3, points at the preserved production `https://appleraven-private.lucasravensnest.workers.dev/mcp`. No new plugin was created and the old package was not updated.
- Mac scripts updated on this candidate branch to use the same production Cloudflare device ingress by default, with `APPLERAVEN_DEVICE_ENDPOINT` override for staging. Owner pairing remains the only path to a device credential (macOS Keychain).
- First M1 installer run, native TCC permissions, pairing, OAuth ChatGPT call, source-provider invocation, file/screenshot transfer, multi-step job execution and offline/reconnect are STILL UNVERIFIED. Web/iOS functionality must be independently accepted.

## Next acceptance sequence

1. Open the Pages installer in a normal owner browser and verify the page, download and owner sign-in link.
2. Run the Mac installer ON RavenAirM1, complete Cloudflare owner approval, grant macOS native permissions and register real provider schemas.
3. Confirm live D1 devices/provider-tools counts and an approved ChatGPT MCP call through the original plugin identity. Check negative, revoke and offline cases.
4. Finish installed-provider coverage and task/job/file streaming tests; then update the original plugin package in place only when new tool discovery and owner auth are confirmed.
5. Preserve previous Worker deployment versions and original LKG; do not mark full release accepted before physical end-to-end receipts.
