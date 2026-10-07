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