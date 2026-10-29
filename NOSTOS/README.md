# NOSTOS — Home & Household (protected engineering candidate)

**Status:** isolated, non-production candidate under GitHub draft PR #25.
This branch preserves the original Dropbox experimental service and tests in Git history.
The Mac source/LKG has not been reconciled and is not modified by this branch.

## Identity, domain and bounds

NOSTOS owns household members, spaces, possessions/garage/vehicles, pantry and supplies,
chores, maintenance, and domestic records. HOMEBASE composes the wider property
and facilities experience; HESTIA/HESPERA own growing. NOSTOS must remain usable
independently and never write other modules' authoritative databases.

ELYSIUM Personal is the optional user-facing private online entry point,
not NOSTOS data ownership or a shortcut to bypass per-actor/site authorization.
No business/spouse/other household rights are inferred. BIFROST is a possible
established private transport, not a mandatory dependency. No physical controls
are part of the candidate.

## Run protected loopback webapp

Python 3.10+; built-in Python libraries only. From this NOSTOS directory:

```sh
export NOSTOS_OWNER_TOKEN="$(python3 -c 'import secrets; print(secrets.token_urlsafe(48))')"
python3 nostos.py
```

Visit http://127.0.0.1:8787/ and enter the same token into the **Owner access**
screen. Token is held only in page memory, not localStorage, cookies or the
repository. Save a durable, private copy of the owner token if you expect to
restart the service without creating a new one. The default database is
`~/Library/Application Support/NOSTOS/nostos.sqlite3`. The optional
`NOSTOS_DATA_DIR` environment setting relocates the data directory.

Server refuses non-loopback `NOSTOS_HOST`; all /api/ endpoints need a bearer
token. Cross-origin and untrusted Host headers are rejected; no CORS grant.
**This is a single-owner development gate, not multi-actor authentication.**
Do not publish it directly to the Internet, a tunnel, reverse proxy, or LAN.

## Supported web operations

- Seven categories; search, create, edit, status and delete.
- Summary counts and due/attention indicators.
- SQLite database download through authenticated API.
- Restore is **disabled by default**. To enable the owner-controlled local
  operation, set `NOSTOS_ENABLE_RESTORE=1` *before starting the service*.
  Use Advanced -> Restore, select a backup, type the exact confirmation phrase
  and confirm. The service validates source integrity and schema, rebuilds
  the data, takes a pre-replacement snapshot under `NOSTOS_DATA_DIR/recovery/`
  and replaces the DB. This does not establish crash/rollback or hostile-file
  acceptance on every host; preserve independent backups before testing.
- Dates must be real ISO YYYY-MM-DD; quantities must be finite, non-negative.

## Optional read-only local MCP

Requires optional official MCP Python SDK v2 on the owner-controlled host.
Do not install on untrusted or shared machines.

```sh
python3 -m pip install 'mcp>=2,<3'
export NOSTOS_OWNER_TOKEN='<same private token as service>'
python3 mcp_readonly.py
```

The host launches this as a stdio subprocess, not a public HTTP MCP server.
Tools: `household_summary`, `search_household`. The adapter calls the
same authenticated local service; does not query SQLite directly or expose
write/delete, backup or restore tools. Giving an MCP host this token gives it
access to the owner's household records; configure only trusted local clients.
No AI provider, web portal, or remote MCP identity has been paired.

## Verify

```sh
python3 -m py_compile nostos.py mcp_readonly.py tests/test_service.py
python3 -m unittest discover -s tests -v
node --check web/app.js
```

GitHub Actions in the private draft PR runs Python/API checks on Ubuntu.
CI is isolated, does not verify the Mac/iPhone, browser interaction, offline
client behavior, service installation, user identity federation or the live
ELYSIUM remote route.

## External reuse research (not imported)

- Grocy — MIT licensed self-hosted household/pantry/chores API; possible
  optional interoperable inventory/shopping interface, not NOSTOS replacement.
- HomeBox — AGPL-3.0 self-hosted home inventory and maintenance; possible
  inventory reference, no source incorporated.
- Official MCP SDK v2 — optional local stdio tool protocol adapter.
Do not import code, stores, APIs, or licenses without fit/security gates.

## Source/provenance

Recovered on 2026-10-29 from connected Dropbox:
`/EDEN-lucas-family/EDEN app/NOSTOS/nostos.py` and
`tests/test_service.py` (experimental recovery, 2026-10-11). The original
service was committed unmodified first, then security implementation on the
same isolated Git branch. Original Dropbox `web/index.html` was reviewed by
extracted text; the new web assets are newly authored for this candidate,
not a claim of byte-exact restoration.

**Do not merge:** actual Mac source/LKG, manual mobile and desktop UX,
independent backup/restore reliability, accessibility, user/site ACLs, remote
access, browser E2E, and optional MCP client lifecycle remain acceptance gates.
