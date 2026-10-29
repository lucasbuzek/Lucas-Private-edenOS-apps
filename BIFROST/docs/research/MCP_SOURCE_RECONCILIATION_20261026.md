# MCP source reconciliation — 2026-10-26

Recovered corresponding public websites from Dropbox archive titles. This review covers five priority projects, not all 386 files. README claims are not independent execution verification.

| Source | Published capability | BIFROST decision |
|---|---|---|
| https://github.com/recursechat/mcp-server-apple-shortcuts | Lists and runs existing shortcuts with optional input; Node 18+, Apache-2.0 | Existing headless/orchestration.py already owns Apple workflows. Evaluate a thin MCP exposure of that owner rather than a second executor. |
| https://github.com/yusongcao2004/storage-steward | Local dashboard, rclone cloud operations, plans, verified copies, pause/cancel, recovery; Python 3.12+, MIT; real cloud/device acceptance explicitly outstanding | Highest-priority storage reference. Review plan/execution and recovery implementation against core/storage_preview.py and storage_capability.py. Preserve PENELOPE ownership and explicit original-removal consent. Not a verified backup engine; no iCloud operations advertised. |
| https://github.com/extrei/project-memory-mcp | Per-project persistent MCP memory backed by SQLite | Candidate memory adapter; distinct from ChatGPT memory recovery. Source/license and migration review still needed before adoption. |
| https://github.com/Dankaro-projects/project-memory | Local SQLite project decisions, evidence, outcomes, bounded retrieval and read-only control panel; public beta, Python 3.11+ | Useful reference for SNOOPY evidence/accepted lessons. Do not import a second governor or enable delegated execution automatically. |
| https://github.com/steipete/macos-automator-mcp | AppleScript/JXA execution and scripting knowledge base; MIT; Node 24+; repository archived September 13, 2026 | Research reference, not default dependency. Broad script execution exceeds current approved-workflow interface. Preserve macOS Automation/Accessibility permissions. |

## Integration sequence
1. Preserve current platform and ownership; compare exact source revisions and licenses.
2. Implement missing storage plan/receipt/recovery lifecycle behind existing headless authentication, with synthetic local tests before real provider acceptance.
3. Expose bounded existing capabilities through an MCP adapter; separate discovery, authorization, execution and result verification.
4. Add persistent project evidence/decisions with provenance and explicit accepted lessons. Never equate these stores with automatic private ChatGPT history access.
5. Verify scoped Mac and provider end-to-end operations before changing candidate status.

## Research workflow correction
An unreadable webarchive is a retrieval-format failure, not a research blocker. Resolve title + author to the original site, follow the source repository, and record exact findings and unresolved checks. No third-party installation or new provider connection was performed during this research.

## Extended source and protocol review — 2026-10-26

### Dropbox inventory and evidence limits

Connected Dropbox folder `/edenOS apps/AI MCP tool`: 386 files, 1,267,048,874 bytes, 373 `.webarchive`, one HTML, seven PNG and five JPG. Filename tagging (overlapping categories, not confirmed capabilities) found 91 Apple/mobile/device references, 53 AI/provider, 49 creative and 16 storage/cloud references. Most are third-party listing snapshots. All 386 were **enumerated**, not all 373 archives were text-extracted or source-reviewed. The five projects listed above were previously reviewed against source websites, not independently executed. Never label metadata enumeration as full examination or installation.

### Independent official/current findings

| Requirement | Primary source / observed boundary | Adoption decision |
|---|---|---|
| Current MCP protocol | https://blog.modelcontextprotocol.io/posts/2026-07-28/ and https://github.com/modelcontextprotocol/modelcontextprotocol/blob/main/docs/specification/2026-07-28/basic/transports/streamable-http.mdx | **Confirmed gap:** existing `headless/mcp_bridge.py` supports stdio negotiation for legacy `2025-06-18`; it does not implement the stateless `2026-07-28` `server/discover` lifecycle. Keep backward compatibility; migrate using an official SDK and actual client interop tests, never mislabel the current adapter as modern-compatible. |
| Standard SDK and test host | https://py.sdk.modelcontextprotocol.io/ and https://github.com/modelcontextprotocol/inspector | Reuse official Python SDK v2 where integration warrants it; Inspector v2 provides CLI/Web/TUI test hosts. Check exact dependencies and protocol negotiation before dependency promotion. |
| Reference servers | https://github.com/modelcontextprotocol/servers and https://github.com/modelcontextprotocol/servers/releases | Use bounded official filesystem/git/fetch examples, not as assumed production-ready services. Filesystem `2.0.1` and fetch `2026.10.24` include recent security fixes. Pin audited releases and verify dependency licenses. |
| Apple native automation | https://support.apple.com/en-gb/guide/shortcuts-mac/apd455c82f02/mac and https://github.com/recursechat/mcp-server-apple-shortcuts | Reuse BIFROST's existing Shortcut/workflow executor. Never add an unrestricted independent AppleScript engine or bypass macOS TCC; `recursechat` is an Apache-2.0 reference. |
| Swift/mobile MCP | https://github.com/modelcontextprotocol/swift-sdk | Official Apple-capable Swift package documents macOS 13+, iOS 16+ and Swift 6; check SDK/protocol support against current revision before relying on it. iOS app transport/lifecycle limitations must be tested rather than assuming a permanent handset MCP daemon. |
| iOS connected devices | https://github.com/libimobiledevice/libimobiledevice | Cross-platform iOS USB/service integration without jailbreak; LGPL/GPL licensing and user-approved pairing apply. Device control cannot be presumed from a detected cable. |
| Mobile E2E | https://github.com/mobile-dev-inc/Maestro | Open-source command-line/MCP route for Android and iOS simulators; its documentation explicitly excludes physical iOS device support. Physical iPhone testing requires native Apple/Xcode-accessible route, not an invented Maestro claim. |
| Local AI engine | https://github.com/ollama/ollama/blob/main/LICENSE and https://github.com/ollama/ollama/blob/main/docs/api/introduction.mdx | Ollama program is MIT, supports local OpenAI-compatible `http://localhost:11434/v1`. Model weights/licenses must be evaluated independently. Reuse existing AI TOOLKIT/provider architecture; do not add another AI router. |
| General macOS scripting | https://github.com/steipete/macos-automator-mcp | MIT but archived 2026-09-13; script execution requires macOS permissions and is broad enough to exceed current safe dispatcher. Reference only pending reviewed restricted workflow implementation. |
| ChatGPT custom MCP | https://help.openai.com/en/articles/12584461-connecting-custom-mcp-servers-in-chatgpt and https://developers.openai.com/api/docs/guides/tools-connectors-mcp | A local stdio MCP cannot be directly registered as a remote ChatGPT connection; a supported secure tunnel or authenticated HTTPS endpoint plus account-level eligibility is required. Cloud is an optional capability, never necessary for offline local use. |
| Remote OAuth and network security | https://github.com/modelcontextprotocol/modelcontextprotocol/blob/main/docs/specification/2026-07-28/basic/authorization/security-considerations.mdx | Validate origin, client/tool capability scopes, resource-bound tokens, approval and negative-path tests. No hardcoded long-lived secrets or exposing LAN services to the internet by default. |

### Mission gaps (evidence level: source-read, not deployment verified)

1. Legacy-only MCP protocol; full `2026-07-28` and client compatibility remain unimplemented.
2. Existing shortNameCall action coverage is incomplete; `bifrost.connection.health.read` is now mapped to the preexisting observer in draft PR #13, read-only with redacted IP/host/account identity. Five mapped read-only actions on macOS; no scan or live service assurance from it.
3. No verified physical M1/M3/iPhone/Android device execution in this cloud environment. Connected RDC agents currently offline; original local dirty state and LKG require reconciliation before install.
4. No verified free/open-source mobile control adapter with authorized pairing and permission receipts across all target devices. Differentiate development bridge, UI testing and production mobile companion.
5. No end-to-end AI-provider adapters beyond the existing toolkit contracts: local model availability, inference, quotas, routing, failures and privacy remain unverified. Proprietary cloud provider APIs are not automatically free/open-source.
6. No production-authorized remote MCP HTTPS/tunnel endpoint, live ChatGPT/Claude registration, multi-tenant boundary tests or consent receipt.
7. Offline startup/recovery, rollback, reverse-connect, Apple TCC, USB trust, Android Debug Bridge authorization, prompt-injection prevention and supply-chain/source license verification remain acceptance gates.

### Integration without parallel products

Continue *one* existing BIFROST shortNameCall dispatcher and headless/Bridge backend; provider and device-specific adapters must call established owners. No second command fabric, project master, generic shell, or scanning daemon. Bring official MCP SDK/Inspector validation to this existing server as a bounded compatibility enhancement. Keep the standalone stdio/local-host path independent from cloud, ChatGPT, Claude, RDC, HEIMDALL and ELYSIUM. Permissioned remote transport extends it only after identity/consent review. Preserve PENELOPE file custody and specialist/portal authority.

**Receipts:** PR #13 candidate source updated on 2026-10-26; latest source commit `bee9b584b9a09cbc7aa124c8f581013689f71b78`. Source readback done; new regression test authored but not executed on a real Mac or GitHub CI (none seen for this commit). Draft remains unmerged and accepted LKG unchanged.


### Apple and physical iPhone reference-source follow-up

Priority references resolved from archive names to **original source**, not archive-text extraction:

| Source and published evidence | Status / reuse decision |
|---|---|
| Apple official Xcode MCP: https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode | **First-party route**. `xcrun mcpbridge` exposes Xcode project/build capabilities to local Claude Code or Codex after explicitly enabling *Settings → Intelligence → Allow external agents to use Xcode tools*. Reuse Apple-provided host instead of installing duplicate third-party Xcode MCP by default. Inspect availability and permission state first; never toggle TCC or user settings automatically. |
| https://github.com/Lakr233/iphone-mcp | MIT, Appium/XCUITest-backed physical iPhone MCP; published screenshot/UI info/touch/app controls. Requires Xcode, WebDriverAgent signing, Node/npm, Python and explicitly selected device UDID. Its loopback Streamable HTTP default is not proof of installed or authorized access; restrict operations and binding; keep real-device acceptance separate. |
| https://github.com/teddyoweh/iphone-mcp | MIT, another physical iPhone WebDriverAgent MCP with read/write actions including Messages. Its own README reports working tested features and experimental Home Screen mutations; not independently reproduced. **Do not install simultaneously with Lakr233** or enable messages/send/unlock by default. Examine own code, license, trusted signer, permission prompts and data exfiltration before any adoption. |
| https://github.com/appium/appium | Official Apache-2.0 W3C WebDriver automation framework underpinning several iPhone MCP options. Appium/XCUITest can exercise physically connected iPhones, provided proper Apple developer signing and device trust; unlike Maestro's published iOS simulator-only route. One owner-scoped Appium gateway, never three competing MCP automators. |
| https://github.com/Nagarjuna2997/ios-agent-skill | MIT local Apple reference/review/simulator MCP, documented Node.js 20+ and Xcode runtime requirements. It has optional commercial AI adapters but review/reference paths remain local; do not import its independent AppDev planning/agent scope over ForgeMASTER. Version and release maturity should be verified at installation. |

**Priority implementation decision:** Apple first-party Xcode MCP for local development; existing BIFROST observer/Shortcuts executor for normal Mac actions; a **single reviewed Appium/XCUITest-based physical-iPhone connector** only after pairing/code review; a separate bounded Android ADB connector. AI providers attach to the preexisting AI TOOLKIT/BIFROST adapter contract, with Ollama locally and explicit opted-in cloud accounts. No phone should become an always-on publicly exposed MCP server merely to support remote control.

**Privacy and safety:** Only expose trusted fixed allowlisted operations, with per-device grants, owner confirmation for effectful app actions, authorization receipts, no automatic messaging/passcode entry, and independent read-only service discovery. A successful screenshot or WDA health check is not evidence of universal iPhone control. This remains source research; **no real phone was connected, paired, automated or modified in this ChatGPT session**.


### ChatGPT desktop versus web MCP support (2026)

Official OpenAI references:
- https://learn.chatgpt.com/docs/extend/mcp — ChatGPT **desktop**, Codex CLI and IDE MCP host share local Codex configuration; desktop MCP settings can add a **stdio server** or Streamable HTTP server. Existing BIFROST `tools/mcp_client_config.py` currently prints **Claude Desktop JSON**, not native Codex `config.toml`; don't assume it registered in ChatGPT desktop.
- https://help.openai.com/en/articles/12584461-connecting-custom-mcp-servers-in-chatgpt — ChatGPT **web Plugins** custom MCP route requires remote HTTPS or Secure MCP Tunnel and account/plan eligibility; custom connector setup on mobile currently unavailable. Local stdio cannot simply be pasted into a web plugin URL.
- https://developers.openai.com/api/docs/guides/tools-connectors-mcp — the **OpenAI API** supports remote MCP or local via Secure MCP Tunnel; third-party model service costs are separate.

**Implementation gap:** The existing BIFROST bridge can be configured locally through each compatible installed host (Claude Desktop, ChatGPT desktop Codex host, Codex CLI) only after source-backed client-specific configuration, protocol interop and permission tests. Avoid duplicate server processes or modifying pre-existing app configs wholesale. For mobile ChatGPT, access to web-established plugins depends on account/UI support; do not pretend iOS launches a desktop stdio executable itself. Distinguish **local model inference**, **local MCP tools**, **remote AI account**, and **web plugin** as four separate capability checks.


## 2026-10-26 full-folder research receipt — corrected scope
**Source hierarchy and destination correction (owner repeated 2026-10-26):** Authoritative mission description is the original LucasRAVEN ChatGPT conversation and recovered decisions, canonical Project Bibles/Git/LKG, and connected Dropbox originals. The MacBook is an Apple compilation/physical-test host, not the sole discoverable source or a cloud-work stop condition. Dropbox `/edenOS apps/` already has BIFROST bridge, headless, installer and storage distribution ZIPs; independent code/byte verification remains pending. `/mnt/data`, `~/edenOS/Temporary` and Downloads are caches/staging ONLY, not mission acceptance or final project distribution. No new parallel project master or generic RDC bootstrap may substitute for the full Apple ecosystem goal. The 391st item is the 60-byte Dropbox `iphone-mcp.url` pointing to [Lakr233/iphone-mcp](https://github.com/Lakr233/iphone-mcp); upstream code/README and default `--relaxed-security` risk were examined, without implying physical iPhone integration. Existing standalone BIFROST Bridge source must be reused.


**Source-of-truth evidence:** [391-item Dropbox metadata ledger](MCP_REFERENCE_INVENTORY_20261026.json), read back from the same existing BIFROST candidate branch. The former 386-file snapshot above is historical, not current. The connected Dropbox returned a complete nonrecursive folder listing of **391 items**, **1,280,522,778 bytes**: **375 Safari .webarchive**, **9 PNG**, **5 JPG**, **1 HTML**, **1 URL**. Tags are overlapping filename-derived candidates, **not validated features**.

**Mandatory correction:** Inventory of all 391 does not mean fullresearch of all 391. Exactly six attempted `.webarchive` text fetches failed because the connected Dropbox extraction service cannot parse the archive format. The single `devops-practices.html` text was successfully fetched/read. Dropbox temporary download links were obtained, but the sandbox host could not resolve Dropbox's temporary download domain; user-source archives were not passed through an untrusted public web search system. Mac remote executor was offline at last check. **All per-item fullresearch_complete flags are false.** Source link, license, actual implementation/API, security and usefulness must be independently checked before integration.

**Additional primary-source verification:**
- Official Apple Xcode external-agent MCP: https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode (use first-party Xcode tool, subject to explicit owner settings, not a third-party replacement).
- Official MCP Python SDK v2: https://py.sdk.modelcontextprotocol.io/whats-new/ (implements `2026-07-28` and backward-compatible old negotiation; reuse one existing bridge with regression).
- Apple Shortcuts MCP: https://github.com/recursechat/mcp-server-apple-shortcuts (Apache-2.0; candidate thin adapter to existing shortcut executor).
- Apple Photos MCP: https://github.com/sweetrb/apple-photos-mcp (read-only by default; requires explicit Full Disk Access and optional mutating opt-in; CURATOR/PENELOPE remain owners).
- iCloud Drive MCP: https://github.com/robworks-code/icloud-mcp (claims remote iCloud file access without locally hydrated copies; requires independent security/authentication audit and privacy approval).
- Physical iPhone automation MCP: https://github.com/Lakr233/iphone-mcp (Appium/XCUITest, WebDriverAgent, signing and device pairing; not general iPhone system control).
- Archived unrestricted AppleScript reference: https://github.com/steipete/macos-automator-mcp (archived 2026-09-13; broad execution surface; **do not automatically install or expose**).

**Follow-on operational gates:** read every archive through a *trusted authorized Mac/local or connector extraction route*, reconcile to each original repo and current release/license, reject untrusted or duplicate wrappers, inspect security/grants and Apple TCC/iOS entitlement boundaries, compare against original BIFROST/HEIMDALL/PENELOPE/CONDUCTOR implementations, patch only demonstrable gaps on protected candidate branches, run local regression and actual M1/M3/iPhone acceptance before any LKG promotion. The iPhone Developer-settings screenshot was an illustrative example, **not scope reduction**. This corrects the earlier premature completion narrative. No secrets, external applications or account changes were authorized or performed by this research.


### Safe Safari webarchive extraction candidate (2026-10-26)

**Actual implementation (new draft branch only):** `BIFROST/tools/research_webarchive.py` and `BIFROST/tests/test_research_webarchive.py`. Synthetic test fixtures in an isolated Python sandbox: **5/5 pass** (main resource text, suppression of script content, malformed plist recovery, symlink refusal, separate output safety/repeatability, bounded GitHub source link extraction). Source and tests were committed to the existing protected draft, never to `main`. The code has NOT been invoked on any original Dropbox archive, Mac or iPhone.

The research extractor is *not* an additional daemon, MCP server, service, provider, planner or replacement application. It uses Python standard library `plistlib` to decode Safari `WebMainResource`, parses only the stored HTML/text without executing scripts, and records bounded source URLs plus GitHub repository references. It refuses symlinks, non-WebArchive input, giant main resources, and output inside the source tree; it defaults to read-only metadata. The optional local `--output` saves textual extracts into an explicitly separate directory, never into GitHub or cloud storage.

On the *authorized connected Mac*, only **after original BIFROST/source/LKG comparison**, test with:

```sh
cd "/Users/lucas/edenOS/Software Development/BIFROST"
python3 -m unittest discover -s tests -p 'test_research_webarchive.py' -v
python3 tools/research_webarchive.py \
  --source "/Users/lucas/Library/CloudStorage/Dropbox/edenOS apps/AI MCP tool" \
  --output "/Users/lucas/edenOS/Temporary/BIFROST-webarchive-research"
```

Those are instructions, **not a claim of command execution**. The script emits JSON lines to the executing terminal; source text remains local to the explicit temporary directory. Read source before invocation; the command must not be used for an account or directory other than the one shown without owner permission. The extractor does NOT prove any listed project is maintained or safe. Complete file-by-file research still requires reading extracted output, tracing links to original source and release/license, reviewing code and security, checking duplicate scope, deciding reuse, then original-project regression/physical acceptance. Protect separately permissioned/private archive contents from external AI services.


## 2026-10-29 shared archive and external REUSE comparison

**Source isolation:** The user-supplied shared Dropbox URL resolves to `/EDEN-lucas-family/AI MCP tool` namespace `ns:13844906001`, not the separate prior `/edenOS apps/AI MCP tool`. Current non-recursive listing: 413 direct entries, 6 named subfolders (`#appleOS`, `#AI toolkit`, `#webMCP`, `#screenshots`, `#AIcustom`, `#domain-specialists`). The `#webMCP` section contains 41 entries; `#appleOS` has 104. This is a **current listing**, not a 413-upstream-code audit, and the root is mutable. Relevant **original text** successfully extracted via connected Dropbox: `#AI toolkit/Online Plugins & Connectors/EDEN-BIFROST-Connector/{README.md,server.py,manifest.json}`, `ZERO Connections/PROJECT_BIBLE.md`, `RavenNest/README.md`, `BIFROST-Variant-MobileCLI/VARIANT.md`, `BIFROST-Variant-LiteLLM/VARIANT.md`, and the group README. These prove historical source, not current local installation.

**Canonical distinctions:** `EDEN-BIFROST-Connector` is a bounded read-only BIFROST stdio adapter, not a general-purpose local/remote execution engine; `ZERO Connections` is a separate standalone identity/account manager, not a BIFROST implementation stage; `RavenNest` is a distinct cloud coordinator; `MobileCLI` and `LiteLLM` are **isolated, uninstalled upstream candidates**; their stubs do not perform device PTY control or inference. Preserve specialist and user-account privacy, current Project Bible/LKG, and the user's separate overarching standalone MCP goal; no substitute master.

**External REUSE verification (upstream, not user-code deployment):**
- https://github.com/stacklok/toolhive — open-source local/container MCP manager, runtime isolation, registry/gateway and desktop/CLI. It requires an installed container runtime for normal local server execution; compare this real footprint against low-resource MacBook Air M1 before adopting. No ToolHive installation performed.
- https://github.com/IBM/mcp-context-forge — Apache-2.0 federated remote MCP proxy/registry/admin UI; release v1.1.0 (2026-10-20) includes modern protocol support, SSO and policy infrastructure. Its upstream currently states production ARM64 container images are unsupported; Mac M1 needs alternate package/runtime or emulation. Adoption is conditional, not approved.
- https://developers.cloudflare.com/cloudflare-one/access-controls/ai-controls/mcp-portals/ — existing provider-managed MCP Portals handle stateless 2026 and legacy 2025 Streamable HTTP, OAuth upstream authentication, per-user server selection; use as **optional remote aggregation** only where account authorization/cost and privacy are verified. It cannot directly substitute for a paired Mac/mobile agent.
- https://developers.cloudflare.com/changelog/post/2026-10-01-workers-oauth-provider-1x/ — first-party OAuth v1 split authorization/resource server model over Service Binding; strongest supported route for private remote tool scope and revocation if a distinct authorized cloud account is selected.
- https://developer.chrome.com/docs/ai/webmcp/imperative-api — browser-tab-bound WebMCP user interactions. NOT a backend stdio/HTTP MCP replacement; must remain permissioned to the webpage's origin/browser environment.
- https://github.com/BerriAI/litellm — broad AI-provider routing; do not install unpinned. Confirmed supply-chain compromise of specific PyPI versions and advisory updated 2026-10-22, including `1.107.0` as identified in GitHub advisory https://github.com/advisories/GHSA-92x9-889m-jgmw ; audit versions and credentials before adoption. Existing LiteLLM adapter remains metadata-only and safely uninstalled.

**Implementation milestone:** existing BIFROSTbridge candidate stdio gained a tested-in-isolation 2026 modern path without replacing 2025 clients; original downstream device/provider effects remain unavailable. Current Dropbox **public+edit** share is confirmed; Asana security task `1220005270489549` is incomplete. Review/fix share audience in Dropbox through owner permissions separately; no unapproved sharing, credential or file operations performed.

**Open acceptance:** Full original-source and archive content review, one verified canonical standalone MCP deployment owner, secure typed local/device executor, E2E Mac M1/M3 and phone pairing, per-device/per-provider grants, genuine task lifecycle, local inference, authenticated remote cloud path, browser file portal, denial/revocation/rollback and independent provider receipts. Do not treat archiving, a PR commit, isolated subprocess tests, web page or Asana tracking as deployed functionality.


## 2026-10-29 THREAD + ARGOS source-depth correction and live MCP implementation gate

### Recovered owner scope and source provenance
- THREAD actual past-conversation search (2026-10-29) established one **universal** BIFROST mission: standalone BIFROSTcore / BIFROSTAIcore, out-of-chat BIFROST Master, existing BIFROSTbridge, Mac/Windows/Linux native and Headless, iOS/Android/embedded targets, local/offline AI, authenticated remote MCP, browser WebMCP, storage/identity/jobs/receipts, and working HEIMDALL/workspace representation. Natural-language CONDUCTOR coordination is reused by BIFROST Intelligence; it is not a second governor. Older Apple/Garden-first sequencing was explicitly superseded; the older representations remain valid.
- User supplied Dropbox **AI MCP tool** public-edit share and older physical Dropbox `edenOS apps/AI MCP tool` are distinct source paths. The source-linked core BIFROST tree is additionally available under `/EDEN-lucas-family/EDEN app/BIFROST/`. The first is a source research library, not proof of installed or safe tools; the latter contains Swift, Headless, tests, BIFROST Intelligence and original Git bundles. Prior chat claims of complete archive research are not substantiated.
- The actual original binary Safari `.webarchive` from `#webMCP/WebMCP Bridge — Connect MCP Servers to Browser AI Agents.webarchive` could not be text-extracted through connected Dropbox fetch; its one-time direct download was also inaccessible in this execution host. **ARCHIVE_BODY_UNVERIFIED**, not FULLRESEARCH_COMPLETE. Retain exact archive and source URL; do not replace it with a guessed summary. Its upstream source still needs audit. Refer to existing `tools/research_webarchive.py` for approved local offline bytes-to-source extraction when the authorized Mac is available.

### Actual primary code/documentation research (not title inventory)
1. **Official MCP Python SDK v2:** https://github.com/modelcontextprotocol/python-sdk/blob/main/docs/whats-new.md at Git blob `ce3fda400499677e491df9359df9039e43cb8cd8`. Its built-in `MCPServer`, `Client`, `streamable_http_app()`, dual legacy/2026 protocol and schema validation mean **do not write another custom remote HTTP framing/auth transport**. BIFROST's existing stdio compatibility shell remains useful for local deployments and non-SDK clients; compare how to retain its stable action IDs/read-only dispatcher as registered SDK tools.
2. **Original official deployment contract:** https://github.com/modelcontextprotocol/python-sdk/blob/main/docs/run/deploy.md, Git blob `5e891fe3baeb610fc684023e5ac1f617341945cf`. Native localhost Host/Origin DNS-rebinding allowlist must be explicitly and narrowly set for a real hostname; public HTTPS requires OAuth bearer token verification per request. Behind TLS proxy, avoid redirect downgrade; modern 2026 requests are stateless, legacy sessions need sticky routing or legacy stateless mode. Do not publicly bind the existing loopback-only BIFROST Headless.
3. **Protocol standard:** https://github.com/modelcontextprotocol/modelcontextprotocol/blob/main/docs/specification/2026-07-28/changelog.mdx . The modern revision removes `ping`, `logging/setLevel`, old `initialize` and sessions; `server/discover` and per-request `_meta` are required. This triggered a scoped correction on the existing draft PR, not a new core.
4. **IBM ContextForge:** https://github.com/IBM/mcp-context-forge/blob/main/README.md, Git blob `c5ffc5c9a9585500d0abcfff76d8f5e8a21ac1d8`; it actually supports registry/federation, auth, rate limits, UI and OpenTelemetry across MCP/REST/gRPC/A2A. Evaluate only for proven multi-tenant federation needs, not Mac M1 low-resource default. Preserve ContextForge as optional external provider, not BIFROST data owner.
5. **Stacklok ToolHive:** https://github.com/stacklok/toolhive/blob/main/README.md ; license read from upstream `LICENSE` (Apache-2.0). Can manage isolated MCP tool processes, dependent on host/runtime constraints; add only if it addresses a verified isolation/registry gap.
6. **Open WebUI:** https://github.com/open-webui/open-webui/blob/main/README.md, Git blob `17b816309d96440f773a77877776dc73b7161de0`. Already offers self-hosted responsive PWA, local Ollama/remote models, groups/RBAC, MCP and STT/TTS. It is a strong optional **external user-facing AI client** for initial natural-language acceptance, not a replacement for BIFROST's permissioned registry, HEIMDALL or native/browser identities. Its external tool guide is https://github.com/open-webui/docs/blob/main/docs/features/extensibility/mcp.mdx ; the actual HTTP endpoint must exist/authenticate before claiming connected.
7. **GoogleChromeLabs WebMCP original tools:** https://github.com/GoogleChromeLabs/webmcp-tools/blob/main/README.md, Git blob `a216607ff4f035972684334fc9b5a08af1ef3bc9`; includes inspector, WebMCP evals, polyfill, Page Agent and example sites. Chrome's WebMCP is browser-tab website tooling, not a service endpoint or unrestricted connector to the device; use existing Web/PWA representations with separate service-side grants.

### Scoped code fix and verification rules
- Candidate PR #13 branch `candidate/bifrost-apple-preflight-20261025` still **DRAFT**, original LKG/master unmodified.
- On 2026-10-29 the existing `headless/mcp_bridge.py` modern path was corrected to reject removed `ping` with method-not-found; original 2025 path still handles legacy `ping`. The tool-call dispatcher now rejects non-string array/object `name` parameters with `-32602`, not an internal server error. Corresponding subprocess test file covers those denials and non-object arguments.
- Git source commits: `d2cd439fef29938fb1a13a2cb88304754f25cf26`, tests `7cbcb1be01e7e624e081fa679bd2e47023a79004`. Exact GitHub file readback was completed; actual regression result remains **NOT_RUN/UNKNOWN** until GitHub Actions or a legitimate connected executor returns a test receipt.
- Added one restricted CI YAML at `.github/workflows/bifrost-mcp-2026-compat.yml` (commits `328941df3bffe28b28f6f67e85703e99c823cea4` and `dd6a7767b7ea41189369ee6c96fae075f9cf43f4`) for source-branch/PR, not deployment. Absence of Actions status must not be reported as PASS.
- Remote authenticated MCP next gate: use SDK v2 under existing BIFROST action registry and source identity, with independently configured OAuth resource grants, no default public listener, no arbitrary shell, positive read-only list/call, unauthenticated and cross-owner denial, token expiry/revocation, typed receipts, provider failures and recoverability. Only then trial Open WebUI/HEIMDALL/ChatGPT clients and actual devices independently. Do not broaden local observation-only `task_ledger.py` into a fabricated remote executor.

**SNOOPY regression classification:** historical prior replies listed archived filenames and pushed Asana updates instead of reading bodies, selecting proven external implementations, doing source work and verifying postconditions. Current code/source edits are concrete corrections; the overall archive audit, full remote MCP and physical acceptance are still not complete.
