# Verified interfaces — 2026-10-05

SIWC is now documented for open-source/local personal projects and selected private apps.
This candidate uses the locally running personal-project route; actual account eligibility
is UNKNOWN until official login. Paid/remotely hosted distribution needs provider approval.
Identity permission alone does not authorize inference.
Source: https://developers.openai.com/cookbook/articles/sign-in-with-chatgpt

Public OAuth uses a stable host ID, state, nonce, PKCE and an issued dynamic client ID.
Authlib performs OAuth/PKCE and RS256 verification against official discovery/JWKS.
Tokens, registration, host identity and RDC OAuth records use the explicit Apple Keychain
backend. No consumer cookies, passwords, ChatGPT.app sessions, Codex credentials, client IDs
or backend-api endpoints are read. No OpenAI devkit code is vendored: its noncommercial
license is not an appropriate universal product dependency.
Source: https://developers.openai.com/siwc/token-sharing-open-source/sign-in

Chat calls the public Responses API with store=false, stream=true and account-specific
model discovery. History is retained by the single Core-owned process, isolated by
verified subject and issued client ID. Restart history persistence is not implemented;
login persists in Keychain. Completion is required; partial text is not committed.
Source: https://developers.openai.com/siwc/token-sharing-open-source/models-and-inference

Inline files/images are supported by compatible models. SIWC excludes Files upload,
hosted MCP, file search and Code Interpreter. Candidate accepts PDF, UTF-8 text/Markdown,
CSV/JSON, PNG/JPEG/WebP; conservative limit 10 MiB each, four files. No server uploads API.
The encoded context budget is 64 MiB, accommodating four full-size files after base64.
Model limits may be smaller; New chat clears context while retaining login.
Capability/model file acceptance still requires live validation.
Source: https://developers.openai.com/siwc/token-sharing-open-source/preview-limitations
Source: https://developers.openai.com/api/docs/guides/file-inputs

RDC endpoint is https://mcp.desktopcommander.app/mcp. MCP SDK v1 owns OAuth discovery,
registration, PKCE/state validation, refresh, JSON-RPC and Streamable HTTP. RDC login is
separate from OpenAI login and optional. The provider checks exact approved tool names;
the trusted BIFROST parent must authorize arguments and consequences per request.
No model-triggered tool execution or hosted MCP on the SIWC route is invented.
Source: https://github.com/desktop-commander/remote-desktop-commander
Source: https://github.com/modelcontextprotocol/python-sdk/tree/v1.x

The recovered RDC lifecycle adapter remains in place. Existing running-state evidence
means a process, not a verified MCP service. Cloud baseline identified and repaired the
stopped/available status regression without changing lifecycle ownership.

Apple bridge embeds a capability pane inside recovered BIFROST. Auth uses the system
browser; file selection uses native security-scoped picker/staging. Only the bundled
helper accesses Keychain. Swift library includes a HEIMDALL AppIntent adapter.
Source: https://developer.apple.com/documentation/appintents/appintent
Source: https://github.com/jaraco/keyring/blob/main/keyring/backends/macOS/__init__.py
