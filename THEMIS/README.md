# THEMIS

THEMIS is the EDEN legal-domain application and master legal helper. This working copy combines recovered canonical v1.0 helper prompts with the private experimental v0.1.0 Python record-store implementation.

## Current software surface

- CLI help: PYTHONPATH=src python3.12 -m themis.cli --help
- Self-test: python3.12 tests/test_themis.py (requires Python 3.10+ per the package release record)
- Default local database: data/themis.json
- Snapshots: data/snapshots/ when using the default database path
- Canonical master prompt: in-chat/THEMIS_v1.0.txt
- Subordinate prompts: #common files/prompts/
- User documentation: THEMIS_PRODUCT_DESCRIPTION and THEMIS_PRODUCT_GUIDE in DOCX and HTML.

## Record kinds

matter, party, agreement, clause, obligation, jurisdiction, evidence, correspondence, research, deadline, version, approval.

## Lifecycle and limitations

Private / experimental v0.1.0; not released. The CLI supports add, list, snapshot and rollback-lkg. It has no GUI, no built-in current-law database, no live provider adapters, and no CLI update/delete command. See the Product Guide for actual commands and safe handling.

## Recovered prompt canon

The original THEMIS master prompt and seven subordinate v1.0 prompt files are preserved as recovered, without replacing their behavior with this README. Prompt contracts define intended helper roles; they are not proof that the same features exist as executable code.
