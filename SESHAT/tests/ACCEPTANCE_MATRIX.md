# SESHAT — Initial Acceptance Matrix

States: PASS / FAIL / UNKNOWN / SKIPPED / N/A. A planned feature is not PASS.

| Gate | Acceptance criterion | Initial state |
|---|---|---|
| Identity | NOSTOS household-only; ARGOS search-only; one SESHAT product across representations | PASS — design baseline |
| In-chat | Grounded stock workflows; no fabricated live data/actions | UNKNOWN — prompt written, no runtime test |
| Ledger core | Receipt, issue, return, transfer and adjustment events; stock arithmetic and compensating reversal | PASS — 13 Node tests cover core prototype; full stocktake workflow still UNKNOWN |
| Idempotency | Retry cannot double-post stock; changed payload with same key rejected | PASS — prototype tests |
| Snapshot integrity | JSON export/import, SHA-256 tamper detection, schema-version and replay validation | PASS — 4 snapshot tests; snapshot remains an in-memory serialization interface |
| Durable persistence | Ledger survives app restart and backup/restore | UNKNOWN — no durable database or actual file-based restore test |
| Roles | Server-side owner/manager/staff/read-only permissions | UNKNOWN — not implemented |
| Import | Preview, mapping, validation, dry run, explicit commit and row-level errors | UNKNOWN — not implemented |
| PWA | macOS/Windows/Linux/iOS/Android browser support | UNKNOWN — not implemented |
| Offline | Visible cache/queue/sync/conflict states; no silent overwrite | UNKNOWN — not implemented |
| OAuth | Least privilege, revocable grants, secure tokens | UNKNOWN — design only; live test needs configuration |
| Drive/Sheets/Docs | Safe file selection/import/export and deterministic document generation | UNKNOWN — not implemented |
| Gmail | Draft first; send only after confirmation | UNKNOWN — not implemented |
| Calendar/Contacts | Optional scoped access and provider-ID mapping | UNKNOWN — not implemented |
| Backup/restore | Integrity and successful restore from a stored backup demonstrated | UNKNOWN — JSON snapshot round-trip passes, but filesystem backup/restore is not implemented |
| Security | Tenant isolation, secret hygiene, audit and export/deletion | UNKNOWN — not implemented |
| GitHub persistence | Canonical repository/branch and revision established | PASS — 13 project/source/test/evidence files matched local contents on `seshat/bootstrap-20261011`; branch not merged to main |
| Release | Reproducible build and required acceptance evidence | SKIPPED — design stage |