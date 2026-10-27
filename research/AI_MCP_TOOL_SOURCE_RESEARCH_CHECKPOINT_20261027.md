# EDEN AI MCP Tool — source-backed research checkpoint (27 October 2026)

## Scope and provenance
Research source: [Dropbox AI MCP tool share](https://www.dropbox.com/scl/fo/21rv7kst0n56iprmdrist/AMhROe7MpqvKtU-D4tGfsxw?rlkey=suc711gm5br3j7jwj60a05g2u&dl=0); related [MacBook Air shared folder](https://www.dropbox.com/scl/fo/wteygch8ci42ll9kfjpmz/AHDPJadLNevfHPPkobCcHSs?rlkey=wp47cjakfam78yk71rbdn0vqo&dl=0).
Source types: authenticated Dropbox folder/file metadata, successfully extracted text of actual original source files, publicly accessible official documentation/GitHub/Glama pages.
Preserve original Project Bible, LKG, source, Git history, identities and original owner boundaries. No MacBook, RDC, provider authentication or physical native installation verified.

## Saved WebArchive custody — NOT body audited
See companion [413-entry refreshed custody JSON](./AI_MCP_TOOL_ARCHIVE_CUSTODY_REFRESH_20261027.json), a snapshot of actual Dropbox listing IDs/paths/sizes.
- Root: 314 .webarchive / 322 direct children
- #appleOS: 60 .webarchive / 60 children
- #webMCP: 37 .webarchive / 41 children
- #AIcustom: 1 .webarchive / 1 child
- #AI toolkit: 1 .webarchive / 33 children
- Total: 413 .webarchive in these verified directories. This supersedes the prior 408-file binary archive count only for this fresh scope; collections or nested directories may differ.
- Original .webarchive bodies decoded: **0/413**. Dropbox fetch rejects application/octet-stream WebArchive text extraction (verified xcode-build and Xcode Studio samples); signed content download could not be resolved in the isolated local tool environment. Filename metadata is not evidence of source content, license or API behavior.
- Excluded: copied Chromium browser profile session/cookie/login databases, cache, credential material. Do not ship or audit secrets as public source.
- MacBook Air share metadata identifies the folder; connected Dropbox list_folder returned zero children. No device connectivity implied.

## Original reusable EDEN source read (actual Dropbox file TEXT fetched)
1. `#AI toolkit/Universal_AI_Toolkit_Final/FULL_INSTRUCTIONS.txt`, `README_v22.txt`, `RESEARCH_NOTES.txt`, `installer.py`, `catalog_metadata.json`: Universal AI Toolkit v22 includes a local HTML wizard and Python-assisted installer macOS/Windows/Linux. Basic selections support certain package-manager installs; most advanced selections open manual/reference URLs. Recommended/Lean/Full/Custom inputs in v22 are planning/report labels, not fully implemented installation profiles. Browser UI, all device paths, uninstall/rollback, hardware benchmarking and offline proof are not accepted. Actual installer script and source catalogue were inspected; do not replace them with a thin newly invented installer.
2. `#AI toolkit/Online Plugins & Connectors/RavenNest/README.md` and `bifrostctl.py`: RavenNest is standalone cloud coordinator/provider and optional Mac bridge, not the BIFROST application. Source README gives canonical branch `ravennest/consolidated-20261010`, Cloudflare Pages UI, Functions/D1, scheduled Worker and tests. README claims Worker deployed but newer Pages/mobile authorization UI *not* deployed; claim has not been independently verified. Mac bridge disabled/manual-only, no hidden watchdog. Do not use it as forced Mac dependency for cloud work.
3. `#AI toolkit/Online Plugins & Connectors/EDEN-BIFROST-Connector/{README.md,manifest.json,server.py}`: original Python standard-library read-only stdio MCP with source/Git and BIFROST health methods, fixed localhost authorization boundary and local device requirement. Manifest v0.2.1. Gemini registration is documented but disabled by trust checks. ChatGPT not directly connected by this local package. Preserve stable machine ID `eden.bifrost.connector` and BIFROST Bridge distinct role.
4. `#AI toolkit/Online Plugins & Connectors/BIFROST-Variant-OpenHands/VARIANT.md`: an isolated proposal/adapter and mock tests, upstream OpenHands runtime NOT installed or connected, physical acceptance unknown.
5. `#AI toolkit/RDC3-Start-Authenticate-Verify.txt`: original separate RDC3 operator start/verify instructions exist. Read-only source recovery, no local execution; preserve existing profile and do not copy credentials or assume device online.
6. Additional ZIP candidates inventoried but binary contents not audited: `Universal_AI_Toolkit_Final.zip`, `Universal_AI_Workspace_Bundle.zip`, `WORKinCODEX-Universal-RDC-Candidate-R2-20261010.zip`, `Universal_Project_Workspace_v0.2.zip`, and Notion workflow archives.

## Public original website / upstream source verification (independent of saved archive bodies)
| Website/source | Observed fact / gate | Source |
| --- | --- | --- |
| Chrome WebMCP documentation | Origin trial Chrome 149; browser tools via imperative/declarative API. Not an authenticated remote MCP replacement. Local browser/user context important. | https://developer.chrome.com/docs/ai/webmcp |
| Chrome WebMCP security | Tool origin restrictions, least privilege, consequential hints, prompt-injection defense. | https://developer.chrome.com/docs/ai/webmcp/secure-tools |
| ChromeLabs WebMCP tools | Inspector, evaluations, polyfill and actual demo examples; examples and polyfills are not standalone installed services. | https://github.com/GoogleChromeLabs/webmcp-tools |
| Cloudflare Browser Run | Remote browser rendering and controlled sessions/quick actions; separate cloud browser worker type, not the Chrome page WebMCP protocol. | https://developers.cloudflare.com/browser-run/ |
| DPGS-oss App Factory MCP | Node >=22.5; local stdio, independent project memory/state, scaffold/audit/deploy. Overlaps ForgeMASTER governor and EITRIFACTORY state, therefore research/audit worker only unless explicit restricted adapter contract. | https://glama.ai/mcp/servers/DPGS-oss/app-factory-mcp |
| Xcode Studio MCP | Swift on macOS, builds + simulator operations; optional idb for UI input, MIT. Needs actual Mac Xcode host; no remote cloud device magically provided. | https://github.com/kevinswint/xcode-studio-mcp |
| devyhan Xcode MCP | npm local Xcode project/build/test/archive and device APIs, MIT. Overlap with Xcode Studio; enable selectively. | https://github.com/devyhan/xcode-mcp |
| Appium MCP | Appium/WebDriver mobile UI automation; local/trusted CI posture; pin remote server URL allowlist, do not expose untrusted general web access. | https://github.com/appium/appium-mcp |
| steipete macOS Automator MCP | Existing AppleScript/JXA bridge needs host app permission; Node 24+; MIT. Not a remote Mac reconnect mechanism by itself. | https://github.com/steipete/macos-automator-mcp |
| OpenHands | SDK, Agent Server and separate automation/scheduling architecture available. Only optional approved sandbox worker, not a second governor. | https://github.com/OpenHands/OpenHands |
| Browser Use | Browser agent Python library and hosted API exist; overlap with currently connected web/TinyFish/Cloudflare capabilities requires gap proof. | https://github.com/browser-use/browser-use |

## Decisions, omissions, evidence grades
- **DIRECT_SOURCE_READ** applies only to named original text files fetched from Dropbox; it does not extend to sibling assets, ZIP internals or binary .webarchive.
- **METADATA_ONLY** applies to the 413 WebArchive files and named ZIP candidates. No original WebArchive site URLs or embedded HTML extracted.
- **PUBLIC_UPSTREAM_READ** applies to the listed currently available official source pages; current upstream behavior may differ from historical saved pages.
- No inference that Glama catalog title implies a runnable installed MCP, valid endpoint, license acceptance or reviewed security.
- User's MacBooks currently unavailable. Continue independent cloud/Dropbox/GitHub/Asana work. Do not treat second Dropbox folder as device connection.
- Do not duplicate ForgeMASTER, original EITRIFACTORY, RavenNest, BIFROST, AI Toolkit, WORKinCODEX or WORKAIcloud. The factory routes specialists and approved workers.
- **UNVERIFIED**: 413 archive bodies, binary ZIP internals, exact changed URLs, third-party repo source deep audits, installed Mac MCPs, live EITRIFACTORY adapter execution, original release LKG promotion, WebMCP/browser client run, fullresearch of every referenced related site.

## Next gate
A provider-compatible binary export or mounted read-only archive must be obtained for each WebArchive. Then use Python `plistlib` to extract `WebMainResource.WebResourceURL`, MIME, HTML bytes and `WebSubresources` plus hashes; crawl distinct original site URLs and their license/README/security/release related links. Record denominator 413 (or updated after nested path scan), per-entry success/error and live-source URL. Continue source-first, protect credentials/cookies and do not assert DONE before 413/413 actually examined.
