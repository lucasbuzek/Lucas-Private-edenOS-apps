# BIFROST

**Identity:** EDEN system-level connective infrastructure  
**Canonical principle:** CONNECT · KEEP · RESOLVE

## Current authoritative stage

Requirements/research recovery before implementation. Existing BIFROST 12.x artifacts are evidence/candidates, not an automatically promoted product baseline.

## Immediate operational milestone

BIFROST must govern the Mac remote-development bridge currently provided by Desktop Commander Remote / Remote Desktop Commander:

- detect whether the Remote Device provider is available;
- fetch/install the official provider if missing;
- start it;
- stop it;
- restart it;
- report truthful status;
- preserve/reuse its existing authorization rather than storing credentials itself;
- expose native macOS keep-awake control separately from remote-access state.

Remote Desktop Commander is a reference implementation, test harness and development bridge. It is not a permanent HEIMDALL runtime dependency and does not replace BIFROST.

## Power-management requirement

Use native macOS `caffeinate` where sufficient. Distinguish:

1. **Remote Access keep-awake** — provider-scoped; Remote Desktop Commander currently uses caffeinate by default while its remote process runs.
2. **BIFROST Keep Awake** — independent native power capability, controllable even when Remote Desktop Commander is stopped.

Do not require a third-party Caffeine/Amphetamine-style app when native macOS capability is sufficient.

## Canonical Mac workspace

Persistent: `~/edenOS/Projects/BIFROST/`  
Temporary: `~/edenOS/Temporary/BIFROST/`

Do not scatter incremental builds through Downloads/Desktop. Git/history carries evolution.

## Authority boundaries

- **EITRI / EITRIMB:** software-development governor.
- **CONDUCTOR:** orchestration under its own canon.
- **FORGE:** deterministic implementation/build/test/package execution.
- **PENELOPE:** App authority for identity, lineage, provenance and recovery relationships.
- **BIFROST:** connectivity, device/provider/capability resolution and persistent connective state.
- Specialist Apps retain their own domain authority and databases.

## Evidence rules

`GENERATED ≠ IMPLEMENTED ≠ BUILT ≠ TESTED ≠ VERIFIED ≠ RELEASED`  
`UNKNOWN ≠ PASS`

Preserve LKG. Do not promote a route, UI, mock, registry entry or package merely because it exists.
