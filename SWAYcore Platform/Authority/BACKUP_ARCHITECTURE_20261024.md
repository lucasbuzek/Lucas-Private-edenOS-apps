# SWAYcore Platform · Independent backup architecture
**Decision:** One current authoritative source per project/variant; one independently verifiable backup set PER actual app/project. The existing SWAYcore platform archive is an umbrella historical/disaster snapshot, NOT the sole backup for independently developed applications. Latest owner clarification: 2026-10-24.

## Boundaries
- **Platform custody:** `#Backups/SWAYcore/SWAYcore_WORKING_BACKUP_20261024.tar.zst`. It is a full-family umbrella recovery snapshot with successful archive integrity and nine representative restorations. It does not supersede per-app backups.
- **Shared Engine:** its own `#Backups/SWAYcore Engine/` versioned set including ZERO TestHost/provider lanes, shared Engine package, historical shared Core/Sharing. Restore shared Engine before a dependent app if its current local counterpart is missing.
- **Applications:** each independently owned app has exactly one CURRENT backup set in `#Backups/<exact app name>/`; Studio Management includes its separate existing `SWAY/Products/StudioManagement/ActiveStudio` physical source.
- **Provider development:** Claude, Gemini, ChatGPT Work are **isolated Engine work contexts**, not three independent project masters or unnecessary full backups; their SHA-indexed source variants are part of Engine backup and mirrored Git evidence. They require separate provider authorization/hand-off.
- **Community:** remains a shared platform/online service contract and local demonstration, not falsely a shipped app or dedicated business user-data backup. Real future production server data requires its own consented backup design when a backend exists.
- **Future focused SWAY/Yoga/Tai Chi:** conceptual/historical identities, not current independently accepted working products. Store their authority with Platform until distinct project source and release exist.

## Current restore-test evidence
The archive for each project passed `zstd -t`, full tar member listing, and real extraction + SHA-256 comparison of the representative files named by its adjacent `BACKUP_STATUS.json`. No overwrites or destructive restore of live project directories.
| Backup set | Archive entries | Compressed bytes | Source samples hash-restored |
|---|---:|---:|---:|
| SWAYcore Engine | 156 | 88,378 | 2 |
| SWAYcore Dance & Fitness | 6597 | 609,003,115 | 2 |
| SWAYcore SWAYZ | 28 | 30,835 | 1 |
| SWAYcore KIDZ | 28 | 30,819 | 1 |
| SWAYcore Studio Management | 49 | 42,151 | 2 |
| SWAYcore HEMA | 26 | 30,864 | 1 |
| SWAYcore Martial Arts | 26 | 30,704 | 1 |
## Operational procedures
1. Read the target project's latest Product/Platform Bible and its `BACKUP_STATUS.json`. Verify archive hash and authoritative paths; preserve existing live source and unrelated apps.
2. Restore the required target to an **empty controlled staging path first**, compare hashes and metadata, and reconcile differences via ForgeMASTER and original user decisions. For cross-app dependencies, restore the shared Engine from its independently verified set instead of copying an unmanaged competing Engine master.
3. Restore only the intended app's source/assets/data. Never overwrite another app or merge Claude/Gemini/ChatGPT Work patches without independent tests.
4. Historical 2026-10-18 umbrella archive is preserved under `~/edenOS/Quarantine/SWAYcore_20261024/` as dated recovery evidence. Source/media requiring licensing, signed provisioning or private business records require separate acceptance and provider rules.
5. Re-test backups after meaningful independent application changes, and maintain an independently verified PRIVATE off-device copy. The GitHub `swaycore-platform-baseline-20261023` branch mirrors source/provenance (~3,529 files), NOT all generated assets or encrypted user data. Do not call it a full binary project archive backup.

**Known limits:** backup integrity ≠ physical iPhone/iPad acceptance; full corpus historical recovery and byte-for-byte restore of every archive member remain unverified. Archive member listing + representative extraction was actually performed. Backup independence is logical; shared Engine remains a versioned dependency, not seven competing master codebases.
