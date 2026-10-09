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
