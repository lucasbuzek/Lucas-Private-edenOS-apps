# ForgeMASTER - reference material (verbatim sources; not needed for normal operation)

See `FORGEMASTER.claude.md` for the operating definition. READ MIRROR.


---
### SOURCE: `reconciled/ForgeMASTER/v1.0/MIGRATION_AND_EVIDENCE.md`
(sha256 3bf8e00248aee5f697f9d5733a6f55fa21ebd3d11ef032aae4ef50780c682537)

# ForgeMASTER v1.0 — Migration and Evidence Record

Date: 2026-10-04

## Requested milestone
Implement the approved Universal Backup, Handoff, Recovery & Continuation Contract and establish ForgeMASTER as sole AppDev governor with shared handoff/backup cores and Codex/Claude adapters.

## Recovered authoritative baseline
GitHub repository: `lucasbuzek/Lucas-private-appDevDocs`, branch `main`.

Recovered prior governor: `EITRIMB/EITRI_The_Master_Builder/v0.2.0/prompts/EITRIMB_MASTER_GOVERNOR.txt`.

Recovered useful prior invariants include recovery/reuse-before-rebuild, strict evidence states, AUTO continuation, LKG preservation, GitHub persistence rules, local-workspace-first Codex behavior and Codex handoff fields. These are incorporated where compatible with the user's newer ForgeMASTER authority decision.

## Supersession
ForgeMASTER v1.0 is the current CANDIDATE governor. EITRI/EITRIMB governor material is retained as provenance and migration input, not as a parallel governor. EITRIFactory remains production execution/orchestration rather than governance authority.

## Implemented in canonical GitHub
- `ForgeMASTER/v1.0/FORGEMASTER_MASTER_GOVERNOR.md`
- `ForgeMASTER/v1.0/CALLS_AND_ROUTING.md`
- this migration/evidence record

Implemented calls in the candidate contract:
- `handofffull`
- `backupfull`
- `backuplocal`
- `handoffCodex`
- `handoffClaude`
- retained `goal`
- added `extendedgoal` semantics already accepted by user

## Verification performed
Static contract verification: PASS for presence of shared handoff core requirements, shared backup core requirements, universal continue-work rule, backup levels, package portability, Codex CLOUD/LOCAL/MIXED confirmation boundary, Claude development-organization role, legacy migration law, and evidence/LKG safeguards.

GitHub persistence: PASS when commits for the candidate files are returned by the GitHub connector.

Local mirror synchronization: pending verification at time this record is first committed; must not be promoted to PASS until the files are actually written/read on the Mac.

Runtime/chat command-router integration: contract-level IMPLEMENTED in canonical prompt/call registry; environment-level behavior remains to be demonstrated through subsequent actual calls. Do not label RELEASED solely from this migration.

## Promotion state
CANDIDATE. Not RELEASE-LKG yet. Promotion requires required verification/acceptance. UNKNOWN != PASS.

## Next executable gate
Synchronize the ForgeMASTER v1.0 candidate to the Mac offline mirror, verify exact files/content exist, then record local evidence. After that, exercise representative call routing (`handofffull`, `backupfull`, `backuplocal`, `handoffCodex`, `handoffClaude`) as real project operations before RELEASE-LKG promotion.


---
### SOURCE: `reconciled/AppDevRules/UNIVERSAL_REBUILD_BACKUP_RULE.md`
(sha256 33ec16af2de1d29070556074800e4bcdb15342ac5d8469f776080e24071363fe)

# UNIVERSAL REBUILD BACKUP RULE

Status: AUTHORITATIVE APPDEV RULE
Applies to: ALL AppDev projects, applications, games, assistants, services, websites, mods, asset pipelines, and related deliverables.

## 0. Authority, persistence and access boundary

Use `UNIVERSAL_PROJECT_STORAGE_RULE.md` for canonical Mac paths and classifications. Do not redefine project identity or storage layout here.

Durable remote AppDev authority is persisted in `lucasbuzek/Lucas-private-appDevDocs` and project implementation in each project's established repository (or the established shared project repository when no dedicated repository exists).

Lucas's Mac has NO assumed GitHub connection. Never require or attempt local GitHub access merely because remote persistence is required. ChatGPT reconciles the independent stores using its authenticated GitHub connector for GitHub and Remote Desktop Commander for the Mac. Cloud Codex may use repository access only when its environment demonstrably provides it.

> **RECONCILED 2026-10-07 - Claude/gh route, surface-dependent (Lucas decision 2026-10-06/07):** `gh` on Lucas's Mac IS authorized (logged in as lucasbuzek; scopes repo/gist/read:org). Where a Claude session is linked to the Mac (Claude desktop app / Claude Code session with Remote Desktop Commander present), Claude reaches the Mac through RDC and uses `gh` and the `codex` CLI there; Claude's own GitHub connector does NOT reach Lucas's private repos. Claude in the browser or the iPhone app has NO Mac/RDC/GitHub access (previously the only Claude surfaces used): there Claude works only from the Claude Project's mirrored files and supplied attachments. The ChatGPT-connector statement above remains valid for ChatGPT sessions. The newest explicit user decision outranks the older line.


Mac global AppDev authority: `~/edenOS/Projects/#appDev Bible/`.
Mac assistants: `~/edenOS/Projects/#app-assistants/`.
Project locations follow `UNIVERSAL_PROJECT_STORAGE_RULE.md`, including `Projects/EDEN Apps/<APP>/` for EDEN Apps and `Projects/<PROJECT>/` for independent projects.
`~/edenOS/Temporary/` is disposable only. `~/edenOS/Backups/` is durable local backup storage.

GitHub and Mac copies must be explicitly reconciled by ChatGPT; never describe them as automatically synchronized.

## 1. Three distinct artifacts — never conflate them

A. DURABLE PROJECT ARCHIVE / REBUILD BACKUP — exhaustive rebuild-capable preservation. Size is secondary to recoverability.

B. ACTIVE WORKING PROJECT — clean current development candidate plus authority and inputs needed for implementation and verification, at the canonical path defined by the storage rule.

C. LEAN TASK HANDOFF — compact task-specific transfer containing what the receiving executor needs to understand canon/current state, execute the assigned work, verify it, and return cumulative results.

Invariant: ARCHIVE is exhaustive; WORKING PROJECT is clean/current; HANDOFF is lean/task-specific.

## 2. Meaning of backup

When Lucas requests a project backup, complete backup, reconstruction package, archive, save-everything package, or equivalent, BACKUP means a verified rebuild-capable package by default.

A handoff, Project Bible, README, summary, source snapshot, ZIP, Git repository, or conversation transcript by itself is not a complete backup unless it independently satisfies the rebuild acceptance gate.

## 3. Required rebuild-backup contents

Preserve everything reasonably required to reconstruct the project without old chat history, including as applicable: current Project Bible/canon; relevant AppDev authority pointers/snapshot; complete source; platform projects/manifests; contracts/interfaces/schemas; database schemas/migrations; tests/fixtures; UI/UIX/design-system definitions; required editable assets and manifests; build scripts/builders/installers; dependency manifests/lockfiles; environment/preflight requirements; provider/adapter definitions; required AI contracts/prompts/schemas; packaging/signing/deployment instructions excluding secrets; exact repository/ref/commit where applicable; LKG/current-candidate/evidence state; known failures/unverified/physical gates; restore/rebuild instructions; file inventory and integrity verification.

Never place credentials, tokens, private keys, signing certificates or passwords in ordinary backups. Preserve required secret names/setup requirements instead.

## 4. Persistence targets

1. Persist remote global/project canon through ChatGPT's authenticated GitHub connector to the established repository.

> **RECONCILED 2026-10-07 - Claude/gh route, surface-dependent (Lucas decision 2026-10-06/07):** `gh` on Lucas's Mac IS authorized (logged in as lucasbuzek; scopes repo/gist/read:org). Where a Claude session is linked to the Mac (Claude desktop app / Claude Code session with Remote Desktop Commander present), Claude reaches the Mac through RDC and uses `gh` and the `codex` CLI there; Claude's own GitHub connector does NOT reach Lucas's private repos. Claude in the browser or the iPhone app has NO Mac/RDC/GitHub access (previously the only Claude surfaces used): there Claude works only from the Claude Project's mirrored files and supplied attachments. The ChatGPT-connector statement above remains valid for ChatGPT sessions. The newest explicit user decision outranks the older line.

2. Persist source/project data to the established remote project repository through an authorized remote mechanism.
3. Maintain the independent Mac/offline copy at the canonical storage-rule location through Remote Desktop Commander or direct local execution.
4. Use `~/edenOS/Temporary/` only for disposable work.
5. Explicit export destinations do not redefine authority.
6. Do not invent replacement locations when an established location exists.
7. Remote persistence does not replace a requested local/offline backup; the local copy does not replace required remote persistence.
8. Reconciliation is an explicit ChatGPT operation across the two access paths, not local Git synchronization.

## 5. Recovery before packaging

If required material is missing in one store, recover from the other authoritative/recovery sources using the access mechanism actually available. Do not create empty scaffolding and call it a backup. Do not substitute explanations for recoverable data. If a genuinely required dependency cannot be recovered after changed-source/method attempts, record the exact blocker and continue packaging everything else safely recoverable.

## 6. Archive structure

Use a clear equivalent structure appropriate to the project, normally including Project Bible, BACKUP_MANIFEST, RESTORE instructions, source, contracts, tests, required assets/asset manifest, build tooling, docs, authority, evidence, repository/history artifact when practical, and SHA-256 integrity manifest. Do not duplicate regenerable caches/build products unless required for reconstruction.

## 7. Lean handoff construction

Determine receiver and exact task first. Include the minimum complete working set: START_HERE/task contract; relevant canon; current evidence/failures; source/contracts/tests/assets required; toolchain/build/run instructions; expected return contract. Exclude unrelated products, redundant archives, caches, DerivedData, regenerable intermediates and archaeology not needed for the assigned task.

## 8. Verification gate

A durable backup is not COMPLETE until verification actually runs. Verify destination, required rebuild-critical files/directories, non-empty source/canon, manifests/dependencies/tests/contracts where applicable, exact state/ref where applicable, archive integrity/checksums, restore instructions and absence of silently omitted required components. Where practical perform a restore smoke test into a temporary location.

For a lean handoff verify self-sufficiency for the stated task.

## 9. Completion language

Only report BACKUP COMPLETE / VERIFIED after the verification gate passes. Otherwise report the bounded factual state. Never equate command/process creation with completion.

## 10. AUTO behavior

Under AUTO/full-auto continue through safe available recovery, packaging, persistence and verification until the requested acceptance gate is reached or a genuine blocker prevents it. Repairable path/auth/source issues, planning, directory creation, or archive creation without verification are not completion.

## 11. Universal invariants

BACKUP = CANON + SOURCE + REBUILD INPUTS + EXACT STATE + RESTORE INSTRUCTIONS + INTEGRITY VERIFICATION.

ARCHIVE = exhaustive durable recovery. WORKING PROJECT = clean current development state. HANDOFF = lean self-contained task transfer.

MAC AND GITHUB ARE INDEPENDENT STORES. CHATGPT RECONCILES THEM THROUGH THEIR RESPECTIVE CONNECTORS. NEVER ASSUME LOCAL GITHUB ACCESS ON LUCAS'S MAC.

> **RECONCILED 2026-10-07 - Claude/gh route, surface-dependent (Lucas decision 2026-10-06/07):** `gh` on Lucas's Mac IS authorized (logged in as lucasbuzek; scopes repo/gist/read:org). Where a Claude session is linked to the Mac (Claude desktop app / Claude Code session with Remote Desktop Commander present), Claude reaches the Mac through RDC and uses `gh` and the `codex` CLI there; Claude's own GitHub connector does NOT reach Lucas's private repos. Claude in the browser or the iPhone app has NO Mac/RDC/GitHub access (previously the only Claude surfaces used): there Claude works only from the Claude Project's mirrored files and supplied attachments. The ChatGPT-connector statement above remains valid for ChatGPT sessions. The newest explicit user decision outranks the older line.


Commands authorize work. Evidence proves state.


---
### SOURCE: `reconciled/AppDevRules/WORKinCODEX.md`
(sha256 5d915b95588a8e9518a55b76a0018e69d224ff2ebc7a8ea840122cdb49249848)

# WORKinCODEX — Universal Codex Cloud Work Rule

Status: CANONICAL AppDevRules procedure
Scope: all AppDev projects, Apps, helpers and specialists when ChatGPT is instructed to submit work to Lucas's configured Cloud Codex environment.
Governance: CONDUCTOR governs continuity, scope, evidence and acceptance. Task-specific frameworks remain task-specific and are not promoted into this universal transport rule.

## Invocation
`WORKinCODEX` or an explicit request to work/continue in Cloud Codex using the established procedure.

## Canonical meaning
WORKinCODEX = CONDUCTOR-governed complete task-specific handoff -> visible Mac Terminal as submission/control surface -> `codex cloud exec` -> designated/configured Cloud Codex environment -> Cloud Codex execution -> evidence/result returned to CONDUCTOR for acceptance or continuation.

The Mac is the control/submission surface. The requested workload executes in Cloud Codex. Do not assume or require a GitHub connection on the Mac.

> **RECONCILED 2026-10-07 - Claude/gh route, surface-dependent (Lucas decision 2026-10-06/07):** `gh` on Lucas's Mac IS authorized (logged in as lucasbuzek; scopes repo/gist/read:org). Where a Claude session is linked to the Mac (Claude desktop app / Claude Code session with Remote Desktop Commander present), Claude reaches the Mac through RDC and uses `gh` and the `codex` CLI there; Claude's own GitHub connector does NOT reach Lucas's private repos. Claude in the browser or the iPhone app has NO Mac/RDC/GitHub access (previously the only Claude surfaces used): there Claude works only from the Claude Project's mirrored files and supplied attachments. The ChatGPT-connector statement above remains valid for ChatGPT sessions. The newest explicit user decision outranks the older line.


## Canonical procedure
1. Recover current project/task authority, current goal, applicable canon, evidence/LKG, required environment identifier and acceptance gate before touching Terminal.
2. Prepare the COMPLETE final Codex execution instruction first. Do not make Lucas reconstruct context inside Codex.
3. Open/use a NEW visible Terminal window on the Mac.
4. Construct the established `codex cloud exec` command targeting the recovered/configured Cloud Codex environment. Never guess the environment identifier.
5. Put the complete command/instruction on the clipboard.
6. Insert it into the visible Terminal using the proven Terminal clipboard/`do script` mechanism. Do not substitute System Events keystrokes, fake/pseudo TTYs, ordinary interactive `codex`, local execution, or another apparently equivalent transport.
7. Verify the complete intended command/handoff is visibly present in the intended Terminal/Codex surface. Pasted != submitted.
8. STOP before execution when Lucas's Enter/confirmation is the established gate. Lucas performs that confirmation.
9. After submission, verify that a Cloud Codex task was actually created/started before reporting STARTED. Submission/request acceptance != started work unless the required evidence is observed.
10. CONDUCTOR evaluates returned evidence/results against the task-specific acceptance gate and issues continuation/repair passes when required. A completed Codex run != completed objective unless acceptance evidence passes.

## Explicit prohibitions
For WORKinCODEX do not silently substitute: ordinary interactive `codex`; local Mac workload execution; fake/pseudo TTY sessions; `script`-manufactured TTY; System Events keystroke automation; GitHub discovery on the Mac as a prerequisite; another Codex environment; another submission mechanism merely because it appears equivalent.

If literal execution is genuinely impossible, identify the exact failed canonical step. Do not silently switch procedures.

## Evidence states
Terminal opened != handoff pasted.
Handoff pasted != submitted.
Submitted != Cloud task started.
Cloud task started != task complete.
Codex run complete != objective accepted.
Evidence determines each transition.

## Mac/GitHub boundary
Lucas's Mac has no assumed GitHub connection. GitHub access/persistence, when required, is performed through ChatGPT's authenticated GitHub connector or by Cloud Codex when that environment demonstrably has repository access. Never attempt local GitHub access merely because remote GitHub persistence is part of the project architecture.

> **RECONCILED 2026-10-07 - Claude/gh route, surface-dependent (Lucas decision 2026-10-06/07):** `gh` on Lucas's Mac IS authorized (logged in as lucasbuzek; scopes repo/gist/read:org). Where a Claude session is linked to the Mac (Claude desktop app / Claude Code session with Remote Desktop Commander present), Claude reaches the Mac through RDC and uses `gh` and the `codex` CLI there; Claude's own GitHub connector does NOT reach Lucas's private repos. Claude in the browser or the iPhone app has NO Mac/RDC/GitHub access (previously the only Claude surfaces used): there Claude works only from the Claude Project's mirrored files and supplied attachments. The ChatGPT-connector statement above remains valid for ChatGPT sessions. The newest explicit user decision outranks the older line.


---
### SOURCE: `reconciled/AppDevRules/handoffClaude.md`
(sha256 31671172a9233dc28f8e2ce3a62ed0829b10d54845f9fb395d187bad5eef57dd)

# handoffClaude — Claude Self-Contained AppDev Handoff

Status: AUTHORITATIVE APPDEV RULE
Base: `AppDevRules/handoffUNI.md`
Command: `@handoffClaude [goal/task]`

Apply `handoffUNI` in full, then specialize for Claude.

## Access invariant
Assume Claude has **no access to Lucas's ChatGPT conversations, Mac, GitHub, prior Claude sessions or private project context** unless the specific transfer mechanism demonstrably provides it. Therefore the handoff itself must contain the actual task-relevant project data, not merely links, remembered facts or instructions to recover unavailable sources.

## Self-contained package
Create an applicable-size cumulative package, normally with:
- `CLAUDE_START_HERE.md`;
- task/goal/deliverable/acceptance contract;
- relevant current Project Bible/canon and bounded AppDev authority required to execute correctly;
- CurrentCandidate source needed for the task;
- LKG/recovery/donor material needed to protect demonstrated capability;
- relevant evidence and regression history;
- tests/contracts/schemas;
- project-generator/build/dependency files;
- task-required editable/runtime assets and asset manifests;
- existing research and provenance/license data;
- implementation plan only where it records executable continuation rather than speculative planning;
- package manifest/checksums;
- exact toolchain/build/run instructions;
- expected cumulative return contract.

Do not bloat the handoff with unrelated projects, caches, DerivedData or archaeology. Self-contained means complete for the assigned task, not a copy of the entire durable archive.

## Claude mandate
Act as a senior software-development team, not a code-completion assistant. First read `CLAUDE_START_HERE.md`, inspect the supplied authority/current candidate/LKG/evidence/research/manifests, and establish evidence state before modification. Do not rewrite first. Do not assume newest source is best. Do not discard working capability merely to compile.

Apply relevant engineering disciplines from `handoffUNI`; perform targeted current-technology and existing-implementation research before substantial custom solutions; preserve project-specific architecture, UIX, terminology and acceptance contracts; use test-driven repair where practical; maintain deterministic asset/build pipelines where applicable; measure performance where relevant.

## Research
Claude must create/update `RESEARCH_AND_ADOPTION_REPORT.md` for non-trivial research. Every incorporated external dependency/asset/implementation requires known licensing and rights. Unknown licensing means do not incorporate.

## One-click factory
When required by the project, produce the project-specific robust builders/installers defined by the handoff. They must preflight, reuse existing tooling, install only missing permitted dependencies, build/test/package/checksum and report evidence rather than blindly wrapping commands.

## Required final return
Do not return suggestions, isolated patches or snippets. Return one cumulative task-complete package/ZIP when portability is requested, containing corrected implementation plus required tests/assets/build tooling/research/license/implementation/regression/unresolved reports/manifests/checksums/instructions.

Before returning a portable package: create it; unpack into a clean temporary directory; run verification from the extracted copy where practical; verify required files; verify checksums; record what actually passed; mark anything not executed `UNKNOWN`.

The returned package must let another developer with no access to the originating conversations, Lucas's Mac, GitHub or previous AI sessions continue without reconstructing the same project history.

**Recover first. Research before reinventing. Preserve demonstrated capability. Implement against canon. Test regressions continuously. Evidence determines state.**

## In-project Claude (claude.ai Project 'edenOS App Development') - RECONCILED 2026-10-07
The no-access assumption above was true when Claude was used only in the browser and the iPhone app, and it still is on those surfaces: there is no Mac, Remote Desktop Commander, `gh` or private-repo access, so Claude works from the mirrored AppDev canon and helper definitions in the Claude Project files plus whatever is attached, and any handoff for such a session must be self-contained. Where the Project session is linked to Lucas's MacBook (Claude desktop app / Claude Code; Remote Desktop Commander tools present), Claude additionally has the Mac files, `gh` as lucasbuzek and the `codex` CLI, and follows WORKinCODEX / ForgeMASTER directly without needing a self-contained package. Claude's own GitHub connector does NOT reach the private repos on any surface. Decide by the tools actually present in the session, never by assumption.


---
### SOURCE: `reconciled/AppDevRules/handoffCodex.md`
(sha256 da3e27a3395777c1f7b9dfa3bdbff862f436c15a66462c4296cab364c1b39d8a)

# handoffCodex — Codex AppDev Handoff

Status: AUTHORITATIVE APPDEV RULE
Base: `AppDevRules/handoffUNI.md`
Command: `@handoffCodex [goal/task]`

Apply `handoffUNI` in full, then specialize for Codex.

## Access/workspace model
Codex works against the existing project repository/workspace available to the selected Codex execution environment. GitHub persists/version-controls; implementation happens in the working repository available to that executor.

Lucas's Mac has NO assumed GitHub connection. Do not require, test, repair, clone, fetch, push, or otherwise attempt local GitHub access on the Mac merely because Codex or the project uses GitHub remotely. ChatGPT uses its authenticated GitHub connector for remote GitHub persistence/recovery. Cloud Codex may use repository access only when its configured cloud environment demonstrably provides it.

> **RECONCILED 2026-10-07 - Claude/gh route, surface-dependent (Lucas decision 2026-10-06/07):** `gh` on Lucas's Mac IS authorized (logged in as lucasbuzek; scopes repo/gist/read:org). Where a Claude session is linked to the Mac (Claude desktop app / Claude Code session with Remote Desktop Commander present), Claude reaches the Mac through RDC and uses `gh` and the `codex` CLI there; Claude's own GitHub connector does NOT reach Lucas's private repos. Claude in the browser or the iPhone app has NO Mac/RDC/GitHub access (previously the only Claude surfaces used): there Claude works only from the Claude Project's mirrored files and supplied attachments. The ChatGPT-connector statement above remains valid for ChatGPT sessions. The newest explicit user decision outranks the older line.


When `WORKinCODEX` is invoked, `WORKinCODEX.md` governs transport literally: the visible Mac Terminal is only the submission/control surface for `codex cloud exec`; the requested workload runs in the designated Cloud Codex environment. Do not silently substitute ordinary interactive `codex` or local Mac execution.

## Required handoff answer
The handoff must unambiguously answer: **WHAT SHOULD CODEX EXECUTE NEXT?**

Provide project, exact goal/milestone/acceptance, authoritative Project Bible/rulebook pointers, repo/ref/branch/worktree where applicable to the actual executor, LKG/current candidate, demonstrated/unverified state, known failures/regressions, protected contracts/tests, relevant donor/recovery paths, environment/toolchain, exact first executable continuation, verification gates and expected cumulative return.

## Package size
Because Codex can often work from repository state, default to a lean control package (`HANDOFF.md` plus only non-repository task inputs) when repository access is demonstrated. Do not copy the full source/archive unless Codex cannot access it. `HANDOFF.md` is volatile continuation state, not a second Project Bible.

## Execution
Inspect before modifying. Preserve LKG. Use current ForgeMASTER/CONDUCTOR/AppDev governance applicable to the project; do not resurrect obsolete governance merely because an older handoff mentions it. Implement in the executor's actual workspace, test, verify, and persist according to current authority. Do not convert repository activity/build-number churn into product-progress claims. Continue safe executable work through repairable failures; retries must change something.

Return cumulative repository changes plus evidence, research/adoption decisions, tests, unresolved gates and exact continuation state. Never return only suggestions or isolated patches when the requested deliverable can be implemented.


---
### SOURCE: `reconciled/AppDevRules/handoffUNI.md`
(sha256 d76c2288bdb6ffde77f88ce003d64041d85e73feb60af2f9083700413d8e37ae)

# handoffUNI — Universal AI Engineering Handoff

Status: AUTHORITATIVE APPDEV RULE
Applies to: any AppDev project/application/game/service/site/mod/asset pipeline and any capable AI executor.

## Command
`@handoffUNI [goal/task]`

## Purpose
Create and verify an applicable-size engineering handoff package, then instruct the receiving AI to recover, research, implement, verify and return cumulative working results. This rule supplements, and never duplicates or replaces, the current AppDev Bible, Project Bible, ForgeMASTER governance, evidence rules, or `UNIVERSAL_REBUILD_BACKUP_RULE.md`.

## 1. Establish authority and task
Before packaging, identify PROJECT, CURRENT GOAL, requested DELIVERABLE/MILESTONE, ACCEPTANCE, authoritative Project Bible, authoritative repository, LKG, current candidate, demonstrated/unverified state, known regressions/failures, constraints and next executable gap. Current authority/evidence wins over stale handoff prose.

Do not assume newest source is best, historical source is authoritative because it compiled, or UI/build/package existence proves functionality. `GENERATED != IMPLEMENTED != BUILT != TESTED != VERIFIED != RELEASED`; `UNKNOWN != PASS`.

## 2. Recover before reinventing
Inspect current source/history, LKG, donor/sibling implementations, tests, evidence, assets, manifests and relevant recovery material. Preserve LKG/recovery before risky changes. Do not discard demonstrated capability merely to simplify compilation.

For substantial unsolved problems research before custom implementation. Preference: platform/native capability -> installed suitable capability -> small mature library/tool/framework -> adaptable existing/open-source implementation -> custom gap. Record serious external candidates with source/version or commit/license/rights/maintenance/platform/offline/runtime cost/integration effort/canon conflicts and ADOPT/ADAPT/REFERENCE/REJECT. Unknown licensing means do not incorporate.

## 3. Engineering-team mode
Apply the disciplines relevant to the project rather than acting as a code-completion assistant: architecture; platform/application engineering; domain specialists; data/storage/security/privacy; UI/UIX/accessibility; asset/technical-art/media where applicable; QA/regression/release; packaging/deployment. Omit irrelevant disciplines and add project-specific ones from the Project Bible.

## 4. Build from project canon
Recover architecture and reusable boundaries. Preserve project terminology, workflows, data contracts, accepted visual/product direction and platform scope. Do not replace established canon with a generic app architecture. One canonical representation/source of truth should drive multiple consumers where the Project Bible establishes one. Do not duplicate subsystem logic inside views or adapters.

## 5. Current technology and existing implementations
Verify current official platform APIs, SDKs, sample code and deployment-target constraints rather than relying on stale assumptions. Search legitimate open-source/reference implementations for each hard subsystem. Reuse/adapt solved engineering where it improves correctness without dependency bloat or canon drift.

## 6. Repair and implementation
For reproducible defects where practical: reproduce -> capture evidence -> failing test -> smallest appropriate repair -> focused test -> subsystem test -> protected regression test -> evidence. Historical failures are investigation targets, not automatic current failures.

Do not stop because a gate fails. Record `STAGE / ACTION / RESULT / ERROR / IMPACT / NEXT ACTION`, change something, retry, and continue safe available work. A genuine blocker requires an attempted action plus an unavailable dependency preventing further safe progress.

Use the current authoritative development pipeline governed by ForgeMASTER where applicable. Specialists own their work; EITRIFactory executes production work where established; evidence determines state. Do not resurrect EITRI/EITRIMB as parallel governors from stale handoff text. Preserve LKG before extension. Compilation is not functionality; installation is not acceptance.

## 7. UI/UIX and assets
A final product must not be an engineering harness disguised as production UI. Preserve project-specific UIX and research comparable products only for interaction/engineering patterns, never proprietary assets/trade dress. For asset-heavy projects, use deterministic editable-source -> validation -> optimization -> runtime integration pipelines and preserve editable masters. Measure performance rather than guessing.

## 8. One-click development factory
Where the project calls for builders/installers, return robust executable entry points appropriate to that project. They should locate root; preflight host/toolchain/resources; detect existing dependencies; install only missing permitted dependencies; preserve signing/configuration; generate deterministic project files where applicable; build/test/package; checksum; and produce evidence. Do not reinstall heavy tooling unnecessarily or hide failed gates.

## 9. Required research output
For non-trivial research create `RESEARCH_AND_ADOPTION_REPORT.md` (or established equivalent) grouped by subsystem. Include problem, candidate, source/version/license, evidence, pros/cons, integration/dependency/privacy/offline cost, decision and implementation result. Do not dump search results; research must yield engineering decisions.

## 10. Handoff package construction
Follow `UNIVERSAL_REBUILD_BACKUP_RULE.md`: HANDOFF is lean/task-specific, not the exhaustive archive. Build the smallest complete package for the receiver and assigned goal.

Include as applicable:
- `START_HERE.md` / exact task contract;
- Project Bible/canon snapshot or exact bounded authority extracts;
- current state, LKG/candidate and relevant evidence;
- source/contracts/tests required for the task;
- relevant editable/runtime assets and manifests;
- donor/recovery material actually needed;
- build/project-generator/dependency files;
- research already performed;
- toolchain/environment/build/run instructions;
- expected return/output contract;
- package manifest and SHA-256 checksums.

Exclude caches, DerivedData, unrelated family projects, redundant archives, unrelated historical archaeology, secrets and regenerable intermediates.

Package size is determined by receiver access and task. If the receiver can access authoritative GitHub, prefer exact repo/ref/path pointers plus only missing task-local material. If the receiver cannot access GitHub/Mac/chat history, include the actual source/assets/evidence needed to make the package independently executable.

## 11. Required final return from executor
The executor must return cumulative results, not isolated patches/suggestions/snippets. Return the corrected current implementation and all changed source/tests/assets/build tooling/research/license/implementation/regression/unresolved-item reports required by the task. For a requested portable package: create it, unpack to a clean temporary location, run its verification tooling there where practical, verify required files and checksums, record actual PASS evidence, and leave unexecuted gates UNKNOWN.

The result must be sufficient for the next developer/executor to continue without reconstructing the same history again.

## 12. Governing invariant
**Recover first. Research before reinventing. Preserve demonstrated capability. Implement against canon. Test regressions continuously. Evidence determines state. Return cumulative working results.**
