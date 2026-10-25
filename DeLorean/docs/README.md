# TimeMachine — DeLorean | candidate evidence-driven component

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
python3 core/timemachine.py --catalog /safe/catalog list
python3 core/timemachine.py --catalog /safe/catalog verify <snapshot-id>
python3 core/timemachine.py --catalog /safe/catalog compare <older-id> <newer-id>
python3 core/timemachine.py --catalog /safe/catalog plan-restore <snapshot-id> --target /safe/new/restore
python3 core/timemachine.py --catalog /safe/catalog stage-restore <snapshot-id> --target /safe/new/restore
python3 core/timemachine.py --catalog /safe/catalog export --output /safe/DeLoreanCatalog.json
```

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
- No direct GitHub/Google Drive/Dropbox adapter or credentials bundled. Connect existing authorized MCP/provider capability later.
- No destructive in-place restore. Deliberate protective policy.
- No automated scheduler, broad filesystem scan, backup payload store, cleanup, or provider token persistence.
