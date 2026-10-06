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
Persistent project: `~/edenOS/Projects/<ProjectName>/`
Disposable work: `~/edenOS/Temporary/<ProjectName>/`
The project folder contains current implementation plus evolution/history, requirements, engineering records, LKG references and Git where used. Primary Xcode workspace/project and user/developer `.command` entry points belong at project root.

Do not scatter incremental builds, duplicate source trees, ZIPs, DerivedData or numbered/final-final project folders across Downloads/Desktop. Temporary outputs belong under the project's edenOS Temporary folder and are cleaned when no longer needed as evidence.
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
Finder tags classify rather than encode engineering truth. Broad industry/sector categories use full names; narrower categories use `#`; lifecycle/organizational tags use `@` (for example `@Active`, `@Archived`). Finder comments may mirror a human-readable state summary. Authoritative engineering state remains in project/system records. PENELOPE owns taxonomy reconciliation rather than each project inventing synonyms.

## Evidence-gated pipeline
REFERENCE → BASELINE → IMPLEMENT → STATIC VERIFY → ENVIRONMENT VERIFY → REGRESSION VERIFY → PACKAGE → PACKAGE VERIFY → PHYSICAL GATE → PROMOTE.

Evidence distinctions remain strict: GENERATED != IMPLEMENTED != BUILT != TESTED != VERIFIED != RELEASED; UNKNOWN != PASS.
## Procedural LKG / anti-drift
Recurring operational workflows are governed by `AppDevRules/PROCEDURAL_LKG_AND_ANTI_DRIFT_RULE.md`. Recover and reuse a physically proven procedure before inventing a substitute. A command/request/process start is not completion; verify the requested postcondition. Preserve recurring successful operational recipes as PROCEDURAL LKG.
