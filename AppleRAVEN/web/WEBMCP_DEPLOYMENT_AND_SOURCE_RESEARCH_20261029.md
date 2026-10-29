# AppleRAVEN — source-grounded WebMCP acceptance receipt (29 Oct 2026)

## Locked mission and boundaries
AppleRAVEN REPLACES Remote Desktop Commander; it is an independent owner-private Cloudflare remote MCP + native MacBook Air M1 agent, with the SAME existing ChatGPT plugin ID. RAVENsNEST is the approved Cloudflare account. Browser WebMCP is an optional browser-local interface, not a Mac connection or replacement for authenticated remote MCP. The ELYSIUM task demonstration is isolated from the autonomous ELYSIUM app and uses only browser localStorage.

## Archive recovery and source provenance (bounded)
User Dropbox share `/EDEN-lucas-family/AI MCP tool` was verified through connected Dropbox metadata as a public, edit-capable link. The `#appleOS` folder contains 104 .webarchive pages (direct child listing complete) and `#webMCP` contains 37 .webarchive pages and four JPEGs (listing complete). Top-level direct listing has 355 webarchives and 413 entries. A recursive scan returned 600 entries and `has_more=true`; the 600 result was PARTIAL and is not the size of the whole folder. Original webarchive binary bodies were not decoded; the downloaded first sample failed DNS in the working container. Filenames represent research leads, not source content acceptance. Connected Dropbox screenshots were exposed through file-preview cards; thumbnail preview is not a full visual inspection.
**Security flag:** public EDIT link currently includes nested Chromium browser-profile files named Cookies, Login Data and Network Persistent State. Do not copy, index, quote or deploy these; their sharing permissions warrant owner review.

Relevant actual upstream pages independently checked:
- Google Chrome WebMCP imperative API (updated 16 Oct 2026): https://developer.chrome.com/docs/ai/webmcp/imperative-api
- Chrome's agentic JavaScript tools guidance: https://developer.chrome.com/docs/modern-web-guidance/guides/webmcp/agentic-javascript-tools
- Cloudflare securing MCP servers (last updated 27 Oct 2026): https://developers.cloudflare.com/agents/model-context-protocol/guides/securing-mcp-server/
- Apple Developer ID/notarization: https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution
- Original previously examined Mac-side references preserved in existing `AppleRAVEN/docs/APPLE_MCP_CANDIDATES_PYAPPLE_QRING_SERVEMYAPI_SHADOWCURSOR_20261028.md` and `AppleRAVEN/docs/WEBSITE_RESEARCH_AND_M1_GATES_20261027.md`.

The Chrome documentation uses **`document.modelContext.registerTool`**. Older `navigator.modelContext` examples are superseded. WebMCP may require an eligible Chromium build/flag; it is not universally supported by ChatGPT iOS or arbitrary browsers.

## Actual code, tests and Cloudflare deployment
- Existing protected branch: `candidate/appleraven-native-dmg-elysium-proof-20261028`. No main/LKG overwrite.
- File: `AppleRAVEN/web/elysium-demo-webmcp.js` — 3057-byte source, GitHub blob `e608d9ed46d951b8c2840262dedb0b0cd8cf5725`, commit `f5b92d961eb9467af43471e9b7e9484e28f10320`.
- Two same-origin browser-local tools:
  - `elysium_demo_list_tasks` lists samples in one of Personal, Business, Organization.
  - `elysium_demo_add_task` submits the existing visible task form, preserving UI behavior and demo workspace separation.
- Isolated JS mock/DOM tests: **six checks passed**, including tool registration, read, add, workspace isolation, rejection of empty task, rejection of unknown workspace. No browser agent acceptance test performed.
- Deployed to the **existing** standalone `appleraven-onboarding` Worker, using Cloudflare provider API PUT HTTP 200/success on 29 Oct. Existing Worker source preflight matched 9564 module-source bytes; updated source 12696 bytes. No owner/device Worker code was modified. New deployment readback: `94cf8cdf-1c98-4d4b-a623-0f0db911f094` created 2026-10-29T07:36:40Z. Previous deployment `ac1cdc8b-7bda-4a9d-b672-74c561e81ecf` retained in Cloudflare for rollback.
- Provider GET content/v2 after deploy: HTTP 200, both browser tool names and `document.modelContext` present, original private owner /pair link present, BROWSER-LOCAL ONLY notice present, `workers.dev` subdomain enabled, Worker bindings remain empty.
- Intended URL: https://appleraven-onboarding.lucasravensnest.workers.dev/ . Independent external HTTP/browser fetch was unavailable in this session; rendering and real browser-side WebMCP discovery are not VERIFIED.
- Private plugin remains original exact ID `plugins_6ae05fb243a48191a7cd678e20ee608c`, v0.1.2, release `pluginrel_6ae17a8981848191b5bd968b98923b06`, preserved OAuth /mcp host.

## Remaining acceptance gates
1. Build AppleRAVEN.app and real UDIF DMG on macOS; GitHub Actions workflow creation from this tool was blocked, no test DMG binary or notarized release claimed.
2. Sign using a valid Apple Developer ID and submit for notarization as required for trusted distribution. No unauthorized paid service or certificate creation.
3. Local user executes installer on real M1, owner performs OAuth and one-time pairing; cloud D1 must contain a genuine paired/granted device and heartbeat.
4. Current supported ChatGPT plugin must make an **authenticated** MCP tool call that causes an approved native Mac action and receives the true result. Verify negative revoked/offline/wrong owner tests.
5. Test the new browser-local WebMCP tools in an actual supported Chromium environment. ELYSIUM browser tasks must remain independent of actual ELYSIUM production.
6. Review/restrict risky Dropbox public EDIT sharing and browser-profile exposure by the Dropbox owner. No automatic permission changes performed.

**No part of this receipt treats RDC/Tailscale/BIFROST as an AppleRAVEN prerequisite.**
