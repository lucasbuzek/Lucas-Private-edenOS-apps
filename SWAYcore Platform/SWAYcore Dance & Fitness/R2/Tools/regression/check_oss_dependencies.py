#!/usr/bin/env python3
"""Fail when AssetFactory code uses an unrecorded or non-OSI dependency."""
import ast
import json
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "AssetFactory/PROVENANCE/oss_dependencies.json"
OSI_LICENSES = {"Apache-2.0", "BSD-2-Clause", "BSD-3-Clause", "GPL-2.0-only",
                "GPL-3.0-or-later", "HPND", "ISC", "LGPL-3.0-or-later", "MIT", "MPL-2.0"}

data = json.loads(MANIFEST.read_text())
entries = data.get("dependencies", [])
errors = []
recorded = {}
for entry in entries:
    missing = [key for key in ("name", "kind", "licence_id", "licence_url", "upstream", "modules") if not entry.get(key)]
    if missing:
        errors.append(f"{entry.get('name', '<unnamed>')}: missing {', '.join(missing)}")
    if entry.get("licence_id") not in OSI_LICENSES:
        errors.append(f"{entry.get('name', '<unnamed>')}: licence is not OSI allow-listed: {entry.get('licence_id')!r}")
    for module in entry.get("modules", []):
        if module in recorded:
            errors.append(f"module {module!r} is recorded more than once")
        recorded[module] = entry.get("name")

local_modules = {p.stem for p in (ROOT / "AssetFactory").rglob("*.py")}
stdlib = getattr(sys, "stdlib_module_names", set())
used_external = set()
for path in sorted((ROOT / "AssetFactory").rglob("*.py")):
    tree = ast.parse(path.read_text(), filename=str(path))
    for node in ast.walk(tree):
        names = []
        if isinstance(node, ast.Import):
            names = [alias.name.split(".")[0] for alias in node.names]
        elif isinstance(node, ast.ImportFrom) and node.module:
            names = [node.module.split(".")[0]]
        for name in names:
            if name not in stdlib and name not in local_modules and name != "__future__":
                used_external.add(name)

unrecorded = sorted(used_external - recorded.keys())
unused = sorted(recorded.keys() - used_external)
if unrecorded:
    errors.append("unrecorded imported dependencies: " + ", ".join(unrecorded))
if unused:
    errors.append("manifest modules not exercised by AssetFactory code: " + ", ".join(unused))
if errors:
    raise SystemExit("OSS dependency/provenance gate FAIL\n- " + "\n- ".join(errors))
print(json.dumps({"status": "OSS_DEPENDENCY_PROVENANCE_PASS", "modules": sorted(used_external),
                  "manifest": str(MANIFEST.relative_to(ROOT))}))
