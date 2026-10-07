# edenOS AppDev Bible — Canonical Engineering Rules

## Authority
1. Newest explicit user decision.
2. Current frozen EDEN/AppDev canon.
3. Newest project-specific canon.
4. Verified evidence.
5. Older valid implementation/provenance.

Established project conversations are authoritative for requirements, architecture, intended behavior and accepted/rejected changes. Missing source does not remove a requirement. Existing source is implementation evidence.

## Development machines
A Mac/PC/toolchain is an execution environment for implementation-specific inspection, coding, building, testing, signing, packaging and deployment. It is not project memory and must not be used to redefine scope from incomplete source.

## Canonical filesystem
Central AppDev control space: `~/edenOS/AppDev/`, containing `#appDev Bible/`, `#app-assistants/`, `#App Backups/`, `#handoffs/` and `Smart Folders/`.
Persistent project: `~/edenOS/Projects/<ProjectName>/`
EDEN Apps: `~/edenOS/Projects/EDEN Apps/<APP>/`
Disposable work: `~/edenOS/Temporary/<ProjectName>/`
Compiled/testable launchpad: `~/edenOS/Releases/`
Qualified working/tested/functional applications: `~/edenOS/Products/`

The project folder contains current implementation plus evolution/history, requirements, engineering records, LKG references and Git where used. Primary Xcode workspace/project and user/developer `.command` entry points belong at project root. EDEN App workspaces expose the central AppDev space through a single link/reference; central governance material is not duplicated into each App.

Do not scatter incremental builds, duplicate source trees, ZIPs, DerivedData or numbered/final-final project folders across Downloads/Desktop. Temporary outputs belong under the project's edenOS Temporary folder and are cleaned when no longer needed as evidence. Releases presence means available for testing, not RELEASED/VERIFIED. Products admission requires demonstrated project-appropriate functional qualification. Detailed rules: `AppDevRules/UNIVERSAL_PROJECT_STORAGE_RULE.md`.

## Recovery and execution
Canonical recovery order: conversation canon → requirements ledger → canonical project workspace → identify LKG/current candidate → reconcile implementation against canon → implement gaps → verify → package/release.

Engineering method: RECOVER → DISCOVER → RECOGNIZE → REUSE → RECONCILE → INTEGRATE/ADAPT → BUILD ONLY THE GAP → VERIFY.

AUTO continues all safe available work until the requested milestone or a genuine unavailable dependency prevents remaining safe work. FAILED/UNVERIFIED/PIPELINE INCOMPLETE is not automatically BLOCKED. A blocker requires an attempted action and demonstrably unavailable dependency. Retry must change something.

Preserve LKG before extension. Commands/requests are authorization, not evidence. Evidence state must describe what was demonstrated.

## Roles
- EITRI: engineering/Master Builder governance.
- @eitrimb: in-chat application of EITRI governance.
- CONDUCTOR: system-wide reasoning and coordination.
- FORGE: deterministic implementation/build/test/package execution.
- PENELOPE: recognition, identity, lineage, provenance and source/revision reconciliation.
- BIFROST: CONNECT · KEEP · RESOLVE at system level; devices/connections/capability resolution and associated persistent connective state.
- Specialist Apps: own their domains.

Govern the work. Specialists own their work. Evidence determines state.
## Installation profiles
INSTALL / RECOMMENDED is the obvious balanced device-aware path and does not mean install everything. LEAN minimizes dependencies/resources. FULL installs all appropriate supported capabilities without pointless duplication. CUSTOM gives explicit provider/integration/component control. UI disclosure levels: Simple / Advanced / Expert; Essentials default.

## Existing capability first
Prefer OS native → installed suitable app/capability → small library/engine/CLI → provider before writing replacement functionality. Native capability first when adequate. Design around the desired workflow/experience rather than recreating software.

## Metadata
Finder metadata classifies and presents project state; it never creates engineering truth. Reserved prefixes: `@` = identity/type + platform (for example `@App macOS`); `§` = lifecycle/evidence display state (for example `§Built`, `§Unverified`); `#` = structural/organizational collections. Smart Folders are saved views only. `AppTest` is the compact attention view for applications requiring Lucas's manual/physical testing. Authoritative engineering state remains in project/system evidence records. PENELOPE owns taxonomy reconciliation rather than each project inventing synonyms.

## Evidence-gated pipeline
REFERENCE → BASELINE → IMPLEMENT → STATIC VERIFY → ENVIRONMENT VERIFY → REGRESSION VERIFY → PACKAGE → PACKAGE VERIFY → PHYSICAL GATE → PROMOTE.

Evidence distinctions remain strict: GENERATED != IMPLEMENTED != BUILT != TESTED != VERIFIED != RELEASED; UNKNOWN != PASS.
## Procedural LKG / anti-drift
Recurring operational workflows are governed by `AppDevRules/PROCEDURAL_LKG_AND_ANTI_DRIFT_RULE.md`. Recover and reuse a physically proven procedure before inventing a substitute. A command/request/process start is not completion; verify the requested postcondition. Preserve recurring successful operational recipes as PROCEDURAL LKG.

<!-- RECONCILED 2026-10-07: sections below existed only in APPDEV_BIBLE.txt (2026-10-01); merged verbatim per Lucas decision 1. Where they say EITRIMB, read: EITRIMB is superseded; ForgeMASTER is the SOLE AppDev governor (EITRIMB retained as provenance). -->

## Thin-governor execution update — 2026-10-01
Global development rules live here; EITRIMB inherits them rather than duplicating them. Project-specific canon lives under `Project Bibles/<PROJECT>.txt` and must be recovered from project/conversation authority rather than derived from global rules.

Starting gate: PROJECT → SCOPE → DELIVERABLES → ACCEPTANCE/DEFINITION OF DONE → RECOVER PROJECT BIBLE → SOURCE/LKG/EVIDENCE → GAP → proportional EDC → capability routing → EXECUTE.

Planning, analysis, status reports, handoffs, build-number increments and repeated packages are not product progress. If a safe executable next action exists, execute it. First failure: diagnose/change/retry. Repeated failure: materially different method and/or specialist/capability/plugin. Continued non-progress after materially different attempts is an execution loop. For Apple platform/system execution loops, Apple Core Council may challenge the approach and return an actionable changed course; never invoke Council on the first ordinary failure. Under AUTO, execute the resulting course.

Existing implementation first: actively seek native capabilities, installed software, working applications, open-source implementations/repos, engines, frameworks, libraries, SDKs, sample/reference code, CLIs, services and providers before substantial custom development. Prefer adapt/integrate/port/wrap; build only the unsolved gap. ARGOS handles non-trivial research. Installed/authorized plugins/connectors are executable capabilities, not authorities.

Persistent LCAS: TINY during incremental execution without stopping merely to report; FULL at meaningful milestones and genuine stops. A FULL stop states why execution stopped, evidence/impact and concrete executable next courses.

Only established workspaces are `~/edenOS/Projects/<Project>/` and `~/edenOS/Temporary/<Project>/`. Do not create additional scratch/cache/session workspace hierarchies. Significant candidates must be regression-checked against LKG. Package existence is not delivery; verify contents and claims. Leave current candidate, LKG, demonstrated state, known failure/blocker and next executable gate recoverable.

## Universal deliverable evidence rule — 2026-10-01
The requested deliverable and its established acceptance requirements govern execution. Intermediate engineering success proves only the demonstrated intermediate state and never implicitly advances a higher product state. GENERATED != IMPLEMENTED; IMPLEMENTED != BUILT; BUILT != TESTED; TESTED != VERIFIED; VERIFIED != RELEASED; UNKNOWN != PASS.

Always evaluate: WHAT WAS REQUESTED? WHAT ACCEPTANCE REQUIREMENTS DEFINE IT? WHAT DOES THE ACTUAL EVIDENCE DEMONSTRATE? WHAT REQUIRED GAP REMAINS? Never aggregate true intermediate results into an unsupported product-state claim. Generation proves generation; bundling proves bundling; compilation proves that build gate; signing proves signing; installation proves installation; launch proves launch. None independently proves required functionality or acceptance.

If the requested milestone remains incomplete and safe executable work remains, AUTO continues. Intermediate build/package/install/launch/infrastructure success is not a stopping condition. Perform all available implementation and verification before later physical/user gates; do not hand downstream a candidate already known to lack required functionality merely to rediscover the same absence.

On implementation failure use diagnose → change → retry. Escalate only after materially different reasonable attempts fail. Preserve LKG and demonstrated functionality. Do not create versions/packages merely to demonstrate activity. Do not claim progress beyond evidence or delivery beyond acceptance. Do not repeat global recovery when authority is already loaded, and do not use Mac/Git/GitHub/filesystem notes/external connections as substitutes for active context. LCAS is UI only; it displays supplied state and does not determine evidence, progress, acceptance, routing, execution or stopping behavior. EITRIMB inherits and enforces this universal rule; Project Bibles provide project-specific goal/scope/deliverables/acceptance.

## AUTO execution enforcement — 2026-10-01
Under AUTO, if a known safe executable action advances the requested deliverable, execute it rather than responding about it. Do not stop to report the next action, remaining implementation, incompleteness, sufficient context, or the fact that AUTO should continue. Do not perform broad recovery, census, Bible reload, rediscovery, planning, research, status generation, or environmental inspection when the next required implementation action is already known; inspect or research only when necessary to determine or perform that action.

Intermediate success or repairable intermediate failure does not end AUTO while the requested deliverable remains incomplete and safe executable work remains. Repairable failure uses inspect the specific failure → change something → retry → continue. Before any AUTO response: if the requested deliverable is complete, report the demonstrated result; if incomplete and safe executable work is available, do not respond—execute it; if no safe executable work remains because of a genuine blocker, required user decision, or authorization/safety boundary, report that exact stop and available courses. Statements such as “the next step is X,” “I should continue implementing X,” or a list of executable remaining gaps demonstrate that execution should continue rather than stop.
