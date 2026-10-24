# BIFROST documentation index

This is the canonical navigation point for BIFROST project documentation. Keep authority, implementation evidence, operations and backups in designated locations; do not leave continuation notes loose in the project root.

## Canonical project
- Project root: ~/edenOS/Software Development/BIFROST/
- Root entry point: README.md
- Current continuation / task handoff: docs/operations/CODEX_CLOUD_HANDOFF.md
- Recovery state: docs/recovery/RECOVERY_STATUS.md
- Implementation inventory: docs/implementation/IMPLEMENTATION_INVENTORY.md
- Runtime delegation contract: docs/architecture/RUNTIME_DELEGATION_CONTRACT.md

- Operational logs: docs/operations/logs/

## Documentation areas
- architecture/ — recovered architecture authority, cross-platform contract, PWA interconnect contract and platform targets.
- decisions/ — master solution decision, extended goal, JARVIS audit, federated connectivity strategy and Mac-liberation plan.
- integrations/ — Apple Shortcuts implementation and RavenNest/cloud integration evidence.
- implementation/ — headless/menu-bar implementation and UI implementation notes.
- migration/ — migration state, final reference and portable-kernel candidate.
- operations/ — active continuation handoff and operational notes.
- recovery/ — recovery artifacts and recovery-specific records.
- verification/ — provider/capability matrix, acceptance contracts, audits and implementation evidence.

## Related projects — ownership remains separate
- RavenNest connector: ~/edenOS/Software Development/Online Plugins & Connectors/RavenNest/
- WORKinCODEX: ~/edenOS/Software Development/Online Plugins & Connectors/WORKinCODEX/
- HEIMDALL Assistant iOS: ~/edenOS/Software Development/HEIMDALL Assistant IOS/

BIFROST owns connectivity/capability resolution and connective state. RavenNest owns its online routing implementation. WORKinCODEX owns its Codex handoff workflow. HEIMDALL owns workspace/voice interaction. Do not copy their source into BIFROST or create duplicate owners.

## Mac-liberation objective
Follow decisions/BIFROST_MAC_LIBERATION_ZERO_LOCAL_ALPHA_BETA_PLAN_20261014.md and verification/BIFROST_PROVIDER_CAPABILITY_MATRIX_20261014.md. Cloudflare is a lightweight routing/control plane; actual project work belongs to a capable, authorized executor. The Mac is not the mandatory router, storage host or general executor.

## Backup and release discipline
- Backups/rollback remain outside the source tree: ~/edenOS/Backups/BIFROST/
- BACKUFULL snapshots are recoverable checkpoints, not active source workspaces.
- Keep build/release outputs under ~/edenOS/Products/ and ~/edenOS/Releases/, not inside docs.
- Never infer PASS, implementation or live connectivity from a document existing. Use explicit evidence and PASS/FAIL/UNKNOWN states.


## Connections
- Project alias map and ownership rules: `integrations/CONNECTIONS_INDEX.md`
- Local navigation links: `~/edenOS/Software Development/BIFROST/Connections/`


## Current audit — 2026-10-14
- Latest local-source, build, PWA smoke and public-gateway evidence: `operations/CURRENT_PROJECT_AUDIT_20261014.md`.
- Current AUTO continuation checkpoint: `operations/AUTO_CONTINUATION_20261014.md`.
- Do not promote/merge a remote branch until exact tree and LKG reconciliation is recorded; the Mac workspace has no local `.git` metadata.

- GitHub branch/source reconciliation (exact blob-SHA comparison): `recovery/BRANCH_RECONCILIATION_20261014.md` and `recovery/GITHUB_BRANCH_MANIFESTS_20261014/`.

- Historical cloud-only ZERO candidate is maintained separately at `~/edenOS/Software Development/Online Plugins & Connectors/RavenNest/workers/zero-cloud-task-gateway/`. It is NOT built or bundled in BIFROST; its worker, tests and original evidence were relocated on 17 October 2026.

- Latest historical ZERO status: `~/edenOS/Software Development/Online Plugins & Connectors/RavenNest/workers/zero-cloud-task-gateway/STATUS_20261014.md` (2026-10-14 evidence snapshot; not a statement about current cloud credentials/deployment). The separate worker's 13 offline tests still pass without node_modules.

- Current macOS Custom Version Zero test candidate and manual acceptance gates: `verification/VERSIONZERO_20261018.md`. Test artifact lives in the flat `~/edenOS/Releases/BIFROST_VersionZero_20261018_macOS_Custom_TEST.app`; no Products promotion.

- BIFROST Menu + independent Headless + full App real-source handoff, paired R2 Custom macOS tests, acceptance and explicit limitations: `verification/BIFROST_MENU_HEADLESS_HANDOFF_20261019.md`.

- Independent BIFROST Menu ↔ Headless ↔ full native App architecture and current R3 physical test candidates: `implementation/BIFROST_MENU_INDEPENDENT_CONTROL_20261019.md`. R3 pair is the latest tested Oct19 engineering candidate; earlier variants remain unpromoted pending ownership reconciliation. Actual menu clicking and launchd behavior from its GUI remain unverified.


## Files & Storage capability — 2026-10-20
- Owner: BIFROST/BIFROSTcore; Lucas macOS primary, independent terminal core first, private ChatGPT plugin, lean native administration; Windows/Linux/server later.
- Current architecture/accepted decisions: `architecture/BIFROST_FILES_STORAGE_CAPABILITY_20261020.md`
- Typed provider/permission catalog: `integrations/files-storage-capability.v1.json`
- Executable terminal: `../tools/bifrost_storage.py`; deterministic core: `../core/storage_capability.py`; tests: `../tests/test_storage_capability.py`
- Current verified evidence and pending gates: `verification/BIFROST_STORAGE_CORE_20261020.md`
- Installed Headless/native BIFROST is NOT replaced or connected to the storage capability yet. The ChatGPT plugin is a separate skills-only representation until real authorized action routing is verified.


## Files & Storage capability — reconciled 2026-10-20

- architecture/BIFROST_FILES_STORAGE_CAPABILITY_20261020.md — user-approved scope and cross-provider architecture; storage stays a BIFROSTcore feature, not a separate platform.
- integrations/files-storage-capability.v1.json — typed provider, ownership, permission and source-only Headless route states.
- verification/BIFROST_FILES_STORAGE_RECONCILIATION_20261020.md — verified CLI/API/native resource tests, failure analysis, physical UNKNOWN gates, exact rollback evidence.
- Implementation: core/storage_capability.py, tools/bifrost_storage.py, headless/storage_adapter.py; two authenticated read-only source routes in the existing headless/server.py. The installed Headless still requires separate acceptance/deployment.
- Private ChatGPT skills plugin: bifrost-files-storage v0.1.1 under the existing plugin service and canonical #in chat/Plugin ChatGPT archive. Its direct live BIFROSTcore bridge is NOT connected or accepted; no provider account reads or file changes are implicit.
