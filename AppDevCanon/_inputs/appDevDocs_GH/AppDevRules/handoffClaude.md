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