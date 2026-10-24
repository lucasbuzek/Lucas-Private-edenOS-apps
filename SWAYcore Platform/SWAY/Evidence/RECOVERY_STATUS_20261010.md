# SWAY full-family recovery status — 2026-10-10
Status recorded after full backup and copy of recovered family source.

**Canonical physical SWAYcore project:** `/Users/lucas/edenOS/AppDev/Projects/SWAYcore` (verified); compatibility links `/Users/lucas/edenOS/Projects/SWAYcore` and `/Users/lucas/edenOS/Software Development/SWAYcore` currently target that same physical directory. User's requested SWAY family folder is `<canonical>/SWAY`. Its existence does NOT mean a new product was released.

**Backup:** `/Users/lucas/edenOS/AppDev/#App Backups/Projects/SWAYcore/SWAY_FULL_20261010`.
Source: 20,584 files, 10 symlinks, 4,046,454,831 regular-file bytes. Complete APFS clone plus exact SHA-256 file/symlink manifest (PASS).
Worktrees: 37,411 files, 9 symlinks, 3,432,832,272 regular-file bytes, all code/assets same; ONLY `.DS_Store` and `one_avatar_20261009/SWAYcore/R2/.DS_Store` changed during copy (Finder metadata; recorded).
Git: 178 MB verified all-ref recovery bundle; includes current local branches and full history; worktree snapshot protects uncommitted changes.
Portable: `SWAY_FULL_20261010.tar.zst` approx. 3.6 GB, zstd integrity PASS; checksum in `SWAY_FULL_20261010_SHA256.txt`. Full clean extraction can be performed after enough disk space is available; off-device mirror UNKNOWN.
Source was never deleted.

**Consolidation:** original Oct 3 family source clone 325 files/27,968,082 bytes, 0 symlinks and exact SHA-256 manifest PASS. All five product sources, packages, scripts, docs and assets are reachable under SWAY. Active R2 remains at `../R2`; copied historical sources are not promoted into production.

**Not yet verified:** five-app physical acceptance, independent family Mac builds, official community backend, locally shared-session flow, and repaired avatar motion. These are explicitly UNKNOWN or pending.
