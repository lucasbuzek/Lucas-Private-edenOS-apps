# AppleRAVEN — ORIGINAL WebArchive content recovery · 2026-10-29

## SNOOPY verified correction
The prior AppleRAVEN response mistakenly presented the existing RAVENsNEST Cloudflare MCP as "the most suitable working route". **It is NOT FUNCTIONAL by the end-to-end user acceptance criterion**: no owner-authenticated real ChatGPT → Mac native action was verified and Cloudflare D1 last returned 0 users / devices / grants / actions / pairing challenges. Deployment and synthetic tests do not constitute a working device MCP. Do not route user through broken/unfinished Cloudflare as a mandatory dependency. RDC must be REPLACED, never revived as a prerequisite.

## ACTUAL source acquisition
The saved Apple `.webarchive` binaries are accessible through **ChatGPT Files raw materialization** using external Dropbox library IDs of the form `external-dropbox:file:id:<DropboxID>`. This corrects earlier declarations that binary extraction was impossible. Python `plistlib.loads` successfully decoded 21 genuine Apple WebArchives. Their `WebMainResource.WebResourceURL`, embedded HTML, title, text and upstream links were read—not guessed from filenames. Main HTML content was analyzed with BeautifulSoup. The selected collection inventory totals 498 archived webpages; **21 original archive bodies recovered, 477 not yet decoded**. This is **PARTIAL_RESEARCH**, not completion of all archives.
Archive source: user's Dropbox shared folder `/EDEN-lucas-family/AI MCP tool`, including `#appleOS`, `#webMCP` and root. Any historic install-invite/session query strings embedded in archived HTML must be treated as private data; none are copied here.

## Original, successfully decoded source URLs
- DeviceLink - Share a folder with ChatGPT or Claude: https://api.devicelink.ai/
- macos-agent-bridge by juliusloon: https://glama.ai/mcp/servers/juliusloon/macos-agent-bridge
- Macbeth MCP Server: https://mcpservers.org/servers/wende/macbeth
- ToolPiper MCP Server: https://mcpservers.org/servers/modelpiper/toolpiper
- macos-mcp by CursorTouch: https://glama.ai/mcp/servers/CursorTouch/MacOS-MCP
- mcp-remote-macos-use by baryhuang: https://glama.ai/mcp/servers/baryhuang/mcp-remote-macos-use
- Apple Shortcuts Server by recursechat: https://glama.ai/mcp/servers/recursechat/mcp-server-apple-shortcuts
- PyApple Tools MCP Server: https://mcpservers.org/servers/54yyyu/pyapple-mcp
- WebMCP · Cloudflare Browser Run: https://developers.cloudflare.com/browser-run/features/webmcp/
- macOS Automator MCP Server by steipete: https://glama.ai/mcp/servers/steipete/macos-automator-mcp
- macos-computer-use-mcp: https://glama.ai/mcp/servers/yyyyyyyyiiiii/macos-computer-use-mcp
- macos-ui-mcp: https://glama.ai/mcp/servers/thangduonghuu/macos-ui-mcp
- macOS Companion MCP: https://glama.ai/mcp/servers/surendranb/macos-mcp
- mcp-oauth-hosting: https://glama.ai/mcp/servers/ierhgfiuoergerg/mcp-oauth-hosting
- ChatGPT iPhone Bridge: https://glama.ai/mcp/servers/kapunakap/chatgpt-iphone-bridge
- macOS GUI Control MCP: https://glama.ai/mcp/servers/Akira-Papa/macOS-GUI-Control-MCP
- macOS Automation MCP Server by matthewdcage: https://glama.ai/mcp/servers/matthewdcage/mcp-applescript-automation
- macOS Defaults MCP: https://glama.ai/mcp/servers/g0t4/mcp-server-macos-defaults
- macOS MCP Server by alexlock1: https://glama.ai/mcp/servers/alexlock1/macos-mcp
- macos-mcp by krmj22: https://glama.ai/mcp/servers/krmj22/macos-mcp
- mcp-server-macos-use by mediar-ai: https://glama.ai/mcp/servers/mediar-ai/mcp-server-macos-use

## Source-verified external capability selection
- **DeviceLink**: original saved page `https://api.devicelink.ai/` explicitly differentiates desktop browser share (Chrome/Edge/Brave/Opera, tab must remain open), separately installed agent, owner device approval and remote MCP `https://mcp.devicelink.ai/mcp`. It only exposes chosen folders read-only; cannot substitute for terminal, Finder UI or full Mac application control. Avoid reusing archived install-invite token.
- **juliusloon/macOS Agent Bridge**: original archived site and current GitHub `README.md` (SHA `294b1977c8c748f3fba1629053f41f0f6d31156b`) confirm 63 local tools, scoped file roots, Apple app integrations, owner approval/idempotent writes, and prebuilt Apple Silicon release `v0.3.0`. Package uses bundled runtime, but ad-hoc signing is not notarization; local stdio DOES NOT deliver remote ChatGPT pairing alone. Strong native capability baseline.
- **wende/Macbeth**: original archive + current GitHub `README.md` (SHA `71adeeaf12e745c05a84c54bffd92e6007da5b8e`) document macOS 14+, Node 20+, signed/notarized universal native daemon, semantic Accessibility GUI + screenshot/OCR. Local stdio and socket; no remote HTTP owner pairing. Strong optional GUI executor.
- **CursorTouch/macOS-MCP**: original archive + GitHub `README.md` (SHA `7dbc54f2234e657c18073696e04735bda98a1306`) have macOS 12+, Python 3.11+, `uvx macos-mcp`, local stdio and optional **loopback** Streamable HTTP. Network exposure requires separate authentication and grants, not a bare public HTTP endpoint.
- **baryhuang/mcp-remote-macos-use**: original archive + current GitHub README verify Docker/VNC/Screen Sharing control, but uses Mac user credentials and reachable Screen Sharing service. Not outbound native agent; avoid exposing VNC remotely.
- **ModelPiper/ToolPiper**: original archive + current GitHub README verify local HTTP MCP, 400+ tools, proprietary binary, macOS >=26 and local installation required. Not universal M1 version fit and no owner remote pairing built in.
- **recursechat Apple Shortcuts**: original archive + GitHub README confirms list/run via local Node MCP, not remote device authentication; running shortcuts is potentially high impact and needs separate grants.
- **Cloudflare WebMCP**: actual saved Cloudflare Browser Run HTML documents `document.modelContext`, Chrome Lab or Kitesurf page-tool discovery. This is BROWSER WEBMCP, not macOS device control.

## Original Project/History recovered
Connected Dropbox files `RavenNest/docs/MAC_BRIDGE_MANUAL_CONTROL.txt` and `RAVEN_TESTING.md` establish that the older `eden.bifrost.raven-bridge` was **manual-only and disabled by default** under BIFROST, and its original testing guide says real physical Mac actions were not accepted. Do NOT silently reactivate it or conflate it with standalone AppleRAVEN. `ZERO Connections/PROJECT_BIBLE.md` is a separate standalone project, NOT AppleRAVEN's gateway.

## Implementation acceptance contract
1. AppleRAVEN installs **its own** easy Mac app/agent independently from RDC and BIFROST; native executor should adapt vetted external capability implementations, not a hollow Shortcuts-only prototype.
2. The service needs a genuinely working authenticated, owner-approved remote pairing transport to the current ChatGPT plugin; the old RAVENsNEST Workers remain unaccepted until proven. Optional hosting choice is NOT a user-visible success claim.
3. On the real M1, confirm native `shortcuts list` or Finder/system semantic read, result returned by current ChatGPT; then negative grant/revocation/offline tests.
4. Sign/notarize production DMG and test the install on a real macOS host; Linux shell syntax checks are static only.
5. Keep ELYSIUM demonstration independent. No password/OTP, plaintext credentials, unrestricted script, direct public VNC or unreviewed user browser-profile uploads.
6. While Mac is not connected to a running AppleRAVEN native agent, first installation and owner approval require physical/authorized device interaction. This is a physical gate, NOT RDC offline or reason to stop cloud/source research.

## Evidence ceiling
GitHub public source code and 21 ORIGINAL Dropbox WebArchive HTML payloads were actually examined. No external native executor was installed, no signed AppleRAVEN DMG produced, no physical Mac pairing, no owner-approved ChatGPT tool invocation; mission OPEN.
