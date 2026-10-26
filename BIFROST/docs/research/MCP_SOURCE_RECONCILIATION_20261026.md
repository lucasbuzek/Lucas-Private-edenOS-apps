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
