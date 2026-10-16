# BIFROST variant — OpenHands execution adapter

Status: isolated read-only adapter and mock tests implemented; upstream NOT installed or connected; Mac build and physical acceptance UNKNOWN.
Base: bifrost/native-consolidated-20261010.
Upstream candidate: https://github.com/OpenHands/OpenHands

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

## Verified source and implementation — 2026-10-16
- Canonical repository moved from `All-Hands-AI/OpenHands` to `OpenHands/OpenHands`. MIT license verified. Current **Agent Canvas** acts as a full agent control center and may launch local host commands, use a full filesystem and network; not a safe drop-in sandbox or bounded BIFROST worker.
- Upstream `docs/SELF_HOSTING.md` explicitly warns that its agent can run arbitrary shell commands and that the browser origin / embedded editor can expose backend session API keys. Shared administrative access is incompatible with BIFROST's intended multi-user isolation without further controls.
- `adapter.py` only checks that a caller-supplied endpoint is explicit IPv4 loopback and contains no credentials, query or task path. It does not make a network request or assert that a sandbox exists; `authenticated` and `sandbox` are `unverified`.
- `test_adapter.py`: five mock tests executed in isolated Python unittest with exact Git blob read-back.
- **Next gate:** demonstrate a genuinely isolated, authenticated, per-user worker with path/network restrictions before connecting any executor. No OpenHands runtime installed.
