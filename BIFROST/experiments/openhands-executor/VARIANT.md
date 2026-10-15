# BIFROST variant — OpenHands execution adapter

Status: isolated research branch; scaffold only; NOT integrated, installed, built, or tested.
Base: bifrost/native-consolidated-20261010.
Upstream candidate: https://github.com/All-Hands-AI/OpenHands

## Hypothesis
If the current BIFROST/RavenNest queue lacks a reliable, isolated execution runtime, evaluate OpenHands as an optional executor behind the existing task and approval contract instead of inventing a second agent runtime.

## Scope boundary
OpenHands is a candidate worker/runtime, not the BIFROST registry, user identity authority, provider-neutral policy layer, or release governor. Existing native and portable BIFROST functions must continue to work without it.

## Proposed boundary
- Adapter accepts only a BIFROST-issued, approved task envelope.
- Use isolated workspace/container and least-privilege filesystem/network access.
- Keep provider secrets out of task text, logs, artifacts and model-visible files where possible.
- Expose truthful lifecycle states and cancellation; do not equate API acceptance with execution.
- Export artifacts to a controlled result staging area, then verify digest and postcondition independently.

## Investigation before implementation
1. Verify license, runtime prerequisites, security advisories, sandbox isolation, persistence and supported deployment modes.
2. Compare current BIFROST task lifecycle with OpenHands APIs and agent-server/runtime contracts.
3. Measure local/offline compatibility and whether the MacBook Air M1 can run the chosen mode without unacceptable resource use.
4. Reject this option if it introduces an unnecessary second orchestrator or weakens the offline/private workflow.

## Required tests
- Sandbox escape/host-path and network policy checks appropriate to the chosen runtime.
- Missing runtime, provider auth, timeout, cancellation and restart recovery.
- No unapproved filesystem writes or deployment actions.
- Artifact integrity and independently verified task postcondition.
- Existing BIFROST suites and LKG unchanged.

## Gate
No runtime installation or privileged worker activation until license, security, resource and integration review is complete.
