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