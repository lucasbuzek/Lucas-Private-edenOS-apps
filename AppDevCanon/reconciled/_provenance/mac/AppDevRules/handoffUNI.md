# handoffUNI — Universal Project Handoff Command

## Invocation
`@handoffUNI [project] [goal]` or by FORGEMASTER / CONDUCTOR / EITRIMB / EitriFactory.

## Purpose
Create a self-contained, evidence-bounded, appropriately sized handoff package that lets a competent AI or developer continue the named app/project without reconstructing its history. This rule prepares the actual data package, not merely a prompt or summary.

## Authority and recovery
1. Identify ACTIVE PROJECT and CURRENT GOAL first. Never drift to another project.
2. Load current AppDev authority, Project Bible/settings, project source/repository, LKG/current candidate, evidence and current requested milestone.
3. Recover narrowly relevant material from donor projects, old builds, branches/worktrees, project conversations and evidence when current authority/source shows a gap. Do not make old governance authoritative.
4. Compare donor/current implementations. Preserve demonstrated working capability before replacement. Newest != best. Compiled != authoritative.
5. Record contradictions and resolve by authority: current user goal -> current Project Bible -> current AppDev rules -> demonstrated source/evidence for implementation truth.

## Evidence inventory
Classify every material claim: GENERATED / IMPLEMENTED / BUILT / TESTED / VERIFIED / RELEASED; UNKNOWN != PASS. Inventory what exists, compiles, is implemented/tested/physically demonstrated, regressed, duplicated, obsolete, missing, or contradictory. Preserve LKG/recovery material.

## Research/reuse
For substantial unsolved gaps use: native/platform -> installed capability -> mature free/open-source/library/tool -> adaptable existing implementation -> custom code. Record source/version/commit, license and rights, maintenance/platform/offline/dependency cost, integration effort, canon conflicts, ADOPT/ADAPT/REFERENCE/REJECT. Unknown licensing means do not incorporate.

## Package contents
Scale package size to project complexity, but include what the recipient cannot otherwise access:
- START_HERE.md with exact continuation directive;
- Authority/ (Project Bible + only necessary governing references or pointers);
- CurrentCandidate/ or reproducible source snapshot;
- LKG/ selected recovery baseline when materially useful;
- SelectedEvidence/ bounded evidence, logs/reports and physical evidence;
- donor/recovery implementations required to prevent regression;
- REQUIREMENTS_LEDGER.md;
- CURRENT_STATE.md;
- IMPLEMENTATION_PLAN.md focused on executable remaining gap;
- RESEARCH_AND_ADOPTION_REPORT.md when research is material;
- THIRD_PARTY_LICENSES.md where dependencies/assets exist;
- build/project-generator/dependency configuration;
- tests and verification tooling;
- asset/source pipelines and editable masters when required;
- one-click build/verify/install entry points appropriate to project;
- PACKAGE_MANIFEST.txt and SHA256SUMS.txt;
- FINAL_ACCEPTANCE.md with PASS/FAIL/UNKNOWN bounded claims.
Exclude DerivedData, caches, irrelevant history, secrets/credentials and redundant generated output.

## Engineering mandate
Recipient acts as a senior multidisciplinary software/product team. Recover before rewriting. Research before reinventing. Preserve canon, architecture, terminology and demonstrated capability. Do not delete functionality merely to compile. Use TDD/regression repair where practical. Retry must change something. Failed gate is evidence, not automatically a blocker.

## Pipeline
REFERENCE -> BASELINE -> IMPLEMENT -> STATIC VERIFY -> ENVIRONMENT VERIFY -> REGRESSION VERIFY -> PACKAGE -> PACKAGE VERIFY -> PHYSICAL GATE -> PROMOTE.

## Package verification
Before handoff: create package/archive; unpack into clean temporary location; verify manifest/checksums; run available build/tests/verification from extracted copy; confirm required files; record actual PASS; leave unexecuted gates UNKNOWN. Package existence is not delivery.

## Required recipient outcome
Continue the CURRENT GOAL, not merely analyze it. Return/persist a cumulative implementation with source, tests, assets, builders, evidence, research/adoption decisions, unresolved items and exact continuation/build instructions. Do not return isolated patches or a suggestion list when implementation is executable.

## Portability invariant
The package must contain enough project-specific information and data for a recipient without conversation history to continue correctly. Provider-specific variants may omit bulk data only when that provider demonstrably has reliable access to the authoritative repository/files; they must still include exact refs/paths/commits and a fallback snapshot strategy.