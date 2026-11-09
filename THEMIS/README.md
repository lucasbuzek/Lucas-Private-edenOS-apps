# THEMIS

THEMIS is the EDEN legal-domain application and master legal helper. This working copy preserves the historical v1.0 Helper artifacts and the private experimental v0.1.0 Python store, alongside the separately implemented Cloudflare owner-private web/MCP access variant. The recovered operational in-chat application master is a 9-Nov source reconstruction, not the verbatim September original.

## Current software surface

- CLI help: PYTHONPATH=src python3.12 -m themis.cli --help
- Self-test: python3.12 tests/test_themis.py (requires Python 3.10+ per the package release record)
- Default local database: data/themis.json
- Snapshots: data/snapshots/ when using the default database path
- Recovered, self-contained application operating prompt: in-chat/THEMIS_APPLICATION_MASTER_v1.0.md (**newly consolidated from verified historical sources on 2026-11-09; not a recovered verbatim original**).
- Historical v1.0 Helper-definition text: in-chat/THEMIS_v1.0.txt (**rejected as the complete application master; preserved unchanged for provenance**).
- Subordinate prompts: #common files/prompts/
- User documentation: THEMIS_PRODUCT_DESCRIPTION and THEMIS_PRODUCT_GUIDE in DOCX and HTML.

## Record kinds

matter, party, agreement, clause, obligation, jurisdiction, evidence, correspondence, research, deadline, version, approval.

## Lifecycle and limitations

The historical local Python CLI baseline remains private/experimental v0.1.0 and supports add, list, snapshot and rollback-lkg. That *CLI variant* has no built-in GUI, current-law database, live provider adapters or CLI update/delete. The separate owner-private cloud web/MCP source resides under cloud/; its Worker, UI, SQLite-backed Durable Object and Cloudflare Access/Managed-OAuth configuration are documented in cloud/README.md. Real owner OAuth login, MCP legal record operations and local/cloud parity remain unverified; do not mistake deployed/configured source for accepted production. See the Product Guide for local CLI instructions.

## Recovered prompt canon

A v1.0 short Helper-definition and seven subordinate v1.0 prompt files are preserved as original historical sources without alteration. The short v1.0 file is **NOT** the complete operational master. The new in-chat/THEMIS_APPLICATION_MASTER_v1.0.md is a usable, explicitly SOURCE-RECONSTRUCTED application prompt built from the existing GitHub plugin legal-master skill, original seven mission definitions and the 31-Oct working-document benchmark. It must not be represented as an original September file. The 2026-10-31 `@themis` ChatGPT session produced an actual editable 19-page safety-document package. That working in-chat behavior is prior acceptance evidence; the historical invocation identity and original full master remain unrecovered. The separately created 2026-11-04 private plugin (v0.1.2 source as of 2026-11-08) is a candidate **access variant** and must not be portrayed as the restored original or a new product. Preserve all source, backups and LKG; verify host behavior before promoting this variant. Prompt contracts define intended helper roles; they are not proof that the same features exist as executable code.
