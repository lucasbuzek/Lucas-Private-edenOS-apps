# KUROSAWA — MCP-first source/reuse evidence (2026-10-29)

**Status: candidate research; not canonical Project Bible, deployment or accepted LKG.**

## User-supplied Dropbox archive
Authenticated share metadata for the supplied link resolves to `/EDEN-lucas-family/AI MCP tool`. Listing returned 411 top-level entries (complete page); `#webMCP` subfolder had 41 entries (complete page). The link is PUBLIC with EDIT permission, security concern, unchanged. The previous path `/edenOS apps/AI MCP tool` is not assumed identical.

Relevant archived webpage filenames: Photoshop MCP; DaVinci Resolve MCP by mateo-khalil, lordhoell, BillyRaz, realmikeshu and others; DaVinci MCP Professional by hoyt-harness; OpenSubtitles; media-generation MCPs; macOS Automator. Filename inventory is **not** content extraction: two direct `.webarchive` text extractions failed and local binary downloads were unavailable. Verify archive content separately before reusing.

## Live primary/upstream source
- [DareDev256/fcp-mcp-server](https://github.com/DareDev256/fcp-mcp-server): independently read README, MIT LICENSE, pyproject.toml from upstream GitHub. Version 0.27.2 observed, Python >=3.10, `mcp>=1.21.1`, `defusedxml`; upstream advertises 15 grouped tools/102 FCPXML editing operations, read/write, QC, undo, preview and NLE interchange. **Reuse as optional independent Final Cut editor MCP; do not replace KUROSAWA production-model authority.** Actual FCP app integration NOT tested here.
- [mateo-khalil/davinci-resolve-mcp](https://github.com/mateo-khalil/davinci-resolve-mcp): free Resolve in-process Lua bridge candidate; `resolve_eval` arbitrary Lua is high-risk, not automatically exposed.
- [hoyt-harness/davinci-mcp-professional](https://github.com/hoyt-harness/davinci-mcp-professional): GPL-3.0/Studio prerequisite, domain-activated tool approach; separate licensing gate.
- [drmedia/photoshop-mcp](https://github.com/drmedia/photoshop-mcp): Photoshop UXP candidate; macOS host functionality remains unverified.
- [Apple FCPXML reference](https://developer.apple.com/documentation/professional-video-applications/fcpxml-reference): official interchange rather than native library replacement.

## Actual local additive engineering
The existing V4 18-tool Swift KUROSAWA MCP was tested with its preserved **Linux** executable, without adding any new Swift tools or modifying the core. Additive `qa/editor_adapter_gate.py` in isolated V5 transfer exercises legacy initialize, tools/list, kurosawa_status **read-only** in a fresh temporary workspace and optionally does only initialize + tools/list against a separately configured trusted external editor MCP. No editing operations, shell execution from MCP input, installation, or paid calls. Tests: Swift 8/8; Python QA 48/48 (34 previous, 9 previous independent client, 5 new adapter-gate; external editor was a MOCK). New release build timed out; only prior V4 executable passed this turn. V5 archive SHA256 `8351ffce43783adc619f230e515eaf1a2d6224db30bd184395182dcb8f48e16c`, transferred in ChatGPT, not installed or promoted.

## Gates
1. Real installed external editor MCP read-only discovery in authorized host, not a synthetic stand-in.
2. Real Final Cut FCPXML import/roundtrip into disposable project; then other NLEs and Photoshop.
3. Reconcile the later original native Mac source/dirty state/accepted LKG before any merge or install. Preserve main.
4. Complete KUROSAWA native UI, media engine, AI/provider routing, specialist/online-storage integration and release acceptance. The standalone MCP remains priority FIRST.
