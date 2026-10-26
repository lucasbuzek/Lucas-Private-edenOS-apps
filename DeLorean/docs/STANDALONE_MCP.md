# TimeMachine — DeLorean standalone MCP (0.2.0 candidate)

## Product identity and scope

**One existing product:** EDEN / edenOS TimeMachine—DeLorean. This is an additive native/headless MCP representation of the same app, not an independent app, alternate repository, new backup authority, replacement for PENELOPE, or BIFROST prerequisite.

DeLorean is a unified project/application/device-data history and recovery interface over established, separately authorized backup engines and locations. Local-only operation works without Internet, PENELOPE, BIFROST, or a cloud account. PENELOPE adds optional relationship/reference discovery. Cloud storage is optional through an independently configured encrypted restic repository (local, S3-compatible, supported provider or rclone as supported by that installed engine).

## Executable status (evidence-gated)

- The stdio Model Context Protocol server is implemented in `core/mcp_server.py` and the guarded offline copy/restore facade in `core/standalone_backup.py`. Python 3.10+ standard library only for stdio. No background daemon, auto-login, token exchange or network listener.
- Existing `core/timemachine.py` remains the original recovered DeLorean candidate: hash manifest, index, compare, timeline, plan/isolated restore. Original code was **not replaced**; the new facade composes it.
- **Working and fixture-tested:** local file/directory/project/app/device-data *file tree* copying to an explicit local backup destination, per-file SHA-256 validation, unchanged snapshot reuse to avoid duplicate clutter, same-owner timeline and compare, full/selected isolated restore to new folder, cross-owner protection, symlink/traversal refusals, no-clobber, JSON-RPC MCP request/list/call/notification handling and persistence. A test fixture is not a production device acceptance.
- **Optional but not exercised on Mac here:** native Apple Time Machine invocation and listing; restic encrypted backup, repository check and owner-tagged snapshot listing/restore; PENELOPE JSON reference import is exercised with fixture.
- **Not implemented:** bootable device imaging; macOS OS installation/media recovery; live app-consistent database capture (must use app/native snapshot API); remote HTTP server/cloud-hosted MCP with verified OAuth/TLS; management of third-party cloud credentials; native Mac GUI installation; macOS/iOS compilation and full-device restore proof. These remain separate product acceptance gates, not PASS.
- **Security warning:** built-in local file-tree copies are **NOT ENCRYPTED** by DeLorean. Choose an encrypted destination or the optional restic/Time Machine adapter for sensitive app and device data. No cloud transfer takes place unless independently configured and explicitly invoked.

## Source and destination boundaries

At launch, the user chooses source and restore roots explicitly. The MCP is confined to these roots for file copies, and creates its separate backup/cat directory at `--home`. Root symlinks and linked files, destructive in-place restore, automatic deletion, cross-owner access and collision overwrite are refused.

Never choose an allowed source root that contains `--home`, or vice versa. The source and DeLorean backup repository must be on independently recoverable storage for real disaster recovery. Do not backup a whole device with the portable file-copy adapter and call that a bootable image.

**Example for an *already recovered* installation** (replace paths with verified existing physical directories; example paths are not claims about your Mac):

```bash
python3 /ACTUAL/DeLorean/core/mcp_server.py \
  --home '/EXISTING/DeLorean-state' \
  --allow-source '/EXISTING/Projects' \
  --allow-restore '/EXISTING/Recovery-Staging' \
  --owner LucasPRIVATE
```

The server waits for JSON-RPC messages on stdin and writes only JSON-RPC responses to stdout. No hidden background service is installed or enabled by default.

### MCP client configuration (example)

```json
{
  "mcpServers": {
    "delorean": {
      "command": "python3",
      "args": [
        "/ACTUAL/DeLorean/core/mcp_server.py",
        "--home", "/EXISTING/DeLorean-state",
        "--allow-source", "/EXISTING/Projects",
        "--allow-restore", "/EXISTING/Recovery-Staging",
        "--owner", "LucasPRIVATE"
      ]
    }
  }
}
```

## Tool surface (19 tools)

Read-only: `delorean_status`, `delorean_capabilities`, `delorean_backup_plan`, `delorean_snapshots`, `delorean_timeline`, `delorean_compare`, `delorean_verify`, `delorean_plan_restore`, `delorean_restic_status`, `delorean_restic_snapshots`, `delorean_restic_check`, `delorean_time_machine_status`.

Write/operation (each explicitly chosen): `delorean_backup_create` (`BACKUP NOW`), `delorean_stage_restore` (`RESTORE TO NEW DIRECTORY`), `delorean_record_event`, `delorean_penelope_import`, `delorean_restic_backup` (`CLOUD BACKUP`), `delorean_restic_restore` (`RESTORE CLOUD SNAPSHOT TO NEW DIRECTORY`), `delorean_time_machine_start` (`START EXISTING TIME MACHINE BACKUP`).

No tool deletes original user material, prunes a backup, installs native applications, rewrites Git history, or restores a live OS volume. JANITOR cleanup is a separately authorized downstream workflow after actual recovery test acceptance.

## PENELOPE optional support

The independent PENELOPE specialist can export a compact, permission-scoped references-only JSON. DeLorean imports **references**, not file payloads and not PENELOPE internal secrets:

```json
{
  "schema": "eden.penelope.references.v1",
  "owner": "LucasPRIVATE",
  "items": [{
    "project": "SampleApp", "reference": "penelope:relationship:opaque-id",
    "time": "2026-10-26T08:00:00Z"
  }]
}
```

Only files already under `--allow-source` can be imported. Other Council owners are rejected. The running PENELOPE app is **not** required for backup/restore.

## Optional encrypted external repository: restic

Configure the *restic executable* with its existing repository and password-file settings **on the executing host**. These are NOT entered into ChatGPT or saved into DeLorean manifest:

```bash
export RESTIC_REPOSITORY='YOUR_ALREADY_CONFIGURED_REPOSITORY'
export RESTIC_PASSWORD_FILE='/PATH/TO/LOCAL/PROTECTED/restic-password'
```

The MCP checks for restic, requires explicit `CLOUD BACKUP` confirmation before delegation, tags snapshots with exact project + owner, and permits restore only for an exact snapshot ID tagged for that identity and into a new authorized directory. Do not assume any backup engine has been installed or its credentials provisioned. Requiring restic repository integrity check and an actual isolated restore is a separate gate. To use a different backend such as Kopia, add a tested adapter to this same DeLorean project; do not add competing snapshot engines automatically.

## Full device vs. app/project/file coverage

| Scope | Supported route | Current state |
|---|---|---|
| Individual file/folder | Portable file-tree adapter | Test-fixture tested; no in-place restore |
| App/package and project | Portable file-tree adapter plus project-specific consistent exports and PENELOPE optional reference links | File tree tested; app-consistency & executable rebuild remain unverified |
| Mac device user data | Existing Apple Time Machine or existing restic-protected paths | Adapter generated, Mac verification unavailable |
| Entire recoverable Mac environment | Time Machine + macOS Recovery/installation + credential/key recovery | Native full recovery has NOT been performed |
| Windows device | Existing VSS/system imaging or separately tested native adapter | Research only, unimplemented |
| Linux device | Existing filesystem snapshot + restic/Kopia or disk imaging | Research only, unimplemented |
| iPhone/iPad | Encrypted computer/Finder backup, Apple device recovery, platform protections | Requires actual paired device and authorized platform adapter; not implemented |
| Provider clouds | Authenticated provider revision references, or restic encrypted repository where provider backend is configured | Reference events locally tested; full cloud adapter unverified |

## Tests and recovery evidence

Run from the repository root:

```bash
python3 -m unittest discover -s DeLorean/tests -v
```

The test suite uses transient directories and deliberately corrupt/mis-scoped fixtures. It never touches user AppDev sources, outside grants, Mac backups, GitHub main, or third-party accounts. An actual restore rehearsal requires user-owned source/backup and separate physical acceptance.

## Implementation owner and release rules

The GitHub candidate remains in existing `lucasbuzek/Lucas-Private-edenOS-apps` draft PR #14; keep `main` and original Mac LKG unchanged. On access to original DeLorean Mac source, use RECOVER → DISCOVER → RECOGNIZE → REUSE → RECONCILE → INTEGRATE → BUILD ONLY THE GAP → VERIFY. Existing PENELOPE, GitHub, BIFROST, HEIMDALL, JANITOR and RAVENsNEST roles are not displaced.
