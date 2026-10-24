# BIFROST Intelligence / JARVIS — Preproduction Dossier R1
Date: 2026-10-19. State: research and preproduction, not model training or release.

## Identity and authority
BIFROST Intelligence is the JARVIS extended goal of BIFROST, not a second project. Canonical working source: /Users/lucas/edenOS/Software Development/BIFROST. Project index: /Users/lucas/edenOS/Projects/BIFROST Intelligence (verified symlink).
ForgeMASTER governs AppDev; CONDUCTOR coordinates; PROMETHEUS governs future physical R&D, DAEDALUS technical preproduction, ARGOS research. BIFROSTcore is separately developed; AI TOOLKIT provides model options; HEIMDALL Assistant iOS and LECTOR remain independent capability owners. Specialist domain data is not automatically imported.
The ChatGPT account export remains deferred until the training/secure-ingest pipeline is ready.

## Actual recovered local evidence
- BIFROST/README.md, docs/decisions/BIFROST_JARVIS_MASTER_AUDIT_AND_EXTENDED_GOAL_20261014.md, docs/verification/BIFROST_REAL_WORKFLOW_ACCEPTANCE_CONTRACT_20261014.md.
- HEIMDALL Assistant IOS/docs/APPLE_COUNCIL_IOS_RECOVERED_20261010.md, HEIMDALL/CouncilExperience.swift, docs/AUTHORITATIVE_SPEC.md.
- LECTOR/PROJECT_BIBLE.md: books/reading owner. Book catalog, annotations and full licensed texts have separate permission/rights gates.
- Shared #common/AppDevRules and BIFROST's established current sources remain authoritative without duplication.
- Mac observed MacBookAir10,1, 8 GiB RAM, approximately 13 GiB free disk (2026-10-19). Intended M3 MacBook Pro hardware has not been inspected; no new weights or training installed.
- Shared DAEDALUS tool audit: BIFROST source 456 indexed files before this dossier, no source mutation, no engineering acceptance.

## Recovered personality and Apple behavior
HEIMDALL APPLE Core Council distinguishes serious Analyze from explicit CASPER Entertainment: Judge This, One Liner, Stand-Up, Council Meeting and Roast; Gentle/Brutal (Brutal requested only). The fictional design/engineering archetypes never impersonate real Apple figures. Native on-device inference on iPhone is not physically verified by the recovered source. BIFROST should inherit a user-approved conversational personality profile, not unsolicited roasts.
## ARGOS ResearchFULL: verified primary references, accessed 2026-10-19
- Apple Foundation Models: https://developer.apple.com/foundation-models-framework/ — native Swift support for guided output/tool calling/on-device models, capability/availability must be detected.
- Apple model updates: https://developer.apple.com/documentation/Updates/FoundationModels — OS updates affect model behavior, regression-evaluate.
- Apple adapter training: https://developer.apple.com/apple-intelligence/foundation-models-adapter/ — requires Apple Silicon Mac with at least 32 GB RAM (or Linux GPU); currently listed 26.0.0 adapter toolkit is incompatible with OS27 and later. An OS27-capable adapter workflow cannot be claimed from this.
- MLX LM: https://github.com/ml-explore/mlx-lm — MLX quantized inference and LoRA on Apple Silicon; actual target resource/license assessment is pending.
- llama.cpp: https://github.com/ggml-org/llama.cpp — Metal/GGUF alternative for low-dependency local inference; measure against existing AI TOOLKIT before using.
- Presidio: https://microsoft.github.io/presidio/text_anonymization/ — candidate local PII identification/anonymization, insufficient by itself to guarantee privacy.
- OpenAI data export: https://help.openai.com/en/articles/7730893-how-to-export-your-chatgpt-data — future manual export; not an internal model or weight export.

## Competing approaches, opposition and decision
A. Train a foundation model from scratch — reject until dataset, compute, rights and evaluation evidence exist.
B. Train on all raw Chats/books immediately — reject: false authority, private-party and copyright contamination, unavailable archive and missing evaluation.
C. Local RAG and structured source-authoritative memory first — SELECTED for preproduction: reversible, current, traceable facts and no base-model fine-tuning required.
D. Optional MLX LoRA for bounded behavior after measured prompting/RAG failures — CONDITIONAL. Do not combine model training data with test/eval examples.
E. Apple Foundation Models custom adapter — HOLD pending an OS-compatible toolkit, licensing/developer entitlements and supported >=32GB training hardware.

## Proposed architecture
Input: Siri / HEIMDALL iOS / BIFROST native or headless / approved ChatGPT plugin
→ identity, requested purpose, specialist routing, policy and grants
→ model gateway: native Apple model if available, otherwise measured local Apple Silicon model, with user-configured optional external provider
→ versioned retrieval: source owner, source revision/SHA, sensitivity, per-user ACL, permission and citation
→ BIFROST CONNECT/KEEP/RESOLVE capabilities, durable plans, authorization, genuine executor, postcondition, cancellation and rollback.
All agent/document input is untrusted. Retrieved text never changes permissions, project canon or tool authority. LCAS is in-chat display only.
## Requirements and acceptance design
REQ01 Each answer references authoritative source/version where available; conflicting older records do not supersede current canon.
REQ02 Corpus inventory never follows symlinks, traverses unrelated project directories or copies content without permission.
REQ03 100% retrieved snippets have source ID, provenance and user visibility scope; revocation removes source from future retrieval.
REQ04 No secret/API token enters embeddings, training data or logs; test false-positive/false-negative/known canary cases.
REQ05 Distinct permission flags for discover, hash inventory, index, retrieve, train, and upload; all unknown flags default DENY.
REQ06 Seriously analyze by default; entertainment sarcasm/roast only when chosen; verify 20+ adversarial and normal mode cases before release.
REQ07 LECTOR book metadata may be described only after user-approved LECTOR export; book full-text training requires separate rights and consent.
REQ08 Build gold tasks from BIFROST decisions, HEIMDALL Apple Council definitions and version conflict examples; train/test separated by conversation/source cluster.
REQ09 Measure actual retrieval relevance/citation accuracy, model instruction following, hallucinations, tone, offline behavior and prompt-injection resistance.
REQ10 Test low-memory/offline/stop-start/crash/backup-restore on actual target; no fabricated tokens-per-second or unsupported M3 assumptions.
REQ11 Automation needs explicit scoped authorization, preview, real provider execution, audit and observed postconditions; deny/replay/cancel tests.
REQ12 Retraction/deletion and provenance updates must work on indexed data. Trained weights cannot be assumed to immediately forget content after source deletion.

## Milestones and specialist work orders
P0 Recovery and source-audit — verified; no model trained.
P1 Bounded source catalog — metadata-only with hash and per-source review states; one canonical BIFROST workspace.
P2 Dataset parser and rights gate — credentials/PII/third-party denial and verified data extraction tests; no automatic recursive user-home scan.
P3 Inference baseline — select existing usable tool/native/MLX/GGUF, measure RAM, disk, speed, battery and offline correctness on intended M3.
P4 RAG — index only explicit approved texts locally; SQL FTS5 first, embeddings only if benchmark shows value.
P5 Export request — user will request ChatGPT history only when safe parser/secure local processing are ready.
P6 Optional training — curated versioned examples, validation/test holdout, adapter/rollback and evidence before any promotion.
P7 Integrate with BIFROSTcore/HEIMDALL/LECTOR through independently authorized contracts and real acceptance; no silent daemons or premature plugin.

## Red-team and integrated gate
Critical risks: raw history prompt injection, cross-owner data leakage, copyrighted books, duplicated masters, obsolete source rules, OS-dependent adapters, underspecified M3, limited connected-Mac disk, cloud data egress, trained-model memorization, self-authorized actions.
Mitigate with deny-by-default policy, stable provenance/hash, signed-in identity, approvals, per-source exclusion/reindex, local logs with redaction, model version/eval and rollback.
ARGOS: sources acquired and opposed; no model tests. DAEDALUS: technical preproduction drafted; not production-certified. PROMETHEUS: hardware/server plan conditional on future specification. ForgeMASTER: no product/plugin promotion. PRETRAIN/FINETUNE GATE = HOLD.
