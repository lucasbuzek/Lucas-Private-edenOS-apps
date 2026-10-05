"""Inspect wheel contents and emit evidence with reproducible file checksums."""
import hashlib
import json
import os
import tarfile
import zipfile
from pathlib import Path

dist = Path("dist")
artifacts = []
required = {"bifrost/native_host.py", "bifrost/native_mcp.py", "bifrost/native_control.py",
            "bifrost/native_transport.py", "bifrost/native_provider.py", "bifrost/remote_provider.py"}
for path in sorted(dist.iterdir()):
    if path.suffix == ".whl":
        with zipfile.ZipFile(path) as wheel:
            assert required <= set(wheel.namelist()), "Missing runtime files"
            assert wheel.testzip() is None, "Corrupt wheel"
            assert not any("native-host.sqlite" in n or n.endswith(".key") for n in wheel.namelist())
    elif path.name.endswith(".tar.gz"):
        with tarfile.open(path) as archive:
            assert all(not m.name.startswith("/") and ".." not in Path(m.name).parts for m in archive.getmembers())
    else:
        continue
    artifacts.append({"file":path.name, "sha256":hashlib.sha256(path.read_bytes()).hexdigest(), "bytes":path.stat().st_size})
assert any(a["file"].endswith(".whl") for a in artifacts)
evidence = {"source_revision":os.getenv("GITHUB_SHA","UNKNOWN"), "version":"0.1.0",
            "artifacts":artifacts, "physical_apple":"UNKNOWN", "rdc_parity":"UNKNOWN",
            "promotion":"NOT PROMOTED"}
Path("package-evidence.json").write_text(json.dumps(evidence, indent=2)+"\n")
print(json.dumps(evidence, indent=2))
