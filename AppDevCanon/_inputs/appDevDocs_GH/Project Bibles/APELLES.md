# APELLES — Project Bible

**Status:** AUTHORITATIVE PROJECT CANON
**Date established:** 2026-10-03
**Project type:** Independent EDEN application/package
**Edition:** Private/Custom baseline

## Identity

**APELLES — Adaptive Production, Editing, Learning & Local Engine for Synthetic/Source Imagery**

Inspired by Apelles, the celebrated master painter of antiquity. User-facing descriptor: **APELLES — Visual Production Studio**.

APELLES is an independent EDEN still-image visual-production and editing application/package. It is not a container for other EDEN assistants and does not own their domains. Its UI identity is a modern photographic atelier/light-table: **the image owns the screen; technology serves the image.** Avoid pseudo-Greek decoration and generic AI-chat/graph UI.

## Product scope

Core functionality:
- local still-image generation from text and reference images;
- professional photographic series using separable subject/identity, anatomy, pose, location, wardrobe, camera/framing, lighting, composition and look controls;
- identity/reference consistency and multiple reference roles;
- image editing, masks/segmentation, inpainting/outpainting, remove/replace, background and wardrobe changes, restoration/upscale and localized generative edits;
- pose extraction/control and reusable corrected pose assets;
- depth/normal/segmentation/control extraction;
- variants, compare/review, contact sheets, persistent/resumable jobs and incremental series output;
- visual/image asset preparation for DÜRER and other compatible peers;
- open file import/export and standard interoperable metadata/package output.

APELLES must support private/non-commercial local use with no subscription, no generation credits, no required paid API and no required cloud inference. Core operation must work offline after provisioning.

## Minimal native UI/UIX

APELLES must remain focused rather than recreating Lightroom, Bridge or a DAM.

Primary native macOS workspaces:
- **Studio** — everyday generation/reference work;
- **Series** — subject × pose × location × wardrobe × camera × lighting production;
- **Edit** — non-destructive/generative editing and direct manipulation;
- **Assets** — image/visual asset preparation and DÜRER-oriented handoffs.

Persistent supporting surfaces: lightweight Files browser, image canvas and contextual Inspector. Use Simple / Advanced / Expert progressive disclosure. Normal mode uses photographic/creative language such as Subject Likeness and Pose Fidelity; implementation terms such as sampler/CFG/model internals belong in Expert.

Series UI must expose plan size, estimated storage, progress, pause/resume, failures/retries, review and contact sheets. Completed items survive quit/crash/interruption.

## Existing capability first

Do not rebuild functionality already adequately provided by macOS or installed software.

- Camera RAW: use macOS native RAW/imaging support. Do not bundle another RAW developer by default. Preserve original RAW untouched and use the native rendered representation for APELLES visual/AI work.
- DAM/cataloguing: CURATOR owns the domain. Private workflows may optionally use Adobe Bridge; digiKam is an acceptable free/open-source alternative. APELLES only needs lightweight file browsing/reference organization.
- Metadata: use native APIs first and ExifTool where deeper EXIF/IPTC/XMP interoperability is required.
- Do not fabricate Adobe Camera Raw/Lightroom Develop adjustments for operations Adobe software did not perform.

## Files, metadata and packages

Support Finder drag/drop, Add Files/import, folders/batches, normal image formats, macOS-supported RAW, references, pose images, masks, textures and supported asset references.

Original/source files are never silently overwritten or deleted. Maintain source → derivative lineage.

There is **no proprietary `.apellespack` requirement**. Export normal files and standard sidecars. Project/series/archive transfer uses ordinary ZIP packages containing images/assets and accompanying XMP sidecars, plus optional contact sheets and a JSON manifest for APELLES-specific reproducibility/lineage information.

Example ZIP contents may include Images/, Originals/ (optional), Assets/Masks, Assets/Depth, References/, Contact Sheets/, XMP sidecars and Manifest/apelles-manifest.json.

XMP is the interoperable photographic metadata layer. Preserve existing EXIF/IPTC/XMP appropriately. APELLES-specific operation/model/revision/hash/seed/reference/pose/lineage data may use a namespaced XMP section and/or JSON manifest. Provide configurable stripping of GPS/private metadata on export.

Large model files are not normally embedded in project ZIPs. Record exact model identity/revision/hash instead.

Respect embedded ICC profiles/ColorSync, orientation and useful source metadata; avoid unnecessary forced conversion to 8-bit sRGB. Preserve higher precision where the underlying operation/output format permits it.

## Installation/provisioning

Private/Custom APELLES requires a one-click self-bootstrapping Apple-Silicon macOS installer. Initial target: MacBook Pro M3 Pro with **16 GB unified memory functional floor** and **18–24 GB enhanced operation**. One installer detects the actual machine/profile automatically.

Installer requirements:
- inspect macOS, Apple Silicon, unified memory, storage and existing capabilities;
- bootstrap official Homebrew automatically if absent where required;
- reuse adequate installed software before installing duplicates;
- automatically configure Git/Git-LFS, aria2, uv/Python and Hugging Face tooling only where needed;
- resumable downloads, caches, hashes/revisions, retries/fallbacks;
- shared model/cache storage and optional external-storage relocation;
- no routine manual model placement/configuration;
- Install/Recommended, Lean, Full and Custom profiles;
- Launch, Update, Repair and Uninstall;
- resume interrupted provisioning;
- physical generation/edit verification before VERIFIED promotion.

16 GB must be genuinely usable. Prefer quantized/optimized models, one major model at a time, dynamic unloading and staged upscale. 24 GB unlocks enhanced optional models/workflows but does not define core functionality.

## Runtime architecture

APELLES is model-agnostic and Swift/native-first at the product layer. Prefer, where technically adequate:
1. macOS/native frameworks and Core ML;
2. MLX/Apple-Silicon-native routes;
3. ComfyUI/PyTorch MPS for the broad generation ecosystem and workflows.

ComfyUI may be a hidden execution backend/API. It must not become APELLES's normal product UI.

Use safe model formats and validated sources/hashes where possible. Do not automatically execute arbitrary downloaded custom-node code merely because a workflow requests it. Local Only must actually disable external inference/network dependencies.

## Candidate model manifest — research baseline, NOT M3 VERIFIED

All candidates remain **UNVERIFIED on the target M3 Pro** until physical qualification. UNKNOWN is not PASS.

- **Z-Image-Turbo** — Priority A base-generation candidate. 6B family, Apache-2.0, photorealistic/efficient focus; project has Apple-Silicon MPS support. First generation model to qualify.
- **FLUX.1-schnell** — Priority B generation fallback; Apache-2.0; test quantized/offloaded Apple-Silicon configuration.
- **Stable Diffusion 3.5 Medium** — compatibility/fallback candidate; qualify particularly for mature control/LoRA ecosystem needs.
- **Qwen-Image-Edit-2509** — advanced editing candidate; Apache-2.0; large model, therefore quantized/offloaded qualification required, especially at 16 GB.
- **FLUX.1 Kontext [dev]** — Private/Custom advanced-edit candidate only where its non-commercial/private-use license fits; do not make it an Official default.
- **SAM 2 family** — core segmentation candidate; choose smallest adequate variant by benchmark.
- **Depth Anything V2 Small Core ML** — preferred core depth candidate; lightweight Apple/Core ML path.
- **Real-ESRGAN** — core predictable restoration/upscale candidate.
- **Pose/identity stack** — unresolved qualification area; research/benchmark DWPose/OpenPose-compatible pose extraction/control and appropriate identity/reference conditioning rather than freezing an untested choice.

Maintain a machine-readable qualification manifest with model identity, source, revision/hash, architecture, precision/quantization, license/use class, size, backend, peak memory, speed, supported functions and VERIFIED/FAILED/UNKNOWN evidence state.

Do not download every candidate in Recommended. Install the smallest complete qualified stack; optional capabilities/models are downloaded on demand. Pin models used by existing projects and support rollback/LKG rather than silently changing behavior after updates.

## Qualification requirements

Physical M3 qualification must test at least:
- text → photograph;
- reference → photograph;
- reference + pose → photograph;
- identity consistency across a small series;
- mask/inpaint edit;
- wardrobe change;
- background change;
- restoration/upscale;
- segmentation and depth;
- persistent/resumable multi-image series.

Record quality observations, failures, generation time, peak unified-memory behavior, storage and stability. Candidate reputation or successful installation is not evidence of capability PASS.

## DÜRER relationship

DÜRER is a separate independent package and retains 3D/CAD/technical/game/app asset authority. DÜRER may reuse APELLES core visual models/capabilities for references, concepts, segmentation, depth/normal data, textures/material references, cutouts, sprites/icons and similar image assets. Do not create a separate default DÜRER image-model pack when APELLES already supplies the capability. Specialist image-to-3D/reconstruction models are optional/on-demand. Visual plausibility does not establish dimensional/technical correctness; DÜRER retains validation authority.

## CURATOR relationship

CURATOR is a separate independent package and retains media/library/selection/relationship/provenance/publishing authority. APELLES supplies visual generation/editing derivatives and analysis inputs without silently replacing authoritative originals. CURATOR may optionally integrate Adobe Bridge or alternatives such as digiKam. CURATOR full workflows may also call CASPER for language/narrative and KUROSAWA for moving-image work.

## CASPER relationship

CASPER is a separate independent publication/creative-authoring system, not a caption utility. Preserve its established subordinate specialist system and broader creative/editorial/publishing scope: prose/books/articles, social copy, narrative development, treatments, dialogue, scripts/screenplays, drafting, rewriting/editing, continuity and publication preparation. APELLES and CASPER may call each other; neither owns the other.

## KUROSAWA relationship

KUROSAWA is a separate independent moving-image/cinematic production system and owns the video domain. Do not create an APELLES Video product/workspace that absorbs KUROSAWA. Preserve KUROSAWA's broader production model from development/planning through sequences, scenes, shots, takes/generations, selection, editing, continuity, versions and deliverables. KUROSAWA may consume APELLES stills/masks/depth/reference assets; APELLES hands moving-image requests to KUROSAWA. Video-specific models belong to KUROSAWA provisioning, with compatible physical components shared where useful.

## IRIS / ARTEMIS / CONDUCTOR

IRIS, ARTEMIS and CONDUCTOR are separate independent packages. IRIS retains visual intelligence/critique/assessment/QA authority. ARTEMIS retains visual creation/production specialist authority. CONDUCTOR retains orchestration/governance. They may call APELLES and APELLES may call them. APELLES must work standalone without them.

## Independent peer-package rule

CONDUCTOR, CURATOR, CASPER and CASPER's subordinates, KUROSAWA, DÜRER, IRIS, ARTEMIS and APELLES are separate independent apps/packages. Each retains its identity, domain authority, canon/context, tools, lifecycle, UI/runtime and local/native AI capability as applicable.

They may discover and call one another bidirectionally through a small shared capability/interoperability protocol supporting discovery, invocation, progress, cancellation, result/artifact exchange and package exchange. This protocol is conceptually separate from BIFROST. Direct peer-to-peer cooperation remains possible; CONDUCTOR may orchestrate but does not own peers.

Shared runtimes/model stores are infrastructure optimizations only and must not erase standalone operation.

## Private/Custom local AI

Private/Custom CONDUCTOR, CURATOR, CASPER/subordinates, KUROSAWA, DÜRER, IRIS, ARTEMIS and APELLES may each have complete offline/local native-AI capability appropriate to their domains.

Each may use Apple native/on-device intelligence, a shared tiny/local model, or optionally a separate more capable specialist tiny/local model. Shared is preferred when adequate; dedicated models are optional/on-demand. Dynamically load/release models according to memory pressure. Models are infrastructure, not assistant identity. Canon/authority/tools/context/permissions remain distinct. Do not bake project canon into model weights.

Official releases may use a lighter Assistant Helper/local-intelligence approach; this does not alter the richer Private/Custom architecture or independent package boundaries.

## BIFROST / HEIMDALL distinction

Do not conflate these products.

- **BIFROST app** = specifically the Voice of/for HEIMDALL through Siri, the Apple-native Siri/voice bridge. It is not HEIMDALL and is not the generic EDEN interoperability protocol.
- **HEIMDALL iOS** = separate native iPhone/iPad application/package with its own UI/UIX, lifecycle and capabilities.
- **HEIMDALL** = separate cross-platform desktop/server package for macOS, Windows and Linux.

Canonical: `BIFROST != HEIMDALL iOS != HEIMDALL desktop/server`.

Where Apple voice control is involved, describe the path explicitly, e.g. Siri → BIFROST → HEIMDALL / appropriate installed specialist capability.

## Reliability, privacy and recovery

Maintain persistent job state independent of transient UI. Series output is incremental. Closing/crashing/sleeping must not discard completed work. Calculate disk requirements and preserve a safety margin before large jobs. Support cache/model relocation to external storage.

Keep sources immutable by default. Define cache/temp locations and cleanup. Make network use visible and enforce Local Only. Preserve useful metadata but allow privacy stripping on export.

Generation history should retain the user-facing request plus effective machine execution parameters, model/revision/hash and lineage. Reproducibility claims must distinguish preserved inputs/environment from genuinely exact reproduction.

## Governance and evidence

Apply current `~/edenOS/Projects/#appDev Bible/`, EITRI/EITRIMB and FORGE evidence governance. Commands authorize work; they are not evidence. Preserve LKG before extending. FAILED/UNVERIFIED/INCOMPLETE is not a blocker while safe repairable work remains. A genuine blocker requires an attempted action and demonstrably unavailable dependency.

Canonical evidence pipeline: reference/baseline → implement → static verify → environment verify → regression verify → package → package verify → physical gate → promote, proportionally applied.

## Current state and implementation sequence

**AUTHORITATIVE BASELINE:** this Project Bible plus current global AppDev authority.
**CURRENT STAGE:** architecture/research complete enough to begin implementation; model physical qualification pending.
**LKG:** no physically verified APELLES product build yet.
**KNOWN BLOCKER:** physical M3 Pro model qualification cannot occur until that machine is available; this does not block code/installer/harness preparation.

Implementation sequence:
- P0 preserve/sync canon;
- P1 prepare runtime/model manifest and qualification harness;
- P2 prepare one-click bootstrap/downloader without falsely promoting models;
- P3 physically qualify models on M3 Pro and establish first model LKG;
- P4 functional local engine/job system;
- P5 native Studio/Series/Edit/Assets UI;
- P6 peer integrations and optional external-tool workflows;
- P7 regression/package verification;
- P8 user physical acceptance.

Codex may implement all safe work through the physical M3 gate: native Swift project, domain/job models, Files/import/export, XMP/ZIP support, engine adapters, ComfyUI API adapter, Core ML/MLX integration boundaries, shared model store/manifest, downloader, hardware profiling, qualification/benchmark harness, installer/update/repair/uninstall, tests, evidence reports and physical-test entry point. It must not invent M3 PASS states or redesign established canon.
