# THEMIS — Recovery and backup status

Canonical ID: THEMIS. Domain: legal application. Profile: Lucas Private / Experimental.

## Recovered canonical prompts
- Historical master helper prompt v1.0 recovered and preserved at THEMIS/in-chat/THEMIS_v1.0.txt.
- All seven subordinate v1.0 contracts recovered under THEMIS/#common files/prompts/: COVENANT, CLAUSE, OBLIGO, JURIS, LEXICON, MANDATE and COMPLY.
- Prompt files were byte-compared against the recovered source archive before synchronization.

## Working implementation
- Private experimental baseline v0.1.0; standard-library Python local/offline domain store, 12 record kinds, CLI, JSON persistence, event history, snapshots and hash-checked LKG rollback.
- BIFROST, HEIMDALL and shared-capability descriptors are contracts only, not proof of live runtime adapters.
- Product Description and Product Guide are included in DOCX and HTML.

## Local validation — 2026-10-15
- Python 3.12.4 syntax compilation: PASS.
- Self-test covering all record kinds and snapshot/LKG/rollback: PASS.
- Isolated CLI add/list/snapshot/rollback test: PASS.
- DOCX packages and styles validated; both opened/exported through Apple Pages to PDF; title and table pages visually inspected.
- HTML syntax validated; Quick Look previews visually inspected. Safari opened the guide; direct DOM inspection was skipped because Safari JavaScript-from-Apple-Events is disabled.

## Still unresolved
- Historical production release/LKG and source lineage before the recovered v0.1.0 baseline.
- Historical UI/live LCAS host integration and provider-specific runtime adapters.
- Separate platform builds and cross-platform verification.
- Original ZIP source archives remain preserved in the local recovery archive; they are not duplicated into the active working tree.

Release state: NOT RELEASED. The experimental v0.1.0 baseline must not be described as a production release.
