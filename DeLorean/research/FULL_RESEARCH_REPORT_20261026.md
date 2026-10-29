# ARGOS / CONDUCTOR / ForgeMASTER — DeLorean standalone MCP research report
Date: 2026-10-26 (UTC+2)

## Actual research-source audit (no inflated claims)

Dropbox path: `/edenOS apps/AI MCP tool` (Mac mirror `/Users/lucas/Library/CloudStorage/Dropbox/edenOS apps/AI MCP tool`). Using authenticated Dropbox direct-child listing, **390 items exhaustively inventoried** (375 `.webarchive`, 9 `.png`, 5 `.jpg`, 1 `.html`); **79** include terms directly relevant to backup, storage, recovery, devices, files, macOS, Git, cloud or encryption. The complete 390-file metadata inventory is in `Dropbox_AI_MCP_tool_inventory_20261026.json` in the same existing GitHub candidate PR. This is a **metadata audit** of all files, NOT a content review of all 390 files.

Eight relevant archived pages were submitted to the connector's text fetch; extraction failed on all eight because `.webarchive` is not supported by this endpoint. Original Mac copy was not mounted to the current runtime and authorized RDC was offline. Therefore **archived-body reading is incomplete**. No claim that saved pages were fully examined. The relevant named projects were further checked through currently accessible public primary documentation where possible. Existing authentic sources are preferable to scraped catalog descriptions.

### Relevant archived references recovered by filename (webarchive contents unverified)

- `storage-steward by yusongcao2004 | Glama.webarchive` — candidate storage-policy/organizer approach, not verified or installed.
- `identity-storage-mcp by MikSkrzyp | Glama.webarchive` — potential identity-scoped storage adapter, unverified.
- `MCP Server for macOS by avanomme | Glama.webarchive`, `macos-mcp-tools by HachiTogo | Glama.webarchive` and `macos-agent-bridge by juliusloon | Glama.webarchive` — Mac tooling, not backup engines.
- `icloud-mcp by adamzaidi | Glama.webarchive` and other iCloud MCP archives — potential provider adapters; Apple platform/authentication limits apply.
- `Storacha MCP Storage Server by storacha | Glama.webarchive` — optional storage ecosystem; do not delegate backups without durability/privacy/restore tests.
- `cloudflare MCP Servers | Glama.webarchive` — host/provider management only where authorized and production-tested.
- `DeviceLink - Share a folder with ChatGPT or Claude.webarchive` — remote folder access candidate, not standalone backup equivalence.
- `Compare Cloud Storage providers - ComparisonTables.webarchive` — price/feature reference, cannot establish cloud integration without live provider docs.

### Verified live evidence and engineering implications

1. Model Context Protocol stdio uses UTF-8 line-delimited JSON-RPC, `tools/list`, `tools/call` and capability declarations. Implemented a minimal tested stdio MCP representation using no extra Python packages. For production HTTP hosting, prefer the official MCP Python SDK v2 and Streamable HTTP with authenticated TLS rather than hand-rolled public transport. https://modelcontextprotocol.io/specification/2025-06-18/basic/transports and https://py.sdk.modelcontextprotocol.io/.
2. Kopia is an existing encrypted, deduplicated file-snapshot/restore engine, **not a bootable disk imaging tool**. Its `snapshot verify` and restore docs emphasize independent recovery testing. https://kopia.io/docs/ ; https://kopia.io/docs/advanced/consistency/ .
3. restic is an established encrypted repository backup/restore CLI. Its restore defaults can overwrite; DeLorean's adapter restricts the target to a newly created isolated directory and rejects unapproved owner/project snapshot IDs. https://github.com/restic/restic/blob/master/doc/050_restore.rst .
4. Apple Time Machine backs up user data/apps/configuration, not OS installation. macOS platform recovery is a separate step. Its network backups generally use SMB, with AFP removed on macOS 27. https://support.apple.com/guide/mac-help/back-up-files-mh35860/mac ; https://support.apple.com/en-ie/102423 .
5. Windows VSS exists to obtain consistent volumes while applications are writing. A plain live-directory copy cannot claim transactionally coherent database or entire disk recovery. https://learn.microsoft.com/en-us/windows/desktop/vss/volume-shadow-copy-service-overview .
6. The public HachiTogo macOS MCP project has EventKit/JXA/SQLite app connectors and requires user-granted permissions. These mechanisms are **not interchangeable with user backup snapshots**. https://github.com/HachiTogo/macos-mcp-tools .
7. Model Context Protocol tool use is subject to least-privilege, validation and human oversight. DeLorean implements explicit launch-time path grants, owner isolation, exact confirmation phrases and refuses in-place restore. https://github.com/modelcontextprotocol/modelcontextprotocol/blob/main/docs/specification/2025-06-18/server/tools.mdx .

## DeLorean integration recommendations

- Preserve the **one DeLorean identity**; standalone MCP is a product interface, not a new independent project or governor. The historical 0.1.x index kernel remains intact, now composed with an on-demand backup facade and testable MCP protocol wrapper.
- **PENELOPE optional**: pass normalized reference/relationship evidence only via an explicit exported contract; never require PENELOPE for backup, versioning or restore.
- **Cloud optional**: use externally configured restic/Kopia repositories/authorized API adapters; never silently upload entire devices to clouds or put credentials in manifest files.
- **Full-device scope**: native OS/system-image backup remains mandatory. File-tree snapshots are not bootable system images. Device recovery must test real boot/reinstall, user migration, settings, apps, system permissions, databases and credentials with owner authority.
- **Integrity vs actual recovery**: SHA-256 indexes and engine repository checks are not a successful application rebuild or physical device restore. Promote status only after isolated restore, app build, platform recovery rehearsal and owner acceptance.
- **No-clobber**: never restore over current working source; create new destination, compare/prove recovery, then separately approve promotion. No automatic JANITOR cleanup of LKG or unique source.

## Known unresolved gates

1. Original Mac DeLorean Bible/source/latest dirty state/LKG could not be read; no native source promotion.
2. `.webarchive` contents could not be extracted; comprehensive body-level investigation of that folder remains unavailable through this connector (metadata inventory completed).
3. No macOS target build/Time Machine operation, Windows VSS, Linux OS snapshot, iPhone physical backup or actual cloud restic repository was tested; these are UNKNOWN, not PASS.
4. No remote authenticated Streamable HTTP MCP endpoint or ChatGPT cloud tool connection has been deployed. The existing private ChatGPT plugin remains an instruction/companion representation until host connection is configured.
