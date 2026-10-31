# AppleRAVEN unified source MCP — recovery and integration (31 October 2026)

This is the *original standalone AppleRAVEN* on a protected candidate branch. It is not MacConnect, Remote Desktop Commander, OracleCloudIn, BIFROST or ELYSIUM.

## Architecture

- **Cloudflare AppleRAVEN owner Worker:** existing owner-signed Access OAuth, MCP client endpoint, pairing/grants and device identity. New source federation owner tools are in cloud/ravensnest/provider-federation.mjs and oracle-federation.mjs.
- **Cloudflare device Worker:** existing Keychain-backed one-time owner-approved enrollment and outbound-only Mac polling. New tools registry/queue/result implementation is in cloud/ravensnest/device-providers.mjs.
- **macOS:** mac/appleraven_unified_agent.mjs adapts the EXISTING owner's MacConnect stdio-MCP aggregation engine to the original AppleRAVEN credentials and endpoints. Installed upstream source servers execute on the Mac after per-call Allow/Deny.
- **Oracle:** isolated always-on Docker MCP gateway aggregates independently authenticated cloud/multi-agent connectors (Conductor, Asana, Dropbox, Google Drive, others). It never performs Apple-native operations or receives a Mac Keychain credential.
- **Cloudflare Pages:** owner-authenticated download/onboarding frontend is the intended distribution. Publishing a real downloadable installer requires a tested, signed Mac artifact and access-protected assets.
- **ChatGPT:** preserve existing PRIVATE appleraven plugin ID plugins_6ae05fb243a48191a7cd678e20ee608c (v0.1.3 at research time) and original MCP URL https://appleraven-private.lucasravensnest.workers.dev/mcp.

## Upstream MCP sources examined

| Capability | Existing source | Requirements and boundary |
|---|---|---|
| Finder, scoped files, Calendar, Reminders, Apple apps, desktop (63 tools) | https://github.com/juliusloon/macos-agent-bridge | MIT; Mac helper/extension and permissions, macOS 14+ |
| Terminal, PTY, filesystem, jobs, Chrome, Codex history | https://github.com/alexanderradahl/mac-developer-bridge | MIT; unrestricted upstream shell, AppleRAVEN dialog required per provider tool |
| Native Notes, Mail, Music, Calendar, Reminders, Shortcuts | https://github.com/0xatrilla/Apple-MCP | Mac TypeScript stdio and Swift setup/permissions |
| Screen, Accessibility, mouse, keyboard, clipboard | https://github.com/antbotlab/mac-use-mcp | MIT; Node22+, Accessibility/Screen Recording, 18 tools |
| Messages, Notes, Contacts, Mail, Reminders, Calendar, Maps, Shortcuts | https://github.com/54yyyu/pyapple-mcp | MIT; 88 operations in ten tools, local permissions |
| Photos inspect/search/export, opt-in album writes | https://github.com/sweetrb/apple-photos-mcp | MIT; Photos permissions / Full Disk Access |
| Apple Photos alternative | https://github.com/thenavidm/apple-photos-mcp-cli | MIT; Mac-local MCP/CLI |
| Xcode/Simulator build, run and UI | https://github.com/kevinswint/xcode-studio-mcp | MIT; Swift + Xcode |
| AppleScript/JXA and Automator knowledge | https://github.com/steipete/macos-automator-mcp | Script execution is powerful; explicit local approval |
| Shortcuts | https://github.com/recursechat/mcp-server-apple-shortcuts | Apache-2.0 |
| Local Apple iCloud apps | https://github.com/MrGo2/icloud-mcp | MIT; local mode avoids exporting account credentials |
| iCloud Mail/CalDAV and Mac helper | https://github.com/epinethrone/icloud-mcp | MIT; extra owner approvals, never export iCloud passwords to Oracle |
| Semantic GUI | https://github.com/wende/macbeth | Native Mac permission |
| Cloud source aggregation | https://github.com/cociweb/mcp-gateway | Oracle Docker/Linux; supports several MCP transports; requires separate Access policy |

No Apple-native MCP source is reimplemented on Linux. Each upstream's own license, macOS permission prompts and operating-system compatibility remain binding.

## Implemented in this branch

- mac/Install-unified.command: Mac-local installer invoking the original Python pairing flow, preserving Keychain, installing selected upstreams, registering a new LaunchAgent without replacing an existing AppleRAVEN app.
- mac/providers.example.json: extendable real command mappings for installed upstream MCP providers, including Apple Photos.
- cloud/ravensnest/migrations/0003_provider_federation.sql: additive D1 catalog/queue tables, leaving existing owner/device tables intact.
- cloud/ravensnest/provider-federation.mjs: owner-granted source catalog, invoke and command result tools; grants scoped to device ID.
- cloud/ravensnest/device-providers.mjs: device-authenticated batched tool registration, polling and result posting.
- cloud/ravensnest/owner-mcp-v2.candidate.mjs and device-worker.candidate.mjs: imports and routes extending the original owner/device Workers.
- cloud/ravensnest/oracle-federation.mjs: owner-authorized cloud catalog/invoke through a configured Cloudflare Access-protected Oracle gateway.
- cloud/oracle/docker-compose.yml and config/mcpServers.json: dedicated loopback-only Docker gateway. All upstream cloud accounts start DISABLED until their real URLs and authorization are verified.

## Deployment gates

1. From the owner's Mac, use the EXISTING SSH key under /Users/lucas/Library/CloudStorage/Dropbox/cloudInstall/ to connect to ubuntu@145.241.191.137. Do not upload or expose the private key to ChatGPT or Cloudflare.
2. Place only AppleRAVEN cloud/oracle assets in a distinct VM directory. Review and pin the gateway image digest. Preserve existing OracleCloudIn Docker containers and port 49321. The new gateway binds loopback at port 5567.
3. Configure actual cloud MCP URLs/secrets in Docker and enable them only after individual account authorization. Verify container health and real MCP tool discovery.
4. Add an outbound Cloudflare Tunnel plus Access Service Auth for Oracle /mcp, preserving the owner Worker as the sole public AppleRAVEN MCP OAuth endpoint.
5. Configure ORACLE_GATEWAY_URL, ORACLE_ACCESS_CLIENT_ID and ORACLE_ACCESS_CLIENT_SECRET on the owner Worker as runtime secrets; never commit them.
6. Apply the additive D1 migration and deploy the candidate Worker modules to STAGING with the correct D1 binding first. Do not overwrite the deployed owner/device Workers or accepted Git branch before acceptance.
7. Install and pair a real Mac using the owner Cloudflare login, then verify actual source tools and local Allow/Deny actions. Test revoked, wrong owner, unpaired and offline behavior.
8. Update the EXISTING Plugin Creator release in place only after end-to-end success; keep backend identity and OAuth endpoint.

## Acceptance and current limitations

Source code is now assembled on a candidate branch, **not operationally accepted**. No Mac was paired or driven in this ChatGPT session. Oracle SSH key is only available on the owner's Mac, not inside this execution environment; no Docker installation was performed. The current D1 JSON relay bounds responses at 150 KB. Large images/screenshots/files require a tested chunked/streaming data plane before full-sized transfers can be claimed. macOS permission and OS-version gates remain. ChatGPT web integration is not evidence that ChatGPT iOS native app supports the same custom MCP flow; test each separately. The exact Pages hostname requested must be verified against the Cloudflare account's actual project subdomain before publishing.


Canonical Cloudflare Pages deployment target (owner correction, 2026-10-31): https://appleravenMCP.ravensnest.pages.dev . This is the requested address, not proof of a live deployment.
