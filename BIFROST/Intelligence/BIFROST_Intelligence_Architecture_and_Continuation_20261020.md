# BIFROST Intelligence — BIFROSTAI / JARVIS Architecture and Continuation

**Date:** 2026-10-20  
**State:** User decisions recovered and documented; implementation/acceptance gates remain independent.  
**Intended physical project-local destination:** `/Users/lucas/edenOS/Software Development/BIFROST/Intelligence/BIFROST_Intelligence_Architecture_and_Continuation_20261020.md`  
**Existing physical project master:** `/Users/lucas/edenOS/Software Development/BIFROST/`  
**Existing separate Finder visual entry (do not modify):** `/Users/lucas/edenOS/Projects/BIFROST Intelligence/`  
**Scope:** BIFROST Intelligence only. The Lucas Buzek Photography Web Portal stays in its Photography conversation/workspace.

## 1. Purpose and settled direction

BIFROST Intelligence is the existing BIFROST family's intelligence and research capability, not an independent application/project master, second headless server, duplicate connection fabric or new sovereign governor. **BIFROST In-Chat is the functional conceptual basis for BIFROSTAI**, the user's JARVIS-inspired intelligent personal orchestration experience. **BIFROSTAIcore** is the intelligence/planning/decision-support module extending BIFROST, not a reimplementation of BIFROSTcore. This is an intended integration target, **not proof of a completed AI runtime**.

Preserve the established canonical BIFROST identity **CONNECT · KEEP · RESOLVE**. No verified approved letter-by-letter BIFROST acronym expansion was found. The previously proposed **“Bridged Intelligence Fabric for Routing, Orchestration, Services & Tasks”** is *an unapproved proposal*, not settled canon; do not silently rename the product or change package identity.

**User's latest governance decision:** BIFROST is the supreme *out-of-chat orchestration entry point/intermediary* from local devices to authorized online/cloud services and cross-provider AI; CONDUCTOR's reasoning/coordination policy participates inside the BIFROST Master experience rather than running as a duplicated always-on controller. This does **not** grant unrestricted system authority: the owner, operating-system permissions, provider/account policies, AppDev canon and each specialist's domain ownership remain binding.

## 2. Responsibility and authority boundaries

| Owner/component | Responsibility | Must not duplicate or override |
|---|---|---|
| **BIFROST Master** | Single out-of-chat entry point, task/connection state, capability discovery, trusted resolution and permission-bound dispatch | Specialist domain logic or arbitrary user-account authority |
| **BIFROSTcore** | Local-first persistent connectivity, device/instance and capability registry, provider/adaptor resolution, actions and execution transport | BIFROSTAI reasoning; specialist data or independent cloud bridge |
| **BIFROSTAIcore** | Local/native-first intelligence, intent understanding, structured planning, model choice, call minimization, proactive *approved* workflows and evaluation of returned evidence | Direct arbitrary shell execution or unrestricted provider/device access |
| **BIFROST In-Chat** | Conversational/ChatGPT-plugin-facing BIFROST Master interface and conceptual basis for BIFROSTAI | Automatic proof that an out-of-chat daemon or host connector is installed |
| **CONDUCTOR** | Cross-domain orchestration methods, delegation strategy, goal continuity, coordination and progress | Separate always-running authority competing with BIFROST |
| **ForgeMASTER** | AppDev canon, code/source/LKG governance, specialist engineering and release acceptance | Autonomous software-release permissions merely because BIFROST invoked an action |
| **APPLE / FORGE** | Apple methodology, native implementation and testing under ForgeMASTER authority | Second engineering governor |
| **HEIMDALL** | Workspace/experience organization and its separately established assistant/voice roles | Device/provider registry ownership |
| **PENELOPE / JANITOR / CURATOR / APELLES / KUROSAWA / WEAVER / CASPER / other specialists** | Independent domain-specific capabilities, rules, assets, data and professional execution | BIFROST absorbing their implementations/data |
| **AI TOOLKIT** | Shared supported AI tools/model hosting and discovery where actually available | Parallel BIFROST orchestration layer |
| **RavenNest / Cloudflare / GitHub / WORKinCODEX / MCP / RDC** | Optional connected remote transports, storage/control planes and provider/executor adapters per verified contracts | Default ownership of local BIFROSTcore; unauthorized deployment or account changes |

**Principle: hosting is transferable; ownership is not.** A specialist can run standalone and may *optionally* register its permitted capabilities with BIFROST. One BIFROST gateway does not imply one omnipotent credential; grant access per action, target, account, environment, time and consequence.

## 3. `shortNameCall` — common callable actions contract (required, not yet verified implemented)

Every specialist defines and owns its *own* actions. BIFROST discovers the contracts and offers one universal, typed, versioned call interface called **`shortNameCall`**. BIFROST routes/authorizes; the registered specialist/native executor performs the action. The caller should not have to know whether it uses App Intents, an installed Shortcut, Automator, CLI, MCP, a Web API, Cloudflare, an AI provider or an app daemon.

Minimum manifest per registered capability:

- Namespace and **stable short name** (`curator.index`, `apelles.inspect`, `weaver.check`, etc. are *illustrative only*, not existing registered names); source owner/project and action version.
- Description, structured input/output JSON schemas, semantic side effects and permissible target locations.
- Runtime type and trusted endpoints: local native App Intent / Shortcut / Automator / CLI / service / MCP / cloud API / provider-specific connector; platform requirements and offline availability.
- Credential identity *reference* and minimum scopes, user/role/site/account/project/device authorization, classification (`read`, `write`, `destructive`, `external publish`, `install`, `paid`). Never expose raw credentials through the manifest.
- Consent policy (`allow once`, narrowly scoped recurring consent, `deny` as appropriate); confirmation and dry-run/preview or ChangeSet for consequential operations.
- Dependencies, health/freshness, estimated runtime/resource/cost, timeout, idempotency key, retry/rate quota policy, cancellation and recovery support.
- Output provenance, postcondition verifier, receipt reference, compatibility/version and import/export schema.

**Conceptual interface (not an implemented endpoint):**

```text
shortNameCall(
  action="<registered-specialist>.<registered-action>",
  input={<schema-validated payload>},
  target={<registered-device/account/environment>},
  grant={<authorized capability scope>},
  idempotencyKey="<stable request identity>"
) -> { taskId, status, receipt, resultReference, effectsVerified }
```

**Required lifecycle:** intent → classify → resolve registered action and target → validate input and authority → minimal sufficient provider selection → user approval when required → dispatch → persist task/receipt → independently verify postconditions → return useful response. Reject unknown names/versions, invalid input, revoked scopes, replay, credential leakage, absent specialist, unsafe script paths, unsupported platforms and unverified effects. Do not let natural-language generation directly become shell commands.

## 4. Rules, Actions, Shortcuts, Automator and scripts: import/export/management

BIFROST should supply **one permission-gated capability manager** for discovery, registration, import, export, creation, editing, versioning, enable/disable, inspection, test, history, migration and removal of:

- Specialist-defined rules and action manifests (domain logic owned by specialist).
- Native Apple **App Intents** and **Shortcuts**, including installed workflow discovery and approved invocation.
- User-saved **Automator** workflows and supported Folder Actions.
- Existing approved AppleScript/OSA, bundled scripts, CLI tools, headless endpoints and MCP actions.
- Optional verified cloud/provider actions (e.g., Cloudflare Workers, official social APIs, GitHub, Codex/Claude/Gemini/ChatGPT integrations) with independent account grants.

Import/export must use inspect → source/provenance verification → safe parsing → schema/version checks → dependency and permission review → preview/ChangeSet → explicit grant where necessary → atomic install/register → test → receipt/rollback. Imported scripts are **data** until individually trusted and authorized; importing cannot automatically execute them. Never overwrite unrelated workflows or enable unattended jobs, broad folder access, launch-at-login, paid usage, publishing or remote access by default. Maintain readable minimal Simple UI; disclose Advanced/Expert controls progressively.

## 5. BIFROSTAIcore and native Apple intelligence

Prioritize native Apple features *when actually supported on that device/version*:

- **Apple Intelligence** and the **Foundation Models framework** for supported on-device language-model reasoning, tool-calling orchestration and structured responses; an available interface does not imply the model is enabled or every language/feature is supported.
- **Core ML**, Apple silicon/**Neural Engine** and native hardware acceleration through OS-approved APIs.
- **Siri, App Intents, App Shortcuts and the Shortcuts app** as the preferred everyday voice/action surface wherever Apple exposes the necessary actions.
- **Automator, Folder Actions, AppleScript/OSA**, `shortcuts` CLI, system-provided commands and supported device automation on macOS; actual permissions/TCC and user approvals remain mandatory.
- **Keychain**, LocalAuthentication, OS entitlement/TCC mechanisms, Network.framework/Bonjour and suitable local IPC/XPC for trust, discovery and action routing.
- Native notification, Spotlight/search, Share Sheet, deep/universal links and related user-facing capabilities when justified.

**Local-first provider order:** exact deterministic native action → already installed trusted local capability / OS framework → suitable free/on-device model → existing authorized provider/remote tool → heavier or paid AI only when task demands it and consent/budget permit. Non-AI mode must continue to work for deterministic tasks. Avoid repeated multiple-model deliberation for routine simple actions.

## 6. Cross-provider orchestration with minimal calls

- BIFROST is the **only normal orchestration entry point**; specialists are called on demand, not kept in recursive discussions with each other.
- Resolve registered capability and device/account context first. Route once to the lowest-cost sufficient authorized provider; use one verified result where possible.
- Keep a durable task ledger: task ID, intent, account/role, project, target, provider identity, idempotency key, timestamps, state, evidence, result/receipt, error/cancel/recovery, without saving secrets.
- Reuse cached validated metadata with a freshness policy. Batch repeatable read operations, prefer event triggers to continual polling, and give quiet summaries of successful background work.
- Count only actual provider usage/quota evidence; unknown quotas remain UNKNOWN. Limit concurrent/paid calls, apply bounded retries/backoff, honor cancellation, and escalate at permission, high-impact or genuinely blocked gates.
- Use Cloudflare/RavenNest only as **optional authenticated online routing / scheduling / small state adapter**, not as an untrusted remote command shell or a replacement for local offline BIFROSTcore. Local operation must remain possible without Cloudflare.
- Source and account boundaries: no Dropbox for AppDev and no Google Chrome for EDEN/ChatGPT agent operations. Follow all live rules for approved releases, backups, source authority and UI.

## 7. What is evidence and what is not

**Recovered source-backed evidence (2026-10-19):**

- The canonical BIFROST master is `/Users/lucas/edenOS/Software Development/BIFROST/`, with an established `Intelligence/` capability/research folder and separate Finder index entry.
- BIFROST Headless has an existing opt-in macOS `headless/orchestration.py` implementation that discovers installed Shortcuts and saved Automator workflows and executes *reviewed installed* actions under narrow local restrictions. The documented candidate passed 108 Python tests and 13 JS tests, but acceptance of real physical Siri actions, GUI approvals and end-to-end cross-provider execution remains separate.
- BIFROST Master architecture and limits are documented in `docs/architecture/BIFROST_CAPABILITY_ARCHITECTURE_RECOVERY_2026-10-07.txt`, `docs/decisions/BIFROST_MASTER_EXTENDED_GOAL_20261014.md`, `docs/decisions/BIFROST_JARVIS_MASTER_AUDIT_AND_EXTENDED_GOAL_20261014.md`, `docs/operations/BIFROST_MASTER_WORKinCODEX_20261019.txt` and the newest *actual* project-local source.
- Existing BIFROST Intelligence preproduction research artifacts must be preserved (README, `PREPRODUCTION_20261019/`, `PREPRODUCTION_DOSSIER_R1.md`, `CORPUS_INGESTION_POLICY.md`, `SOURCE_CANDIDATE_CATALOG.json`, `tools/catalog_candidates.py`). Prior reporting indicates research cataloging is metadata-only and model training/ingestion remains disabled pending separate gates.

**UNKNOWN / not to overclaim:** operational `shortNameCall` registry or real dispatcher; complete BIFROSTAIcore; live installed ChatGPT plugin/host orchestration path; persistent cross-provider automatic execution; real Siri/iPhone/Apple Intelligence inference test; cloud-to-Mac pairing; provider billing/quota awareness and approvals; end-to-end Cloudflare/MCP/Codex task receipts. No approval of the proposed BIFROST acronym. Do not imply a finished JARVIS assistant from architecture alone.

## 8. Canonical continuation in a different chat

**This document is for the BIFROST Intelligence/JARVIS project.** Do not switch the Photography project conversation into BIFROSTAI development. The Lucas Buzek Photography Web Portal remains separate under `/Users/lucas/edenOS/Projects/lucasbuzek-webportal/site`, with owner-authorized project-local edits but strict no-public-deployment rules.

**Suggested new-chat execution instruction:**

> @CONDUCTOR @ForgeMASTER @FORGE @APPLE BIFROSTAI Intelligence AUTO — Recover canonical `/Users/lucas/edenOS/Software Development/BIFROST/Intelligence/` and parent BIFROST source/Bible/LKG, read this handoff and live `#common` rules. Extend BIFROST In-Chat into BIFROSTAIcore, preserving BIFROSTcore connectivity, CONDUCTOR policy coordination, specialist-owned actions and local-first runtime. Implement a versioned `shortNameCall` capability registry and authenticated broker with import/export/rules/Shortcuts/Automator/script management, action-level consent, durable task receipts, idempotency and independent postconditions. Favor Apple Intelligence/Foundation Models/Siri and native actions before cloud AI; minimize provider calls. First verify one genuine safe local read-only action end-to-end, then one authorized cloud action. Preserve independent source, user data, LKG and existing service/installed builds. Do not create a new orchestrator, cloud bridge, product master, or publish/install without separate acceptance.

## 9. Project-local custody and verification requirements

This document is a **new supplemental decision/handoff**, not a replacement of the Intelligence README, project Bible, source registry, existing research dossier or any global AppDev rule. When Mac access is available, the canonical `#common/projectlocal.py` pipeline must `discover → plan → apply --confirm → verify` a SHA-256-manifested copy into the already established physical `BIFROST/Intelligence/` folder without overwriting existing content. Preserve original source manifests, Git/LKG and independent specialist identities; no migration or modification of `/Users/lucas/edenOS/Projects/BIFROST Intelligence/` (Finder index). The file's presence alone is not implementation or functional acceptance.
