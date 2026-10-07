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
