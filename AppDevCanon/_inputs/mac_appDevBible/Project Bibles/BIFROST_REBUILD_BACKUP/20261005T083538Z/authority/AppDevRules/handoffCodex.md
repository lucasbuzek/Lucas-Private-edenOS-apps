# handoffCodex — Codex Engineering Handoff

Inherit `handoffUNI.md` completely. This file specializes execution for Codex.

## Invocation
`@handoffCodex [project] [goal]`

## Workspace contract
Codex works against the existing repository/workspace. Prefer LOCAL WORKSPACE FIRST -> IMPLEMENT -> VERIFY -> COMMIT -> PUSH. GitHub is persistence/version control, not a substitute implementation workspace. Do not recreate repositories via API/blob operations when normal local Git is available.

## Package strategy
Because Codex can work from the repository, keep the handoff efficient: package unique canon/evidence/recovery inputs and exact refs rather than needlessly duplicating a large repository. Include a source snapshot only when repository access cannot be guaranteed or uncommitted/current candidate material would otherwise be lost.

`CODEX_START_HERE.md` must answer **WHAT SHOULD CODEX EXECUTE NEXT?** and provide: repo/worktree; branch/base commit; Project Bible/rules refs; goal and acceptance; LKG; current candidate; dirty/uncommitted state; demonstrated tests/builds; known failures; donor/recovery locations; exact first commands/actions; required verification; commit/push expectations; physical gates that Codex cannot prove.

## Behavior
Inspect before edit. Preserve LKG. Do not rewrite working subsystems without evidence. Research/reuse before bespoke implementation. Use tests for reproducible defects where practical. Continue safe executable work through failed gates; retry with changed method. Never claim physical verification from compilation/simulator evidence.

## Completion
Leave repository recoverable and cumulative: implementation, tests, required assets/tooling, evidence report, research/adoption report where material, clean diff/commit history appropriate to task, exact unresolved items, and next physical/user gate. Verify any archive from a clean extraction before calling the handoff complete.