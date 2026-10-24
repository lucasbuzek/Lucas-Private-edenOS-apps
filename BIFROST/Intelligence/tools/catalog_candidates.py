#!/usr/bin/env python3
"""Metadata-only review catalog; no content copy, model training, uploads or source writes."""
import hashlib
import json
import os
from datetime import datetime, timezone
from pathlib import Path

DEV = Path("/Users/lucas/edenOS/Software Development")
ROOT = DEV / "BIFROST/Intelligence"
SOURCES = [
    ("BIFROST", "README.md", "BIFROST", "CANON_REVIEW"),
    ("BIFROST", "Intelligence/README.md", "BIFROST", "CANON_REVIEW"),
    ("BIFROST", "Intelligence/CORPUS_INGESTION_POLICY.md", "BIFROST", "CANON_REVIEW"),
    ("BIFROST", "Intelligence/PREPRODUCTION_DOSSIER_R1.md", "BIFROST", "CANON_REVIEW"),
    ("BIFROST", "docs/decisions/BIFROST_JARVIS_MASTER_AUDIT_AND_EXTENDED_GOAL_20261014.md", "BIFROST", "CANON_REVIEW"),
    ("BIFROST", "docs/decisions/BIFROST_MASTER_SOLUTION_DECISION_20261014.md", "BIFROST", "CANON_REVIEW"),
    ("BIFROST", "docs/verification/BIFROST_REAL_WORKFLOW_ACCEPTANCE_CONTRACT_20261014.md", "BIFROST", "CANON_REVIEW"),
    ("#common", "APPDEV_BIBLE.md", "AppDevRules", "LIVE_REFERENCE_ONLY"),
    ("#common", "AppDevRules/00_CANONICAL_PROCEDURE_FIRST_RULE.md", "AppDevRules", "LIVE_REFERENCE_ONLY"),
    ("HEIMDALL Assistant IOS", "docs/APPLE_COUNCIL_IOS_RECOVERED_20261010.md", "HEIMDALL Assistant iOS", "PERSONALITY_REFERENCE_ONLY"),
    ("HEIMDALL Assistant IOS", "HEIMDALL/CouncilExperience.swift", "HEIMDALL Assistant iOS", "PERSONALITY_REFERENCE_ONLY"),
    ("HEIMDALL Assistant IOS", "docs/AUTHORITATIVE_SPEC.md", "HEIMDALL Assistant iOS", "SPECIALIST_REFERENCE_ONLY"),
    ("LECTOR", "PROJECT_BIBLE.md", "LECTOR", "BOOKS_CONTRACT_ONLY"),
    ("LECTOR", "README.txt", "LECTOR", "BOOKS_CONTRACT_ONLY"),
]
def catalog():
    records = []
    for root_name, relative, owner, role in SOURCES:
        declared_root = DEV / root_name
        path = declared_root / relative
        record = {"owner": owner, "role": role, "path": str(path),
                  "index_approved": False, "train_approved": False,
                  "content_imported": False, "network_transfer": False}
        # Explicit allowlist only: no globbing or traversal into home, personal or caches.
        if ".." in Path(relative).parts or Path(relative).is_absolute():
            raise ValueError("Bad allowlisted path")
        resolved_root = declared_root.resolve(strict=True)
        resolved = path.resolve(strict=False)
        if not resolved.is_relative_to(resolved_root):
            raise ValueError("Path escapes explicitly selected source root")
        if not resolved.is_file():
            record["status"] = "MISSING"
        elif resolved.suffix.lower() not in {".txt", ".md", ".swift"}:
            record["status"] = "UNSUPPORTED"
        else:
            stat = resolved.stat()
            record["bytes"] = stat.st_size
            if stat.st_size > 2_000_000:
                record["status"] = "OVERSIZED_REVIEW"
            else:
                with resolved.open("rb") as fh:
                    record["sha256"] = hashlib.file_digest(fh, "sha256").hexdigest()
                record["status"] = "METADATA_VERIFIED_PENDING_RIGHTS_AND_CONTENT_REVIEW"
        records.append(record)
    return {"schema": "bifrost.intelligence.catalog.v1",
            "generated_utc": datetime.now(timezone.utc).isoformat(),
            "mode": "allowlist_metadata_only", "source_content_copied": False,
            "trained": False, "chatgpt_export_requested": False,
            "records": records}

def main():
    dest = ROOT / "SOURCE_CANDIDATE_CATALOG.json"
    document = catalog()
    raw = (json.dumps(document, indent=2, ensure_ascii=False) + "\n").encode()
    fd = os.open(dest, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, "wb") as stream:
        stream.write(raw)
    readback = json.loads(dest.read_text())
    assert readback["source_content_copied"] is False
    assert all(not x["index_approved"] and not x["train_approved"] for x in readback["records"])
    print(json.dumps({"path": str(dest),
                      "sources": len(readback["records"]),
                      "available": sum(x["status"].startswith("METADATA_VERIFIED") for x in readback["records"]),
                      "missing": sum(x["status"] == "MISSING" for x in readback["records"]),
                      "catalog_sha256": hashlib.sha256(raw).hexdigest(),
                      "content_imported": False}, indent=2))

if __name__ == "__main__":
    main()
