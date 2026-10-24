"""BIFROSTcore Files & Storage v0.1 — local-first, opt-in, safe metadata core.

One independent component of BIFROST. No server, scheduler, browser, login or
transfer side effects. No credentials are returned. Python 3.9+ standard library.
"""
from __future__ import annotations
import json
import os
import re
import stat
import tempfile
from pathlib import Path

SCHEMA = "bifrost.storage.v1"
MAX_ENTRIES = 200
MAX_CONFIG = 524288
MAX_PROFILES = 32
REMOTE_RE = re.compile(r"^[A-Za-z0-9_-]{1,80}$")
PROVIDERS = (
    ("local", "Local / external drive", "filesystem", "read-only"),
    ("icloud", "iCloud Drive", "apple-native", "read-only"),
    ("dropbox", "Dropbox", "rclone", "existing-dropbox-lite-adapter-only"),
    ("drive", "Google Drive", "rclone", "browse-only"),
    ("onedrive", "Microsoft OneDrive / SharePoint", "rclone", "browse-only"),
    ("box", "Box", "rclone", "browse-only"),
    ("webdav", "WebDAV / Nextcloud", "rclone", "browse-only"),
    ("s3", "S3-compatible / MinIO", "rclone", "browse-only"),
    ("sftp", "SFTP / SSH server", "rclone", "browse-only"),
    ("smb", "SMB / NAS", "rclone-or-mounted-folder", "browse-only"),
    ("syncthing", "Syncthing peers", "external-optional", "integration-pending"),
)


class StorageDenied(ValueError):
    pass


def providers():
    return [{"id": i, "name": n, "adapter": a, "state": s}
            for i, n, a, s in PROVIDERS]


def status():
    return {"schema": SCHEMA, "owner": "BIFROSTcore",
            "mode": "local-first, user-scoped, read-only",
            "connected_to_bifrost_headless": False,
            "chatgpt_action_bridge_verified": False,
            "auto_sync": False, "hosting_enabled": False,
            "accounts_authorized_by_this_module": False,
            "provider_count": len(PROVIDERS),
            "actions": ["status", "providers", "accounts", "profiles",
                        "local.list", "icloud.list", "profile.preview"],
            "pending": ["provider OAuth setup", "verified sync/write adapters",
                        "hosted gateway", "native admin UI",
                        "authenticated live BIFROST bridge"]}


def _home(home=None):
    return Path(home) if home is not None else Path.home()


def _not_symlink(path: Path):
    """Reject symlinks in existing ancestors and target, including broken ones."""
    absolute = Path(os.path.normpath(str(path.absolute())))
    for part in (absolute,) + tuple(absolute.parents):
        try:
            mode = part.lstat().st_mode
        except FileNotFoundError:
            continue
        if stat.S_ISLNK(mode):
            raise StorageDenied("Symbolic link paths are not allowed")
    return absolute


def _safe_local(path, home=None, *, icloud=False):
    root = _home(home).absolute()
    target = Path(path)
    if not target.is_absolute() or not str(path).strip():
        raise StorageDenied("Select one absolute folder")
    target = _not_symlink(target)
    if icloud:
        icloud_root = _not_symlink(root / "Library/Mobile Documents/com~apple~CloudDocs")
        if target != icloud_root and icloud_root not in target.parents:
            raise StorageDenied("Select an iCloud Drive folder")
    elif target != root and root not in target.parents and Path("/Volumes") not in target.parents:
        raise StorageDenied("Only selected home or /Volumes folders are supported on macOS")
    # No generic management of identities, AppDev, product candidates or secrets.
    protected = [root / "edenOS/Software Development", root / "edenOS/Products",
                 root / "edenOS/Releases", root / "edenOS/Projects",
                 root / ".ssh", root / ".config", root / "Library/Keychains",
                 root / "Library/Application Support"]
    if not icloud:
        protected += [root / "Library/Mobile Documents", root / "Library/CloudStorage"]
    if any(target == p or p in target.parents for p in protected):
        raise StorageDenied("Protected location requires a different scoped owner")
    if not target.is_dir():
        raise StorageDenied("Selected directory is unavailable")
    return target


def list_direct(path, *, home=None, icloud=False):
    """Only top-level metadata. Never open or hydrate any file, or recurse."""
    folder = _safe_local(path, home=home, icloud=icloud)
    entries = []
    with os.scandir(folder) as iterator:
        for entry in iterator:
            if len(entries) == MAX_ENTRIES:
                raise StorageDenied("Entry limit reached; narrow the selected folder")
            metadata = entry.stat(follow_symlinks=False)
            entries.append({"name": entry.name,
                            "kind": "symlink" if stat.S_ISLNK(metadata.st_mode)
                            else "folder" if stat.S_ISDIR(metadata.st_mode) else "file",
                            "bytes": metadata.st_size if stat.S_ISREG(metadata.st_mode) else None})
    return {"schema": SCHEMA, "folder": str(folder),
            "mode": "one-level-metadata-only", "count": len(entries),
            "entries": sorted(entries, key=lambda row: row["name"].casefold())}


def _config_paths(home):
    return [("system", home / ".config/rclone/rclone.conf"),
            ("managed-dropbox-lite", home / "Library/Application Support/Dropbox Lite/rclone.conf")]


def accounts(*, home=None):
    """Only remote section names and type= lines, never token/key/password values."""
    found = []
    for source, path in _config_paths(_home(home)):
        if not path.is_file():
            continue
        _not_symlink(path)
        if path.stat().st_size >= MAX_CONFIG:
            raise StorageDenied("Rclone config exceeds the inspection size limit")
        contents = path.read_text(encoding="utf-8")
        if contents.lstrip().startswith("RCLONE_ENCRYPT_V"):
            raise StorageDenied("Encrypted Rclone config requires native authorized setup")
        section, backend = None, None
        def append_section():
            if section and backend:
                found.append({"id": source + ":" + section, "name": section,
                              "provider": backend, "source": source,
                              "authorized_by_storagecore": False})
        for line in contents.splitlines():
            clean = line.strip()
            if clean.startswith("[") and clean.endswith("]"):
                append_section()
                candidate = clean[1:-1]
                section = candidate if REMOTE_RE.fullmatch(candidate) else None
                backend = None
            elif section and "=" in clean and clean.split("=", 1)[0].strip().lower() == "type":
                candidate = clean.split("=", 1)[1].strip().lower()
                backend = candidate if re.fullmatch(r"[a-z0-9_-]{1,32}", candidate) else None
        append_section()
    return sorted(found, key=lambda item: item["id"])


def account_config_digest(source, remote, provider, *, home=None):
    """Opaque fingerprint of one exact Rclone section, not a token or login.

    Changes to that section revoke prior preview grants until explicitly
    reapproved. An OAuth refresh may also change the fingerprint; fail closed.
    """
    import hashlib
    if source not in ("system", "managed-dropbox-lite") or not REMOTE_RE.fullmatch(remote):
        raise StorageDenied("Invalid account configuration source")
    config = dict(_config_paths(_home(home)))[source]
    _not_symlink(config)
    try:
        state = config.stat()
        if not stat.S_ISREG(state.st_mode) or state.st_mode & 0o077 or state.st_size > MAX_CONFIG:
            raise StorageDenied("Provider configuration is not private")
        raw = config.read_text(encoding="utf-8")
    except (OSError, UnicodeError) as exc:
        raise StorageDenied("Provider configuration is unavailable") from exc
    if raw.lstrip().startswith("RCLONE_ENCRYPT_V"):
        raise StorageDenied("Encrypted configuration needs provider setup")
    selected = []
    in_section = False
    occurrences = 0
    for line in raw.splitlines():
        clean = line.strip()
        if clean.startswith("[") and clean.endswith("]"):
            in_section = clean == "[" + remote + "]"
            if in_section:
                occurrences += 1
        if in_section:
            selected.append(line)
    if occurrences != 1 or len(selected) > 1000:
        raise StorageDenied("Account identity is unavailable")
    if not any(line.strip().lower() == "type = " + provider
               or (line.split("=", 1)[0].strip().lower() == "type"
                   and line.split("=", 1)[-1].strip().lower() == provider)
               for line in selected if "=" in line):
        raise StorageDenied("Provider type has changed")
    material = (source + "\\0" + remote + "\\0" + "\\n".join(selected)).encode("utf-8")
    return hashlib.sha256(material).hexdigest()


def _profile_path(home):
    return home / "Library/Application Support/BIFROST/storage-profiles.v1.json"


def profiles(*, home=None):
    url = _profile_path(_home(home))
    if not url.is_file():
        return []
    _not_symlink(url)
    if url.stat().st_size > 100000:
        raise StorageDenied("Storage profile metadata is too large")
    data = json.loads(url.read_text(encoding="utf-8"))
    if data.get("schema") != SCHEMA or not isinstance(data.get("profiles"), list):
        raise StorageDenied("Unrecognized storage profile schema")
    return data["profiles"]


def safe_remote_scope(folder):
    """Exact non-root cloud folder; never an absolute path, URL or traversal."""
    if not isinstance(folder, str) or not folder or len(folder) > 480:
        raise StorageDenied("Select an exact cloud folder before browsing")
    parts = folder.split("/")
    if len(parts) > 12 or any(
        not part or part in (".", "..") or
        any(c in part for c in (chr(92), ":", "%")) or
        any(ord(c) < 32 for c in part)
        for part in parts
    ):
        raise StorageDenied("Unsafe or ambiguous cloud folder")
    return folder


def configure_profile(name, provider, source, remote, local_root, *,
                      home=None, apply=False, remote_root=None):
    """Preview default; writes only with explicit terminal --apply approval."""
    known = {p["id"] for p in providers()}
    if not REMOTE_RE.fullmatch(name) or provider not in known:
        raise StorageDenied("Invalid profile name or provider")
    if source not in ("system", "managed-dropbox-lite", "native-local", "native-icloud"):
        raise StorageDenied("Unrecognized provider configuration source")
    if provider in ("local", "icloud"):
        expected = "native-icloud" if provider == "icloud" else "native-local"
        if source != expected or remote or remote_root:
            raise StorageDenied("Local provider cannot use remote credentials")
    else:
        if source not in ("system", "managed-dropbox-lite") or not REMOTE_RE.fullmatch(remote):
            raise StorageDenied("Choose an existing Rclone remote")
        current = [a for a in accounts(home=home)
                   if a["source"] == source and a["name"] == remote and a["provider"] == provider]
        if len(current) != 1:
            raise StorageDenied("Selected account is not configured with this provider")
        if remote_root:
            remote_root = safe_remote_scope(remote_root)
            account_binding = account_config_digest(source, remote, provider, home=home)
    folder = _safe_local(local_root, home=home, icloud=(provider == "icloud"))
    profile = {"name": name, "provider": provider, "source": source,
               "remote": remote or None, "local_root": str(folder),
               "sync_mode": "off", "schedule": None, "transfers_authorized": False}
    if remote_root:
        profile["remote_root"] = remote_root
        profile["account_binding"] = account_binding
    existing = profiles(home=home)
    if any(x.get("name") == name for x in existing):
        raise StorageDenied("Profile already exists; nothing was changed")
    if len(existing) >= MAX_PROFILES:
        raise StorageDenied("Profile limit reached")
    if not apply:
        return {"status": "PREVIEW_ONLY", "profile": profile, "changed": False}
    url = _profile_path(_home(home))
    url.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    _not_symlink(url.parent)
    if url.exists():
        _not_symlink(url)
    payload = json.dumps({"schema": SCHEMA, "profiles": existing + [profile]},
                         indent=2, sort_keys=True).encode()
    fd, temp = tempfile.mkstemp(prefix=".storage-profiles.", dir=url.parent)
    try:
        with os.fdopen(fd, "wb") as out:
            os.fchmod(out.fileno(), 0o600)
            out.write(payload)
            out.flush()
            os.fsync(out.fileno())
        os.replace(temp, url)
    finally:
        if os.path.exists(temp):
            os.unlink(temp)
    return {"status": "METADATA_SAVED_NO_TRANSFER", "profile": profile,
            "changed": True}
