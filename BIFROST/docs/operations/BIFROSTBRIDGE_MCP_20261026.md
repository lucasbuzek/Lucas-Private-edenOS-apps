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
