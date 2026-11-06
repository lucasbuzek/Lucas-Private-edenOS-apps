# THEMIS

THEMIS is the EDEN legal-domain application and master legal helper. This working copy combines recovered canonical v1.0 helper prompts with the private experimental v0.1.0 Python record-store implementation.

## Current software surface

- CLI help: PYTHONPATH=src python3.12 -m themis.cli --help
- Self-test: python3.12 tests/test_themis.py (requires Python 3.10+ per the package release record)
- Default local database: data/themis.json
- Snapshots: data/snapshots/ when using the default database path
- Historical v1.0 helper-definition text: in-chat/THEMIS_v1.0.txt (**rejected by the owner as the full working master**; original accepted master not yet recovered)
- Subordinate prompts: #common files/prompts/
- User documentation: THEMIS_PRODUCT_DESCRIPTION and THEMIS_PRODUCT_GUIDE in DOCX and HTML.

## Record kinds

matter, party, agreement, clause, obligation, jurisdiction, evidence, correspondence, research, deadline, version, approval.

## Lifecycle and limitations

Private / experimental v0.1.0; not released. The CLI supports add, list, snapshot and rollback-lkg. It has no GUI, no built-in current-law database, no live provider adapters, and no CLI update/delete command. See the Product Guide for actual commands and safe handling.

## Recovered prompt canon

A v1.0 helper-definition file and seven subordinate v1.0 prompt files are preserved as historical source without alteration. The short v1.0 file is **NOT** the verified original complete operational master. The 2026-10-31 `@themis` ChatGPT session produced an actual editable 19-page safety-document package. That working in-chat behavior is prior acceptance evidence; the historical invocation identity and original full master remain unrecovered. The separately created 2026-11-04 private plugin (v0.1.1 as of 2026-11-06) is a candidate **access variant** and must not be portrayed as the restored original or a new product. Preserve all source, backups and LKG; verify host behavior before promoting this variant. Prompt contracts define intended helper roles; they are not proof that the same features exist as executable code.
