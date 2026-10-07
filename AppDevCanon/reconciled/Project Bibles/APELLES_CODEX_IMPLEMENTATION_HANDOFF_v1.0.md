# APELLES CODEX IMPLEMENTATION HANDOFF v1.0

**Mode:** AUTO — continue all safe work until a genuine blocker or the physical M3 qualification gate.
**Project:** `~/edenOS/Projects/APELLES`
**Target:** native macOS / Apple Silicon, M3 Pro, 16 GB functional floor, 18–24 GB enhanced.

## Authority and execution rules

If available, read in this order before implementation:
1. `~/edenOS/Projects/#appDev Bible/`
2. `~/edenOS/Projects/APELLES/PROJECT_CANON.md`
3. GitHub `lucasbuzek/Lucas-private-appDevDocs/Project Bibles/APELLES.md`

This handoff is intentionally self-contained enough to continue if one external source is unavailable, but it does not supersede newer explicit authority. Do not restart product design or reconstruct canon from assumptions.

AUTO means execute, not merely plan. Preserve LKG before extension. Commands are authorization, not evidence. FAILED/UNVERIFIED/PIPELINE INCOMPLETE is not a blocker while a safe repair action remains. Retry must change something. Do not claim M3/model PASS without physical evidence.

## Product identity

**APELLES — Adaptive Production, Editing, Learning & Local Engine for Synthetic/Source Imagery**

Inspired by Apelles, master painter of antiquity. User-facing descriptor: **Visual Production Studio**. APELLES is an independent EDEN still-image production/editing app/package. It is not a generic AI frontend and not a container for other EDEN assistants.

Design identity: modern photographic atelier/light-table. **The image owns the screen; technology serves the image.** No generic chatbot-dominated UI, exposed ComfyUI graph as product UI, pseudo-Greek decoration or unnecessary infrastructure terminology.

## Functional scope

Implement local/offline-capable:
- text → still image;
- reference → image;
- multi-reference roles and identity consistency;
- subject/identity, anatomy, pose, location, wardrobe, camera/framing, lighting, composition and photographic-look controls;
- reusable pose extraction/control assets and correction UI/data model;
- masks/segmentation;
- inpainting/outpainting;
- object/background/wardrobe replacement;
- restoration/upscale;
- depth/normal/control extraction;
- variants and compare/review;
- contact sheets;
- persistent/resumable batch and series jobs;
- incremental output so completed items survive failure/interruption;
- image/visual asset preparation for DÜRER and compatible peers.

APELLES is free/private/non-commercial by baseline: no subscription, credits, mandatory paid API or mandatory cloud inference. After provisioning, core work must operate offline.

## Explicit non-goals

Do not rebuild Lightroom/Adobe Camera Raw, Adobe Bridge, a full DAM, CURATOR, CASPER, KUROSAWA, DÜRER, IRIS, ARTEMIS or CONDUCTOR inside APELLES.

Use existing capability first. macOS handles supported RAW decoding. CURATOR owns DAM/library authority and may optionally use Adobe Bridge or digiKam. ExifTool may provide deeper metadata interoperability. KUROSAWA owns video. DÜRER owns technical 3D/CAD/game/app asset validation. CASPER owns publication/creative authoring. IRIS owns visual assessment. ARTEMIS owns visual creation specialist work. CONDUCTOR owns orchestration/governance.

## Native UI/UIX

Build a native SwiftUI/AppKit application with four primary workspaces:
- **Studio** — generation/reference work;
- **Series** — planned/batch photographic production;
- **Edit** — non-destructive/generative editing;
- **Assets** — image/visual asset preparation and handoff.

Supporting surfaces: lightweight Files browser, central image canvas and contextual Inspector. Use Simple / Advanced / Expert progressive disclosure. Simple/normal UI uses photographic language such as Subject Likeness and Pose Fidelity. Expert may expose models, sampler/steps, quantization and engine internals.

Series must expose plan size, estimated storage, progress, pause/resume, failures/retries, review/contact sheets and persistent state. Direct manipulation should be preferred: select/click garment/person/background/object, then request change rather than forcing manual mask plumbing.

## File workflow

Support Finder drag/drop, Add Files/import, folder/batch intake, normal images, macOS-supported RAW, references, poses, masks, textures and supported asset references.

Source/original files are immutable by default. Maintain source → derivative lineage and allow multi-parent lineage for composites.

Do not implement a proprietary `.apellespack` requirement. Export normal image/assets plus XMP sidecars. Series/project/archive transfer uses ordinary ZIP containing images/assets/XMP, optional originals, contact sheets and `Manifest/apelles-manifest.json`.

Read/preserve appropriate EXIF/IPTC/XMP. Use native APIs first and ExifTool when useful. Do not fabricate Adobe Camera Raw/Lightroom Develop fields. APELLES-specific reproducibility/lineage may use namespaced XMP and/or JSON. Provide optional GPS/private-metadata stripping.

Respect ColorSync/ICC, orientation and source metadata. Avoid unnecessary forced 8-bit sRGB conversion. Preserve useful bit depth/precision where supported.

## Runtime architecture

Product layer is Swift/native-first. Prefer:
1. macOS/native frameworks and Core ML where adequate;
2. MLX/Apple-Silicon-native execution where adequate;
3. ComfyUI/PyTorch MPS as hidden generation/workflow backend when its ecosystem is advantageous.

Create engine protocols/adapters so APELLES is not coupled to ComfyUI. ComfyUI may be launched/managed headlessly/local-API style but is never the ordinary APELLES UI.

Implement shared model/cache storage, model identity/revision/hash tracking, capability metadata, project model pinning and rollback/LKG support. Support model/cache relocation to external storage.

Security: prefer safe model formats, validate source/hash/revision, and do not blindly execute arbitrary downloaded custom-node Python. Implement enforceable Local Only mode.

## Hardware profiles

Single installer, automatic detection.

**16 GB M3 Pro:** mandatory functional floor. Quantized/optimized models, aggressive unload/offload, one major model at a time, staged upscale.

**18–24 GB:** enhanced profile; permit larger optional models and reduced unloading where evidence supports it.

Never design core functionality around 24 GB and merely label 16 GB supported. Implement memory-aware scheduling and avoid concurrent residency of unrelated large models.

## Candidate models — UNVERIFIED until physical M3 tests

Treat every candidate below as UNKNOWN/UNVERIFIED, not selected production authority:

- **Z-Image-Turbo** — Priority A base-generation candidate; first to qualify.
- **FLUX.1-schnell** — Priority B generation fallback; qualify Apple-Silicon quantized/offloaded route.
- **Stable Diffusion 3.5 Medium** — compatibility/fallback, especially mature control/LoRA ecosystem.
- **Qwen-Image-Edit-2509** — advanced edit candidate; large, so quantized/offloaded qualification required.
- **FLUX.1 Kontext [dev]** — Private/Custom advanced edit candidate only where its non-commercial/private-use license fits; not an Official default.
- **SAM 2** — segmentation family; benchmark smallest adequate variant.
- **Depth Anything V2 Small Core ML** — preferred lightweight depth candidate.
- **Real-ESRGAN** — predictable restoration/upscale candidate.
- **Pose/identity stack** — unresolved. Research/benchmark DWPose/OpenPose-compatible pose extraction/control plus suitable identity/reference conditioning. Do not freeze an untested choice.

Create a machine-readable model manifest including source, revision/hash, architecture, precision/quantization, license/use class, download/install size, backend, functions, peak memory, benchmark results and evidence state.

Recommended installation must not blindly download all candidates. Prepare candidate downloader/qualification mode; after physical qualification, Recommended installs the smallest complete LKG stack. Optional capabilities are fetched on demand.

## Qualification harness

Prepare automated physical tests for:
- text → photograph;
- reference → photograph;
- reference + pose;
- identity consistency across a small series;
- mask/inpaint;
- wardrobe change;
- background change;
- restoration/upscale;
- segmentation;
- depth;
- persistent/resumable multi-image series.

Record actual model/revision/hash, parameters, output paths, timings, peak memory/resource observations where obtainable, failures and evidence state. Never convert UNKNOWN to PASS because download/import/build succeeded.

## Installer and maintenance

Prepare one-click/self-bootstrapping macOS scripts/application flow that:
- detects hardware/macOS/storage and existing dependencies;
- bootstraps official Homebrew if absent only when required;
- reuses adequate existing installations;
- installs/configures Git/Git-LFS, aria2, uv/Python/Hugging Face tooling only as required;
- uses resumable downloads and shared caches;
- supports Install/Recommended, Lean, Full and Custom;
- supports Launch, Update, Repair and Uninstall;
- resumes interrupted provisioning;
- verifies hashes/revisions;
- keeps model/project data separate from disposable runtime caches;
- allows explicit retention/removal of shared models during uninstall.

Do not label the installer production VERIFIED until physical M3 generation/edit tests pass.

## Reliability and job system

Implement a persistent job database/state store independent of transient UI. Series jobs save every completed result immediately. Quit/crash/sleep/power interruption must be recoverable. Failed attempts remain evidence. Retries should preserve failure records and change parameters where appropriate.

Before large jobs, estimate workspace/output requirements and retain a disk safety margin. Provide pause/cancel/resume. Model updates must not silently change existing project behavior; support pinned versions and rollback.

Generation history retains both user-facing structured intent and effective machine parameters, model/revision/hash, seed where applicable, reference roles and lineage. Do not promise exact reproducibility when an engine/runtime cannot guarantee it.

## Peer-package architecture

These are independent apps/packages, never modules embedded in APELLES:
- CONDUCTOR
- CURATOR
- CASPER and CASPER's subordinate specialist system
- KUROSAWA
- DÜRER
- IRIS
- ARTEMIS
- APELLES

Each owns its identity, domain authority, canon/context, tools, lifecycle, UI/runtime and local/native AI capability as applicable. Shared runtimes/models are infrastructure optimizations only.

Implement a small peer interoperability contract, conceptually independent of BIFROST, for capability discovery, invocation, progress, cancellation, results/artifacts and package exchange. APELLES must remain fully usable when no peer is installed. Direct peer calls are allowed; CONDUCTOR may orchestrate but does not own peers.

## Peer authority summaries

**CURATOR:** media/library/selection/relationship/provenance/publishing authority. Optional Bridge/digiKam workflows. Can request APELLES edits/generation; APELLES can hand media/library operations to CURATOR.

**CASPER:** full publication/creative-authoring system with established subordinate specialists. Includes prose/books/articles, social copy, narrative development, treatments, dialogue, scripts/screenplays, drafting, rewriting/editing, continuity and publication preparation. Do not reduce to captions/screenplays.

**KUROSAWA:** full moving-image/cinematic production system and video authority. Preserve development/planning → sequence → scene → shot → take/generation → selection → edit → deliverable model, continuity, versions and broader production management. Video-specific models belong there, not APELLES.

**DÜRER:** technical 3D/CAD/game/app asset authority. May reuse APELLES imagery, masks, depth/normal, textures, sprites/reference views. Optional 3D reconstruction models only on demand. Visual plausibility is not technical validation.

**IRIS:** visual intelligence/critique/assessment/QA authority.

**ARTEMIS:** visual creation/production specialist authority.

**CONDUCTOR:** orchestration/governance authority. APELLES does not require CONDUCTOR to function.

## Private/Custom local AI

Private/Custom versions of all named peers may contain complete offline/local native AI appropriate to their domains. Each can use Apple native intelligence, a shared tiny/local model, or optionally a stronger dedicated specialist tiny/local model. Shared by default when adequate; specialist models on demand. Models do not define assistant identity. Never bake project canon into model weights.

## BIFROST / HEIMDALL — do not conflate

- **BIFROST app:** specifically Voice of/for HEIMDALL through Siri; Apple-native Siri/voice bridge.
- **HEIMDALL iOS:** separate native iPhone/iPad product/package.
- **HEIMDALL:** separate cross-platform macOS/Windows/Linux desktop/server product/package.

`BIFROST != HEIMDALL iOS != HEIMDALL desktop/server`.

Do not name the generic peer protocol BIFROST. Where relevant, Siri → BIFROST → HEIMDALL / appropriate installed specialist capability.

## Required repository/project structure

Work under `~/edenOS/Projects/APELLES`. Do not pollute `#appDev Bible`.

Create a clear structure for native app source, engine adapters, manifests, scripts/bootstrap, tests, evidence, docs/handoff and generated build/package output. Preserve existing files/canon before modification. Use Git commits/branches/worktrees according to current AppDev authority.

## Required deliverables before physical M3 gate

Produce actual code/artifacts, not another architecture document:
- buildable native Xcode/Swift project and application shell;
- Studio/Series/Edit/Assets UI structure;
- core domain models and persistent job system;
- file import/drag-drop/export infrastructure;
- XMP/ExifTool and ZIP/manifest infrastructure;
- engine protocol plus ComfyUI local API adapter;
- Core ML/MLX integration boundaries/adapters where implementable without target models;
- shared model store and machine-readable candidate manifest;
- hardware/profile detector;
- candidate downloader;
- model qualification/benchmark harness;
- installer/bootstrap;
- Update, Repair and Uninstall;
- unit/static/integration tests possible without production models;
- evidence reports/logging;
- README/build/recovery documentation;
- one obvious physical M3 verification entry point.

## Completion boundary

Continue implementation and repair automatically through all safe work available. The legitimate unresolved boundary is physical model/runtime qualification on the target M3 Pro when that machine is unavailable. Reaching that gate is not permission to invent results. Report exact completed state, failed gates, attempted repairs and the next physical command/action.

Functionality before presentation; evidence determines state.
