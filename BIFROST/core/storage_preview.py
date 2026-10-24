"""Account-scoped, one-level preview for BIFROST Files & Storage.

No implicit remote calls. A profile only authorizes a selected local root
or a separately saved, exact cloud directory for read-only metadata.
"""
from __future__ import annotations

import importlib.util
import os
import re
from pathlib import Path

# Resolve the established BIFROSTcore module from this exact core directory,
# including the existing native App/Menu resource bundle layout.
_CORE_FILE = Path(__file__).resolve().with_name("storage_capability.py")
_CORE_SPEC = importlib.util.spec_from_file_location("bifrost_storage_preview_core", _CORE_FILE)
if _CORE_SPEC is None or _CORE_SPEC.loader is None:
    raise ImportError("BIFROST storage core unavailable")
core = importlib.util.module_from_spec(_CORE_SPEC)
_CORE_SPEC.loader.exec_module(core)

_SCOPE_PART = re.compile(r"^[^\\/:\x00-\x1f%]+$")


def _segments(path: str, *, allow_empty: bool) -> tuple[str, ...]:
    if not isinstance(path, str) or len(path) > 480:
        raise core.StorageDenied("Invalid selected folder")
    if not path:
        if allow_empty:
            return ()
        raise core.StorageDenied("A selected cloud folder is required")
    parts = tuple(path.split("/"))
    if len(parts) > 12 or any(
        not p or p in (".", "..") or not _SCOPE_PART.fullmatch(p)
        for p in parts
    ):
        raise core.StorageDenied("Folder must be an exact relative directory")
    return parts


def remote_scope(path: str) -> str:
    return "/".join(_segments(path, allow_empty=False))


def preview(name: str, *, folder: str = "", home=None,
            read_remote: bool = False, remote_reader=None) -> dict:
    """Preview exactly one stored profile and at most one directory level."""
    if not isinstance(name, str) or not core.REMOTE_RE.fullmatch(name):
        raise core.StorageDenied("Select a named storage profile")
    profiles = core.profiles(home=home)
    matched = [p for p in profiles if isinstance(p, dict) and p.get("name") == name]
    if len(matched) != 1:
        raise core.StorageDenied("Profile is unavailable or ambiguous")
    entry = matched[0]
    provider, source, remote = (
        entry.get("provider"), entry.get("source"), entry.get("remote"))
    if provider not in {x["id"] for x in core.providers()}:
        raise core.StorageDenied("Unsupported storage profile")
    parts = _segments(folder, allow_empty=True)
    if provider in ("local", "icloud"):
        expected = "native-icloud" if provider == "icloud" else "native-local"
        if source != expected or remote is not None:
            raise core.StorageDenied("Storage account identity changed")
        root = core._safe_local(entry.get("local_root"), home=home,
                                icloud=provider == "icloud")
        selected = root.joinpath(*parts)
        if root not in selected.parents and selected != root:
            raise core.StorageDenied("Selection left the approved root")
        listing = core.list_direct(str(selected), home=home,
                                   icloud=provider == "icloud")
        return {
            "schema": core.SCHEMA, "profile": name, "provider": provider,
            "account_id": None, "scope": str(root), "folder": str(selected),
            "status": "LOCAL_READ_ONLY", "remote_read_executed": False,
            "count": listing["count"], "entries": listing["entries"]
        }

    if source not in ("system", "managed-dropbox-lite") or not isinstance(remote, str):
        raise core.StorageDenied("Remote configuration source is unavailable")
    known = [a for a in core.accounts(home=home)
             if a["source"] == source and a["name"] == remote
             and a["provider"] == provider]
    if len(known) != 1:
        raise core.StorageDenied("Account or provider identity has changed")
    binding = core.account_config_digest(source, remote, provider, home=home)
    if entry.get("account_binding") != binding:
        raise core.StorageDenied("Stored account approval is stale; review this connection")
    scope = remote_scope(entry.get("remote_root") or "")
    selected = "/".join((scope,) + parts)
    result = {
        "schema": core.SCHEMA, "profile": name, "provider": provider,
        "account_id": source + ":" + remote, "scope": scope,
        "folder": selected, "status": "REMOTE_READ_NOT_REQUESTED",
        "remote_read_executed": False, "count": None, "entries": []
    }
    if not read_remote:
        return result
    if remote_reader is None:
        raise core.StorageDenied("A verified provider metadata adapter is required")
    data = remote_reader(source, remote, selected, provider)
    if not isinstance(data, list) or len(data) > core.MAX_ENTRIES:
        raise core.StorageDenied("Unbounded or invalid remote listing")
    verified = []
    for item in data:
        if not isinstance(item, dict):
            raise core.StorageDenied("Invalid remote metadata")
        label = item.get("name")
        if not isinstance(label, str) or not label or label in (".", "..") or "/" in label or "\x00" in label:
            raise core.StorageDenied("Invalid remote file name")
        kind = item.get("kind")
        size = item.get("bytes")
        if kind not in ("folder", "file") or (size is not None and
            (type(size) is not int or size < 0)):
            raise core.StorageDenied("Invalid remote type or size")
        verified.append({"name": label, "kind": kind,
                         "bytes": size if kind == "file" else None})
    result.update(status="REMOTE_READ_ONLY", remote_read_executed=True,
                  entries=sorted(verified, key=lambda x: x["name"].casefold()),
                  count=len(verified))
    return result


def rclone_metadata_reader(source: str, remote: str, folder: str,
                          provider: str, *, home=None) -> list[dict]:
    """Explicitly requested one-level cloud metadata; never sync or transfer.

    Runs existing Rclone as one bounded child and discards provider diagnostics
    rather than risking secret leakage into Headless, terminal or test logs.
    """
    import json
    import shutil
    import stat
    import subprocess
    import tempfile

    if source not in ("system", "managed-dropbox-lite"):
        raise core.StorageDenied("Unknown Rclone account source")
    if not core.REMOTE_RE.fullmatch(remote):
        raise core.StorageDenied("Invalid Rclone account reference")
    folder = core.safe_remote_scope(folder)
    candidates = dict(core._config_paths(core._home(home)))
    config = candidates[source]
    try:
        state = config.lstat()
        if not stat.S_ISREG(state.st_mode) or state.st_mode & 0o077:
            raise core.StorageDenied("Provider configuration is not private")
    except OSError as exc:
        raise core.StorageDenied("Provider configuration unavailable") from exc
    accounts = [item for item in core.accounts(home=home)
                if item["source"] == source and item["name"] == remote
                and item["provider"] == provider]
    if len(accounts) != 1:
        raise core.StorageDenied("Provider identity changed")
    binary = shutil.which("rclone")
    if not binary:
        raise core.StorageDenied("Rclone metadata provider is unavailable")
    arguments = [
        binary, "lsjson", remote + ":" + folder,
        "--config", str(config), "--max-depth", "1",
        "--disable", "ListR", "--no-modtime", "--no-mimetype",
        "--retries", "1", "--low-level-retries", "1",
        "--contimeout", "5s", "--timeout", "10s"
    ]
    with tempfile.TemporaryFile(mode="w+b") as output:
        try:
            completed = subprocess.run(
                arguments, stdin=subprocess.DEVNULL, stdout=output,
                stderr=subprocess.DEVNULL, check=False, timeout=15
            )
        except (OSError, subprocess.TimeoutExpired) as exc:
            raise core.StorageDenied("Remote metadata read unavailable") from exc
        if completed.returncode != 0 or output.tell() > 512 * 1024:
            raise core.StorageDenied("Remote metadata read unavailable or too large")
        output.seek(0)
        try:
            data = json.load(output)
        except (UnicodeError, ValueError) as exc:
            raise core.StorageDenied("Unrecognized remote listing") from exc
    if not isinstance(data, list) or len(data) > core.MAX_ENTRIES:
        raise core.StorageDenied("Too many remote directory entries")
    parsed = []
    for row in data:
        if not isinstance(row, dict) or type(row.get("IsDir")) is not bool:
            raise core.StorageDenied("Invalid provider metadata entry")
        is_dir = row["IsDir"]
        size = row.get("Size")
        if is_dir:
            size = None
        elif type(size) is not int or size < 0:
            raise core.StorageDenied("Invalid provider file size")
        parsed.append({"name": row.get("Name"),
                       "kind": "folder" if is_dir else "file",
                       "bytes": size})
    return parsed
