# ForgeMASTER v1.0 — Calls and Routing

This registry is normative for ForgeMASTER v1.0.

## Goal calls
`@forgemaster goal (...)` — normal goal execution contract.

`@forgemaster extendedgoal (...)` — expand plain-language intent into a comprehensive execution contract, present it to the user for submission, and STOP. Submission of the expanded contract is the execution authorization. `extendedgoal` does not silently execute the expanded goal.

## Handoff / backup calls
`@forgemaster handofffull` → shared HANDOFF CORE → destination-neutral portable continuation package.

`@forgemaster backupfull` → shared BACKUP CORE → RECOVERY-level canonical backup, verified for expected contents/recoverability.

`@forgemaster backuplocal` → shared BACKUP CORE → synchronized Mac offline/recovery mirror at requested backup level.

`@forgemaster handoffCodex` → HANDOFF CORE + CODEX ADAPTER → Codex-ready executable task → offer `Start Codex: CLOUD | LOCAL | MIXED` → explicit confirmation required before starting new session/task.

`@forgemaster handoffClaude` → HANDOFF CORE + CLAUDE ADAPTER → self-contained Claude-compatible development-team package and instructions.

## Shared handoff core
All handoff adapters MUST inherit: authority recovery; Project Bible/global canon reconciliation; repository/branch/worktree/LKG/candidate state; complete product definition relevant to continuation; evidence-state distinctions; completed/in-progress/unfinished/failures/regressions/blockers; package manifest/provenance; universal continue-work rule; deterministic next gate/action; recovery location.

## Shared backup core
All backup adapters MUST inherit: source + history/references + canon + configuration + assets + tests + docs + evidence + LKG/candidate + environment/dependency manifest + failures/blockers + handoff/continuation record; secret exclusion/safe representation; transactional verify-before-success behavior.

## Universal continue-work rule
MILESTONE REACHED with evidence OR GENUINELY BLOCKED. Repairable failure follows FAIL → CAPTURE EVIDENCE → DIAGNOSE → CHANGE SOMETHING MEANINGFUL → RETRY → REVERIFY → CONTINUE. Never repeat an identical failed operation indefinitely.

## Compatibility migration
EITRI/EITRIMB-era handoff definitions are provenance inputs, not parallel governance. Existing names may remain aliases only when routed through ForgeMASTER shared cores. No legacy alias may bypass current evidence, LKG, recovery, backup, continuation, or confirmation rules.
