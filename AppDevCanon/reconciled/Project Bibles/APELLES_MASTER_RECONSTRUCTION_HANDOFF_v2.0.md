# APELLES MASTER RECONSTRUCTION HANDOFF v2.0

**Status:** AUTHORITATIVE CONVERSATION-DERIVED RECONSTRUCTION INPUT
**Date:** 2026-10-03
**Purpose:** Rebuild APELLES from scratch without access to the originating ChatGPT conversation. Unknown physical benchmark results remain PENDING/UNVERIFIED and must not be invented.

## Identity and goal

**APELLES — Adaptive Production, Editing, Learning & Local Engine for Synthetic/Source Imagery**. User-facing descriptor: **APELLES — Visual Production Studio**. Inspired by Apelles, master painter of antiquity. Preserve both the historical inspiration and full acronym.

APELLES is an independent EDEN still-image application/package for local image generation, reference-controlled photographic series, generative photo editing and visual asset production. Private/Custom APELLES targets the user's MacBook Pro M3 Pro and must create coherent series from reference images plus lists of poses, locations, wardrobe/body-presentation choices, camera/framing, lighting and looks. It must support the full lawful private figure-study and wardrobe range required by the user, without making cloud inference a dependency.

Private baseline: free/no subscription, no generation credits, no required paid API, local/offline after provisioning, reuse open-source/existing software and model ecosystems rather than starting from scratch, automatic provisioning rather than manual downloader/runtime/model configuration, and normal import/upload plus image/package export.

## Hardware

Target Apple Silicon M3 Pro. **16 GB unified memory is the genuine functional floor; 18–24 GB is enhanced.** One installer detects hardware automatically. At 16 GB use quantization/optimization, aggressive unload/offload, one major model at a time, bounded concurrency and staged upscale. 24 GB may unlock larger optional models or reduce unloading but must not define core functionality. Prefer efficient working-resolution generation followed by selective final upscale.

## Core functionality

Implement text-to-image; reference-to-image; multiple reference roles; subject/identity consistency; pose control/extraction; location/background control; wardrobe/body-presentation replacement; camera/framing/composition; lighting/look; anatomy/pose fidelity; batch/series combinations of subject × pose × location × wardrobe × camera × lighting; persistent resumable jobs; incremental save after every completed image; variants; compare/review; contact sheets; photo editing; masking/segmentation; inpaint/outpaint; object/person/background/garment selection and replacement; restoration/upscale; depth; normal/control maps where useful; reusable/correctable pose assets; and visual assets for apps/games/DÜRER.

Prefer direct manipulation: select/click subject, garment, background or object and request the change. Do not force routine users to understand masks or node graphs.

## UI/UIX

Canonical native macOS workspaces: **Studio · Series · Edit · Assets**. Supporting surfaces: lightweight Files browser, central image canvas, contextual Inspector and activity/progress. The image owns the screen; technology serves the image. Modern photographic atelier/light-table identity; no pseudo-Greek decoration, generic AI-chat shell or exposed ComfyUI graph as normal UI.

Studio = everyday generation/reference work. Series = structured multi-image production. Edit = non-destructive/generative editing. Assets = visual asset preparation/handoff. Use **Simple / Advanced / Expert** progressive disclosure. Normal UI uses photographic language such as Subject Likeness, Pose Fidelity, Framing and Lighting; model IDs/sampler/quantization/backend internals belong in Expert/diagnostics.

Series shows planned count, storage estimate, progress, completed/failed, pause/cancel/resume, retry, review and contact sheets. User can add/drop/import files and save/export individual results or whole packages.

## Files, RAW, metadata and packages

Do not build a new RAW developer: macOS already reads supported RAW. Preserve original RAW untouched and use native rendered representations for APELLES processing. Do not build a full DAM: CURATOR owns professional media/library/curation semantics. APELLES needs lightweight Files/reference organization only.

Use native metadata APIs first and **ExifTool** for deeper EXIF/IPTC/XMP interoperability. **Adobe Bridge** is an optional Private workflow, especially through CURATOR; **digiKam** is an acceptable free/open-source alternative. Neither is required for standalone APELLES.

The proposed proprietary `.apellespack` was rejected. Canonical package interchange is ordinary **ZIP with images/assets plus XMP sidecars**, optionally including a JSON manifest for APELLES-specific lineage/reproducibility. Example: Images/, optional Originals/, References/, Assets/Masks/, Assets/Depth/, Assets/Normals/, Contact Sheets/, XMP and Manifest/apelles-manifest.json.

Never silently overwrite/delete originals. Maintain source→derivative and multi-parent lineage. Preserve appropriate EXIF/IPTC/XMP, orientation, ICC/ColorSync and useful precision/bit depth; avoid needless forced 8-bit sRGB. Do not fabricate Lightroom/Camera Raw Develop settings. APELLES-specific model/revision/hash/seed/reference/pose/lineage fields may use namespaced XMP and/or JSON. Offer GPS/private-metadata stripping. Record model identity/revision/hash rather than embedding huge weights in packages.

## Existing Capability First

Mandatory sequence: **SEARCH → VERIFY → COMPARE → REUSE → INTEGRATE → ADAPT → BUILD ONLY WHAT IS MISSING → TEST.** Prefer platform-native → installed app/system capability → small proven library/framework/CLI → specialist/provider → custom code only for the gap. Reuse macOS RAW, ExifTool, CURATOR/Bridge/digiKam, Core ML/MLX and proven local-generation ecosystems rather than recreating them.

## Runtime

APELLES is model-agnostic. Preferred execution order: (1) macOS/native frameworks and Core ML where adequate; (2) MLX/Apple-Silicon-native paths; (3) ComfyUI/PyTorch MPS for broad generative workflows. ComfyUI is a hidden local backend/API, never the product UI. Build explicit engine protocols/adapters.

Use shared model/cache storage where practical. Track exact source/revision/hash, architecture, precision/quantization, license/use class, capabilities and evidence. Shared physical weights do not merge app/assistant identities. Prefer safe model formats and verified sources; do not blindly execute arbitrary downloaded custom-node code. Local Only must disable external inference/network dependencies.

## Researched model candidates — NOT M3 VERIFIED

**Z-Image-Turbo — PRIORITY A base generation.** First to qualify: comparatively efficient 6B-class family, photorealistic/instruction-oriented, researched Apache-2.0 release and Apple-Silicon/MPS path.

**FLUX.1-schnell — PRIORITY B generation fallback.** Fast low-step generation and researched Apache-2.0 release; larger/heavier, so test quantized/offloaded Apple-Silicon configuration rather than assuming 16 GB suitability.

**Stable Diffusion 3.5 Medium — COMPATIBILITY/FALLBACK.** Resource-conscious SD-family candidate and mature control/LoRA ecosystem. Record exact license/use conditions in manifest.

**Qwen-Image-Edit-2509 — ADVANCED EDIT CANDIDATE.** Powerful instruction editing but large (Qwen-Image family around 20B class); quantization/offload qualification is required, especially at 16 GB. Do not install full large repositories blindly in Recommended.

**FLUX.1 Kontext [dev] — PRIVATE ADVANCED EDIT CANDIDATE.** Eligible for the stated Private/non-commercial use where its license permits; not an Official/public default.

**SAM 2 family — CORE SEGMENTATION CANDIDATE.** Subject/garment/background/object selection, masks and edit masks. Benchmark smallest adequate variant.

**Depth Anything V2 Small Core ML — PREFERRED CORE DEPTH CANDIDATE.** Lightweight Apple/Core ML path useful to APELLES and DÜRER.

**Real-ESRGAN — CORE RESTORATION/UPSCALE CANDIDATE.** Predictable relatively lightweight faithful path; heavier generative enhancement remains optional.

**Pose/identity stack — UNRESOLVED PHYSICAL QUALIFICATION.** Research/benchmark DWPose/OpenPose-compatible pose extraction/control plus suitable identity/reference conditioning. Do not freeze an untested winner. This is the highest-priority unresolved model area because coherent subject series is a primary use case.

Machine-readable manifest fields: canonical ID, role, upstream source, exact revision/hash, architecture, precision/quantization, license/use class, backend, disk size, memory observations, functions, qualification state/evidence, fallback and LKG status. Recommended installs the smallest complete qualified stack; heavier/optional models download on demand. Pin model revisions for existing projects and support rollback/LKG.

## Physical qualification

On target M3 Pro test: text→photo; reference→photo; reference+pose; identity consistency across a small series; mask/inpaint; wardrobe/body-presentation change; background/location change; restoration/upscale; segmentation; depth/control extraction; persistent/resumable multi-image series. Record quality, identity fidelity, pose adherence, anatomy/hands, edit fidelity, timing, memory/resource behavior, storage, stability and failures. Download/build/import success is not capability PASS. UNKNOWN remains UNKNOWN.

## Installer/downloader

User explicitly requires one-click setup and does not want to manually configure Homebrew/downloaders/models where automation is possible. Detect macOS/Apple Silicon/memory/storage and existing software; bootstrap official Homebrew automatically if absent and needed; reuse adequate installs; provision Git/Git-LFS, aria2, uv/Python and Hugging Face tooling only where required; permit other proven download mechanisms automatically; resume/retry downloads; verify revisions/hashes; use shared caches/model store; support external storage relocation; avoid routine manual model placement; preserve user/project data during maintenance; provide Launch, Verify, Update, Repair and Uninstall; resume interrupted provisioning.

Profiles: **INSTALL/RECOMMENDED** balanced/device-aware and defers heavy optional components; **LEAN** minimum core; **FULL** all appropriate supported capabilities without pointless duplication; **CUSTOM** explicit component/provider/model control.

Also provide a separate **model downloader script** as an extra utility. It reads the manifest, offers capability/profile selection, shows size/license class, resumes downloads, verifies revision/hash and places weights in shared storage.

## Persistent jobs/recovery

Series work is persistent, not a transient UI loop. Save every successful result immediately. Quit/crash/sleep/power interruption must preserve completed work. Failed attempts remain evidence. Retries preserve failure records and record changed parameters/workflow. Estimate disk/temp requirements before large jobs and retain a safety margin. Support pause/cancel/resume. Generation history retains structured user intent, effective engine parameters, model/revision/hash, seed where applicable, reference roles and lineage. Distinguish preserved reproducibility inputs from genuinely deterministic reproduction.

## Independent peer packages

CONDUCTOR, CURATOR, CASPER and CASPER's established subordinate specialist system, KUROSAWA, DÜRER, IRIS, ARTEMIS and APELLES are separate independent apps/packages. Each retains identity, domain authority, canon/context, tools, lifecycle, UI/runtime and local/native AI capability. APELLES may call peers and peers may call APELLES; APELLES works standalone when peers are absent.

Implement a small versioned peer contract for discovery, invocation, progress, cancellation, result/artifact and package exchange. Direct peer-to-peer calls are allowed. CONDUCTOR may orchestrate but does not own peers. Shared runtimes/models are infrastructure optimizations only.

### CURATOR
Professional photography/media-management and curation authority: organize/classify/find/curate, collections, metadata, provenance, asset routing, selection and publishing. APELLES supplies generated/edited derivatives without replacing authoritative originals/library ownership. CURATOR may optionally use Bridge/digiKam. CURATOR may call CASPER for narrative/social/publishing text and KUROSAWA for moving-image work.

### DÜRER
Independent 3D/CAD/technical/game/app asset specialist. Reuse APELLES visual core where adequate rather than installing a redundant default image stack. APELLES may supply references, concepts, masks, segmentation, depth/normal, textures/material references, cutouts, sprites/icons. Specialist image-to-3D/reconstruction models are optional/on-demand. Visual plausibility is not dimensional/technical validation; DÜRER retains that authority.

### KUROSAWA
Video was considered as an APELLES optional model download, then correctly assigned to KUROSAWA. KUROSAWA owns moving-image/cinematic production and is broader than a video generator: development/planning → sequence → scene → shot → take/generation → selection → edit → continuity/version → deliverable. Video-specific models/heavy runtime are optional KUROSAWA provisioning; compatible physical components may be shared. APELLES hands it stills/masks/depth/references/storyboards/look assets.

### CASPER
Separate full publication/creative-authoring system, not merely captions. Preserve its established subordinate specialists and broad scope: prose/books/articles, social copy, narrative development, treatments, dialogue, scripts/screenplays, drafting, rewriting/editing, continuity and publication preparation. CURATOR/KUROSAWA/APELLES may call CASPER as appropriate; neither owns it.

### IRIS
Visual understanding/inspection, comparison, interpretation, critique/assessment/QA; native/on-device visual capabilities first where adequate.

### ARTEMIS
Autonomous asset creation/production specialist. Preserve the rule that a generated asset is not automatically a finished/validated/integrated asset. ARTEMIS may call APELLES for image generation/transformation and APELLES may hand broader production to ARTEMIS.

### CONDUCTOR
Orchestration/governance/intelligence. Principle: AI reasons; deterministic services execute. It can route among peers but is not required for standalone APELLES.

## Private local AI / Assistant Helper

Official releases may use a lightweight **Assistant Helper** local-intelligence layer for offline interpretation/routing. Private/Custom CONDUCTOR, CURATOR, CASPER/subordinates, KUROSAWA, DÜRER, IRIS, ARTEMIS and APELLES may each have complete local/native AI appropriate to domain. Each may use Apple native/on-device intelligence, a shared tiny local model, or an optional stronger dedicated specialist tiny/local model. Shared is preferred when adequate; specialist models are optional/on-demand. Dynamically load/release under memory pressure. Models are infrastructure, not assistant identity; do not bake project canon into model weights.

## BIFROST / HEIMDALL correction

Do not conflate products. **BIFROST app** = specifically Voice of/for HEIMDALL through Siri, the Apple-native Siri/voice bridge. **HEIMDALL iOS** = separate native iPhone/iPad app/package. **HEIMDALL desktop/server** = separate macOS/Windows/Linux package. Canonical: `BIFROST != HEIMDALL iOS != HEIMDALL desktop/server`. Do not name the generic peer protocol BIFROST.

## Privacy/security

Core is local-first/offline after provisioning. Provisioning/model network use must be visible. Local Only prevents external inference. Do not silently upload source/reference photos. Validate model sources/revisions/hashes; prefer safe serialization; treat custom nodes/scripts as executable code requiring qualification. Keep credentials/secrets out of exported packages. Support privacy metadata/GPS stripping.

## Governance

Apply current EDEN/AppDev evidence rules. Commands authorize work but are not evidence. Preserve LKG. State progression is evidence-based: REQUESTED → PLANNED → IN PROGRESS → IMPLEMENTED → VERIFIED → ACCEPTED → AUTHORITATIVE where applicable. FAILED/UNVERIFIED/PIPELINE INCOMPLETE is not a blocker while safe repairable work remains. Genuine blocker requires attempted action plus demonstrably unavailable dependency. Missing historical source may be reconstructed from trustworthy evidence but identified as reconstruction. Retry must change something. Functionality before presentation.

FORGE path: REFERENCE → BASELINE → IMPLEMENT → STATIC VERIFY → ENVIRONMENT VERIFY → REGRESSION VERIFY → PACKAGE → PACKAGE VERIFY → PHYSICAL GATE → PROMOTE. Do not promote a model because it downloaded or a UI because it compiled.

## Codex implementation deliverables

Codex should implement, not return another design document: native Xcode/Swift/SwiftUI app; Studio/Series/Edit/Assets UI; domain/project/reference/series models; persistent job/recovery; Finder drag/drop/import/export; native RAW intake; XMP/ExifTool; ZIP+JSON manifest; engine protocol; hidden ComfyUI API adapter; Core ML/MLX integration boundaries/native helpers; shared model store/manifest; 16/18/24 GB hardware detection; candidate downloader; qualification/benchmark harness; bootstrap INSTALL/VERIFY/UPDATE/REPAIR/UNINSTALL; tests possible without production weights; evidence logs/reports; README/recovery/build docs; physical M3 verification entry point; versioned peer capability protocol.

Do not invent M3 performance, select models by reputation alone, absorb peer apps, rebuild DAM/RAW development, or make APELLES merely a ComfyUI wrapper.

## Pipeline

P0 preserve/sync canon/evidence. P1 implement skeleton/runtime abstractions/model manifest/qualification harness. P2 implement bootstrap/downloader/acquisition without false PASS. P3 physically qualify generation/edit/pose/identity/segmentation/depth/upscale on M3 and establish first model LKG. P4 complete functional engine/persistent series around qualified stack. P5 production native UI/UIX. P6 peer and optional external-tool integrations. P7 regression/package/installer verification. P8 user physical acceptance/promotion. M3 unavailability blocks P3 evidence, not P0–P2 preparation.

## Reconstruction rule

This file is intended to eliminate dependence on the originating chat for APELLES product reconstruction. A developer receiving it should know what APELLES is, what it does, its UI, files/packages, runtime, provisioning, model candidates and rationale, hardware behavior, peer boundaries, local-AI architecture, security and evidence gates. `UNVERIFIED/PENDING` means the requirement is established but the physical implementation winner/result still needs evidence; it is not permission to redesign the product.
