# KUROSAWA — source intake and external capability research
<!-- Non-authoritative append-only research record. Current Mac Project Bible/LKG takes precedence. -->
Date: 2026-11-10
Status: SOURCE_READ_PARTIAL / PROPOSALS_ONLY / NOT_INSTALLED / NOT_PROMOTED
Scope: KUROSAWA audiovisual Director and production manager. Do not treat research as implementation approval.

## Authority and reconciliation
- Latest recovered KUROSAWA project/source and Project Bible: Dropbox `/EDEN-lucas-dev/EDEN app/KUROSAWA/` (read on 2026-11-10), backed by current physically established `~/edenOS/Software Development/KUROSAWA/` according to its HANDOFF.md. Dropbox copy contains KurosawaKit, App, macos, ios (historical), project.yml, KUROSAWA.xcodeproj, GUI sources, in-chat prompt and product guides.
- Current Project Bible/HANDOFF: native **macOS** Apple-Silicon KUROSAWA studio is the active standalone execution scope. iOS/iPadOS is NOT a required target or acceptance gate; an older GitHub handoff still says otherwise and is not sufficient to supersede the newer canon.
- Old GitHub `lucasbuzek/Lucas-Private-edenOS-apps/KUROSAWA/HANDOFF.md` still describes 2026-10-09 initial Swift package and 2 tests. Do not sync old files over current project or designate this repo authoritative without source reconciliation.
- Current Dropbox HANDOFF reports Swift 32/32 October 17, 2026, macOS Release arm64 PASS, ad-hoc candidate, NLE FCPXML 1.9 limited 30fps source cuts, and absence of Final Cut/Resolve host import acceptance. Prior conversation reports 42/42 October 19; not independently retested here. Code examined: KurosawaCore/NLEInterchange.swift, NLEWorkflow.swift, ProviderCatalog.swift, NativeVision.swift, MediaAudit.swift. SOURCE_READ is not a fresh host test.
- Preserve native NLE ownership: Final Cut Pro first, DaVinci Resolve second, Premiere Pro third. Maintain separate media stems/tracks, source and rights provenance, non-destructive edits and explicit format-loss reports.
- Existing Photoshop Workflow Library is a separate independent peer; current canon only authorizes research, offline guide/catalogue, static checks. Do not launch Adobe or modify originals without separate permission.

## Sources scanned: exact provenance and limits
1. Dropbox folder `/EDEN-lucas-dev/AI MCP tool/` resolved via Dropbox search, folder id `id:KqcGNtH_uy8AAAAAAAWbXA`. Its mounted namespace source `ns:13844906001//` contained 345 top-level entries as listed by Dropbox, mostly `.webarchive`, `.html`, `.url`, and grouped research folders. Entries are *links/research*, not installed plugins or vetted source archives. Dropbox text fetch could not extract several Safari webarchives.
2. Dropbox `#AIcustom/#creative/` includes references labelled DaVinci Resolve MCP, DaVinci MCP Professional, LogicProMCP, OBS MCP, short video tools, generation tools; `#AIcustom/#3d modeling/` includes reference links for 3D adapters; do not equate catalog titles with runtime verification.
3. Dropbox `/EDEN-lucas-dev/EDEN app/KUROSAWA/`: read Project Bible, HANDOFF, README and five Swift source files; named candidate file remains under the established Mac root; no source files changed.
4. AppleRAVEN owner-paired Mac `Lucas-MacBook.local` device `mac_66ea038df1a9cf796ccd2fed`: read `/Users/lucas/Downloads/#to ingest` listing on 2026-11-10: 178 items: 148 JPEG (`.jpeg`), 25 JPEG (`.jpg`), 2 AVIF, 2 ZIP (`Universal_AI_Toolkit_Final 2.zip`, `Universal_AI_Workspace_Bundle.zip`), 1 `.DS_Store`. Contents of 175 images and exact ZIP bytes are NOT yet inspected or ingested. Current KUROSAWA HANDOFF records 320 reference catalogue entries already imported from `Universal_AI_Toolkit_Final 2.zip`: 172 tools, 76 models, 72 utilities. Compare revisions/digests before duplicate import. No originals moved/deleted.
5. Google Drive Lucas account: no KUROSAWA-titled project sources found in the scoped search. RAVENsNEST account found only incidental media index files; no canonical KUROSAWA Drive destination confirmed. No Drive writes made.
6. QuickMemory MCP v0.4.0 reports `QUICK_CAPTURE_AVAILABLE` but `persistence_live:false`, `ingestion_enabled:false`, `source_reads_enabled:false`, `downloads_enabled:false`, `writes_enabled:false`. This note is NOT a verified complete QuickMemory ingestion, and source hard-copy/restore gates remain open.

## Reuse candidates (source-backed, no automatic installation)
### High priority: frame-accurate NLE interchange
- Gap: local `NLEInterchange.swift` exports FCPXML 1.9 with fixed 30fps and imports a supported asset-clip/spine subset; real Final Cut/Resolve roundtrip not proven, complex tracks/effects rejected.
- Candidate: `https://github.com/ChatOctopus/timeline` provides FCPXML 1.8, xmeml v5 and OTIO read/write, rational frame math, conversions and validation. Important limitation: not full FCPXML coverage; format/version differs from KUROSAWA output. Evaluate license, semantic compatibility, local wrapping, no automatic adoption. Alternative/reference: AcademySoftwareFoundation/OpenTimelineIO.
- Proposed feature: versioned interchange adapter with 23.976/24/25/29.97/30/50/59.94fps, discrete audio/stems/titles/captions, edit markers, relink identity, translation-loss manifest and native NLE round-trip tests. Preserve native editing ownership.

### High priority: Resolve agent adapter
- Stored source link names in `#AIcustom/#creative` include DaVinci MCP Professional and multiple Resolve servers.
- Upstream examples: `https://github.com/samuelgursky/davinci-resolve-mcp`, `https://github.com/hoyt-harness/davinci-mcp-professional`. The latter exposes domain-activated MCP tools, but requires DaVinci Resolve Studio and is GPL-3.0; assess its compatibility, security and licensing before reuse. Resolve scripting depends on installed/authorized local application. This is the *second* editor after FCP, not a replacement pipeline.
- Proposed feature: capability discovery, approval-gated read/annotate/import/render commands, persistent returned-edit job and checksum/relink verification. Do not use unrestricted editor automation.

### High priority: 3D previsualization adapter (DÜRER/Blender peer)
- Public sources: `https://github.com/kleer001/blender-mcp` (typed Blender MCP tools) and `https://www.blender.org/lab/mcp-server/`. Blender's own page warns its example MCP can execute model-generated Python without guardrails; evaluate confined permissions and project copies. Never grant arbitrary code to production originals.
- Proposed feature: per-shot camera/lens/light setup, animatics, scene/blocking exports, provenance manifests, ordered queued renders and deterministic review; DÜRER owns geometry.

### Medium priority: cinematography reference retrieval
- Saved URL `i_built_a_massive_cinematic_reference_library_for.url` points to Reddit reference collection; inspect rights before any image copying.
- External `https://github.com/framethrower-ai/framethrower-mcp` describes film-frame metadata searches and an initial credit offer, not a free unlimited local library.
- Proposed feature: searchable *licensed/reference links* by framing, movement, lens, light/color/mood, captured as attributed inspiration in the Creative Bible. Do not copy film frames into release assets without rights.

### Optional: external generated content / cloud delivery
- `https://github.com/strato-space/media-gen-mcp`: typed image/video provider tooling with output resource links; OpenAI/Google paid API/model access is NOT default/local/free and requires user choice.
- `https://www.mux.com/docs/integrations/mcp-server`: hosted video/live and performance management; no reason to make Mux a native editing or offline prerequisite.
- `https://mcp.jsoncut.com/mcp` / `https://jsoncut.com/docs/studio/`: OAuth remote editable layers/video projects; a SaaS adapter only if project needs it. The older `jsoncut/jsoncut-mcp-server` GitHub repository is deprecated in favor of remote endpoint.
- Proposed feature: per-production provider choice, price/credits/auth disclosure, reversible job ledger, independent generated media/stems, download and provenance verification, no silent paid runs.

## Already exists in current source — DO NOT duplicate
- Core hierarchy, brief, Council, continuity, scene/shot/take selection, persistence, checksum/media relink, local Apple Vision, local capability/provider detection, one-source production authority, FCPXML 1.9 candidate, nle-handoffs state, limited curated Universal AI Toolkit browser.
- Photoshop Workflow Library and CURATOR existing workflow patterns are independent peer sources; do not create replacement Adobe application/NLE.
- Existing 320-entry Universal_AI_Toolkit_Final catalogue needs revision/hash comparison only; do not blindly import as a new product.

## State, safeguards and next evidence gates
- SAVE RECEIPT: this is a non-destructive *research record* only; no native code, existing guides, production media, rollout status or old repositories modified.
- Research coverage remains PARTIAL: Safari webarchives only indirectly resolved via names/upstream; no original-source Git bundles/verified source-hash archives for proposed third-party code. Rights/license audits and machine tests remain open.
- Local image intake needs asset-level content review to classify actual photographs/screenshots and source attribution. The files are preserved unmodified. The Mac AppleRAVEN Files allowed roots include Downloads, not ~/edenOS.
- Exact next gates: (1) read image contents/source names, extract link subjects without blind OCR, verify ZIP duplicates/revisions (2) resolve upstream license/security/versions and secure hard copies under QuickMemory's source-backup contract (3) perform safe compatibility spike in a separate worktree before importing code (4) on-device FCP/Resolve integration acceptance with user media copies (5) update original KUROSAWA project canon only after user-approved and source-backed feature decision.


## Cross-check with existing QuickMemory Google Drive research (2026-11-10)
- Existing RAVENsNEST Google Drive QuickMemory corpus was located; no new folder or competing memory index was created. This corpus is already separately attributed, source-versioned and private.
- `fmhy-ai-video-generation.md` (Drive file `1pNlAzcU8HBaWHk15oz4bq9qVBYsZvHOu`, ID `QM-20261109-FMHY-VIDEO`) indexes 15 source lines and 27 link occurrences, including VBench benchmark, Wan, FramePack and hosted services; its own status is `source-extracted-upstream-claims-unverified`. FramePack's directory description says NVIDIA required; incompatible as a direct M1 baseline without a different supported backend. These are discovery links, not proof of free credits or permissions.
- `fmhy-ai-audio-generation.md` (Drive file `1jmvsSgsO4_xnczhKn3N0o8oc6FfIE-e-`, ID `QM-20261109-FMHY-AUDIO`) indexes speech, audio separation, sound and music tools. Because KUROSAWA delegates music/sound authority to a separate specialist, the correct proposed reuse is discrete, provenance-preserving stems via a capability adapter, not incorporation of a DAW.
- `fmhy-ai-image-generation.md` (Drive file `1JxrxpEAfIrNn3Fat-orftgzk3cDRT_Bm`, ID `QM-20261109-FMHY-IMAGE`) provides image generation/local frontend links. Attribution and per-provider license/cost/security verification required; avoid duplicates of current `ProviderCatalog.swift` / toolkit browser.
- `mediafinder-local-media-manager.md` (Drive file `1CUADCbUpeMVSZrxhFXzFL-IfkCt1UOMY`, ID `QM-B001-MEDIAFINDER`) documents an existing **Windows/PySide6, GPL-3.0** media indexing project with SQLite FTS5 and playback. The knowledge record says its original Git source was hard-copied to Drive and hash-readback verified on 2026-11-08; this fact belongs to MediaFinder's own project record, **not** a KUROSAWA source-backup receipt. Reuse only conceptual patterns for source media discovery/search; do not import GPL code or another full media manager into KUROSAWA without explicit license/architecture review.
- These four Google Drive records were *read*, not rewritten. Their original knowledge content and source snapshot authorities remain separate. No QuickMemory end-to-end ingestion receipt for this KUROSAWA batch exists.
