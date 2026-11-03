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
