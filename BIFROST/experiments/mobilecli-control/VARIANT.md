# BIFROST variant — MobileCLI control-plane adapter

Status: isolated research branch; scaffold only; NOT integrated, installed, built, or tested.
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
