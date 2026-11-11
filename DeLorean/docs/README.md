# DeLorean TimeMachine | candidate evidence-driven component

**Stage:** Source candidate only; not a promoted master or verified Apple-device build.

**Authority:** Original DeLorean app/Project Bible/local LKG still to be reconciled. This additive candidate is staged in an existing private edenOS repo **branch** for review; no original source overwritten. It must be integrated into original app, not deployed as a duplicate engine.

## Responsibility boundaries
- **DeLorean:** index and compare project snapshots, export read-only timelines, plan and verify isolated restoration.
- **PENELOPE:** original authority for recognising and relating user files, including duplicates and fragments.
- **Git / GitHub:** code history and source control authority. A Git revision alone is not a complete application backup.
- **Apple Time Machine, PENELOPE, existing backup tools:** own backup payload generation/storage. DeLorean *registers* externally created backup directory states; it does not create competing backups.
- **RAVENsNEST:** independent, permissioned Google Drive coordination/index. The current pilot exports manually; Google authentication/API storage are NOT in this prototype.
- **CONDUCTOR / ForgeMASTER:** coordination and AppDev acceptance. **JANITOR:** only afterward, after exact approval and recovery checks.
- **BIFROSTbridge is a separate app.** Not required for this Python candidate.

## Offline quick start (Python 3.10+, standard library only)

The directory passed to `register` must already be a verified backup copy, NOT the current working directory. This tool produces metadata only and never manufactures a backup. `--catalog` must be outside the backed-up tree.

```bash
python3 core/timemachine.py --catalog /safe/catalog register --project EDEN --owner LucasPRIVATE --provider local-existing-backup --root /already-existing/snapshot
python3 core/timemachine.py --catalog /safe/catalog record-event --project EDEN --owner LucasPRIVATE --provider GitHub --kind COMMIT --ref abcdef --occurred-at 2026-10-25T18:30:00Z
python3 core/timemachine.py --catalog /safe/catalog timeline --project EDEN --owner LucasPRIVATE
python3 core/timemachine.py --catalog /safe/catalog list
python3 core/timemachine.py --catalog /safe/catalog verify <snapshot-id>
python3 core/timemachine.py --catalog /safe/catalog compare <older-id> <newer-id>
python3 core/timemachine.py --catalog /safe/catalog plan-restore <snapshot-id> --target /safe/new/restore
python3 core/timemachine.py --catalog /safe/catalog stage-restore <snapshot-id> --target /safe/new/restore
python3 core/timemachine.py --catalog /safe/catalog stage-restore <snapshot-id> --target /safe/new/selective --include README.md source/app.swift
python3 core/timemachine.py --catalog /safe/catalog export --output /safe/DeLoreanCatalog.json
```

- **Selection** lists exact relative file paths; unknown, duplicate, unsafe or cross-owner paths fail closed.
- **Stage** means a fresh isolated directory, verified by SHA-256 after copy. No command promotes or overwrites live project source.
- If an existing backup file has changed, source verification fails and staging aborts.
- Follow verified Apple/GitHub/provider restoration methods for subsequent promotion (outside this adapter).
- `export` deliberately excludes absolute backup paths and contains only hashes, names, metadata, and owner labels. Do not export private filenames to another tenant.
- `platforms/web/index.html` works offline via macOS Safari and iPhone Safari/Files: open file locally then select an exported catalog. Its restore request is *not approval or executable restore*.
- `platforms/apple/DeLoreanCompanion.swift` is candidate **SwiftUI source**, not a compiled or signed iOS/macOS application. It imports only catalogs using Apple File Importer security-scoped access. Additional Xcode project/testing/integration must be done through verified live Mac source.

## Verification

```bash
python3 -B -m unittest discover -s tests -v
```

Run from the `DeLorean` folder. The tests check safe metadata indexing, two-state comparison, cross-owner refusal, corrupted backup failure, symlinks/path traversal, no-clobber, real isolated restoration and export. A passing test on a temporary fixture is not proof that a user's real project is backed up or can be restored.

## Evidence states
`INDEXED_HASHED_NOT_RESTORE_TESTED` is recorded after snapshot indexing. On actual isolated restoration, the CLI reports `ISOLATED_RESTORE_VERIFIED`. It never labels a snapshot as complete, authoritative LKG, deployed or field-tested without independent proof.

## Known gaps
- Mac original Project Bible and any prior code/LKG not yet reconciled.
- No native macOS binary or signed iOS app; no connected Mac device for Xcode acceptance.
- No direct GitHub/Google Drive/Dropbox authenticated adapter or credentials bundled. Provider-event references can be recorded manually using original source IDs; that is not verification of a provider snapshot. Connect existing authorized MCP/provider capability later.
- No destructive in-place restore. Deliberate protective policy.
- No automated scheduler, broad filesystem scan, backup payload store, cleanup, or provider token persistence.


## 2026-10-29 cross-platform correction
DeLorean is one agentic multi-client plugin and native app family, not ChatGPT/macOS-only. See `PLATFORMS_AND_AGENT_BRIDGES.md` for independently authorized provider connectors, desktop/mobile/web targets and current verification. Native clients and full-device restore remain pending per-platform acceptance; the core Python MCP is a candidate, not the entire product.


## v0.2.6 — Connector-neutral verified metadata handoff

The one DeLorean TimeMachine now has a local MCP evidence handoff for authorized provider connector metadata: `delorean_connector_preview` (read), `delorean_connector_events` (read), `delorean_connector_import` (locally write-gated). **32 total MCP tools (21 default read-only / 11 write-enabled)**; original backup/recovery capabilities unchanged. Host applications may use real connected GitHub/Drive/Dropbox APIs independently when no DeLorean device is online; a remote DeLorean endpoint is optional. New metadata-only records are explicitly NOT verified backups. See `docs/CONNECTOR_BRIDGE.md`, `core/connector_evidence.py`, `tests/test_connector_bridge.py`.

Local Python test suite passed **134/134** on Linux; three actual provider revision records were retrieved by connected tools then imported into an isolated local MCP and read back. No native on-device install, ChatGPT direct DeLorean MCP connection, Windows/macOS/Android/iOS build, complete device-image recovery or physical restoration is claimed.
