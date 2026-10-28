# AppleRAVEN upstream MCP candidates — source audit and integration decision

Date: 2026-10-28. Owner: AppleRAVEN. Status: **design research only**. Verified original GitHub code for three libraries and live ShadowCursor vendor docs. No install, service deploy, privilege grant, Mac pairing, ChatGPT connector link, LKG promotion or device action authorized/executed.

## Existing AppleRAVEN architecture — untouched
- Owner-private ChatGPT plugin identity, existing Cloudflare remote authenticated MCP service and independent native M1 agent are three distinct components.
- Existing MacBook Air Dropbox folder is an empty folder, not device control. Local native M1 connectivity and macOS permissions are unverified.
- The cloud service may be reached on a supported client but does not make local Mac MCP/stdio endpoints accessible on its own.
- The owner-only M1 first acceptance remains: remote authenticated call + paired local agent + one real read-only Apple action, with negative grant/offline tests. No assertion of iOS custom MCP support. Official FAQ https://help.openai.com/en/articles/12584461-connecting-custom-mcp-servers-in-chatgpt currently says **custom MCP mobile: no; web only**.

## (A) pyapple-mcp — high-value Apple-native modular adapter reference
- Source: https://github.com/54yyyu/pyapple-mcp ; main source files `pyproject.toml` (v1.6.1, MIT, Python >=3.10, FastMCP>=3,<4, PyObjC), `pyapple_mcp/server.py`, `pyapple_mcp/policy.py`, `pyapple_mcp/consent.py`, `pyapple_mcp/utils/shortcuts.py`, `README.md`, `CHANGELOG.md`.
- README claims 88 operations across 10 groups: Messages, Notes, Contacts, Mail, Reminders, Calendar, Maps, Shortcuts, Presence and Doctor. Also an independent `pyapple` CLI sharing the same policy.
- `PYAPPLE_READ_ONLY=1` and `PYAPPLE_PERMS` narrow classes read/write/draft/send and fail closed. `PYAPPLE_CONFIRM_SENDS=1` binds a one-time ticket to the exact send payload, but a client can still preview and confirm without presenting a user with the content; AppleRAVEN must enforce its own human-consent flow.
- **Important:** `shortcuts run` is **send-class**, because installed Shortcuts may contact outside parties, read restricted data or wait for interaction; Shortcut actions are not reliably introspectable.
- Sensitive private stores require macOS TCC/Full Disk Access, may be undocumented/OS-version dependent, and cannot be treated as implicitly granted. `mail`, `messages`, `photos` and contacts never become remote default exports.
- **Decision:** prioritize a small allowlisted read-only adapter with optional local use; evaluate latest source/tests and Mac OS version before permissioning. No auto-install and no third-party code vendoring until source/LKG and license audits.

## (B) q-ring — optional local secret governance, NOT Apple native actions
- Source: https://github.com/I4cTime/q-ring ; inspected `package.json` (v0.18.0, Node >=18, AGPL-3.0-only), `docs/threat-model.md`, `PRIVACY.md`, `SECURITY.md`.
- Features: Keychain/OS vault storage, project-scoped grants, HMAC approval, secret expiry, audit-chain anchoring, local MCP airlock wrapping another tool server, provider-targeted secret push.
- **Boundaries from own threat model:** wrapped child MCP server is NOT sandboxed; retains file, network and Keychain access. Tool output is scrubbed for exact known secret values, but encoded/split values can escape. A permitted secret read can return the value to the MCP transcript. Some commands inject secret values into child process environment. Audit client label is not proof of identity.
- **Decision:** consider independently installed local optional secret vault; do not mix its code into AppleRAVEN private source pending AGPL advice, do not expose secret retrieval/export through remote AppleRAVEN MCP. Avoid unnecessary duplicate credential managers if Keychain/native OS storage already meets requirements.

## (C) ServeMyAPI — explicitly not suitable for remote AppleRAVEN secrets
- Source: https://github.com/Jktfe/serveMyAPI ; inspected `README.md`, `docs/LOCAL-ONLY-SECURITY.md`, `package.json` (v1.0.0, ISC declared), `src/index.ts`, `src/server.ts`, `src/mcp/tools.ts`.
- Provides macOS Keychain / other-platform encrypted file storage and MCP/CLI tools to store, get, delete, list secrets. `get-api-key` returns a secret in plaintext to caller by design. A separate Express server has SSE/JWT/API-key middleware but upstream explicitly forbids remote, cloud, VPN, shared or hosted versions for real secrets. README warns not to use hosted Smithery for real keys.
- **Decision: EXCLUDE** from cloud AppleRAVEN/ChatGPT-hosted MCP. Optionally research on-device local-only use if necessary; never put real production API keys in external/hosted demo. Its README's claim 'never transmitted over internet' only holds when locally configured and when the MCP client itself does not send tool output to a remote AI provider: ensure no false confidentiality promise.

## (D) ShadowCursor — optional paid Mac GUI executor; external privacy trust boundary
- Source: https://mcpservers.org/servers/shadowcursor-com , https://shadowcursor.com/guides/computer-use-mcp-server-mac/ (vendor documentation updated Oct 20 2026), https://shadowcursor.com/privacy/ , https://shadowcursor.com/terms/.
- Vendor reports standalone macOS >=15 local app + MCP server. GUI accessibility tree/screenshot + operations list_apps/launch_app/get_app_state/click/hover/drag/scroll/type_text/press_key/set_value/select_text/select_menu_item/paste, with per-agent cursor, clipboard and covered-window use. Works with Claude Code, Codex, Cursor, VS Code and other local MCP clients; hidden/minimized windows do not work. Source implementation is not presented as open-source in inspected references, so vendor claims remain vendor claims until real on-device tests.
- Optional browser ChatGPT/Claude connection: vendor terms say https://shadowcursor.com/mcp relays calls/screenshots/typed results over its servers, claiming not to store message contents. It is a **third-party remote relay**, not the existing owner-private AppleRAVEN Cloudflare endpoint, and browser support ≠ ChatGPT iOS custom MCP support.
- Vendor-listed price at research time: 7-day trial; $12.99/mo or $69.99/yr, 3 devices. External subscription and Mac OS version are explicit acceptance dependencies.
- **Decision:** worthwhile only as an optional Mac-side GUI fallback for native apps whose action APIs are missing, after permissions, privacy and cost review. **Not first AppleRAVEN MVP** and not default remote access to GUI without per-window allowlists, explicit user confirmation for destructive actions, privacy/secret handling and proof of disconnection. Review actual vendor license and signed installer before trying.

## Integration priority and acceptance matrix

| Candidate | Apple actions | Secret store | Remote Cloudflare backend | ChatGPT iOS | AppleRAVEN use |
|---|---|---|---|---|---|
| pyapple-mcp | Local native macOS | Not primary | Requires AppleRAVEN-owned adapter, auth and outbound device agent | Does not solve | Narrow selected read tools after M1 pairing |
| q-ring | No native app action | Local vault + governance | Not as remote secret-return tool | Does not solve | Optional security experiment, license review |
| ServeMyAPI | No native app action | Local-only secret-return MCP | **Explicit upstream prohibition** | Does not solve | Exclude from remote; do not deploy |
| ShadowCursor | Vendor GUI computer use | Not primary | Its *separate* optional third-party relay, not AppleRAVEN | Does not prove | Optional GUI fallback, Mac required |

### Explicit security and implementation gates
1. Recover/verify original AppleRAVEN native source/LKG and architecture; avoid new app/portal ownership.
2. Check M1 macOS 15+ requirement for ShadowCursor and Python versions for pyapple; user currently reports no Mac connection.
3. Prefer private authenticated owner-to-cloud MCP read-only status, then M1 enrollment and independent read-only `shortcuts list` under OS approval. Only then expand to Notes/Calendar/Contacts with per-tool grants.
4. No default remote secret-return, screenshot capture, arbitrary desktop/AppleScript/shell or Mail/Messages send.
5. Require real test receipts for authorization, revocation, deny, offline, preview consent, rollback and cross-account isolation.
6. Append research to existing Asana AppleRAVEN owner / M1 task; keep incomplete until real native execution.

**Evidence limitation:** code and documentation were inspected remotely; no local binary, app signature, package install, Mac screenshot or MCP live tool call was tested.
