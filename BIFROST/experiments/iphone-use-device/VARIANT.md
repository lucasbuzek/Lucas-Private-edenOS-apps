# BIFROST variant — iphone-use physical-device adapter

Status: isolated read-only adapter and mock tests implemented; upstream NOT installed or connected; Mac build and physical acceptance UNKNOWN.
Base: bifrost/native-consolidated-20261010.
Upstream candidate: https://github.com/leeguooooo/iphone-use

## Hypothesis
Reuse an existing real-device iPhone automation interface for physical acceptance testing and authorized device interaction rather than implementing a new USB/Wi-Fi automation stack.

## Scope boundary
This is a device-control/test adapter, not BIFROST's AI provider router, cloud coordinator, identity system, or Mac build executor. It must be optional and independently disableable.

## Proposed boundary
- Explicit device enrollment and user-approved pairing.
- Read-only device inventory and capability discovery first.
- Device actions require a named test/task and bounded action allowlist.
- Device screenshots, logs and action receipts are evidence attached to a BIFROST task ID.
- No unattended UI actions, account changes, credential extraction, or destructive actions by default.

## Investigation before implementation
1. Verify upstream license, maintainer/release activity, API/MCP/HTTP surface and supported iOS/macOS versions.
2. Inspect permission model, USB/Wi-Fi trust assumptions, pairing and sensitive-data exposure.
3. Map the existing BIFROST acceptance contract to only the missing device-control operations.
4. Keep all hardware interaction behind an explicit opt-in adapter.

## Required tests
- No paired device and denied permissions fail closed.
- Device identity cannot be silently substituted.
- Read-only inspection does not invoke taps, typing or state-changing actions.
- Actions are traceable to an approved test ID and captured result.
- Device disconnect/timeouts produce UNKNOWN rather than PASS.
- Existing BIFROST tests remain green.

## Gate
Do not integrate until security and license checks pass. Physical-device acceptance is not proven by simulator tests or a successful MCP/API connection.

## Verified source and implementation — 2026-10-16
- Upstream `LICENSE` and `LICENSING.md`: **PolyForm Shield 1.0.0**, source-available with a noncompetition restriction, not OSI open source. No upstream code copied, vendor binary redistributed or runtime installed. Adoption requires license compatibility determination.
- `docs/agent-reference.md` documents `GET /agent/status` / MCP `phone_status` fields `device_state`, `drivable`, `human_handoff`, `lock_readiness`; and a strict idle-release / avoid unnecessary reconnect policy.
- `adapter.py` is a read-only status projection only, omits device identity, never taps/types/reconnects, and cannot authorize a device action.
- `test_adapter.py`: five mock regressions executed in isolated Python unittest with exact Git blob read-back. Real device and pairing are UNKNOWN.
- **Next gate:** written license compatibility approval and physical-device/pairing evidence. No installation until then.
