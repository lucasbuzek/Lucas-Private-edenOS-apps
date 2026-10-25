# BIFROST — Project State

## Ledger

PROJECT: BIFROST  
AUTHORITATIVE BASELINE: recovered conversation canon / BIFROST Project Handoff  
LAST KNOWN GOOD: not yet reconciled from historical runtime evidence  
CURRENT CANDIDATE: none promoted; prior 12.x packages retained as evidence only  
CURRENT STAGE: requirements/research recovery  
REFERENCE HARNESS: Desktop Commander Remote / Remote Desktop Commander  
HEIMDALL iOS RUNTIME DEPENDENCY: not required  
NEXT GATE: canonical Mac workspace + provider implementation + target verification

## EDC — Remote Access & Availability Provider

**Class:** STANDARD  
**Requirement:** BIFROST can keep a trusted development Mac remotely available and govern its current remote bridge without absorbing that provider's credentials/domain.

### Required capabilities

- `remote.provider.detect`
- `remote.provider.fetch`
- `remote.provider.start`
- `remote.provider.stop`
- `remote.provider.restart`
- `remote.provider.status`
- `power.keepawake.start`
- `power.keepawake.stop`
- `power.keepawake.status`

### Selected providers

- Remote bridge: official `@wonderwhy-er/desktop-commander` Remote Device CLI until BIFROST replaces the gap natively.
- macOS power assertion: native `/usr/bin/caffeinate`.

### Acceptance criteria

1. Missing Remote Device CLI can be fetched through the official npm/npx distribution path when Node/npm are available.
2. Start does not create duplicate managed Remote Device processes.
3. Stop terminates only the BIFROST-managed Remote Device process.
4. Restart is stop + verified start.
5. Status distinguishes unavailable / stopped / running / stale state.
6. BIFROST does not store Desktop Commander account credentials.
7. Independent Keep Awake uses native caffeinate and records its managed PID/state.
8. Keep Awake can be disabled without stopping Remote Access.
9. Remote Access can be stopped without forcing independent Keep Awake off.
10. Failures return actionable evidence rather than false PASS.

### Security boundary

BIFROST may govern lifecycle and availability. Authentication remains owned by the Remote Device provider. No provider tokens, private keys or account credentials belong in this repository.

## Current evidence

- GitHub continuity path exists at `Lucas-Private-edenOS-apps/BIFROST`.
- Connected Remote Desktop Commander registry knows `Lucas-MacBook.local`, but the device was OFFLINE at the last live check.
- Therefore target-Mac implementation/physical verification is pending; repository recovery work can continue independently.


## 2026-10-25 approved BIFROSTzero AUTO continuation

This dated entry supersedes the old recovery-only status above for this candidate; historical text is retained as provenance.

- Owner approved all six BIFROSTzero checklist stages through private ZERO. No public release, purchases, destructive changes or new account grants.
- Recovered full source from `bifrost/recovery-20261024`, commit `cae5b8bfda558988f6da414a6ebed561c1fe8e85`. The small main-branch snapshot is not the current complete implementation.
- Candidate: `candidate/bifrost-zero-dispatch-guards-20261025`. Existing dispatcher/schema retained; no new executor or governor.
- Reproduced defect: on Linux, `call platform.read --platform macos` returned Linux metadata with verified=true. Fixed actual-host execution checks while preserving cross-platform resolve/planning.
- Resolver now requires an allowlisted adapter, read effect, implemented-readonly state and explicit requiresApproval=false. Workflow approval requirements are also enforced.
- Validation: Python unittest test_shortcalls.py: 13 tests, 12 passed, 1 skipped (real macOS). Matching-host unit tests use mocked Darwin; not physical Mac evidence. CLI foreign-host denial tested in real subprocesses. Full app regression and native build NOT RUN.
- All four RDC connections exposed to this session returned their listed Mac devices offline. Historical authorization/pairing is preserved; this is not an account-registration failure. RDC7 is not exposed here. Direct git clone returned HTTP 403; authenticated GitHub file access succeeded and supplied exact pinned source for isolated tests.
- Separate `candidate/apple-capability-discovery-20261025` at `b36f28da7e13b6f78cb48d7cb9e09a431220be22` inspected; not merged or replaced. Its Apple discovery candidate is not proven live integration.
- LKG, main, recovery branch, Mac source, services, credentials and grants unchanged. No ZERO FUNCTIONAL or release claim.
- Next gate: reconcile this small candidate with the current Mac dirty tree/LKG when a proven transport is reachable; run existing dispatcher regressions and real Shortcuts/status observation. Then reuse the separate Apple capability work for the established executor preflight, with host-specific permission evidence. Multi-device/provider, interruption/resume and native acceptance remain UNKNOWN.
