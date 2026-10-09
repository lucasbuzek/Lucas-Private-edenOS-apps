#!/usr/bin/env python3
"""Verify the corrected EDEN filesystem canon and recovery evidence."""
from pathlib import Path
import hashlib
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []

def require(condition: bool, message: str) -> None:
    if not condition:
        errors.append(message)

eden = {"BIFROST", "CURATOR", "JANITOR", "KUROSAWA", "NOSTOS", "PENELOPE", "SKALD"}
direct = {"edenOS Embedded", "SWAYcore", "ModernGenerals", "Lucas-AI-Journey-TOME"}
assistant = {"EITRI-EITRIMB", "CONDUCTOR", "FORGE-FORGEMASTER", "HEIMDALL", "KUROSAWA-in-chat", "ARGOS", "ARTEMIS", "IRIS", "CASPER", "MIRROR", "READ", "DURER"}

require(not (ROOT / "Projects/Backups").exists(), "forbidden Projects/Backups exists")
require(not (ROOT / "Temporary").exists(), "Temporary unexpectedly contains repository authority")
for name in eden:
    require((ROOT / "Projects/EDEN Apps" / name).is_dir(), f"missing EDEN App: {name}")
for name in direct:
    require((ROOT / "Projects" / name).is_dir(), f"missing direct project: {name}")
for name in eden | {"APELLES", "CRESUS", "HESPERA"}:
    require(not (ROOT / "Projects" / name).exists(), f"EDEN App incorrectly direct under Projects: {name}")
require(not (ROOT / "Projects/EDEN Apps/SWAYcore").exists(), "SWAYcore incorrectly classified as EDEN")
require(not (ROOT / "Projects/EDEN Apps/ModernGenerals").exists(), "ModernGenerals incorrectly classified as EDEN")
require((ROOT / "Backups/EDEN Apps/CURATOR/v1.3.5").is_dir(), "CURATOR durable backup missing")

for name in assistant:
    package = ROOT / "Projects/#app-assistants" / name / "repository-evidence-v1"
    for filename in ("README.md", "EVIDENCE.md", "HISTORY.md", "MANIFEST.sha256"):
        require((package / filename).is_file(), f"{name}: missing {filename}")
    manifest = package / "MANIFEST.sha256"
    if manifest.is_file():
        for line in manifest.read_text().splitlines():
            match = re.fullmatch(r"([0-9a-f]{64})  (.+)", line)
            if not match:
                errors.append(f"{name}: malformed manifest line: {line}")
                continue
            expected, relative = match.groups()
            target = package / relative
            if not target.is_file():
                errors.append(f"{name}: manifest target missing: {relative}")
            elif hashlib.sha256(target.read_bytes()).hexdigest() != expected:
                errors.append(f"{name}: checksum mismatch: {relative}")
    require((ROOT / "Recovery/ChatGPT Inbox/helpers" / f"{name}.md").is_file(), f"{name}: recovery inbox missing")

inboxes = list((ROOT / "Recovery/ChatGPT Inbox").rglob("*.md"))
require(len(inboxes) == 15, f"expected 15 recovery inboxes, found {len(inboxes)}")

if errors:
    print("CANON VERIFY: FAIL")
    for error in errors:
        print(f"- {error}")
    sys.exit(1)
print(f"CANON VERIFY: PASS ({len(eden)} EDEN Apps, {len(direct)} direct projects, {len(assistant)} assistant backups, {len(inboxes)} recovery inboxes)")
