# BIFROSTcore — Runtime Reconciliation and Verified-State Contract
Date: 2026-10-20. Status: INTERNAL ENGINEERING CANDIDATE — not installed, migrated, released or physically accepted.
Authority: BIFROST Project decisions section 19, current #common AppDevRules, actual native/Menu/Headless sources and bounded runtime evidence. This is implementation documentation, not a second Project Bible or standalone Core project.

## Identity and ownership

- **BIFROST**: one complete user product / app platform.
- **BIFROSTcore**: intended total operating runtime. In ZERO proof of concept, its first *verified interface* is an observation/control contract built around the existing local BIFROST Headless owner. A shared name does not merge the historical process or database.
- **BIFROST App**: full native user-facing setup, accounts, connections, permissions and workflow management UI, attaching to existing Headless through its verified local API.
- **BIFROST Menu**: optional independent menu-bar control process; never another independent connection or task owner.
- **BIFROST Connector/inchatXP**: thin authenticated provider/ChatGPT representation; not yet proven as live dispatch.
- **ZERO**: the proof of concept that streamlines established authorized workflows; NOT a separately named executable.
- External **RDC5/6**, ZERO Connections, RavenNest, WORKinCODEX and specialist apps are independent implementations/providers. Their lifecycle/data/credential stores are not taken over merely by discovery. BIFROST owns its EDEN-integrated RDC routing intent; transport remains vendor-owned.

## Actual local state — distinct components (observed, not inferred)

1. Existing BIFROST Headless: local loopback port 8798, launchd label `eden.bifrost.headless`, local settings under `~/Library/Application Support/BIFROST/settings.json`, private session token, local-only SQLite task ledger, typed status `/api/status/v1`; currently observed live identity `fb7c5b677c245cd5`. Its task receipts are local observations, not cloud execution.
2. Historical Core: `~/Library/Application Support/EDEN/BIFROST/Core/app.py` v0.11.0, configured launchd label `org.eden.bifrost.core`, separate `bifrost.db` with identities/providers/metadata/jobs/events. No current process/service-health evidence. The script has historical HEIMDALL configuration fallbacks and default port 8090; HEIMDALL has independently referenced that port. DO NOT AUTOSTART, bind port 8090, import the legacy script, modify its config/data, merge the two databases or infer it is a modern BIFROSTcore LKG.
3. Native App `eden.private.bifrost` and independent Menu target `eden.private.bifrost.menu` are separate processes, already consuming the existing Headless client. Current user request does not authorize reinstallation or replacement.

## New versioned observed-state slice (internal candidate)

`headless/core_runtime.py` is a Python 3.9+ standard-library implementation that (a) performs a proxy-free bounded read of the existing Headless /api/health, (b) validates schema/product/runtime-path-derived runtime ID and installed source SHA256 before claiming `identity-verified`, (c) inspects only the exact legacy Core script and launchd plist identities with bounded no-symlink reads, and (d) reports launchd registration distinct from real service health. It reads NO legacy SQLite, provider settings, credential store or unrelated user data, and starts no service.

One schema: `bifrost.core.runtime-state.v1`, with explicit `headless`, `legacyCore`, `stateOwnership`, `operations`, observation time and `mode=read-only-federation`. Separate databases, unverified shared task dispatch and unverified external execution remain explicit `false`/UNKNOWN. Registration never implies health. No remote provider calls occur.

- Terminal: `python3 -B headless/core_runtime.py status --json` is independently available without a GUI, installer or Headless restart.
- Headless candidate: **GET /api/core/v1** uses the SAME module/schema, requires the existing local session header and does not accept writes. The adapter catalog advertises it as local read-only.
- BIFROST native App (Connections) and independent Menu (Advanced/Expert) invoke **the same authenticated API via the existing HeadlessClient** on explicit user action; they show source-verified versus unavailable status, and native feedback is invalidated after Headless identity loss/stop.
- Both native targets already bundle the Headless resource folder, including this module, without altering the canonical Xcode project. The installed Headless is still the old release: its new route is NOT YET LIVE. Display UNKNOWN until actually deployed and inspected.

## Terminal configuration — tightly limited first slice

```
python3 -B headless/core_runtime.py status
python3 -B headless/core_runtime.py status --json
python3 -B headless/core_runtime.py config show --json
python3 -B headless/core_runtime.py config set caffeinateMinutes 30
python3 -B headless/core_runtime.py config set caffeinateMinutes 30 --apply
```

The default `config set` is **PREVIEW ONLY**. An explicit `--apply` invokes the **existing Headless /api/preferences** API after validating installed Headless identity and strict local user-owned private session-token file; it performs readback of the existing shared settings file and refuses if verification fails. Only established values 0/30/60/120 minutes are accepted. It does not activate Caffeinate, change startup state, alter provider credentials, manage RDC or create another configuration store. Real-user `--apply` remains NOT PHYSICALLY EXERCISED in this pass; tests use synthetic isolated stores and mocked authenticated HTTP.

## Verification and deployment gates

- Existing baseline: 134 Python tests PASS; 16 Node PASS.
- Reconciled candidate: 152 Python tests PASS; 16 Node PASS; Python 3.9 focused Core 13/13 PASS.
- Native BIFROST and BIFROSTMenu unsigned Debug candidates: Xcode BUILD SUCCEEDED; new module verified in BOTH app resource folders.
- Auth negative tests: no token -> 403; untrusted Origin -> 403; POST to read-only route -> 404. Fake/wrong source or runtime identity, malformed/unexpected Core plist, symlinked metadata, wrong settings, insecure token and unavailable providers refuse authority/updates.
- Original changed-source files preserved in the existing `BACKUFULL_20261014/evidence/BIFROST_CORE_RECONCILE_PRECHANGE_20261020.zip`, six files, clean extraction content/sha equality verified before modification. Restore only selected changed files if rollback is needed; preserve any later concurrent work.
- Live Headless launchd identity and source hash unchanged; no legacy launch, port 8090 listener, external model calls, provider sessions, cloud tasks, credential replacements, disk migration, app install or release promotion.

**UNKNOWN gates:** installed Headless API deployment by explicit accepted physical procedure; actual SwiftUI/Menu interaction and Accessibility; secure shared write authorization across independent Core/UI/connector adapters; legacy metadata migration compatibility and owner separation; live BIFROSTcore authenticated provider execution; actual in-chat ChatGPT connector; remote Mac-offline task continuity. NEVER promote this read-only federation as completed runtime consolidation.

## Next compatible slice

1. Physically verify App/Menu user-triggered inspection against a qualified candidate Headless in a controlled environment, without terminating or replacing the current installed service.
2. Compare the historical v0.11 SQLite tables/export strategy and modern task ledger in a disposable migrated COPY, with schema/permission/ownership tests. Do NOT write either live database.
3. Implement a stable shared capability/permission/receipt adapter for ONE real authorized executor, preserving the owning app's domain state and provider credential store; verify local & offline/denied/deduplication gates.
4. Only after that, select a controlled opt-in migration/replacement path using verified backup/restoration, exact launchd labels and ports, per-service lifecycle acceptance and physical sign-off.

No new separate master/repository, standalone AI governor, provider credential store or agent is authorized by this contract.
