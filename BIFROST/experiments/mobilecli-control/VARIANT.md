# BIFROST variant — MobileCLI control-plane adapter

Status: isolated read-only adapter and mock tests implemented; upstream NOT installed or connected; Mac build and physical acceptance UNKNOWN.
Base: bifrost/native-consolidated-20261010.
Upstream candidate: https://github.com/MobileCLI/mobilecli

## Hypothesis
Reuse MobileCLI's existing iPhone-to-Mac coding-agent control and daemon capabilities where they overlap with BIFROST, instead of rebuilding phone control or another long-running terminal relay.

## Preserve BIFROST authority
BIFROST remains EDEN's connection/capability registry and policy boundary. RavenNest remains the optional online coordination plane. This experiment must not replace the canonical app, change LKG, silently start a daemon, or make BIFROST depend on MobileCLI being installed.

## Proposed boundary
- Adapter discovers MobileCLI only when explicitly configured and available.
- Report capability and availability separately from authorization and actual task completion.
- Delegate only user-authorized task requests to a named project/workspace.
- Correlate request ID, agent session ID, worker task ID and result receipt.
- Return actual artifact/evidence metadata; never infer success from a chat response or queued request.

## Investigation before implementation
1. Verify upstream repository identity, current release, license, macOS/iOS requirements, data flows and security model.
2. Inspect current BIFROST provider/capability contracts and RavenNest enrollment/approval interfaces.
3. Identify the smallest adapter seam; no second daemon until required and explicitly approved.
4. Document what MobileCLI already does versus what BIFROST must still own.

## Required tests
- Upstream absent, offline, unauthorized and stale-session cases fail closed.
- A queued request is not reported as executing or succeeded.
- Duplicate requests are idempotent or explicitly rejected.
- Task cancellation, timeout and worker disconnect become truthful states.
- Result includes artifact digest and independently checked postcondition.
- Existing BIFROST tests and LKG remain unchanged.

## Gate
Proceed to adapter code only after source/license/security review and a contract match. Physical iPhone → authorized Mac → artifact receipt remains UNKNOWN until observed.

## Verified source and implementation — 2026-10-16
- **Correct upstream:** `MobileCLI/mobilecli` (MIT license in `cli/LICENSE`); this is the Rust PTY/WebSocket relay for Claude, Codex, Gemini and other terminal sessions. **Not** `mobile-next/mobilecli`, which is an unrelated device-management CLI.
- Auth-v2 challenge-response pairing is upstream-owned; the daemon exposes PTY input, session spawn, file access and Expo push notifications. This branch does not connect to the daemon, start any service, retain credentials or expose terminal text.
- Inspected `cli/src/protocol.rs`: `ServerMessage::Sessions` contains `sessions` with `cli_type`; `WaitingForInput` contains `wait_type` and `cli_type`. `adapter.py` only reduces caller-supplied event data to non-identifying counters or wait reasons, with `authorization: none`. Events remain unverified until authenticated transport exists.
- `test_adapter.py`: six mock regressions executed with Python unittest in an isolated container; the exact tested Git blobs were compared with read-back. Local Mac/real WebSocket/session/approval acceptance remains UNKNOWN.
- **Next gate:** independently authenticate a caller against MobileCLI and the BIFROST subject/task grant, without duplicating RavenNest bridge or turning on a PTY daemon at startup.
