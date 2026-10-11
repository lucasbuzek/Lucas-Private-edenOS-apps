# SESHAT — Initial Acceptance Matrix

States: PASS / FAIL / UNKNOWN / SKIPPED / N/A. A planned feature is not PASS.

| Gate | Acceptance criterion | Initial state |
|---|---|---|
| Identity | NOSTOS household-only; ARGOS search-only; one SESHAT product across representations | PASS — design baseline |
| In-chat | Grounded stock workflows; no fabricated live data/actions | UNKNOWN — prompt written, no runtime test |
| Ledger | Receipt, issue, return, transfer, adjustment and stocktake are auditable events | UNKNOWN — not implemented |
| Idempotency | Retry cannot double-post stock | UNKNOWN — not implemented |
| Roles | Server-side owner/manager/staff/read-only permissions | UNKNOWN — not implemented |
| Import | Preview, mapping, validation, dry run, explicit commit and row-level errors | UNKNOWN — not implemented |
| PWA | macOS/Windows/Linux/iOS/Android browser support | UNKNOWN — not implemented |
| Offline | Visible cache/queue/sync/conflict states; no silent overwrite | UNKNOWN — not implemented |
| OAuth | Least privilege, revocable grants, secure tokens | UNKNOWN — design only; live test needs configuration |
| Drive/Sheets/Docs | Safe file selection/import/export and deterministic document generation | UNKNOWN — not implemented |
| Gmail | Draft first; send only after confirmation | UNKNOWN — not implemented |
| Calendar/Contacts | Optional scoped access and provider-ID mapping | UNKNOWN — not implemented |
| Backup/restore | Integrity and successful restore demonstrated | UNKNOWN — not implemented |
| Security | Tenant isolation, secret hygiene, audit and export/deletion | UNKNOWN — not implemented |
| GitHub persistence | Canonical repository/branch and revision established | UNKNOWN — not established |
| Release | Reproducible build and required acceptance evidence | SKIPPED — design stage |