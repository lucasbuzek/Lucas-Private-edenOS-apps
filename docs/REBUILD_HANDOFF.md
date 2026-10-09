# Rebuild and recovery handoff

1. Run `python3 scripts/verify_canon.py` from repository root.
2. Treat `docs/UNIVERSAL_FILESYSTEM_CANON.md` as the storage/classification ledger for this consolidation, while preserving each project's own product authority.
3. Restore CURATOR's archive from `Backups/EDEN Apps/CURATOR/v1.3.5/RESTORE.sh`; extraction is an explicit operator action and must not overwrite an LKG silently.
4. For an assistant, verify its `repository-evidence-v1/MANIFEST.sha256`, retain that version, then intake raw ChatGPT exports through its matching `Recovery/ChatGPT Inbox/helpers/` request as a new immutable version.
5. For missing projects, stage received material outside authoritative project paths, checksum and inventory it, resolve identity/classification from evidence, then promote only to the path allowed by canon. HESPERA is already classified as an EDEN App; its implementation/state is not recovered.
6. Re-run verification after any intake. Never use `Temporary/` as recovery authority and never create `Projects/Backups`.
