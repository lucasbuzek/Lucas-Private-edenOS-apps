"""BIFROST local setup-package manager.

Discovers two known, user-supplied ZIP package types. A stage action validates
and extracts data to private Application Support, but NEVER executes any
downloaded Python/shell/Windows installer or touches package-manager state.
Installation, model pulls and provider logins require later explicit,
separately verified user-authorized steps.
"""
from __future__ import annotations

import hashlib
import json
import os
import pathlib
import platform
import shutil
import stat
import tempfile
import zipfile

SUPPORT = pathlib.Path.home() / "Library" / "Application Support" / "BIFROST"
# Headless imports only from its managed private inbox; macOS Downloads may
# require interactive TCC approval unavailable to a background launch agent.
DOWNLOADS = SUPPORT / "Incoming"
STAGED = SUPPORT / "Setup Packages"

PACKAGES = {
    "ai-toolkit": {
        "name": "Universal AI Toolkit",
        "kind": "toolkit",
        "names": ("Universal_AI_Toolkit_Final.zip",
                  "Universal_AI_Toolkit_Final 2(1).zip"),
        "mandatory": {"installer.py", "catalog_metadata.json", "index.html"},
        "guide": "Select tools/models, export ai-toolkit-config.json, review installation plan, authorize individual operations and verify each outcome.",
        "platforms": ["macos", "windows", "linux"],
    },
    "project-workspace": {
        "name": "Universal Project Workspace",
        "kind": "template",
        "names": ("Universal_Project_Workspace_v0.2.zip",
                  "Universal_Project_Workspace_v0.2(3).zip"),
        "mandatory": {"project.json", "update_index.py", "index.html"},
        "guide": "Customize project metadata, create an isolated workspace, index files offline, register project, and verify recovery information.",
        "platforms": ["macos", "windows", "linux"],
    },
}

MAX_ENTRIES = 2000
MAX_TOTAL_BYTES = 256 * 1024 * 1024
MAX_FILE_BYTES = 100 * 1024 * 1024
MAX_RATIO = 500


class SetupError(ValueError):
    pass


def archive_for(package_id: str):
    config = PACKAGES.get(package_id)
    if not config:
        raise SetupError("unknown setup package")
    for filename in config["names"]:
        path = DOWNLOADS / filename
        if not path.is_symlink() and path.is_file() and path.parent.resolve() == DOWNLOADS.resolve():
            return path
    return None


def inspect_package(path, package_id):
    config = PACKAGES.get(package_id)
    if config is None:
        raise SetupError("unknown setup package")
    if not path or not path.is_file():
        raise SetupError("package archive missing")
    if path.stat().st_size > MAX_TOTAL_BYTES:
        raise SetupError("archive too large")

    with zipfile.ZipFile(path) as archive:
        entries = archive.infolist()
        if len(entries) > MAX_ENTRIES:
            raise SetupError("archive has too many entries")
        names = []
        sizes = 0
        for entry in entries:
            filename = entry.filename.replace("\\", "/")
            pure = pathlib.PurePosixPath(filename)
            if not filename or filename.startswith("/") or any(segment in ("..", ".") for segment in pure.parts) or ":" in pure.parts[0]:
                raise SetupError("unsafe archive path")
            if entry.flag_bits & 0x1:
                raise SetupError("encrypted archive unsupported")
            if stat.S_ISLNK(entry.external_attr >> 16):
                raise SetupError("archive contains a symlink")
            if entry.is_dir():
                continue
            sizes += entry.file_size
            if sizes > MAX_TOTAL_BYTES or entry.file_size > MAX_FILE_BYTES:
                raise SetupError("archive expands beyond safe bounds")
            if entry.file_size > 1_048_576 and entry.file_size > max(1, entry.compress_size) * MAX_RATIO:
                raise SetupError("archive compression ratio unsafe")
            names.append(filename)
        if len(set(names)) != len(names):
            raise SetupError("duplicate archive filenames")

        prefix = ""
        parts = [p.split("/", 1) for p in names]
        if parts and all(len(p) > 1 for p in parts):
            first = parts[0][0]
            if all(p[0] == first for p in parts):
                prefix = first + "/"
        stripped = [name[len(prefix):] for name in names]
        if not config["mandatory"].issubset(stripped):
            raise SetupError("archive does not match expected package structure")
        if len(set(stripped)) != len(stripped):
            raise SetupError("duplicate package paths")
        if archive.testzip() is not None:
            raise SetupError("archive integrity check failed")
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        return {
            "package_id": package_id,
            "archive_name": path.name,
            "sha256": digest,
            "entries": len(stripped),
            "expanded_bytes": sizes,
            "archive_bytes": path.stat().st_size,
            "prefix": prefix,
            "files": stripped,
        }


def stage_package(package_id):
    path = archive_for(package_id)
    manifest = inspect_package(path, package_id)
    SUPPORT.mkdir(parents=True, exist_ok=True)
    STAGED.mkdir(mode=0o700, parents=True, exist_ok=True)
    final = STAGED / package_id
    if final.exists():
        existing = final / ".bifrost-stage.json"
        try:
            current = json.loads(existing.read_text(encoding="utf-8"))
            if current.get("sha256") == manifest["sha256"]:
                return {"status": "staged", "already_present": True, "path": str(final),
                        "manifest": {k:v for k,v in current.items() if k != "files"}}
        except (OSError, ValueError):
            pass
        raise SetupError("another version is staged; inspect and back up before replacing")

    scratch = pathlib.Path(tempfile.mkdtemp(prefix=".stage-" + package_id + "-", dir=STAGED))
    try:
        with zipfile.ZipFile(path) as archive:
            for entry in archive.infolist():
                if entry.is_dir():
                    continue
                relative = entry.filename.replace("\\", "/")[len(manifest["prefix"]):]
                target = scratch.joinpath(*pathlib.PurePosixPath(relative).parts)
                target.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
                # Extraction uses file-only copying; no installer execution and
                # no preserved executable permissions from untrusted archive.
                with archive.open(entry, "r") as src, target.open("xb") as dest:
                    shutil.copyfileobj(src, dest, length=1024 * 1024)
                target.chmod(0o600)
        (scratch / ".bifrost-stage.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
        (scratch / ".bifrost-stage.json").chmod(0o600)
        os.replace(scratch, final)
    except BaseException:
        shutil.rmtree(scratch, ignore_errors=True)
        raise
    return {"status": "staged", "already_present": False, "path": str(final),
            "manifest": {k:v for k,v in manifest.items() if k != "files"}}


def installed_tools():
    # Inventory only local runtimes and native development prerequisites.
    # Online accounts, cloud provider CLIs and tunnels belong to separately
    # installed plugins. This read-only inventory never runs these tools.
    targets = ("python3", "git", "brew", "node", "docker", "xcodebuild")
    return {name: bool(shutil.which(name)) for name in targets}


def catalog():
    records = []
    for package_id, spec in PACKAGES.items():
        path = archive_for(package_id)
        staged = (STAGED / package_id / ".bifrost-stage.json").is_file()
        record = {
            "id": package_id, "name": spec["name"], "kind": spec["kind"],
            "platforms": spec["platforms"], "guide": spec["guide"],
            "available": bool(path), "archive_name": path.name if path else None,
            "staged": staged,
            "status": ("staged" if path else "review-required") if staged else
                      ("available" if path else "missing"),
            "installation": "not-verified",
            "error": "Staged package exists, but its source ZIP is missing" if staged and not path else None,
        }
        if path:
            try:
                info = inspect_package(path, package_id)
                if staged:
                    saved = json.loads((STAGED / package_id / ".bifrost-stage.json").read_text(encoding="utf-8"))
                    if saved.get("sha256") != info["sha256"]:
                        record["status"] = "review-required"
                        record["error"] = "Imported archive differs from staged version; preserve existing stage"
                record["files"] = info["entries"]
                record["archive_bytes"] = info["archive_bytes"]
                record["sha256"] = info["sha256"]
            except (OSError, ValueError, zipfile.BadZipFile, SetupError) as exc:
                record["status"] = "invalid"
                record["error"] = str(exc)
        records.append(record)
    return {
        "schema": 1, "packages": records, "executionsEnabled": False,
        "environment": {"os": platform.system(), "architecture": platform.machine(),
                        "tools": installed_tools()},
        "security": "Import/stage only. Never automatically execute installer scripts.",
    }
