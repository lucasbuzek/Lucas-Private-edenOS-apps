# AppleRAVEN — website research and Mac M1 acceptance gates

Date: 2026-10-27. Status: research and source inventory; no Mac device or remote custom ChatGPT MCP acceptance implied.

## Source custody and availability

- User-linked Dropbox research folder: `/EDEN-lucas-family/AI MCP tool`, viewable. Independent complete *immediate-children* scans of five selected curated groups found **413 `.webarchive` reference pages**: root 314; `#appleOS` 60; `#webMCP` 37; `#AI toolkit` top-level 1; `#AIcustom` 1. A larger recursive scan also encounters browser profiles, installers and other unrelated files, which are not interpreted as reference websites.
- Machine-folder link: `/EDEN-lucas-family/@devices/lucas/MacBook Air`, viewable, **zero entries**. This is an online Dropbox folder, not a live Mac filesystem/MCP connection.
- Machine agent state and native Mac account/Apple TCC permission remain UNKNOWN/OFFLINE from existing observations. No macOS terminal, Finder or Photos execution verified here.
- Complete current metadata inventory: `AppleRAVEN/docs/ARCHIVE_WEBSITE_INVENTORY_20261027.json`, 413 filenames + exact Dropbox file IDs + byte sizes and provenance, from live readbacks.
- Binary WebArchive extraction: Dropbox `fetch` failed on representative small and large `.webarchive` files. A temporary direct-download attempt failed in this runtime (network DNS blocked). **No individual raw WebArchive source URL or HTML body was extracted.** Directory names and public website search match the live projects, not proof of archived binary contents. Do not mark all 413 site contents reviewed.

## Live upstream research mapped to archive leads

| Reference website | Confirmed current features | Risk/reuse decision |
|---|---|---|
| [Apple MCP Tools by wearesage](https://glama.ai/mcp/servers/%40wearesage/mcp-apple) | Contacts, Notes, Messages, Mail, Reminders, Calendar, Maps, web search; AppleScript-based automation | Useful decomposition into Apple-specific adapters. Broad PIM/communication scope should NOT be automatically installed, exposed to internet or run with full permissions. Source and dependency audit before reuse. |
| [recursechat/mcp-server-apple-shortcuts](https://github.com/recursechat/mcp-server-apple-shortcuts) | List and run macOS Shortcuts through local MCP | Preferred narrow adapter pattern for a first explicit owner-allowed Shortcut test, after M1 connection and user permission. Apache-2.0 declared upstream; verify actual license and version on incorporation. |
| [sweetrb/apple-photos-mcp](https://github.com/sweetrb/apple-photos-mcp) | Search, album metadata, thumbnails, duplicate detection, export; optional controlled metadata writes; read-only default | Suitable reference for consent-gated photo read tools. Photos library full-disk permission is sensitive and must remain target-device/operator controlled. Not mandatory M1 first-run dependency. |
| [mpacarroll/apple-messages-mcp-remote](https://github.com/mpacarroll/apple-messages-mcp-remote) | Optional remote HTTP bridge for local Messages reads and message sending; upstream cautions about bearer credential exposure | HIGH SENSITIVITY. No default deployment or Internet exposure; message sends need explicit recipient/content confirmation. Not M1 owner MVP acceptance. |
| [steipete/macos-automator-mcp](https://github.com/steipete/macos-automator-mcp) | AppleScript / JXA scripting of macOS apps through local MCP; upstream now indicates Node.js >=24 | Reuse capability only through allowlisted signed actions and distinct OS permission grants; avoid generic arbitrary-script or shell tool on remote interface. |
| [HachiTogo/macos-mcp-tools](https://github.com/HachiTogo/macos-mcp-tools) | Separate Mail, Contacts, Notes, Messages, EventKit Calendar and Reminders handlers | Feature reference for modular services, but SQLite access and unrestricted CRUD are privacy risks. Do not auto-enable. |
| [robworks-code/icloud-mcp](https://github.com/robworks-code/icloud-mcp) | Direct iCloud Drive file inventory, sync status, read/write/trash/restore; persistent session cookies for cloud auth | Requires separate user-granted Apple identity, protected session lifecycle and revocation. Keep distinct from local iCloud Drive File Provider and do NOT combine Cloud provider accounts. |
| [Lakr233/iphone-mcp](https://github.com/Lakr233/iphone-mcp) | Appium/Xcode WebDriverAgent-based iPhone screenshots, UI interactions and app launch via local HTTP MCP | Requires physical iPhone, Xcode, Appium and pairing. Useful later for explicit device test; not iOS ChatGPT custom MCP support. |

## Official platform contracts (not plugins installed in AppleRAVEN)

- [Apple App Intents](https://developer.apple.com/documentation/AppIntents): native structured Siri/Shortcuts integration for actions and entities. An App Intent is not automatically a remote MCP call.
- [Apple macOS App Sandbox file access](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox): per-user selected folder access, security-scoped URLs/bookmarks; file grants do not bypass TCC or OS restrictions.
- [Cloudflare remote MCP](https://developers.cloudflare.com/agents/model-context-protocol/guides/remote-mcp-server/): remote Streamable HTTP handler. Authorization must be explicit, enforced by server/tool and auditable; hosting alone does not pair a Mac.
- [Cloudflare OAuth guidance](https://developers.cloudflare.com/agents/model-context-protocol/protocol/authorization/): use independent owner sign-in, token audience, scope, grant revocation and least privilege.
- [Chrome WebMCP tool security](https://developer.chrome.com/docs/ai/webmcp/secure-tools): browser-tab agent tools are origin-specific; not a replacement for private authenticated remote HTTP MCP or native Mac service.
- [OpenAI custom MCP connection FAQ](https://help.openai.com/en/articles/12584461-connecting-custom-mcp-servers-in-chatgpt): explicitly says custom MCP servers **web-only** as of this research. Do not assert ChatGPT iOS custom MCP integration merely from user plugin metadata.

## Source-backed AppleRAVEN architecture and acceptance

1. **Owner private ChatGPT plugin** already exists (`plugins_6ae05fb243a48191a7cd678e20ee608c`, v0.1.1 from prior verified Asana/Creator receipts). It must retain this identity; website registration is optional and separate. A plugin manifest is NOT proof of installation/usable tools on ChatGPT iOS.
2. **Owner OAuth remote Cloudflare MCP** already deployed at `https://appleraven-private.lucasravensnest.workers.dev/mcp` from prior provider receipts. Current owner-token session and actual read-only plugin invocation unverified.
3. **Native M1 AppleRAVEN local agent**: must be independently installable and outbound-only paired, with explicitly selected file/action grants, Apple OS permissions, audit and rollback. A blank Dropbox machine folder doesn't run an agent. Browser WebMCP cannot grant Mac file/shell execution.
4. **Owner M1 minimum acceptance**: (a) native client-specific authenticated MCP tool read works; (b) actual M1 session enrolls; (c) device read-only status/Shortcuts list works; (d) one explicitly approved allowed Shortcut/file read succeeds; (e) wrong owner, revoked token, unauthenticated caller, unsupported native action and offline-device tests are denied as designed.
5. **Security:** no generic remote AppleScript/shell; no implicit Mail/Messages send; no automatic Photos Full Disk Access, iCloud credentials or family/user tenant inheritance; full rollback preserving original owner worker/branch/LKG.

## Exact outstanding blockers

- Website archive raw content research is not complete: 0/413 `.webarchive` decoded; 8 upstream matching live sites verified independently. The catalog is exhaustive for its **declared bounded groups**, not all website contents and not all deeply nested browser/installer assets.
- Dropbox machine folder has no files. No connected Mac agent/permissions/paired Apple device currently available through this source.
- Physical M1 acceptance and current supported ChatGPT owner's authenticated plugin invocation cannot be done through archive URLs alone.
- No production deployment, original native source overwrite, install or Apple account authorization was performed for this research.

## Next independent work

Preserve above inventory and eight-source capability decisions in AppleRAVEN master Asana. Continue authenticated *cloud* MCP/provider read-only acceptance through existing Creator/Cloudflare while the Mac is offline, without inventing supported iOS custom MCP. Once actual signed owner + local Mac session is established, enroll M1 and execute native read-only then permissioned write test.

## Additional independently verified live references (same research session)

| Archived title matched to live source | Evidence and AppleRAVEN relevance |
|---|---|
| [juliusloon macos-agent-bridge](https://glama.ai/mcp/servers/juliusloon/macos-agent-bridge) | File-root scoped native tools, approvals, idempotent writes, Shortcut gate, Mail draft/send gates and Raycast control panel. Valuable architecture comparison for AppleRAVEN permission UX, but its local scope does NOT equal our deployed owner relay. |
| [thangduonghuu macos-ui-mcp](https://glama.ai/mcp/servers/thangduonghuu/macos-ui-mcp) | Semantic UI tree and click/type/screenshot via instrumented debug-build app harness. Development/testing reference only, NOT arbitrary macOS desktop access. |
| [kapunakap ChatGPT iPhone Bridge](https://github.com/kapunakap/chatgpt-iphone-bridge) | Secure tunnel + Appium/Xcode path and opt-in separate iPhone browser. Requires actual Mac, signed WDA/phone and supported developer MCP client; never evidence of current iOS ChatGPT custom MCP support. |
| [nickatnight96 iphone-mirror-mcp](https://glama.ai/mcp/servers/nickatnight96/iphone-mirror-mcp) | iPhone Mirroring control from macOS 15+, explicit Screen Recording/Accessibility, paired phone. Deferred optional physical acceptance path rather than owner M1 first MVP. |
| [ailenshen Apple Notes MCP](https://glama.ai/mcp/servers/ailenshen/apple-notes-mcp) | Notes lists, search, read and Markdown draft creation. Must separately confirm exact note identification, native permissions and write consent. |
| [kevinswint xcode-studio-mcp](https://github.com/kevinswint/xcode-studio-mcp) | Swift build, simulator launch, screenshot and UI interaction; good isolated engineering test dependency, not part of family end-user AppleRAVEN install. |

Index update: 413 saved archived page identifiers remain inventoried, **14 live upstream project examples now independently verified**. Binary WebArchive content extraction remains **0**; the original saved URL/body for each archive was not independently decoded. Previous count of eight verified source matches in earlier paragraphs is the older checkpoint.
