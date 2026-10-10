# BACKUPFULL — BIFROST + RavenNest (2026-10-10)

**Purpose:** GitHub source-recovery counterpart of the one existing owner-only Mac directory snapshot. This branch is backup/evidence only, not a production release or promotion.

## Canonical Mac workspaces
- BIFROST: `~/edenOS/Software Development/BIFROST/`
- RavenNest: `~/edenOS/Software Development/Online Plugins & Connectors/RavenNest/`
- Verified local snapshot: `~/edenOS/Backups/BIFROST/BACKUFULL_20261010/` (historical folder spelling; see local MANIFEST.json and SHA256SUMS.txt)

## Git contents and verification
- `BIFROST/`: **71** current native/Headless source files including Xcode project, core, tests, scripts, design reference, web assets. Two transient `.log` files, symlinks to unrelated edenOS locations, build caches and local private state are omitted.
- `RavenNest/`: **67** canonical provider files, Cloudflare Worker, Pages source, D1 migrations, docs, tests and manual-only launch-agent template.
- Every Git blob SHA was compared to its corresponding canonical Mac file. **71/71 BIFROST and 67/67 RavenNest source file blobs matched** at snapshot time.
- Do not move RavenNest source back into BIFROST or Temporary. Its legacy Python namespace `bifrost/` belongs inside RavenNest only.

## Private state boundaries
The Mac directory backup (not this Git repository) stores a protected Cloudflare D1 SQL export and installed launch agent, subject to separate restore authorization. No Keychain passwords, operator/node tokens, local application state, user conversations, macOS caches, cloud secrets or remote user datasets belong in this Git tree. Do not restore the D1 database over live Cloudflare state without comparing current data and approval.

## Operating state / LKG boundaries
- RavenNest Mac launch-agent default: **DISABLED**, `RunAtLoad=false`, `KeepAlive=false`. The native UI provides explicit manual start/stop. A running Cloudflare Worker is a different service and remains independent.
- Cloudflare Pages ZERO is live; the cloud controller's scheduled queue has been observed. External AI provider execution and physical iPhone enrollment remain unverified.
- Native app builds/tests are evidence of a candidate, not an accepted end-user release. Existing LKG and release channels must not be overwritten by restoring this branch.
- No project ZIP or extra local backup directory was created for this Git counterpart.

## Restore order
1. Verify existing Mac snapshot's `MANIFEST.json` and `SHA256SUMS.txt`; preserve newer canonical source.
2. If canonical source is lost, restore `BIFROST/` and `RavenNest/` to their separate target locations above, not to the Git repository root.
3. Run native Python/JS tests and Xcode build, then RavenNest Python/Worker/Pages tests.
4. Verify the Mac Raven launch agent is disabled before any UI/physical tests.
5. Reconcile Cloudflare deployment and D1 data separately. Do not use historical snapshot as authority over current live cloud state.
