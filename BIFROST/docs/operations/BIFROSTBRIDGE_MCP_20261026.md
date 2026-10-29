# BIFROSTbridge MCP implementation receipt

Local stdio transport implements protocol 2025-06-18 negotiation, initialized
notification, ping, tools/list and tools/call. It lists only locally available
read-only dispatcher adapters plus saved storage-profile metadata. Unsupported
methods, unregistered tools, extra arguments and pre-initialization calls fail.
No generic shell, remote online calls or effectful operations are exposed.
This is an initial bridge implementation, not complete platform acceptance.

Run `python3 -B headless/mcp_bridge.py` through an MCP client, not as an HTTP server.
Run `python3 -B tools/mcp_client_config.py` in the installed runtime to print
an absolute-path Claude Desktop-style mcpServers fragment. Merge that one entry
with existing settings; do not replace other server registrations. The generator
only prints configuration and never alters a client installation.

For a local Codex MCP host (including compatible ChatGPT desktop installations),
run `python3 -B tools/mcp_client_config.py --codex` in the installed
BIFROST working runtime to **print** a shell-quoted `codex mcp add` command.
Review it and register through the normal installed client only after the
device and exact source path have been verified. Default no-argument JSON
output remains unchanged. A printed command is NOT an installed connection.
ChatGPT **web** custom plugin MCP still requires HTTPS or Secure MCP Tunnel.
See https://learn.chatgpt.com/docs/extend/mcp and
https://help.openai.com/en/articles/12584461-connecting-custom-mcp-servers-in-chatgpt.

The transport was exercised as a real subprocess with initialize, tool listing,
a real platform-read call, unknown-tool denial and invalid-argument denial.
The platform-read adapter now maps Linux/Windows as well as macOS; platform
spoofing guards remain. Full regression: 300 Python tests, 298 passed, 2 skipped;
49 JavaScript tests passed; isolated HTTP and archive checks passed.

ChatGPT remote integration is NOT delivered by a stdio configuration. It needs
an authenticated remote MCP endpoint or a supported secure tunnel, followed by
client registration and real invocation. No fake remote URL is supplied.
Cloudflare account discovery succeeded on 2026-10-26 and returned one generic
existing account. A distinct BIFROSTserver account required by the recovered
2026-10-21 directive has not been identified. Its identity/isolation must be
resolved before cloud deployment; the existing account was not repurposed.
Claude Desktop client invocation, Mac launchd installation and cross-device
acceptance remain unverified. Client installation is separate from protocol tests.

Sources:
- https://modelcontextprotocol.io/specification/2025-06-18/basic/transports
- https://modelcontextprotocol.io/specification/2025-06-18/basic/lifecycle
- https://support.claude.com/en/articles/10949351-getting-started-with-local-mcp-servers-on-claude-desktop
- https://help.openai.com/en/articles/12584461-connecting-custom-mcp-servers-in-chatgpt


## 2026-10-29 additive dual-era stdio implementation

Candidate source `headless/mcp_bridge.py` now also supports the MCP `2026-07-28` stateless **stdio** request envelope while retaining legacy `2025-06-18` initialize/initialized behavior. The modern path validates per-request `_meta` protocol version and client capabilities; implements `server/discover` and modern `tools/list`, `tools/call`, `ping`; returns `resultType: complete`, private/zero-TTL caching hints for listings; and reports version mismatch as `-32022` with supported/requested versions. Both eras delegate only to the EXISTING read-only shortNameCall/storage adapter; no new command authority, HTTP listener, account, or unattended automation.

**Source/verification receipt:** draft PR #13 on candidate branch, bridge Git blob `b7b3050460d6b95695764ab8597ce2654894cad8`; the exact blob was reconstructed byte-for-byte in an isolated container and `git hash-object` matched. Five focused Python subprocess test groups passed on this exact bridge blob with stubbed allowlisted dispatcher/storage adapters: legacy handshake; modern discovery/list/call; invalid versions/unknown tools/extra arguments/missing capabilities; malformed messages; oversized-message rejection. A new GitHub regression was also committed, but this full-repository test suite has **not** been executed against live authoritative shortcalls, nor on macOS, nor through a real client. No LKG promotion.

**Scope limits:** This is STDIO compatibility only, not MCP Streamable HTTP over a network. It is NOT evidence of universal device discovery/pairing, physical iPhone control, remote hosted MCP, Cloudflare OAuth or HEIMDALL/ELYSIUM live end-to-end execution. An authenticated remote MCP gateway with per-user grants, revocation, task receipts and audit remains a separate accepted delivery gate. For a production-quality complete protocol lifecycle prefer the **official MCP SDK v2** after dependency and source comparison; preserve the legacy bridge until real client acceptance.

References: https://blog.modelcontextprotocol.io/posts/2026-07-28/ ; https://github.com/modelcontextprotocol/modelcontextprotocol/blob/main/docs/specification/2026-07-28/server/discover.mdx ; https://github.com/modelcontextprotocol/modelcontextprotocol/blob/main/docs/specification/2026-07-28/basic/versioning.mdx.
