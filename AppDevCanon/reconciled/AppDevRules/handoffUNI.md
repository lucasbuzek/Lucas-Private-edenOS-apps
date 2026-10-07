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