# DeLorean TimeMachine — source-first external reuse review

Date: 2026-10-29. Scope: existing DeLorean **candidate**; all source changes are additive and remain unmerged. Product mission is standalone device/app/project/file backup, protected recovery, local-first history, optional PENELOPE and optional cloud. There is no automatic promotion to authoritative Mac app/LKG.

## Original user-supplied Dropbox location

The URL `https://www.dropbox.com/scl/fo/21rv7kst0n56iprmdrist/AMhROe7MpqvKtU-D4tGfsxw?rlkey=0rzp2ohk8hamdhdkhanda4dq3&dl=0` was resolved **through the connected Dropbox shared-link metadata tool**, which reported namespace `ns:13844906001`, folder `/EDEN-lucas-family/AI MCP tool`, audience `public`, **access_level `edit`**, download allowed. This is *not* the old `/edenOS apps/AI MCP tool` path previously used in 2026-10-26 research.

- 411 direct root entries at last observation, including six directories and 355 `.webarchive` saved pages, 37 `.url` Internet Shortcut files, 6 PNG, 5 JPEG/JPG, one PDF and one HTML. `has_more=false` for direct-child listing.
- `#appleOS`: 104 `.webarchive` entries, no further pagination.
- `#webMCP`: 37 `.webarchive` and 4 JPG entries, no further pagination.
- `#screenshots`: 26 JPG and one PNG.
- `#AI toolkit`: recursive listing reaches its 600-entry page limit (`has_more=true`) and includes a Chromium profile with cookies, device-bound sessions and other authentication material. **Protected**: its sensitive content was NOT read, copied, exported, or processed. It is not appropriate backup adapter source and must remain excluded from public code/test artifacts.
- Root `.url` files are readable using the connected Dropbox text tool; verified examples include `cloudflare webmcp.url` → `https://blog.cloudflare.com/webmcp/` and `desktop-commander.url` → `https://aicommander.dev/compare/desktop-commander/`.
- Sample selected `.webarchive` text extraction attempts through the Dropbox connector failed; generated temporary binary Dropbox download links cannot be fetched by this isolated build container (network denied). **No source-page-content audit of all archived webpages** is claimed; titles alone are clues, not code review or authority.
- The **public-edit share** is a supply-chain/tamper concern. Preserve source, recommend changing the original share to owner-controlled/least-privilege outside any unattended agent session. DeLorean must not load executable code directly from shared archives.

## External alternatives — source-level research, not merely directory names

| Candidate | Verified published capability and source | License | Fit | Decision |
|---|---|---|---|---|
| **Kopia CLI + KopiaUI** | Encrypted incremental/deduplicated snapshots, local/NAS/S3/B2/Google Drive/rclone repositories, policies, verification, browse/restore; CLI `snapshot create/list/verify/restore` with JSON output and no-overwrite flags. https://kopia.io/docs/features/ ; https://kopia.io/docs/repositories/ ; https://kopia.io/docs/reference/command-line/common/snapshot-create/ ; https://github.com/kopia/kopia | Apache-2.0 | Excellent external reusable data backup backend | Add optional grant-scoped Kopia adapter; **not** bootable OS image; actual engine not installed/tested here. |
| **restic** | Cross-platform end-to-end encrypted CLI; snapshot tags, consistency check and new-target restore. https://restic.readthedocs.io/en/stable/045_working_with_repos.html ; https://github.com/restic/restic | BSD-2-Clause | Existing DeLorean adapter preserved | Keep; production repo operations require real host. |
| **Backrest + backrest-mcp** | Existing restic WebUI/orchestrator and third-party MCP exposing health, snapshots, dashboard, operations, guarded writes. https://github.com/TadMSTR/backrest-mcp ; https://github.com/garethgeorge/backrest | Inspect exact version/implementation license before incorporation | Potential strong candidate instead of custom admin/monitoring UI | Evaluate bounded optional attachment; do not clone or run blindly, no duplicate default scheduler. |
| **restic-defensive-mcp** | Structurally read-only restic MCP design, fixed repository config, no arbitrary shell or restore paths. https://github.com/ThomasCrouzet/restic-defensive-mcp | Inspect before copying | Valuable threat-model reference | Adopt strict read-only defaults/immutable grant boundaries, not its code by fiat. |
| **time-machine-mcp-server** | Apple `tmutil` status, backups, local snapshots; also lists destructive operations. https://github.com/deeplook/time-machine-mcp-server | Inspect before copying | Mac-specific native adapter | Read-only subset and preconfigured start only; never expose delete/format to AI automatically. |
| **UrBackup** | Local/network backup server with macOS, Linux, Windows clients. https://www.urbackup.org/download.html | See upstream release license | Possible managed device fleet | Not a generic bootable macOS/iOS restore. Requires physical fleet scope & operational assessment. |
| **Borg + Vorta** | Encrypted deduplicated archives, macOS/Linux GUI, restore. https://vorta.borgbase.com/ ; https://www.borgbackup.org/ | Borg BSD-3; Vorta GPL | Alternative, especially LAN/NAS | Don't bundle GPL GUI without license review; current Kopia/restic sufficient. |
| **Apple Time Machine** | Native Mac user files/apps/settings backup, APFS local snapshots; external destination recommended. https://support.apple.com/en-ie/guide/mac-help/mh35860/27/mac/27 | Platform-native | Required native Mac integration | No independently bootable macOS image; recovery process and device exercise distinct. |
| **MCP official/Cloudflare SDK** | stdio local vs OAuth/Streamable HTTP remote; explicit per-tool scopes; authenticated hosting. https://developers.cloudflare.com/agents/model-context-protocol/ ; https://modelcontextprotocol.io/specification | SDK implementation-specific | Required for live ChatGPT integration | Do not expose existing local write MCP via unauthenticated Worker or unsigned tunnel; remote connected tool endpoint remains unverified. |
| **WebMCP (Chrome/Cloudflare)** | Browser page agent tools, browser-local user workflows. https://blog.cloudflare.com/webmcp/ | Browser/platform | Useful **complement** for web interface | Not a remote backup engine, storage method or ChatGPT MCP transport; do not conflate. |

## Required boundaries and issues not solved by any selected library

1. **Device vs. data**: Kopia/restic/Time Machine have different supported recovery scopes; true bootable OS/bare-metal, iOS encrypted device restore, Android OEM/Windows/Linux recovery all require native operators, physical tests and separate protected grant paths.
2. **App consistency**: SQLite online backup in candidate covers one SQLite DB including committed WAL; user settings, attachments, Keychain, running other DBs and app-specific dependencies require compatible native application snapshots. Never label a raw `copytree` as a complete live app restore.
3. **Identity/provenance**: owner, project, source, original provider, immutable snapshot/root IDs, backup type and recovery-test status are separate. Metadata alone is not a restore proof.
4. **Security**: default read-only MCP, write tools available only under locally enabled session, path grants, distinct owner identity, no generic shell, explicit target, no overwrite/no auto-cleanup. Remote mode needs real authorization/audience binding, not magic confirmation text.
5. **Authenticity**: original DeLorean Mac project Bible/source, dirty worktree, LKG and approved design remain inaccessible in the five current RDC connections; source must be reconciled before merging candidate or calling it deployed.
6. **Research coverage**: this review inspected current upstream published docs and actual candidate source; it did not download/review every saved .webarchive nor inspect protected Chromium browser profiles. Full corpus-level content research is incomplete due to the connector/container extraction boundary.

## Applied candidate extension v0.2.4

- Added **optional Kopia adapter to the SAME DeLorean server**, using an existing external encrypted repository. The adapter does not initialize repositories, schedule backups, run prune, or recreate encryption/deduplication.
- Registered five bounded MCP tools: status, source-and-owner-scoped snapshots, verified index check, encrypted backup (local write session only), and isolated no-overwrite restore (local write session only).
- Commands constructed as argument arrays, no arbitrary shell, with owner/project tags and Kopia snapshot hooks disabled during backup; exact ID/root validation; restore is staged into a new directory.
- Strictly test in fixture/mock first; no Kopia binary in isolated environment and no physical Mac backup/restore has been verified. Existing v0.2.3 tests remain applicable.

## Critical remaining acceptance gates

Live Mac source/LKG comparison; real Kopia/restic or Time Machine integration using an independently encrypted, configured repository; selected-file & project restore rehearsal; application rebuild; per-provider failed auth and out-of-scope tests; actual owner-approved remote MCP authentication; Apple-native GUI/iPhone build and approved visual readback; independent backup durability and recovery proof; protected JANITOR review only after acceptance.
