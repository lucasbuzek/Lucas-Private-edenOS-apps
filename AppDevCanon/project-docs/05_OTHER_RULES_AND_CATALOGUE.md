

<!-- SOURCE: reconciled/AppDevRules/00_CANONICAL_PROCEDURE_FIRST_RULE.md | SHA256:3f22738c9d19 -->

# CANONICAL PROCEDURE FIRST — Highest-Priority AppDevRule

Status: CANONICAL — FIRST RULE
Scope: all EDEN/AppDev work, every project, App, helper, specialist, governor, handoff, tool action, and response.
Priority: evaluate and apply this rule before every AppDev response and before selecting or executing any action.

> When a canonical procedure exists, execute it literally. Do not substitute an apparently equivalent procedure. Do not report a state until the required evidence for that state has actually been observed.

## Mandatory per-response preflight
Before every AppDev response or action:
1. Recover/check the applicable canonical procedure and current authority.
2. Follow that procedure literally, in its defined order and using its defined mechanism.
3. Do not improvise, optimize, replace, approximate, or substitute another mechanism merely because it appears equivalent.
4. Observe the procedure's required evidence gate before reporting any resulting state.
5. If the required evidence has not been observed, the state remains UNKNOWN/UNVERIFIED; never report it as complete, started, pasted, executed, built, tested, verified, released, or otherwise advanced.
6. If literal execution is genuinely impossible, identify the exact failed canonical step. Do not silently switch procedures.

This rule precedes and constrains all lower AppDevRules, Project Bibles, procedures, workflows, AUTO execution, handoffs, and tool-selection decisions unless Lucas explicitly supersedes the canonical procedure.

<!-- SOURCE: reconciled/AppDevRules/PROCEDURAL_LKG_AND_ANTI_DRIFT_RULE.md | SHA256:ca429da8f978 -->

# PROCEDURAL LKG + ANTI-DRIFT RULE

Status: GLOBAL APPDEV CANON
Purpose: preserve proven operational procedures and prevent execution-path drift.

## Proven procedure is executable authority
Once an operational procedure physically succeeds, preserve its exact execution context as PROCEDURAL LKG: goal, command(s), working directory, repository/worktree/branch/environment/task identifiers where applicable, authentication mechanism, expected result, verification/postcondition, and date/evidence. Reuse the Procedural LKG before inventing a replacement route.

## Recover before solve
For a previously performed operation, recover the last successful procedure from project authority, handoff, Git records, execution history, or PROCEDURES_LKG before proposing or executing a new method. Do not rediscover a solved workflow.

## No substitute path without failed LKG
Do not replace a known-good procedure until the actual LKG procedure has been attempted and demonstrably failed or is no longer applicable. Record the failure evidence and the reason the substitute is necessary. Retry must change something relevant to the demonstrated failure, not the user's goal.

## Minimum-path execution
Use the shortest already-proven route that satisfies the requested action. Do not introduce cloning, packaging, rebuilding, authentication, alternate services, new worktrees, or architecture changes unless required by evidence.

## Command is not result
A command start, process creation, request acceptance, upload initiation, clone initiation, build invocation, or tool return is not completion. Completion requires the requested postcondition to be verified from resulting state/artifacts.

## Identifiers are recovered, never guessed
Do not infer or fabricate repository paths, worktrees, branches, environment IDs/names, task IDs, device IDs, credentials requirements, artifact paths, or package names when they can be recovered. If unresolved, state PROCEDURE/IDENTIFIER UNKNOWN and continue targeted recovery rather than improvising.

## Preserve user intent through repair
A failed transfer authorizes repair of the transfer, not repository redesign, rebuild, repackage, alternate deployment, or unrelated cleanup. A failed build authorizes build repair, not product redesign. Scope expansion requires evidence or explicit authority.

## Mandatory postcondition
Every executable action must have a machine-verifiable postcondition defined before completion is claimed. Verify the actual artifact/state, not merely command exit when stronger evidence is available. Example: cloud-task transfer = apply completes + expected changed files exist locally + status/count/hash or equivalent evidence checked.

## PROCEDURES_LKG ledger
Projects and shared tooling may maintain a compact PROCEDURES_LKG.md for recurring operational recipes. Entries contain: NAME; GOAL; STATUS; LAST VERIFIED; CONTEXT; EXACT PROCEDURE; EXPECTED RESULT; POSTCONDITION; FALLBACK; EVIDENCE. Do not duplicate product canon in this ledger.

## Fail closed against drift
Recovered authority and Procedural LKG outrank a newly improvised execution path. If they conflict, follow authority/LKG unless demonstrated evidence invalidates it. If no established procedure can be recovered, mark PROCEDURE UNKNOWN, use the canonical engineering method to establish one, verify it, then promote it to Procedural LKG.

<!-- SOURCE: reconciled/AppDevRules/UNIVERSAL_APP_INTEGRATION_HIERARCHY_RULE.md | SHA256:1e14beddc727 -->

# UNIVERSAL APP INTEGRATION & HIERARCHY RULE

Status: AUTHORITATIVE UNIVERSAL APPDEV RULE
Applies to: ALL AppDev applications, services, assistants, specialist apps, bridges and higher-level orchestration products.

## 1. Standalone-first invariant

Every application is independently complete for its core domain unless its Project Bible explicitly defines it as a subordinate component.

A specialist app must not require HEIMDALL, BIFROST, CONDUCTOR or another EDEN app merely to perform its own core work.

Removing a higher-level EDEN layer must not destroy the specialist app's core standalone functionality.

## 2. Optional integration, not ownership transfer

Higher-level systems may:
- discover an app;
- call its capabilities;
- deep-link into it;
- invoke App Intents / Shortcuts;
- use its API/headless service;
- embed an authorized representation;
- route work to it;
- present it inside a broader workspace.

This does NOT transfer domain ownership.

The specialist app remains authoritative for its domain logic, state and user-facing product behavior.

## 3. Independence is bidirectional

A higher-level app must not depend on one specialist app unless explicitly defined.

A specialist app must not depend on a higher-level app unless explicitly defined.

Example:
- HEIMDALL may call CRESUS.
- BIFROST may discover/route to CRESUS.
- CONDUCTOR may request a CRESUS capability.
- Siri may invoke CRESUS directly.
- CRESUS may run fully without HEIMDALL/BIFROST/CONDUCTOR.
- HEIMDALL/BIFROST/CONDUCTOR may run fully without CRESUS.

## 4. Role hierarchy

Unless a Project Bible defines otherwise:

CONDUCTOR
- interprets, reasons, coordinates and routes complex work;
- does not own specialist domain logic.

BIFROST
- discovers/resolves providers, capabilities, connections and representations;
- may provide shared connective/hosting infrastructure;
- is not the specialist app and is not the AI itself.

HEIMDALL
- provides organizing/understanding/workspace-oriented user experiences where established;
- may surface or invoke specialist capabilities;
- does not absorb specialist domain ownership.

SPECIALIST APPLICATION
- owns its domain;
- executes its own deterministic work;
- owns its own native UI where justified;
- exposes capabilities to other layers;
- remains standalone.

SIRI / APPLE SYSTEM SURFACES
- may invoke an app directly through App Intents/Shortcuts;
- may invoke higher-level EDEN apps;
- may perform their own Apple Intelligence/provider escalation.

## 5. Capability contract

Each integratable app should expose, as applicable:
- identity/version;
- capabilities/actions;
- inputs/outputs;
- availability;
- required permissions;
- local/network characteristics;
- consequence level;
- deep links/routes;
- App Intents / App Shortcuts;
- service/headless/API endpoint;
- representation types;
- health/state;
- data authority/ownership;
- optional shared-host compatibility;
- provider/intelligence requirements.

## 6. Representation progression

Use the lowest sufficient representation:

LINK
-> WEB/TAB
-> EMBED
-> NATIVE BRIDGE
-> NATIVE

Do not create duplicate native clients merely for architectural purity.

Native first does not mean native at all costs.

## 7. Shared hosting

An app may voluntarily allow compatible generic infrastructure to be hosted by BIFROST or another approved shared host.

HOSTING IS TRANSFERABLE.
DOMAIN OWNERSHIP IS NOT.

The app must retain enough standalone capability to recover/reclaim its hosted function where practical.

## 8. Intelligence independence

Apps may own their own:
- deterministic reasoning;
- native/device AI;
- silentChatGPT path;
- cloud provider adapters;
- provider login/configuration.

Higher-level EDEN systems may also own their own independent intelligence/provider stack.

A higher-level system may choose to:
- reason itself and call a deterministic specialist capability;
- call the specialist app's own intelligent capability;
- delegate the entire specialist task to the app.

No universal broker dependency is implied.

## 9. Data ownership

Specialist app data remains owned by the specialist domain/user.

Higher-level systems may store:
- connective metadata;
- capability registry;
- location/connection state;
- representation metadata;
- interoperability metadata;
- references/provenance needed for routing.

They must not silently swallow specialist databases into a monolith.

User data must outlive any optional integration layer.

## 10. Siri / direct system invocation

A standalone app should expose direct system integration where useful.

Canonical examples:
Siri -> CRESUS App Intent -> CRESUS
Siri -> HEIMDALL -> CRESUS
HEIMDALL -> CRESUS
BIFROST -> CRESUS
CONDUCTOR -> CRESUS

All are valid if implemented.

No path is universally mandatory.

## 11. Failure isolation

If BIFROST is unavailable, specialist apps continue standalone.
If HEIMDALL is unavailable, specialist apps continue standalone.
If CONDUCTOR is unavailable, specialist apps continue standalone.
If one specialist app is unavailable, higher-level systems continue and report that capability as unavailable rather than faking it.

Integration failure must not create false feature availability.

## 12. UI / hierarchy

Higher-level UI should not erase specialist identity.

A specialist app may appear:
- as a direct app;
- inside a workspace;
- as an embedded/native representation;
- as an invoked capability;
- as a background execution target.

The product should present the correct owner/context where that matters.

## 13. Universal invariant

APPS ARE STANDALONE DOMAIN OWNERS.
HIGHER LAYERS MAY DISCOVER, ROUTE, EMBED OR CALL THEM.
INTEGRATION IS ADDITIVE.
DEPENDENCY MUST BE EXPLICIT.
HOSTING MAY MOVE; OWNERSHIP DOES NOT.


<!-- SOURCE: reconciled/AppDevRules/UNIVERSAL_PROJECT_STORAGE_RULE.md | SHA256:d8c8157ee73c -->

# UNIVERSAL PROJECT STORAGE, APPDEV SPACE & PACKAGE DELIVERY RULE

Status: CANONICAL GLOBAL APPDEV RULE
Authority: AppDevRules; applies to all current and future AppDev work.
Supersedes conflicting older storage, Finder-tag and Releases/Products wording.

## 1. Central AppDev space
`~/edenOS/AppDev/` is the central AppDev control and governance space.

It contains:
- `#appDev Bible/` — global AppDev authority, rules and Project Bibles.
- `#app-assistants/` — authoritative/reconstructible in-chat helper, assistant, specialist and governor material.
- `#App Backups/` — durable AppDev/application backup and recovery packages.
- `#handoffs/` — active and retained handoff material.
- `Smart Folders/` — saved Finder searches/views for AppDev navigation and status; never engineering authority.

These are control/support collections, not application source workspaces.

## 2. Canonical project storage
- `~/edenOS/Projects/EDEN Apps/<APP>/` — EDEN software applications only.
- `~/edenOS/Projects/<PROJECT>/` — independent products/projects and HW/SW projects.
- `~/edenOS/Temporary/<PROJECT>/` — disposable cache, DerivedData, scratch, transient staging and rebuildable intermediates only.
- `~/edenOS/Quarantine/` — uncertain/misplaced material awaiting reconciliation; quarantine is not deletion.
- No duplicate authoritative copies. Backup/recovery duplicates must be explicitly identified as such.

Established classifications:
- HESPERA: EDEN App.
- HESTIA / gardenOS: independent HW/SW project.
- SWAYcore: independent project; NOT EDEN.
- Modern Generals Native/mods: independent project family; NOT EDEN.

## 3. Per-App workspace
Each EDEN App folder is a neat, self-contained durable workspace for all non-temporary App-specific material. Preserve existing build-system conventions and working repository paths; do not rename merely for cosmetic uniformity.

Each EDEN App workspace exposes the central AppDev space using a single link/reference:
`AppDev -> ~/edenOS/AppDev`

Do not duplicate the AppDev governance tree into every App.

App-specific durable material may include source, tests, resources, configuration, documentation, data, evidence, recovery records, tools and package records as appropriate. Temporary/cache/rebuildable outputs belong under `~/edenOS/Temporary/`.

## 4. Releases — test launchpad
`~/edenOS/Releases/` is the launchpad for intentionally compiled/testable application builds.

A compiled application may be made available there for manual, physical-device or user testing. Presence in Releases does NOT mean evidence state RELEASED, VERIFIED, TESTED or WORKING.

Evidence tags/records must state the demonstrated truth, e.g. `§Built`, `§Test`, `§Unverified`.

Never promote evidence state merely because an artifact exists in Releases.

## 5. Products — qualified functional applications
`~/edenOS/Products/` contains applications that have demonstrated the project's required working/tested/functional gate.

Admission to Products requires evidence appropriate to the project. Compilation alone is insufficient.

Products does not replace source Projects, LKG records, release artifacts, manifests or recovery evidence.

## 6. Package delivery
Evidence-gated flow remains:
REFERENCE -> BASELINE/LKG -> IMPLEMENT -> VERIFY -> REGRESSION -> PACKAGE -> PACKAGE VERIFY -> PHYSICAL GATE -> PROMOTE.

A normal local progression is:
Project workspace -> compiled/testable candidate in Releases -> required testing/verification -> qualified working application in Products.

GENERATED != IMPLEMENTED != BUILT != TESTED != VERIFIED != RELEASED.
UNKNOWN != PASS.
Preserve LKG.

## 7. Finder taxonomy and Smart Folders
Finder metadata is a navigation/classification layer, never engineering authority.

Reserved semantics:
- `@` = identity / implementation type + platform, e.g. `@App macOS`, `@App iOS`, `@App iPadOS`, `@App Windows`, `@App Android`, `@PWA Web`, `@PWA Agent Web`, `@Assistant In-Chat`, `@ChatGPT`.
- `§` = lifecycle/evidence display state, e.g. `§In Development`, `§Built`, `§Test`, `§Alpha`, `§Beta`, `§Working`, `§Verified`, `§Recovery`, `§LKG`, `§Unverified`.
- `#` = structural/organizational collections such as `#appDev Bible`, `#app-assistants`, `#App Backups`, `#handoffs`.

Smart Folders are saved searches/views only. They do not move, copy, promote or determine state.

Canonical AppDev Smart Folder views should include:
APPDEV: All Apps; macOS Apps; iOS Apps; Web / PWA.
STATUS: In Development; AppTest; Alpha; Beta; Working; Recovery; Unverified.

`AppTest` is the compact user-facing attention queue for applications requiring Lucas's manual/physical testing. Its membership is driven by appropriate metadata/evidence; AppTest itself is not an evidence state.

The AppDev Smart Folder collection is stored under:
`~/edenOS/AppDev/Smart Folders/`

The Smart Folders collection is intended for Dock access as a Stack. Finder sidebar remains minimal; AppTest is the primary AppDev attention view.

## 8. Classification and migration safety
1. Canon determines identity; never classify from name or current filesystem location alone.
2. UNKNOWN remains UNKNOWN until classified.
3. Audit before moving; preserve Git/source relationships, LKG, recovery evidence and unique history.
4. A move is incomplete until path/reference migration and verification pass.
5. Existing working functionality and repository conventions outrank cosmetic reorganization.
6. Migration to this layout must be non-destructive and evidence-verified.


<!-- SOURCE: reconciled/AppDevRules/UNIVERSAL_REBUILD_BACKUP_RULE.md | SHA256:33ec16af2de1 -->

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

<!-- SOURCE: reconciled/AppDevRules/WEB_BROWSER_BRIDGE_CAPABILITY_RULE.md | SHA256:1d395f646257 -->

# WEB / BROWSER BRIDGE - SHARED CAPABILITY RULE (AppDevRule, Mac-only canon)

<!-- RECONCILED 2026-10-07: extracted verbatim from the tail of Mac file `appDev main/AppDevRules_Web_Browser_Bridge_Canon_v1.1.txt` (24228 B), whose first 460 lines are a copy of the appDev MASTER reconciliation handoff. Source sha256 2789ed918466885952094b82c591a60807719f5b8fa7fa9b3cac48184dfed392. Status: Mac-only canon, not yet in GitHub. -->

APPDEVRULE
— WEB / BROWSER BRIDGE SHARED CAPABILITY
============================================================

WEB / BROWSER BRIDGE — SHARED CAPABILITY RULE

The Web / Browser Bridge is a first-class independently consumable
shared EDEN capability. It is not owned exclusively by WEAVER, HERMES,
BIFROST, or another consuming App.

ARCHITECTURE EDEN WEB CAPABILITY / BROWSER BRIDGE CORE → Safari native /
WebExtension adapter — first-class for the Apple-centric Private build →
Chromium WebExtension adapter → Firefox WebExtension adapter →
default-browser / URL / Share fallback where richer integration is
unavailable

Apps consume the shared Web capability directly through a stable common
contract where technically practical.

BIFROST may discover, register, permission, expose, coordinate,
synchronize and enhance the Web capability, but BIFROST must not become
a mandatory runtime gateway or single point of failure.

WEAVER owns website design/development/optimization/SEO, not the generic
Browser Bridge. HERMES may use rich browser/page/form capabilities for
opportunity and application workflows, but does not own the generic
Browser Bridge. Other compatible Apps may consume the same capability
directly.

COMMON CAPABILITY SURFACE The shared contract may expose, where
supported and authorized: web.open web.fetch web.search web.download
web.capture active-page URL/title/metadata page/rendered-content
extraction current user selection page-to-App handoff
permission-controlled browser actions

Adapters normalize browser/platform differences behind the shared
contract. Capability/status semantics must truthfully expose what each
adapter can and cannot do.

INTERACTION PIPELINE For rich browser interaction, use: READ → EXTRACT →
UNDERSTAND → PREPARE → PREVIEW → AUTHORIZED ACTION → VERIFY

Reading/extraction and external actions remain permission-aware.
Consequential actions such as submissions, purchases, commitments,
messages, account changes or irreversible external actions require the
appropriate authorization and must follow: REQUEST → VALIDATE → SAFETY
CHECK → EXECUTE → CONFIRM

The Browser Bridge must not silently submit, purchase, commit, publish
or perform another consequential external action merely because it can
inspect or prepare the page.

APPLE PRIVATE BUILD Safari receives first-class native optimization and
integration for the Private Apple-centric environment where materially
useful. The shared core remains portable and must not become Safari-only
or Apple-only.

CROSS-PLATFORM Chromium and Firefox use compatible WebExtension/platform
adapters where practical. Unsupported browser functionality must degrade
gracefully to available capabilities rather than breaking unrelated EDEN
operation.

NO EDEN BROWSER REQUIREMENT Do not create a separate EDEN browser merely
to provide this capability when mature browser-extension/native
integration can satisfy the requirement. Integrate/adapt existing
browser platforms first.

LOCAL / PROVIDER INDEPENDENCE Browser integration is an adapter/provider
layer, not the owner of user data or domain logic. Loss of a browser
adapter must not invalidate EDEN-owned data, canonical state or
unrelated capabilities.

VERIFICATION Architecture/design status and implementation status are
separate. A Browser Bridge or adapter is not considered implemented,
installed, functional or verified until the relevant build,
installation, permissions and target-browser behavior have been tested
with evidence.


<!-- SOURCE: reconciled/AppDevRules/handoffCodex.md | SHA256:da3e27a33957 -->

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

<!-- SOURCE: reconciled/AppDevRules/handoffGPT.md | SHA256:147d978f8db4 -->

# handoffGPT — ChatGPT AppDev Handoff

Status: AUTHORITATIVE APPDEV RULE
Base: `AppDevRules/handoffUNI.md`
Command: `@handoffGPT [goal/task]`

Apply `handoffUNI` in full, then specialize the transfer for ChatGPT.

## Access model
ChatGPT may have authenticated GitHub/connectors, current conversation files and approved development/testing plugins. Do not duplicate repository contents into the package when ChatGPT can retrieve the authoritative exact repo/ref/path. Use current connected sources and cite/record exact authority. Recover narrowly from conversation history only when a required project fact has not yet been migrated to authority.

Lucas's Mac has NO assumed GitHub connection. ChatGPT accesses GitHub through its authenticated GitHub connector and accesses the Mac through the authorized Mac/Remote Desktop bridge. Never require local GitHub access on the Mac merely because GitHub persistence is required.

> **RECONCILED 2026-10-07 - Claude/gh route, surface-dependent (Lucas decision 2026-10-06/07):** `gh` on Lucas's Mac IS authorized (logged in as lucasbuzek; scopes repo/gist/read:org). Where a Claude session is linked to the Mac (Claude desktop app / Claude Code session with Remote Desktop Commander present), Claude reaches the Mac through RDC and uses `gh` and the `codex` CLI there; Claude's own GitHub connector does NOT reach Lucas's private repos. Claude in the browser or the iPhone app has NO Mac/RDC/GitHub access (previously the only Claude surfaces used): there Claude works only from the Claude Project's mirrored files and supplied attachments. The ChatGPT-connector statement above remains valid for ChatGPT sessions. The newest explicit user decision outranks the older line.


## In-chat directive authority
AppDevRules are not merely files for local tools. They are directives for ChatGPT's in-chat AppDev behavior whenever the relevant authority is available in the active project/session context.

Before an AppDev response or action, apply `00_CANONICAL_PROCEDURE_FIRST_RULE.md` first: recover/check the applicable canonical procedure and authority, execute an established procedure literally, do not substitute an apparently equivalent mechanism, and do not report a state until its required evidence has actually been observed.

Chat memory/context may help recover a directive, but it is not the sole durable authority. Durable global AppDev rules are persisted in `lucasbuzek/Lucas-private-appDevDocs/AppDevRules`; the independent Mac copy lives at `~/edenOS/Projects/#appDev Bible/AppDevRules/`. ChatGPT explicitly reconciles the two through their respective connectors; never describe them as automatically synchronized.

## Package
Create an applicable-size `HANDOFF_GPT/` or archive containing `START_HERE.md`, exact project/goal/acceptance, authority/repository/ref pointers, LKG/candidate/evidence, relevant missing/local-only files, task-specific source/assets when connector access is insufficient, build/test instructions, expected return contract, manifest and checksums.

ChatGPT must not treat chat memory as durable project authority. Material discoveries/corrections that become project canon or implementation state must be persisted to the authoritative Project Bible/repository according to AppDev rules.

## Execution
Use available suitable tools/plugins directly when they advance the goal. GitHub is persistence/version control, not a substitute for actual build/runtime evidence. Mac/device bridge tools are for genuinely local execution/physical verification and for maintaining/reconciling the independent Mac authority copy; they are not a substitute for ChatGPT's GitHub connector.

Return cumulative implementation/evidence and persist durable results. Do not stop at a plan, status report, code snippets or a handoff description when safe executable work remains.

<!-- SOURCE: reconciled/AppDevRules/handoffUNI.md | SHA256:d76c2288bdb6 -->

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

<!-- SOURCE: reconciled/GMR.txt | SHA256:389bafeb5a91 -->

GMR — GrandMasterRegister — RECOVERED CANONICAL CORE
Status: ACTIVE catalogue authority.

GrandMasterRegister is the catalogue, not AppDev rules and not an execution owner.
It contains registered Apps, Products, Workspaces where appropriate, Specialists, Helpers, Tiny Apps/Helpers, Agents, Modules, shared capabilities, providers where appropriate, and other registered entities.

For every candidate distinguish:
TYPE ≠ CAPABILITY ≠ PROVIDER ≠ INSTANCE/CONNECTION ≠ REPRESENTATION ≠ WORKSPACE/COMPOSITION.

Statuses: ACTIVE · SUPERSEDED · PROVENANCE · RECOVERY_PENDING.
UNRESOLVED ≠ PERMISSION TO INVENT.

Do not automatically register every panel, view, layout, workspace instance, provider connection or contextual action as a top-level entity.
Do not invent canonical IDs, expansions, symbols, parentage, personalities or capabilities. Unsupported facts remain RECOVERY_PENDING.

A dedicated App Release Register is separate and distinguishes app_version, source_revision, build_id, package_version, release_channel, authority, audience, profile/schema/migration version, build/test evidence, representations/targets, dependencies, installed/deployed state where evidenced, LKG, limitations, recovery pending, and next release target.


<!-- SOURCE: reconciled/namingRules.txt | SHA256:db6c71fe97cf -->

EDEN NAMING RULES — PRIVATE AUTHORITATIVE SOURCE
Version: 2026.09.22
Status: ACTIVE

1. Preserve established project identities. Do not rename an established project without explicit instruction.
2. Canonical project display: [ACRONYM] — [Expanded Functional Meaning] — v[VERSION].
3. Machine identity is stable ASCII. Display identity, acronym, personality, aliases and legacy names are separate fields.
4. Functional responsibility is authoritative. Personality/decorative naming never changes hierarchy or ownership.
5. Legacy identity is preserved for provenance, then resolved to its canonical successor. New work uses the current identity.
6. Names should be functional, conceptual, behavioral, technical, portable, distinct, traceable and honest.
7. MEMORABLE TO HUMANS. STABLE TO MACHINES. MEANINGFUL IN CONTEXT. INDEPENDENT OF DECORATION. TRACEABLE THROUGH HISTORY.
8. Do not invent a new app/system identity where an existing identity or capability already owns the scope. THREAD recovery precedes invention when historical identity may exist.


<!-- SOURCE: reconciled/DESIGN_MANTRA.txt | SHA256:a6d4254be222 -->

DESIGN MANTRA — AUTHORITATIVE RECOVERED CORE

LOCAL FIRST. USER DATA OUTLIVES SOFTWARE. DATA BELONGS TO THE USER, NOT THE FIRMWARE IMAGE. INTEGRATIONS ARE ADAPTERS, NOT OWNERS. MIGRATE, DO NOT RESET. RECOVERY IS A PRODUCT FEATURE. SAFETY IS ARCHITECTURE. QUALITY IS MEASURED, NOT ASSUMED. POLISH IS FUNCTIONAL. DEFAULTS SHOULD BE GOOD ENOUGH TO SUCCEED. DESIGN FOR THE COMMON CASE; RETAIN POWER FOR THE EXPERT. PROGRESSIVE DISCLOSURE. SHOW STATE. CONFIRM CONSEQUENCE. MAKE AUTOMATION EXPLAINABLE. BUILD A SMALL CORE AND MOVE WEIGHT OUTWARD. REMOVE BEFORE ADDING. ONE AUTHORITATIVE PATH. DETAIL ON DEMAND. VERIFY BEFORE DESTRUCTIVE ACTION.

Overarching EDEN principle: Beauty, capability and dignity should not be premium features.

Engineering shorthand: Fresh architecture. Proven components. Integrate → Adapt → Optimize → Customize UX. Recreate only when justified by evidence.

Migration: DETECT → VALIDATE → BACKUP/STAGE → MIGRATE → VERIFY → COMMIT → ROLLBACK ON FAILURE.
Consequential action: REQUEST → VALIDATE → SAFETY CHECK → EXECUTE → CONFIRM.
RECOVER/REUSE LAST KNOWN GOOD BEFORE REDESIGN. No new feature silently regresses verified behavior.
Tests: PASS / FAIL / UNKNOWN / SKIPPED / N/A. UNKNOWN is never PASS. PASS requires evidence. Platform behavior is UNKNOWN until tested on target platform.
