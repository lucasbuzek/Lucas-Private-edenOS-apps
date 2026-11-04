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

## Cloud-first installer and local-engine repair (same day)

- Fixed a reproducible first-run Python error in `mac/appleraven_agent.py`: `os.environ` was used before `import os`. Commit `3619cf255d9d4149d4c077982a6309df8854c8e0`.
- Fixed `Install-unified.command` so repeat installs restart the existing user LaunchAgent; without this, a live old process would keep running after updating the source. Commit `0937d0ae18e6900337661a6031ce0df24ade3156`.
- Extended the installed Mac agent with file metadata + SHA-256, owner-approved text write, folder creation, safe move, and detached/persistent Terminal job start/status/cancel. V8 static syntax parse completed, **Mac runtime untested**. Commit `8ed6cb35f17584c1ab230b7b97bc82332c8b6eb4`.
- Added explicit terminal opt-in for Mac Developer Bridge full-user-power tools; no automatic broad unlock. Each federated call retains the AppleRAVEN on-Mac approval dialog; operator can revoke provider unlock. Commit `6907f1c468ba597d8caabb2c83e4127560924490`.
- Added upstream `@heznpc/imcp@1.3.0 --full` for native Notes/Calendar/Mail/Messages/Music/Safari etc.; `apple-tools-mcp` via `uvx` (if installed; free Homebrew bootstrap), alongside mac-use-mcp and Apple Photos. Actual upstream readiness and schema registrations remain unverified until Mac enrollment. Commit `58119f14b4509a1618467af470a6b9462b18a400`.
- Cloudflare D1 independent recheck after the production deployments still returned active_devices=0, registered_tools=0, pending_jobs=0. Owner Mac login/pairing is the single missing physical dependency, not an Oracle requirement.
- Existing ChatGPT plugin `plugins_6ae05fb243a48191a7cd678e20ee608c` still points to production MCP, but its v0.1.3 descriptive metadata is outdated; do not represent it as upgraded or end-to-end callable.

### Current verification tier
- **Cloudflare production Workers:** deployed, 100% version rollout verified by Cloudflare API.
- **Cloudflare Pages:** preview alias successful by Cloudflare deployment API; direct external browser fetch not independently verified.
- **GitHub Mac agent:** modified and statically parsed; not executed under macOS.
- **First paired Mac + consent + live tool call:** not completed. Do not mark AppleRAVEN operational.

## Final installer/source verification addendum

- Repaired slow-provider startup: the native Mac tool catalog now registers immediately and the heartbeat/queue loop starts while optional upstream MCP servers initialize asynchronously; source commit `dc065a4025d51d4512a6660df1678b780dc99bb6`.
- Installer now installs matching free Homebrew Node.js 22 only if current Node is absent/outdated; confirms formula currently exists. It displays background-agent status after installation; source commits `9440fdf8bdbded83a5f0918fd2ae855c3aa0408d` and `99ffbe8142aa7390ce79fc3e945a366c22994056`.
- Pairing now attempts to open the existing Cloudflare owner page, with printed URL fallback if no GUI browser is available; source commit `029c6217e6247389722aedad36c806c64a62680b`.
- Latest source readback + independent syntax checks: `bash -n` both Mac installer and Pages bootstrap **PASS**; Python AST parse pairing agent **PASS**; Node ESM `--check` federated Mac agent **PASS**. No hidden inference of macOS native acceptance from these results.
- Existing production Cloudflare Workers and Pages remain as previously recorded. No additional cloud deployments were necessary for these dynamic GitHub-bootstrap Mac-script improvements.


## 2026-11-04 — Separate AppleRAVEN Secure MCP Tunnel origin

- Deployed Cloudflare Worker `appleraven-tunnel-origin` to the existing **ravensnest** Cloudflare account `d468143e61d414b11fed13f133732964`, preserving `appleraven-private`, `appleraven-device`, and their existing LKG deployments.
- Private MCP origin URL: `https://appleraven-tunnel-origin.lucasravensnest.workers.dev/mcp`; `workers.dev` route enabled and preview URLs disabled.
- Cloudflare bindings verified by API: existing D1 `DB`, KV `OAUTH_KV`, and encrypted `TUNNEL_ORIGIN_TOKEN` secret. **Never store or commit the secret in GitHub.**
- Separate sources added in the existing AppleRAVEN tree: `cloud/ravensnest/owner-mcp-tunnel.mjs`, `tunnel-origin.mjs`, and `tunnel-wrangler.candidate.jsonc`. Reused the existing owner pairing, device providers, cloud and iCloud federation modules without cloning their business logic.
- Standard stateless Streamable HTTP MCP routing added: `initialize`, `notifications/initialized`, `ping`, `tools/list`, `tools/call`, with preserved legacy method translation and backend owner grants. The `/mcp` route requires a strong bearer token. The older `/api/mcp` route remains behind existing owner authentication.
- **Browser-observed live selftest** at `https://appleraven-tunnel-origin.lucasravensnest.workers.dev/health/mcp` returned HTTP success with `{"mcp_compatible":true,"initialize_http":200,"tools_list_http":200,"tool_count":11,"version":"0.2.0"}`; DB-backed `/health` returned `database:true`.
- OpenAI tunnel-client supports origin header injection via `--mcp.extra-headers "Authorization: env:APPLERAVEN_ORIGIN_AUTH_HEADER"`. This allows **ChatGPT Connection: Tunnel, Authentication: No authentication** while the separate persistent tunnel-client inserts the securely stored upstream bearer token; do not disable origin authentication.
- **Not yet verified**: live OpenAI tunnel-client process, distinct AppleRAVEN tunnel ID, plugin installation into ChatGPT web/mobile, owner macOS pairing, full desktop execution, private cloud iCloud Drive/Photos source. These require the separately established tunnel runtime and connected sources. Do not represent the MCP smoke as evidence for native execution.


## 2026-11-04 — Canonical direct Cloudflare MCP (supersedes separate tunnel origin)

- **Current canonical ChatGPT remote MCP:** `https://appleraven-private.lucasravensnest.workers.dev/mcp`. Cloudflare Workers + Cloudflare Access OAuth DCR, owner-only. **No Oracle, AWS, OpenAI tunnel-client, browser extension or desktop bridge is required to host the connector.** Previous `appleraven-tunnel-origin` is NOT the selected ChatGPT target and should not be presented as a prerequisite.
- Updated the *existing* production `appleraven-private` Cloudflare Worker in place with `access-origin.mjs`, standard Streamable HTTP MCP `initialize`, `ping`, `notifications/initialized`, `tools/list`, `tools/call`. The underlying owner and device modules, D1 DB, KV and signed Cloudflare Access JWT verification were preserved. New deployment `596bc844-0f53-4832-bf35-5f1ba6ab7518`, version `aa73462e-b46a-4774-a8a2-17b9b00a7931` (Cloudflare API success/readback). Rollback version `1794bc2c-5db3-456c-b873-389ee807f9b4` retained.
- Existing private ChatGPT plugin `plugins_6ae05fb243a48191a7cd678e20ee608c`, version `0.1.3`, already references that endpoint and the existing Access OAuth DCR issuer. Do not create or rename a plugin.
- Cloudflare Access app `f1483df9-fc1f-4be5-80fe-c22c1c8c261f` remains restricted to `lucasbuzek@gmail.com`, DCR enabled, allowed ChatGPT OAuth redirect URIs retained. Browser GET to the registered `/mcp` is intercepted by the expected AppleRAVEN Access owner sign-in; this confirms a gate, **not** an authenticated MCP tool-call acceptance.
- Original private GitHub candidate branch updated in place: `AppleRAVEN/cloud/ravensnest/access-origin.mjs` and exported the existing signed Access verifier from `owner-mcp-v2.candidate.mjs`. No new repository or Project Bible created. Source commit `95a0d0ff5e0a4cc54632479d988cf9c7f6bc523b` reflects both files.
- Cloudflare Pages owner installer `https://appleravenmcp.ravensnest.pages.dev/` was observed live in the authorized browser, with both Mac download and owner pairing links. Existing Mac Agent source was staged on connected Apple Silicon Mac (`Lucas-MacBook.local`, macOS 27.0.1) using the owner's private GitHub credential; owner-authenticated pairing has been initiated, **approval is pending**. No native Mac call from ChatGPT is yet verified.
- Acceptance remains: owner approves one-time pairing; Mac agent LaunchAgent starts; real device and provider tools appear; ChatGPT OAuth connects and calls at least status and an owner-approved native tool. Until then do not claim end-to-end completion.


## 2026-11-04 — Verified Mac owner pairing and native federation acceptance

- Device `Lucas-MacBook.local` (Apple Silicon, macOS 27.0.1, local user `lucas`) enrolled through the existing Cloudflare device Worker and original owner pairing portal, with one-time code approved through owner sign-in. Its device credential was stored in the user's macOS login Keychain; no credential contents were exported to GitHub or Cloudflare configuration.
- Reproduced and fixed a real native Keychain ACL issue: the separate `/usr/bin/security -w` executable timed out when reading a credential created by Python Security.framework. Both canonical `mac/appleraven_agent.py` and `mac/appleraven_unified_agent.mjs` now use the same Keychain-aware Python helper. Read-only `--status` test returned `device_credential_present: true` and Node syntax check passed on the real Mac.
- Reproduced and fixed a shell quoting bug in `mac/Install-unified.command` (apostrophe in an embedded single-quoted JS comment). Fresh `bash -n` passed on the Mac. Added a backward-compatible option to defer large optional Python-provider downloads while the native agent starts; installed `pyapple-mcp==1.6.1` independently with the existing `uv` tool, 76 packages, successful receipt.
- The owner's requested `@joshuarileydev/mac-apps-launcher-mcp-server@0.0.1` has a broken published `bin` path (`dist/index.js` vs `dist/src/index.js`) and shell interpolation of user-controlled app/file names. Added canonical `mac/patch-launcher.mjs` to verify exact npm version, use the working entrypoint, replace shell calls with argument-vector `execFile`, validate installed app names and absolute paths, and migrate the private provider registry. Patched local module passed Node syntax check; do not treat upstream package alone as deploy-ready.
- On the real Mac, persistent LaunchAgent `com.lucasbuzek.appleraven.unified` was installed and launched; `launchctl` reported loaded, active process parent PID 1, and local Mac status succeeded. `Mac Developer Bridge` full-access provider was left **disabled**, pending separate owner decision. Manual duplicate test agent was terminated after LaunchAgent startup.
- Real native log verified connected providers: `macui` (18), `applaunch` (3), `imcp` (123), `photos` (21), `appletools` (184), `pyapple` (10). Native federation reported **373** catalog tools after de-duplication/validation. Independent Cloudflare D1 readback returned `373` `appleraven_provider_tools` rows and a recent heartbeat for the paired device. These are *registered callable definitions*, not proof that every macOS TCC permission is granted.
- Unused `appleraven-tunnel-origin` Worker URL was disabled through Cloudflare workers.dev subdomain settings (`enabled:false, previews_enabled:false`) without deleting its retained deployment or impacting `appleraven-private`/`appleraven-device`. It is not a ChatGPT prerequisite.
- **Still outstanding end-to-end:** install existing private plugin in owner's ChatGPT account, complete ChatGPT-to-Cloudflare Access OAuth DCR, verify live `initialize` + `tools/list` + `appleraven.owner.status`, then issue an owner-approved native tool call from ChatGPT web and mobile. No unauthorized Mac write or message-send was attempted. Do not label that last client roundtrip accepted until its actual tool receipt is observed.


## 2026-11-04 — Owner control, branded node and Claude OAuth compatibility

- Real Mac LaunchAgent executable switched to stable symlink `/Users/lucas/Library/Application Support/AppleRAVEN/Unified/AppleRAVENnode` → the existing Homebrew Node runtime. `launchctl` reported `state = running` and `program = .../AppleRAVENnode`; `ps` showed that exact executable name. Canonical `mac/Install-unified.command` now creates/uses this branded alias on fresh installs. Source commit `481d7064d99b80a38d136998b2ea6633966a7712`.
- Existing Cloudflare `appleraven-private` Worker now serves an owner-authenticated dashboard at `/manage`, with one-time pairing shortcut, devices/online status, tool counts, per-device `tools.proxy` and `shortcuts.list` grant enable/disable, explicit-confirmation device revocation, sanitized recent action status and pairing events, and secure MCP URL plus client compatibility notices. New source module `cloud/ravensnest/owner-manage-addon.mjs` is imported by the existing `owner-mcp-v2.candidate.mjs`—**not** a new Worker, app or plugin. Owner audit table `appleraven_owner_audit` created in existing D1. All dashboard APIs independently verify signed Cloudflare Access owner identity, reject cross-origin writes and require a deliberate owner action. Root and browser Accept-html `/health` requests route to `/manage`, preserving JSON health response for API clients.
- Cloudflare Worker deployment receipt `54b62b2a301e4485b9e1070a80375df7` at `2026-11-04T05:47:15.456078Z`; retained previous deployments allow rollback. Staged module/browser JS syntax checks passed. External unauthenticated GET to `/manage` returned Cloudflare Access HTTP 401, and browser Accept-html GET returned HTTP 302 to the owner login. This is a **negative security acceptance**, not a logged-in dashboard UI acceptance.
- Cloudflare Access managed-OAuth dynamic client registration retains the original ChatGPT redirect allowlist and now includes ONLY the verified Anthropic callback `https://claude.ai/api/mcp/auth_callback`, so Claude can attempt its own owner OAuth handshake. No wildcard, new token, other email, service key, or paid subscription was added. Client-side authorization in Claude remains unverified.
- Post-change Mac readback: `AppleRAVEN unified catalog ready: 373 tools` for 6 connected third-party native source providers plus 17 direct native tools, and an independent Cloudflare D1 query showed 373 tool rows and current heartbeat. Service/registration remain live after the process branding change.
- The existing personal plugin `plugins_6ae05fb243a48191a7cd678e20ee608c` is still v0.1.3 and its web detail page displays `Open in desktop app` with stale pre-pairing text. The remote MCP URL is correctly declared in its manifests, **but** no verified ChatGPT web/mobile tool call exists. This ChatGPT-host presentation cannot be repaired through Cloudflare deployment alone. The account plugin editor available here requires a new ZIP upload; its local staging environment was explicitly read-only, and the signed-in ChatGPT browser page was blocked by host policy. No duplicate plugin was created or claimed installed.
- ChatGPT Help Center currently states directly connected *custom MCP servers* are web-only, not mobile. Claude.ai/Claude mobile support remote MCP connectors after account-side connection; Google Gemini API/Antigravity support remote MCP but their auth/client flows differ; direct Meta AI consumer app custom MCP support was not verified. Each client remains individually pending authentic provider-side installation and authorization.
- Next acceptance for owner: authenticate to `https://appleraven-private.lucasravensnest.workers.dev/manage`; verify real dashboard behavior and a controlled permission change. Complete existing ChatGPT plugin connection through an eligible remote MCP installation route, then test authenticated `initialize`, `tools/list`, `owner.status` and one native tool call; repeat for Claude. No claim of full end-to-end ChatGPT or cross-provider completion until receipts exist.
