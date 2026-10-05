"""BIFROST Native Host: owner-approved scopes, effects, and truthful evidence.

No listener, no implicit enrollment, no default directory grants or shell. Owner
control methods are deliberately not MCP tools. This is an authorization layer,
not an OS sandbox; an approved command retains the owner's OS privileges.
"""
from __future__ import annotations

import base64
import binascii
import contextlib
import hashlib
import hmac
import json
import os
import secrets
import shutil
import signal
import socket
import sqlite3
import stat
import subprocess
import sys
import threading
import time
import uuid
from dataclasses import dataclass, field
from pathlib import Path


class NativeError(Exception):
    def __init__(self, code, message):
        self.code = code
        super().__init__(message)


class AppleSecrets:
    """Explicit native backend. Never accept a plaintext or third-party fallback."""
    service = "org.eden.bifrost.native-host"
    def __init__(self):
        if sys.platform != "darwin":
            raise NativeError("apple_required", "Production enrollment requires macOS Keychain")
        from keyring.backends.macOS import Keyring
        self.backend = Keyring()
    def get(self, key):
        try:
            return self.backend.get_password(self.service, key)
        except Exception:
            raise NativeError("keychain_unavailable", "Unlock Keychain or confirm BIFROST access in macOS") from None
    def put(self, key, value):
        try:
            self.backend.set_password(self.service, key, value)
        except Exception:
            raise NativeError("keychain_unavailable", "macOS did not authorize Keychain storage") from None
    def delete(self, key):
        if self.get(key) is not None:
            try:
                self.backend.delete_password(self.service, key)
            except Exception:
                raise NativeError("keychain_unavailable", "Device is revoked; remove its BIFROST Keychain item when unlocked") from None


@dataclass(frozen=True)
class Session:
    device_id: str
    nonce: str


@dataclass
class Job:
    p: subprocess.Popen
    device_id: str
    command_id: str
    started: float
    deadline: float
    stdout: bytearray = field(default_factory=bytearray)
    stderr: bytearray = field(default_factory=bytearray)
    truncated: bool = False
    readers: list = field(default_factory=list)
    lock: threading.Lock = field(default_factory=threading.Lock)


class NativeHost:
    chunk_limit = 256 * 1024
    output_limit = 1024 * 1024
    file_limit = 1024 * 1024 * 1024
    def __init__(self, state_dir: Path, secret_store=None):
        self.state_dir = Path(state_dir).expanduser().absolute()
        self.state_dir.mkdir(mode=0o700, parents=True, exist_ok=True)
        info = self.state_dir.lstat()
        if stat.S_ISLNK(info.st_mode) or info.st_uid != os.getuid() or info.st_mode & 0o077:
            raise NativeError("unsafe_state", "Native Host state must be an owner-only directory")
        self.state_dir = self.state_dir.resolve()
        dbpath = self.state_dir / "native-host.sqlite3"
        if dbpath.exists() or dbpath.is_symlink():
            info = dbpath.lstat()
            if not stat.S_ISREG(info.st_mode) or info.st_nlink != 1 or info.st_uid != os.getuid() or info.st_mode & 0o077:
                raise NativeError("unsafe_state", "Unsafe Native Host database")
        else:
            fd = os.open(dbpath, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
            os.close(fd)
        self.db = sqlite3.connect(dbpath, check_same_thread=False, timeout=5)
        self.db.row_factory = sqlite3.Row
        self._lock = threading.RLock()
        self.vault = secret_store if secret_store is not None else AppleSecrets()
        self._sessions = {}
        self._jobs = {}
        self._uploads = {}
        self._closed = threading.Event()
        self.db.executescript("""
            CREATE TABLE IF NOT EXISTS meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
            CREATE TABLE IF NOT EXISTS devices (id TEXT PRIMARY KEY, name TEXT NOT NULL, revoked INTEGER NOT NULL);
            CREATE TABLE IF NOT EXISTS grants (id TEXT PRIMARY KEY, device TEXT NOT NULL,
                root TEXT NOT NULL, dev INTEGER NOT NULL, inode INTEGER NOT NULL,
                permissions TEXT NOT NULL, revoked INTEGER NOT NULL);
            CREATE TABLE IF NOT EXISTS commands (id TEXT PRIMARY KEY, device TEXT NOT NULL,
                grant_id TEXT NOT NULL, cwd TEXT NOT NULL, argv TEXT NOT NULL,
                digest TEXT NOT NULL, environment TEXT NOT NULL, timeout REAL NOT NULL, revoked INTEGER NOT NULL);
            CREATE TABLE IF NOT EXISTS audit (seq INTEGER PRIMARY KEY, at REAL NOT NULL,
                device TEXT, operation TEXT NOT NULL, outcome TEXT NOT NULL);
        """)
        with self.db:
            self.db.execute("INSERT OR IGNORE INTO meta VALUES ('host_id', ?)", (str(uuid.uuid4()),))
            self.db.execute("INSERT OR IGNORE INTO meta VALUES ('schema', '1')")
        schema = self.db.execute("SELECT value FROM meta WHERE key='schema'").fetchone()[0]
        if schema != "1":
            raise NativeError("schema_unknown", "Unknown schema; preserve data and use matching host version")
        self.identity = self.db.execute("SELECT value FROM meta WHERE key='host_id'").fetchone()[0]
        self._watcher = threading.Thread(target=self._watch, daemon=True)
        self._watcher.start()

    @staticmethod
    def _approval(approved):
        if approved is not True:
            raise NativeError("confirmation_required", "Explicit owner confirmation is required")

    def _audit(self, device, operation, outcome="ok"):
        with self._lock, self.db:
            self.db.execute("INSERT INTO audit(at,device,operation,outcome) VALUES (?,?,?,?)",
                            (time.time(), device, operation, outcome))
            self.db.execute("DELETE FROM audit WHERE seq <= (SELECT COALESCE(MAX(seq),0)-1000 FROM audit)")

    def devices(self):
        with self._lock:
            return [dict(row) for row in self.db.execute("SELECT * FROM devices ORDER BY id")]

    def enroll(self, name, *, approved=False):
        self._approval(approved)
        if not isinstance(name, str) or not 1 <= len(name.strip()) <= 128:
            raise NativeError("invalid_name", "Use a device name of 1 to 128 characters")
        device = str(uuid.uuid4())
        token = secrets.token_urlsafe(32)
        # Vault first: DB failure cannot grant authority.
        self.vault.put(device, token)
        try:
            with self._lock, self.db:
                self.db.execute("INSERT INTO devices VALUES (?,?,0)", (device, name.strip()))
        except Exception:
            self.vault.delete(device)
            raise
        self._audit(device, "enroll")
        return {"id": device, "name": name.strip(), "host_id": self.identity}

    def authenticate(self, device_id, token):
        with self._lock:
            row = self.db.execute("SELECT revoked FROM devices WHERE id=?", (device_id,)).fetchone()
            expected = self.vault.get(device_id) if row and not row[0] else None
            if not isinstance(token, str) or not expected or not hmac.compare_digest(expected, token):
                self._audit(device_id if row else None, "authenticate", "denied")
                raise NativeError("unauthorized", "Pair this device in BIFROST or unlock Keychain")
            session = Session(device_id, secrets.token_urlsafe(32))
            self._sessions[session.nonce] = (session.device_id, time.monotonic() + 12 * 3600)
            return session

    def _check(self, session):
        with self._lock:
            entry = self._sessions.get(getattr(session, "nonce", None))
            row = self.db.execute("SELECT revoked FROM devices WHERE id=?", (getattr(session, "device_id", ""),)).fetchone()
            if (not entry or entry[0] != session.device_id or entry[1] < time.monotonic()
                    or not row or row[0] or self._closed.is_set()):
                raise NativeError("unauthorized", "Session is unpaired, expired or revoked")

    def revoke(self, device_id, *, approved=False):
        self._approval(approved)
        with self._lock, self.db:
            self.db.execute("UPDATE devices SET revoked=1 WHERE id=?", (device_id,))
            self.db.execute("UPDATE grants SET revoked=1 WHERE device=?", (device_id,))
            self.db.execute("UPDATE commands SET revoked=1 WHERE device=?", (device_id,))
            jobs = [job for job in self._jobs.values() if job.device_id == device_id]
        for job in jobs:
            self._stop(job)
        with self._lock:
            for uid in list(self._uploads):
                if self._uploads[uid]["device"] == device_id:
                    self._discard_upload(uid)
        self._audit(device_id, "revoke")
        self.vault.delete(device_id)
        return {"revoked": device_id}

    def grant(self, device_id, root, permissions, *, approved=False):
        self._approval(approved)
        root = Path(root).expanduser().resolve(strict=True)
        if root == Path("/") or root == Path.home().resolve() or root == self.state_dir or root in self.state_dir.parents or self.state_dir in root.parents:
            raise NativeError("unsafe_scope", "Select a specific work folder outside Native Host private state")
        permissions = set(permissions)
        if not permissions or not permissions <= {"read", "write", "search", "delete"}:
            raise NativeError("invalid_scope", "Unknown folder permission")
        with self._lock:
            row = self.db.execute("SELECT revoked FROM devices WHERE id=?", (device_id,)).fetchone()
            if not row or row[0]:
                raise NativeError("unauthorized", "Device is not enrolled")
            fd = os.open(root, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
            try:
                info = os.fstat(fd)
            finally:
                os.close(fd)
            grant = str(uuid.uuid4())
            with self.db:
                self.db.execute("INSERT INTO grants VALUES (?,?,?,?,?,?,0)",
                                (grant, device_id, str(root), info.st_dev, info.st_ino, json.dumps(sorted(permissions))))
            self._audit(device_id, "grant")
            return {"id": grant, "root": str(root), "permissions": sorted(permissions)}

    def revoke_grant(self, grant_id, *, approved=False):
        self._approval(approved)
        with self._lock, self.db:
            self.db.execute("UPDATE grants SET revoked=1 WHERE id=?", (grant_id,))
            self.db.execute("UPDATE commands SET revoked=1 WHERE grant_id=?", (grant_id,))
            command_ids = {r[0] for r in self.db.execute("SELECT id FROM commands WHERE grant_id=?", (grant_id,))}
            jobs = [j for j in self._jobs.values() if j.command_id in command_ids]
        for job in jobs:
            self._stop(job)
        return {"revoked": grant_id}

    def _grant(self, session, grant_id, permission):
        self._check(session)
        with self._lock:
            row = self.db.execute("SELECT * FROM grants WHERE id=? AND device=? AND revoked=0",
                                  (grant_id, session.device_id)).fetchone()
        if not row or permission not in json.loads(row["permissions"]):
            raise NativeError("scope_denied", "This device has no permission for this folder operation")
        return row

    @staticmethod
    def _parts(path):
        if not isinstance(path, str) or len(path) > 4096 or "\x00" in path or path.startswith("/"):
            raise NativeError("invalid_path", "Use a relative path inside the approved folder")
        if path in ("", "."):
            return []
        parts = path.split("/")
        if any(part in ("", ".", "..") for part in parts):
            raise NativeError("invalid_path", "Traversal and ambiguous path components are forbidden")
        return parts

    @contextlib.contextmanager
    def _directory(self, row, parts):
        fd = None
        try:
            fd = os.open(row["root"], os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
            info = os.fstat(fd)
            if (info.st_dev, info.st_ino) != (row["dev"], row["inode"]):
                raise NativeError("scope_changed", "Approved folder moved or was replaced; confirm it again")
            for part in parts:
                next_fd = os.open(part, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=fd)
                os.close(fd)
                fd = next_fd
            yield fd
        except OSError:
            raise NativeError("filesystem_denied", "Folder is missing, linked, or macOS denied access") from None
        finally:
            if fd is not None:
                os.close(fd)

    @contextlib.contextmanager
    def _file(self, parent, name, flags=os.O_RDONLY):
        fd = None
        try:
            fd = os.open(name, flags | os.O_NOFOLLOW | os.O_NONBLOCK, dir_fd=parent)
            info = os.fstat(fd)
            if not stat.S_ISREG(info.st_mode) or info.st_nlink != 1:
                raise NativeError("unsafe_file", "Only unlinked regular files are allowed")
            yield fd, info
        except OSError:
            raise NativeError("filesystem_denied", "File is missing, linked, or access was denied") from None
        finally:
            if fd is not None:
                os.close(fd)

    @staticmethod
    def _digest(fd):
        h = hashlib.sha256()
        pos = 0
        while True:
            block = os.pread(fd, 256 * 1024, pos)
            if not block:
                return h.hexdigest()
            h.update(block)
            pos += len(block)

    def list(self, session, grant_id, path=".", offset=0, limit=200):
        row = self._grant(session, grant_id, "read")
        if not 0 <= offset <= 100000 or not 1 <= limit <= 1000:
            raise NativeError("invalid_bounds", "Listing limit is 1 to 1000")
        with self._directory(row, self._parts(path)) as parent:
            names = sorted(os.listdir(parent))
            entries = []
            for name in names[offset:offset+limit]:
                try:
                    info = os.stat(name, dir_fd=parent, follow_symlinks=False)
                    entries.append({"name": name, "size": info.st_size,
                                    "kind": "directory" if stat.S_ISDIR(info.st_mode) else "file" if stat.S_ISREG(info.st_mode) else "blocked"})
                except FileNotFoundError:
                    continue
        self._audit(session.device_id, "list")
        return {"entries": entries, "next_offset": offset + limit if offset + limit < len(names) else None}

    def metadata(self, session, grant_id, path):
        row = self._grant(session, grant_id, "read")
        parts = self._parts(path)
        if not parts:
            raise NativeError("invalid_path", "Choose a file")
        with self._directory(row, parts[:-1]) as parent, self._file(parent, parts[-1]) as (fd, info):
            return {"size": info.st_size, "modified_ns": info.st_mtime_ns, "mode": stat.S_IMODE(info.st_mode),
                    "sha256": self._digest(fd), "kind": "file"}

    def read(self, session, grant_id, path, offset=0, length=chunk_limit):
        row = self._grant(session, grant_id, "read")
        if not isinstance(offset, int) or not isinstance(length, int) or offset < 0 or not 1 <= length <= self.chunk_limit:
            raise NativeError("invalid_bounds", "Read chunk must be 1 to 262144 bytes with nonnegative offset")
        parts = self._parts(path)
        if not parts:
            raise NativeError("invalid_path", "Choose a file")
        with self._directory(row, parts[:-1]) as parent, self._file(parent, parts[-1]) as (fd, info):
            if info.st_size > self.file_limit:
                raise NativeError("file_too_large", "File exceeds the 1 GiB transfer limit")
            data = os.pread(fd, length, offset)
            result = {"data": base64.b64encode(data).decode(), "encoding": "base64", "size": info.st_size,
                      "offset": offset, "next_offset": offset+len(data) if offset+len(data) < info.st_size else None,
                      "sha256": self._digest(fd)}
        self._audit(session.device_id, "read")
        return result

    @staticmethod
    def _decode(data, limit):
        if not isinstance(data, str) or len(data) > 4 * ((limit + 2) // 3):
            raise NativeError("invalid_data", "Binary chunk exceeds transfer limit")
        try:
            value = base64.b64decode(data, validate=True)
        except (ValueError, binascii.Error):
            raise NativeError("invalid_data", "Use valid base64 data") from None
        if len(value) > limit:
            raise NativeError("invalid_data", "Binary chunk exceeds transfer limit")
        return value

    def _existing(self, parent, name, expected_sha256):
        try:
            info = os.stat(name, dir_fd=parent, follow_symlinks=False)
        except FileNotFoundError:
            if expected_sha256 is not None:
                raise NativeError("conflict", "Expected existing file is missing")
            return False
        if not expected_sha256:
            raise NativeError("conflict", "Existing file requires its current SHA-256 before replacement")
        with self._file(parent, name) as (fd, info):
            if not hmac.compare_digest(self._digest(fd), expected_sha256):
                raise NativeError("conflict", "File changed; read it and confirm replacement again")
        return True

    def _publish(self, parent, name, data, expected_sha256):
        exists = self._existing(parent, name, expected_sha256)
        temporary = ".bifrost-stage-" + secrets.token_hex(16)
        fd = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600, dir_fd=parent)
        try:
            with os.fdopen(fd, "wb") as stream:
                stream.write(data)
                stream.flush()
                os.fsync(stream.fileno())
            if exists:
                self._existing(parent, name, expected_sha256)
                os.replace(temporary, name, src_dir_fd=parent, dst_dir_fd=parent)
            else:
                # link provides atomic no-clobber publish; never truncate an existing file.
                os.link(temporary, name, src_dir_fd=parent, dst_dir_fd=parent, follow_symlinks=False)
                os.unlink(temporary, dir_fd=parent)
            os.fsync(parent)
        except FileExistsError:
            raise NativeError("conflict", "Destination appeared during write; nothing overwritten") from None
        finally:
            try:
                os.unlink(temporary, dir_fd=parent)
            except FileNotFoundError:
                pass

    def write(self, session, grant_id, path, data, expected_sha256=None):
        with self._lock:
            row = self._grant(session, grant_id, "write")
            parts = self._parts(path)
            if not parts:
                raise NativeError("invalid_path", "Choose a file")
            value = self._decode(data, self.chunk_limit)
            with self._directory(row, parts[:-1]) as parent:
                self._publish(parent, parts[-1], value, expected_sha256)
            self._audit(session.device_id, "write")
            return {"bytes": len(value), "sha256": hashlib.sha256(value).hexdigest()}

    def mkdir(self, session, grant_id, path):
        row = self._grant(session, grant_id, "write")
        parts = self._parts(path)
        if not parts:
            raise NativeError("invalid_path", "Choose a new folder")
        with self._directory(row, parts[:-1]) as parent:
            try:
                os.mkdir(parts[-1], 0o700, dir_fd=parent)
            except OSError:
                raise NativeError("filesystem_denied", "Folder already exists or creation was denied") from None
        return {"created": True}

    def move(self, session, grant_id, source, destination):
        with self._lock:
            row = self._grant(session, grant_id, "delete")
            self._grant(session, grant_id, "write")
            a, b = self._parts(source), self._parts(destination)
            if not a or not b:
                raise NativeError("invalid_path", "Choose two file paths")
            with self._directory(row, a[:-1]) as pa, self._directory(row, b[:-1]) as pb:
                with self._file(pa, a[-1]):
                    try:
                        os.link(a[-1], b[-1], src_dir_fd=pa, dst_dir_fd=pb, follow_symlinks=False)
                    except OSError:
                        raise NativeError("conflict", "Destination exists or move is unavailable") from None
                    os.unlink(a[-1], dir_fd=pa)
            return {"moved": True}

    def remove(self, session, grant_id, path, expected_sha256=None):
        with self._lock:
            row = self._grant(session, grant_id, "delete")
            parts = self._parts(path)
            if not parts:
                raise NativeError("invalid_path", "Scope root cannot be deleted")
            with self._directory(row, parts[:-1]) as parent:
                if not self._existing(parent, parts[-1], expected_sha256):
                    raise NativeError("missing", "File is missing")
                os.unlink(parts[-1], dir_fd=parent)
            self._audit(session.device_id, "delete")
            return {"removed": True}

    def search(self, session, grant_id, query, content=False, limit=200):
        row = self._grant(session, grant_id, "search")
        if not isinstance(query, str) or not 1 <= len(query) <= 1024 or not 1 <= limit <= 1000:
            raise NativeError("invalid_search", "Use 1 to 1024 characters and a limit of 1 to 1000")
        results, visited, skipped = [], 0, 0
        deadline = time.monotonic() + 5
        truncated = False
        def walk(parent, prefix="", depth=0):
            nonlocal visited, skipped, truncated
            if depth > 32:
                truncated = True
                return
            for name in sorted(os.listdir(parent)):
                if len(results) >= limit or visited >= 10000 or time.monotonic() > deadline:
                    truncated = True
                    return
                visited += 1
                rel = prefix + name
                try:
                    info = os.stat(name, dir_fd=parent, follow_symlinks=False)
                    if stat.S_ISDIR(info.st_mode):
                        if not content and query.casefold() in rel.casefold():
                            results.append({"path": rel, "kind": "directory"})
                        fd = os.open(name, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=parent)
                        try:
                            walk(fd, rel + "/", depth+1)
                        finally:
                            os.close(fd)
                    elif stat.S_ISREG(info.st_mode) and info.st_nlink == 1:
                        if content:
                            if info.st_size > 1024 * 1024:
                                skipped += 1
                                continue
                            with self._file(parent, name) as (fd, _):
                                value = os.read(fd, 1024 * 1024 + 1)
                            if b"\x00" in value or len(value) > 1024 * 1024:
                                skipped += 1
                                continue
                            for number, line in enumerate(value.decode("utf-8", errors="replace").splitlines(), 1):
                                if query.casefold() in line.casefold():
                                    results.append({"path": rel, "line": number, "text": line[:4096]})
                                    if len(results) >= limit:
                                        truncated = True
                                        break
                        elif query.casefold() in rel.casefold():
                            results.append({"path": rel, "kind": "file"})
                    else:
                        skipped += 1
                except (OSError, NativeError):
                    skipped += 1
        with self._directory(row, []) as parent:
            walk(parent)
        self._audit(session.device_id, "search")
        return {"results": results, "truncated": truncated, "skipped": skipped, "engine": "deterministic-posix"}

    def approve_command(self, device_id, argv, grant_id, cwd=".", environment=None, timeout=300, *, approved=False):
        self._approval(approved)
        if not isinstance(argv, list) or not argv or len(argv) > 128 or any(not isinstance(a, str) or "\x00" in a or len(a) > 8192 for a in argv):
            raise NativeError("invalid_command", "Approve a bounded exact argument vector")
        executable = Path(argv[0])
        if not executable.is_absolute() or not executable.is_file() or not os.access(executable, os.X_OK):
            raise NativeError("invalid_command", "Choose an installed executable by absolute path")
        executable = executable.resolve()
        argv = [str(executable)] + argv[1:]
        environment = environment or {}
        # Explicit command-specific values only; no loader/shell/startup injection.
        if not isinstance(environment, dict) or set(environment) - {"LANG", "LC_ALL", "TZ"} or any(not isinstance(v, str) or len(v)>1024 or "\x00" in v for v in environment.values()):
            raise NativeError("invalid_environment", "Only LANG, LC_ALL and TZ can be configured")
        if not isinstance(timeout, (int, float)) or not 1 <= timeout <= 3600:
            raise NativeError("invalid_timeout", "Command lifetime must be 1 to 3600 seconds")
        with self._lock:
            row = self.db.execute("SELECT * FROM grants WHERE id=? AND device=? AND revoked=0",
                                  (grant_id, device_id)).fetchone()
            device = self.db.execute("SELECT revoked FROM devices WHERE id=?", (device_id,)).fetchone()
            if not row or not device or device[0]:
                raise NativeError("scope_denied", "Command needs an enrolled device and approved working folder")
            with self._directory(row, self._parts(cwd)):
                pass
            digest = hashlib.sha256(executable.read_bytes()).hexdigest()
            command = str(uuid.uuid4())
            with self.db:
                self.db.execute("INSERT INTO commands VALUES (?,?,?,?,?,?,?,?,0)",
                                (command, device_id, grant_id, cwd, json.dumps(argv), digest, json.dumps(environment), timeout))
            self._audit(device_id, "approve_command")
            return {"id": command, "argv": argv, "cwd": cwd, "os_privileges": "owner"}

    def start(self, session, command_id):
        with self._lock:
            self._check(session)
            row = self.db.execute("SELECT * FROM commands WHERE id=? AND device=? AND revoked=0",
                                  (command_id, session.device_id)).fetchone()
            if not row:
                raise NativeError("command_denied", "Owner must approve this exact command first")
            scope = self.db.execute("SELECT * FROM grants WHERE id=? AND device=? AND revoked=0",
                                    (row["grant_id"], session.device_id)).fetchone()
            if not scope:
                raise NativeError("scope_denied", "Working folder was revoked")
            if len(self._jobs) >= 32:
                # Completed jobs can be released explicitly; never silently lose output.
                raise NativeError("capacity", "Release completed jobs before starting more")
            argv = json.loads(row["argv"])
            if hashlib.sha256(Path(argv[0]).read_bytes()).hexdigest() != row["digest"]:
                raise NativeError("command_changed", "Executable changed; approve it again")
            with self._directory(scope, self._parts(row["cwd"])):
                pass
            cwd = str(Path(scope["root"]).joinpath(*self._parts(row["cwd"])))
            env = {"PATH": "/usr/bin:/bin:/usr/sbin:/sbin", "LANG": "en_US.UTF-8"}
            env.update(json.loads(row["environment"]))
            p = subprocess.Popen(argv, cwd=cwd, env=env, stdin=subprocess.DEVNULL,
                                 stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                 start_new_session=True, close_fds=True)
            job = Job(p, session.device_id, command_id, time.time(), time.monotonic()+row["timeout"])
            jid = str(uuid.uuid4())
            self._jobs[jid] = job
            for pipe, target in ((p.stdout, job.stdout), (p.stderr, job.stderr)):
                t = threading.Thread(target=self._drain, args=(job, pipe, target), daemon=True)
                job.readers.append(t)
                t.start()
            self._audit(session.device_id, "process_start")
            return {"id": jid, "state": "running"}

    def _drain(self, job, pipe, target):
        try:
            while True:
                block = pipe.read(8192)
                if not block:
                    break
                with job.lock:
                    room = self.output_limit - len(target)
                    target.extend(block[:room])
                    if len(block) > room:
                        job.truncated = True
        finally:
            pipe.close()

    def _job(self, session, job_id):
        self._check(session)
        with self._lock:
            job = self._jobs.get(job_id)
        if not job or job.device_id != session.device_id:
            raise NativeError("job_denied", "Only this device's managed jobs can be controlled")
        return job

    def process(self, session, job_id, stdout_offset=0, stderr_offset=0, length=chunk_limit):
        job = self._job(session, job_id)
        if min(stdout_offset, stderr_offset) < 0 or not 1 <= length <= self.chunk_limit:
            raise NativeError("invalid_bounds", "Output needs nonnegative offsets and bounded length")
        code = job.p.poll()
        if code is not None:
            for reader in job.readers:
                reader.join(timeout=.2)
        with job.lock:
            out = bytes(job.stdout[stdout_offset:stdout_offset+length])
            err = bytes(job.stderr[stderr_offset:stderr_offset+length])
            return {"id": job_id, "state": "running" if code is None else "exited",
                    "exit_code": code, "stdout": base64.b64encode(out).decode(),
                    "stderr": base64.b64encode(err).decode(), "encoding": "base64",
                    "stdout_size": len(job.stdout), "stderr_size": len(job.stderr),
                    "stdout_next": stdout_offset+len(out), "stderr_next": stderr_offset+len(err),
                    "truncated": job.truncated}

    @staticmethod
    def _stop(job):
        # Only live child handles; no persisted PID reuse and no arbitrary PID API.
        if job.p.poll() is None:
            try:
                os.killpg(job.p.pid, signal.SIGTERM)
                job.p.wait(timeout=1)
            except subprocess.TimeoutExpired:
                if job.p.poll() is None:
                    os.killpg(job.p.pid, signal.SIGKILL)
                job.p.wait(timeout=2)
            except ProcessLookupError:
                job.p.wait(timeout=2)

    def terminate(self, session, job_id):
        job = self._job(session, job_id)
        self._stop(job)
        self._audit(session.device_id, "process_terminate")
        return self.process(session, job_id)

    def release(self, session, job_id):
        job = self._job(session, job_id)
        if job.p.poll() is None:
            raise NativeError("job_running", "Terminate or wait before releasing this job")
        for reader in job.readers:
            reader.join(timeout=1)
        with self._lock:
            del self._jobs[job_id]
        return {"released": job_id}

    def jobs(self, session):
        self._check(session)
        with self._lock:
            ids = [key for key, value in self._jobs.items() if value.device_id == session.device_id]
        return [{"id": key, "state": self.process(session, key)["state"]} for key in ids]

    def _watch(self):
        while not self._closed.wait(.1):
            with self._lock:
                candidates = list(self._jobs.values())
                invalid = set()
                for job in candidates:
                    row = self.db.execute("SELECT d.revoked,c.revoked,g.revoked FROM devices d JOIN commands c ON c.device=d.id JOIN grants g ON g.id=c.grant_id WHERE c.id=?",
                                          (job.command_id,)).fetchone()
                    if not row or any(row):
                        invalid.add(job.command_id)
            for job in candidates:
                if time.monotonic() > job.deadline or job.command_id in invalid:
                    self._stop(job)

    def status(self, session):
        self._check(session)
        with self._lock:
            grants = [dict(row) for row in self.db.execute("SELECT id,root,permissions FROM grants WHERE device=? AND revoked=0", (session.device_id,))]
            commands = [dict(row) for row in self.db.execute("SELECT id,argv,cwd FROM commands WHERE device=? AND revoked=0", (session.device_id,))]
        for grant in grants:
            grant["permissions"] = json.loads(grant["permissions"])
        for command in commands:
            command["argv"] = json.loads(command["argv"])
        return {"provider": "bifrost.native", "host_id": self.identity, "device_id": session.device_id,
                "name": socket.gethostname(), "authorized": True, "transport": "stdio",
                "remote_enabled": False, "grants": grants, "commands": commands,
                "process_recovery": "not-resumable-after-host-exit", "version": "0.1.0"}

    def discovery(self, session):
        self._check(session)
        names = ("ssh", "sftp", "rg", "mdfind", "shortcuts", "caffeinate", "swift", "xcodebuild")
        tools = {name: {"path": shutil.which(name), "available": bool(shutil.which(name)),
                        "authorized": False} for name in names}
        return {"tools": tools, "platform": sys.platform, "remote": {"enabled": False, "transport": "OpenSSH-stdio"},
                "apple": {"keychain": "selected" if isinstance(self.vault, AppleSecrets) else "injected-test-vault",
                          "permissions": "OS-enforced; physical confirmation UNKNOWN",
                          "spotlight": "available" if shutil.which("mdfind") else "unavailable"}}

    def close(self):
        if self._closed.is_set():
            return
        self._closed.set()
        self._watcher.join(timeout=2)
        for job in list(self._jobs.values()):
            self._stop(job)
            for reader in job.readers:
                reader.join(timeout=1)
        for uid in list(self._uploads):
            self._discard_upload(uid)
        self._sessions.clear()
        self.db.close()

    def begin_upload(self, session, grant_id, path, size, expected_sha256=None):
        self._grant(session, grant_id, "write")
        parts = self._parts(path)
        if not parts or not isinstance(size, int) or not 0 <= size <= self.file_limit:
            raise NativeError("invalid_transfer", "Choose a relative file and size up to 1 GiB")
        with self._lock:
            if len(self._uploads) >= 4:
                raise NativeError("capacity", "Finish or abort an existing transfer")
            uid = str(uuid.uuid4())
            stage = self.state_dir / ("upload-" + uid)
            fd = os.open(stage, os.O_RDWR | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
            self._uploads[uid] = {"device": session.device_id, "grant": grant_id, "path": path,
                                  "size": size, "offset": 0, "expected": expected_sha256,
                                  "fd": fd, "stage": stage, "expires": time.monotonic()+3600}
            return {"id": uid, "next_offset": 0, "size": size}

    def _upload(self, session, upload_id):
        self._check(session)
        upload = self._uploads.get(upload_id)
        if not upload or upload["device"] != session.device_id:
            raise NativeError("transfer_denied", "Transfer is not owned by this device")
        self._grant(session, upload["grant"], "write")
        if time.monotonic() > upload["expires"]:
            self._discard_upload(upload_id)
            raise NativeError("transfer_expired", "Restart the expired transfer")
        return upload

    def upload_chunk(self, session, upload_id, offset, data):
        with self._lock:
            upload = self._upload(session, upload_id)
            chunk = self._decode(data, self.chunk_limit)
            if offset != upload["offset"] or offset+len(chunk) > upload["size"]:
                raise NativeError("transfer_conflict", "Use the exact next offset and declared size")
            view = memoryview(chunk)
            while view:
                count = os.write(upload["fd"], view)
                view = view[count:]
            upload["offset"] += len(chunk)
            return {"id": upload_id, "next_offset": upload["offset"]}

    def finish_upload(self, session, upload_id, sha256):
        with self._lock:
            upload = self._upload(session, upload_id)
            if upload["offset"] != upload["size"] or not isinstance(sha256, str) or self._digest(upload["fd"]) != sha256:
                raise NativeError("transfer_conflict", "Transfer size or SHA-256 does not match")
            row = self._grant(session, upload["grant"], "write")
            parts = self._parts(upload["path"])
            with self._directory(row, parts[:-1]) as parent:
                exists = self._existing(parent, parts[-1], upload["expected"])
                temporary = ".bifrost-stage-" + secrets.token_hex(16)
                fd = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600, dir_fd=parent)
                try:
                    with os.fdopen(fd, "wb") as stream:
                        position = 0
                        while position < upload["size"]:
                            chunk = os.pread(upload["fd"], self.chunk_limit, position)
                            if not chunk:
                                raise NativeError("transfer_conflict", "Staged transfer was truncated")
                            stream.write(chunk)
                            position += len(chunk)
                        stream.flush()
                        os.fsync(stream.fileno())
                    if exists:
                        self._existing(parent, parts[-1], upload["expected"])
                        os.replace(temporary, parts[-1], src_dir_fd=parent, dst_dir_fd=parent)
                    else:
                        os.link(temporary, parts[-1], src_dir_fd=parent, dst_dir_fd=parent, follow_symlinks=False)
                        os.unlink(temporary, dir_fd=parent)
                    os.fsync(parent)
                except FileExistsError:
                    raise NativeError("conflict", "Destination appeared; nothing overwritten") from None
                finally:
                    try:
                        os.unlink(temporary, dir_fd=parent)
                    except FileNotFoundError:
                        pass
            size = upload["size"]
            self._discard_upload(upload_id)
            self._audit(session.device_id, "transfer_complete")
            return {"bytes": size, "sha256": sha256}

    def _discard_upload(self, upload_id):
        upload = self._uploads.pop(upload_id)
        os.close(upload["fd"])
        upload["stage"].unlink(missing_ok=True)

    def abort_upload(self, session, upload_id):
        with self._lock:
            self._upload(session, upload_id)
            self._discard_upload(upload_id)
            return {"aborted": upload_id}
