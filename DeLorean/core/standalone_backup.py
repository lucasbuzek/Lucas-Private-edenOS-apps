"""DeLorean standalone on-demand backup/restore facade, independent of PENELOPE/cloud.

The file-tree adapter is deliberately scoped to explicitly allowed directories; it
is NOT a disk image, application-consistent database snapshot or OS recovery tool.
Optional restic/Time Machine adapters delegate those jobs to existing engines.
No daemon, key escrow, implicit cloud upload, service install or destructive restore.
"""
from __future__ import annotations

import json
import hashlib
import sqlite3
from contextlib import closing
import os
import platform
import shutil
import stat
import subprocess
import sys
import time
import uuid
from pathlib import Path
from typing import Any

try:
    from . import timemachine as history
    from . import connector_evidence
except ImportError:
    import timemachine as history
    import connector_evidence


class Denied(history.RecoveryError):
    pass


def _canonical(path: str | Path) -> Path:
    p = Path(path).expanduser().absolute()
    # Deny symlink components (even if resolve() would hide them).
    if any(c.is_symlink() for c in (p, *p.parents)):
        raise Denied('Symlinked root/parent denied')
    return p.resolve(strict=False)


def _within(p: Path, root: Path) -> bool:
    return p == root or history._is_within(p, root)


def _must_be_new(path: Path) -> None:
    if path.exists() or path.is_symlink():
        raise Denied('Destination already exists; no overwrite')


def _identifier(s: str) -> str:
    if not isinstance(s, str) or not s or len(s) > 120 or not all(x.isalnum() or x in '_.-' for x in s):
        raise Denied('Use a project identifier with letters, digits, dots, hyphens or underscore')
    if s in ('.', '..'):
        raise Denied('Invalid project identifier')
    return s


def _sqlite_logical_digest(path: Path) -> str:
    """Deterministic *logical* fingerprint, not an integrity or auth signature.

    SQLite's online backup may increment header counters without any logical
    change, so raw-byte comparison alone cannot deduplicate stable databases.
    """
    h = hashlib.sha256()
    from urllib.parse import quote
    uri = 'file:' + quote(str(path), safe='/:') + '?mode=ro'
    with closing(sqlite3.connect(uri, uri=True, timeout=15)) as db:
        for statement in db.iterdump():
            h.update(statement.encode('utf-8'))
            h.update(b'\n')
    return h.hexdigest()


class DeLorean:
    """Explicit grant-oriented facade around existing DeLorean history kernel."""

    def __init__(self, home: str | Path, read_roots: list[str], restore_roots: list[str], owner='LucasPRIVATE'):
        self.home = _canonical(home)
        self.catalog = self.home / 'catalog'
        self.sets = self.home / 'sets'
        self.owner = _identifier(owner)
        self.read_roots = [_canonical(p) for p in read_roots]
        self.restore_roots = [_canonical(p) for p in restore_roots]
        # Reject overbroad grants and accidental catalog/backup self-registration.
        if any(_within(self.home, root) or _within(root, self.home) for root in self.read_roots):
            raise Denied('Backup storage must be separate from every allowed source root')
        if any(_within(self.home, root) or _within(root, self.home) for root in self.restore_roots):
            raise Denied('Restore grants must be separate from backup storage')

    def _grant(self, path: str, grants: list[Path], *, existing: bool = True) -> Path:
        dest = _canonical(path)
        if not any(_within(dest, root) for root in grants):
            raise Denied('Path is outside explicit allowed roots')
        if existing and not dest.exists():
            raise Denied('Source path unavailable')
        return dest

    def status(self) -> dict:
        return {
            'identity': 'EDEN/edenOS DeLorean TimeMachine',
            'runtime': 'standalone-stdio-on-demand', 'owner': self.owner,
            'system': platform.system(),
            'catalog_exists': self.catalog.is_dir(),
            'read_grants': len(self.read_roots), 'restore_grants': len(self.restore_roots),
            'cloud_enabled': bool(os.environ.get('RESTIC_REPOSITORY') and os.environ.get('RESTIC_PASSWORD_FILE')),
            'restic_available': shutil.which('restic') is not None,
            'kopia_available': shutil.which('kopia') is not None,
            'time_machine_available': platform.system() == 'Darwin' and shutil.which('tmutil') is not None,
            'penelope': 'OPTIONAL_EXTERNAL_ADAPTER_NOT_REQUIRED',
            'system_image_restoration': 'REQUIRES_PLATFORM_RECOVERY_OUTSIDE_MCP',
        }

    def _manifest(self, snapshot: str) -> dict:
        m = history.find(self.catalog, snapshot)
        if m.get('owner') != self.owner:
            raise Denied('Snapshot belongs to a different owner')
        p = _canonical(m.get('source_root', ''))
        if not _within(p, self.sets):
            # Legacy manifests of existing backups may be indexed in read-only mode,
            # but restoration of them needs explicit adapter integration/approval.
            raise Denied('Restore source outside managed snapshot location')
        return m

    def dashboard_catalog(self) -> dict:
        """Owner-scoped, source-root-redacted metadata for MCP Apps UI.

        The underlying snapshot files never leave the backup host.
        """
        snapshots = []
        for f in history.catalogue_files(self.catalog):
            m = history.load_manifest(f)
            if m.get('owner') != self.owner:
                continue
            item = {k:v for k,v in m.items() if k not in ('source_root','content_sha256')}
            snapshots.append(item)
        events = self.timeline()
        return {'schema': history.CATALOG_SCHEMA,
                'snapshots': sorted(snapshots,key=lambda x:x['recorded_at']),
                'events': events,
                'local_paths_redacted': True,
                'restore_verified_by_live_app': False}

    def snapshots(self) -> list[dict]:
        result = []
        for f in history.catalogue_files(self.catalog):
            m = history.load_manifest(f)
            if m.get('owner') != self.owner:
                continue
            result.append({k:m.get(k) for k in ('snapshot_id', 'project', 'owner', 'provider', 'recorded_at', 'evidence')}
                          | {'files':len(m['files']), 'total_bytes':sum(x['size'] for x in m['files'])})
        return sorted(result,key=lambda x:x['recorded_at'])

    def backup_plan(self, source: str, scope: str, project: str) -> dict:
        if scope not in ('file', 'folder', 'project', 'app', 'device-data'):
            raise Denied('Allowed scopes: file, folder, project, app, device-data; not disk-image')
        project = _identifier(project)
        p = self._grant(source, self.read_roots)
        if p.is_symlink() or not (p.is_dir() or p.is_file()):
            raise Denied('Only regular files or directories supported')
        if p.is_file():
            if not stat.S_ISREG(p.stat().st_mode):
                raise Denied('Source must be a regular file')
            files = [{'path': p.name, 'size':p.stat().st_size, 'sha256':history._hash(p)}]
        else:
            files = history.scan(p)
        return {
            'scope':scope, 'project':project, 'owner':self.owner,
            'source':str(p), 'files':len(files), 'total_bytes':sum(x['size'] for x in files),
            'destination_root':str(self.sets),
            'kind':'FILE_TREE_COPY_NOT_SYSTEM_IMAGE',
            'warning':'UNENCRYPTED LOCAL COPY. Avoid sensitive device/app data unless destination is already encrypted. Close live databases or export transactionally before backup.',
            'confirmation_required':'BACKUP NOW',
        }

    def backup_create(self, source: str, scope: str, project: str, confirmation: str) -> dict:
        if confirmation != 'BACKUP NOW':
            raise Denied('Backup requires exact confirmation BACKUP NOW')
        preview = self.backup_plan(source,scope,project)
        p = Path(preview['source'])
        # A no-clobber, reuse-if-identical index prevents repeated backup clutter.
        current_files = ([{'path':p.name, 'sha256':history._hash(p), 'size':p.stat().st_size}]
                         if p.is_file() else history.scan(p))
        fingerprint = __import__('hashlib').sha256(json.dumps(
            {'source':str(p),'owner':self.owner,'scope':scope,'project':project,'files':current_files},
            sort_keys=True).encode()).hexdigest()
        for old_info in sorted(self.sets.glob('*/backup_info.json')) if self.sets.is_dir() else []:
            if old_info.is_symlink() or any(parent.is_symlink() for parent in old_info.parents):
                continue
            try:
                old = json.loads(old_info.read_text(encoding='utf-8'))
                if old.get('fingerprint') != fingerprint:continue
                snapshots=self.snapshots()
                for snapshot in snapshots:
                    if snapshot.get('provider')!='delorean-local-files':continue
                    m=self._manifest(snapshot['snapshot_id'])
                    if m.get('provider_ref')==old_info.parent.name and history.verify(m)['ok']:
                        return {'status':'UNCHANGED_REUSED_VERIFIED','snapshot_id':m['snapshot_id'],
                                'snapshot_directory':str(old_info.parent),'files':len(m['files']),
                                'bytes':sum(x['size'] for x in m['files']),'scope':scope,'owner':self.owner}
            except (OSError,ValueError,history.RecoveryError):
                continue
        self.sets.mkdir(parents=True, exist_ok=True)
        self.catalog.mkdir(parents=True, exist_ok=True)
        name = _identifier(project) + '-' + time.strftime('%Y%m%dT%H%M%SZ', time.gmtime()) + '-' + uuid.uuid4().hex[:10]
        finished = self.sets / name
        temporary = self.sets / ('.inprogress-' + uuid.uuid4().hex)
        _must_be_new(finished)
        try:
            temporary.mkdir(mode=0o700)
            payload = temporary / 'payload'
            payload.mkdir()
            if p.is_file():
                target = payload / p.name
                shutil.copy2(p,target,follow_symlinks=False)
            else:
                # All entries validated before copy; second scan after detects changed inputs.
                for f in history.scan(p):
                    dest=payload / history._safe_relpath(f['path'])
                    dest.parent.mkdir(parents=True,exist_ok=True)
                    source_file=p / f['path']
                    if source_file.is_symlink() or history._hash(source_file) != f['sha256']:
                        raise Denied('Source changed during backup; refusing snapshot')
                    shutil.copy2(source_file,dest,follow_symlinks=False)
                    if history._hash(dest) != f['sha256']:
                        raise Denied('Copied file failed integrity check')
            copied = history.scan(payload)
            if p.is_file() and (copied != [{'path':p.name, 'sha256':history._hash(p), 'size':p.stat().st_size}]):
                raise Denied('File changed during backup')
            if p.is_dir() and copied != history.scan(p):
                raise Denied('Backup does not match source after copy')
            # Store copy metadata with the payload, no source/user secrets in metadata.
            (temporary / 'backup_info.json').write_text(json.dumps({'scope':scope,'project':project,'owner':self.owner,'kind':'FILE_TREE_COPY','created_at':history.stamp(),'fingerprint':fingerprint,'encryption':'NONE_DESTINATION_OWNER_RESPONSIBILITY'},indent=2)+'\n')
            _must_be_new(finished)
            temporary.rename(finished)
            # Register backup payload, not working source. Integrity hashing after commit.
            try:
                manifest=history.register(self.catalog,project,str(finished/'payload'),provider='delorean-local-files',ref=name,owner=self.owner)
            except Exception:
                # Keep completed backup recoverable if indexing fails. Never erase it.
                raise
            verification=history.verify(manifest)
            if not verification['ok']:
                raise Denied('Copied backup failed post-registration verification')
            return {'status':'BACKUP_FILES_VERIFIED_NOT_APPLICATION_CONSISTENT', 'snapshot_id':manifest['snapshot_id'], 'snapshot_directory':str(finished),'files':len(copied),'bytes':sum(x['size'] for x in copied), 'scope':scope,'owner':self.owner,'encrypted':False}
        finally:
            if temporary.exists():
                shutil.rmtree(temporary)  # only our unique temporary tree

    def sqlite_backup_plan(self, source: str, project: str) -> dict:
        """Plan a transactionally consistent copy of one existing SQLite database.

        Captures the primary SQLite database via sqlite3 backup API, including
        committed WAL data. Other external attachments are not included.
        """
        p = self._grant(source, self.read_roots)
        project = _identifier(project)
        if not p.is_file() or not stat.S_ISREG(p.stat().st_mode):
            raise Denied('SQLite source must be an existing regular file')
        try:
            with p.open('rb') as handle:
                magic = handle.read(16)
        except OSError as exc:
            raise Denied('SQLite source unreadable') from exc
        if magic != b'SQLite format 3\x00':
            raise Denied('Not a SQLite 3 database; external app engine required')
        return {
            'source': str(p), 'project': project, 'owner': self.owner,
            'scope': 'sqlite-app', 'kind': 'SQLITE_ONLINE_BACKUP_API',
            'size_at_plan_bytes': p.stat().st_size,
            'destination_root': str(self.sets),
            'confirmation_required': 'BACKUP SQLITE DATABASE',
            'warning': 'Consistent primary SQLite DB only; external attachments, app preferences and files need separate native backups. Unencrypted destination.'
        }

    def sqlite_backup_create(self, source: str, project: str, confirmation: str) -> dict:
        if confirmation != 'BACKUP SQLITE DATABASE':
            raise Denied('Requires exact BACKUP SQLITE DATABASE confirmation')
        plan = self.sqlite_backup_plan(source, project)
        p = Path(plan['source'])
        self.sets.mkdir(parents=True, exist_ok=True)
        self.catalog.mkdir(parents=True, exist_ok=True)
        temporary = self.sets / ('.inprogress-sqlite-' + uuid.uuid4().hex)
        finished = self.sets / (_identifier(project) + '-sqlite-' + time.strftime('%Y%m%dT%H%M%SZ', time.gmtime()) + '-' + uuid.uuid4().hex[:10])
        _must_be_new(temporary)
        _must_be_new(finished)
        try:
            temporary.mkdir(mode=0o700)
            payload = temporary / 'payload'
            payload.mkdir(mode=0o700)
            dest = payload / p.name
            # Mode ro prevents altering the source; online backup consolidates WAL.
            from urllib.parse import quote
            uri = 'file:' + quote(str(p), safe='/:') + '?mode=ro'
            with closing(sqlite3.connect(uri, uri=True, timeout=15)) as origin:
                with closing(sqlite3.connect(str(dest), timeout=15)) as target:
                    origin.backup(target, pages=128, sleep=0.05)
                    integrity = target.execute('PRAGMA integrity_check').fetchone()
                    if not integrity or integrity[0] != 'ok':
                        raise Denied('SQLite integrity_check failed for backup')
                    # Convert copied SQLite to one closed, self-contained file.
                    # A source may be in WAL mode; we must not leave -wal/-shm
                    # files in a purported single-file application snapshot.
                    target.execute('PRAGMA journal_mode=DELETE')
                    target.commit()
            if list(payload.glob(p.name + '-*')):
                raise Denied('SQLite backup left unexpected companion files')
            logical_digest = _sqlite_logical_digest(dest)
            source_meta = {'scope': 'sqlite-app', 'project': project, 'owner': self.owner,
                'kind': 'SQLITE_ONLINE_BACKUP_API', 'created_at': history.stamp(),
                'encryption': 'NONE_DESTINATION_OWNER_RESPONSIBILITY',
                'attachments': 'NOT_INCLUDED', 'sqlite_logical_sha256': logical_digest}
            (temporary / 'backup_info.json').write_text(json.dumps(source_meta, sort_keys=True) + '\n', encoding='utf-8')
            # Identical verified SQLite backup is reused rather than copied twice.
            new_hash = history._hash(dest)
            for f in history.catalogue_files(self.catalog):
                m = history.load_manifest(f)
                if m.get('owner') != self.owner or m.get('project') != project or m.get('provider') != 'delorean-sqlite-online-backup':
                    continue
                if len(m['files']) != 1 or m['files'][0]['path'] != p.name:
                    continue
                if not history.verify(m)['ok']:
                    continue
                if m['files'][0]['sha256'] != new_hash:
                    prior_root = Path(m['source_root'])
                    meta_file = prior_root.parent / 'backup_info.json'
                    try:
                        old_meta = json.loads(meta_file.read_text(encoding='utf-8'))
                    except (OSError, ValueError):
                        continue
                    if old_meta.get('sqlite_logical_sha256') != logical_digest:
                        continue
                return {'status': 'UNCHANGED_SQLITE_REUSED_VERIFIED', 'snapshot_id': m['snapshot_id'],
                    'project': project, 'scope': 'sqlite-app', 'files': 1,
                    'encrypted': False, 'application_consistency': 'SQLITE_PRIMARY_DATABASE'}
            temporary.rename(finished)
            # Refer only to verified payload, preserving source and avoiding LKG edits.
            manifest = history.register(self.catalog, project, str(finished / 'payload'),
                provider='delorean-sqlite-online-backup', ref=finished.name, owner=self.owner)
            verified = history.verify(manifest)
            if not verified['ok']:
                raise Denied('Post-commit SQLite backup hash verification failed')
            return {'status': 'SQLITE_ONLINE_BACKUP_HASH_VERIFIED',
                'snapshot_id': manifest['snapshot_id'], 'project': project, 'scope': 'sqlite-app',
                'files': 1, 'encrypted': False,
                'application_consistency': 'SQLITE_PRIMARY_DATABASE_ONLY'}
        except sqlite3.Error as exc:
            raise Denied('SQLite API backup failed; source and LKG preserved') from exc
        finally:
            if temporary.exists():
                shutil.rmtree(temporary)

    def device_recovery_plan(self, device: str = 'auto') -> dict:
        """Non-destructive native recovery capability lookup, never image/erase."""
        if device not in ('auto','mac','iphone','ipad','windows','linux','android'):
            raise Denied('Unsupported device family')
        detected = platform.system()
        if device == 'auto':
            device = {'Darwin': 'mac', 'Windows': 'windows', 'Linux': 'linux'}.get(detected, 'linux')
        native = {
            'mac': ('Time Machine + macOS Recovery + Migration Assistant',
                'Verify actual Time Machine backup, recovery media and restored apps/settings on the authorized Mac.'),
            'iphone': ('Encrypted Finder/Apple Devices local backup or iCloud Backup',
                'Device pairing and user-approved encrypted backup/restore required; no unattended iOS image.'),
            'ipad': ('Encrypted Finder/Apple Devices local backup or iCloud Backup',
                'Device pairing and user-approved encrypted backup/restore required; no unattended iPadOS image.'),
            'windows': ('Windows Backup / wbadmin VSS system backup and Windows Recovery Environment',
                'Verify VSS writers, privileged native backup, catalog and bare-metal recovery media.'),
            'linux': ('Distribution filesystem/snapshot and boot/reinstall recovery method',
                'Select proven filesystem-native method for root filesystem, volumes and bootloader; file-copy is not imaging.'),
            'android': ('Vendor/Android backup and authorized device migration',
                'App-specific exclusions and OEM restrictions require manual validation; no unattended system image.'),
        }
        engine, gate = native[device]
        return {
            'device':device, 'executor_os':detected,
            'native_engine':engine,
            'native_full_recovery_tested':False,
            'full_device_recovery_by_delorean':'NOT_IMPLEMENTED',
            'native_recovery_gate':gate,
            'local_file_tree_backup':'DATA_ONLY_UNENCRYPTED_UNLESS_DESTINATION_ENCRYPTED',
            'optional_cloud':'ENCRYPTED_RESTIC_OR_KOPIA_BACKEND_CONFIGURED_SEPARATELY',
            'requires_owner_approval_for_restore':True,
        }

    def verify_snapshot(self, snapshot: str) -> dict:
        return history.verify(self._manifest(snapshot))

    def compare(self, old: str, new: str) -> dict:
        return history.compare(self._manifest(old), self._manifest(new))

    def recovery_plan(self, snapshot: str, target: str, include: list[str] | None = None) -> dict:
        m=self._manifest(snapshot)
        t=self._grant(target, self.restore_roots, existing=False)
        return history.plan(m,str(t),include)

    def recovery_stage(self, snapshot: str, target: str, confirmation: str, include: list[str] | None = None) -> dict:
        if confirmation != 'RESTORE TO NEW DIRECTORY':
            raise Denied('Requires exact confirmation RESTORE TO NEW DIRECTORY')
        preview=self.recovery_plan(snapshot,target,include)
        result=history.stage(self._manifest(snapshot),str(preview['target']),include)
        return result | {'promotion_requires_separate_approval':True}

    def reference_event(self, project: str, provider: str, kind: str, ref: str, occurred_at: str) -> dict:
        return history.record_event(self.catalog,_identifier(project),self.owner,provider,kind,ref,occurred_at)

    def connector_preview(self, bundle:dict) -> dict:
        return connector_evidence.preview(bundle,self.owner)

    def connector_import(self, bundle:dict, confirmation:str) -> dict:
        if confirmation != 'IMPORT CONNECTOR REFERENCES':
            raise Denied('Connector evidence import requires local operator write approval')
        return connector_evidence.import_events(self.catalog,bundle,self.owner)

    def connector_events(self, project:str='') -> list[dict]:
        return connector_evidence.list_events(self.catalog,self.owner,project)

    def timeline(self, project: str = '') -> list[dict]:
        native=history.timeline(self.catalog,project or None,self.owner)
        connector=[{'event_id':e['event_id'],'event_type':e['kind'],
                    'project':e['project'],'owner':e['owner'],'provider':e['provider'],
                    'account_alias':e['account_alias'],'provider_ref':e['provider_ref'],
                    'occurred_at':e['occurred_at'],'evidence':e['evidence'],
                    'recoverability':e['recoverability']} for e in self.connector_events(project)]
        return sorted(native+connector,key=lambda e:(e['occurred_at'],e['event_id']))

    def capabilities(self) -> dict:
        return {
            'native': ['file-tree backup with hash verification', 'isolated restore','manifest/timeline/compare'],
            'optional': ['restic or Kopia externally configured encrypted repositories', 'Apple Time Machine for supported device data','PENELOPE recognition (external separately permitted integration)'],
            'not_implemented': ['bootable device image', 'platform-consistent open-database capture', 'cloud credentials management', 'remote device power/control', 'in-place system restore', 'automated JANITOR deletion'],
        }

    def restic_status(self) -> dict:
        exe=shutil.which('restic')
        repository=os.environ.get('RESTIC_REPOSITORY')
        keyfile=os.environ.get('RESTIC_PASSWORD_FILE')
        return {'engine':'restic','binary':bool(exe),'configured':bool(repository and keyfile and Path(keyfile).is_file()),'remote_destination_possible':bool(repository),'secrets_exposed':False}

    def restic_backup(self, source: str, project: str, confirmation: str) -> dict:
        if confirmation != 'CLOUD BACKUP':
            raise Denied('Encrypted optional restic backup requires CLOUD BACKUP confirmation')
        if not self.restic_status()['configured']:
            raise Denied('Install restic and configure RESTIC_REPOSITORY + RESTIC_PASSWORD_FILE locally')
        p=self._grant(source,self.read_roots)
        # Do not expose credential strings or repository URL in results/logs.
        argv=['restic','backup','--json','--tag','delorean:'+_identifier(project),'--tag','delorean-owner:'+self.owner,str(p)]
        completed=subprocess.run(argv,env=os.environ.copy(),stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True,timeout=3600,check=False)
        if completed.returncode:
            raise Denied('restic exited with error; examine local protected logs (credentials not exposed)')
        summary=[json.loads(line) for line in completed.stdout.splitlines() if line.strip().startswith('{') and 'snapshot_id' in line]
        if not summary:
            raise Denied('No restic snapshot proof in result; verify repository before completion')
        # Actual restore test and repository check are independent acceptance gates.
        return {'engine':'restic','snapshot_id':summary[-1].get('snapshot_id'),'status':'ENGINE_REPORTED_SNAPSHOT_NOT_RESTORE_TESTED', 'project':project}

    def time_machine_status(self) -> dict:
        if platform.system()!='Darwin' or not shutil.which('tmutil'):
            return {'available':False,'state':'NOT_MACOS'}
        proc=subprocess.run(['tmutil','listbackups'],capture_output=True,text=True,timeout=30)
        return {'available':True,'exit_code':proc.returncode,'number_of_backups':len([x for x in proc.stdout.splitlines() if x.strip()]),'error':proc.stderr[:200] if proc.returncode else ''}

    def time_machine_start(self, confirmation: str) -> dict:
        if confirmation != 'START EXISTING TIME MACHINE BACKUP':
            raise Denied('Explicit START EXISTING TIME MACHINE BACKUP confirmation required')
        if platform.system()!='Darwin' or not shutil.which('tmutil'):
            raise Denied('Apple Time Machine is unavailable on this host')
        # Does not format/configure destination; only invokes user's established Time Machine plan.
        result=subprocess.run(['tmutil','startbackup','--block'],capture_output=True,text=True,timeout=3600)
        if result.returncode:
            raise Denied('Time Machine reported failure; inspect protected local logs')
        return {'state':'NATIVE_BACKUP_REPORTED_SUCCESS','verification_required':'Confirm backup destination, list backups, rehearse file restore'}



# KOPIA OPTIONAL ADAPTER — delegates encryption/deduplication to an existing
# user-configured Kopia repository. Does not create, prune or migrate a repository.
# This is NOT an OS image, device recovery, or unauthenticated remote interface.
import re as _kopia_re


def _kopia_checked(argv: list[str], timeout: int = 300) -> str:
    exe = shutil.which('kopia')
    if not exe:
        raise Denied('Kopia CLI is not installed on this executor')
    proc = subprocess.run([exe, '--no-progress', *argv], capture_output=True,
                          text=True, timeout=timeout, check=False)
    if proc.returncode:
        # Kopia can print repository URLs / host paths in error text: redact.
        raise Denied('Kopia operation failed; inspect local protected executor logs')
    return proc.stdout


def kopia_status(self: DeLorean) -> dict:
    if not shutil.which('kopia'):
        return {'engine': 'kopia', 'installed': False, 'connected': False,
                'credentials_exposed': False}
    try:
        status = json.loads(_kopia_checked(['repository', 'status', '--json'], 30))
        ok = isinstance(status, dict) and bool(status)
    except (Denied, ValueError, subprocess.TimeoutExpired):
        ok = False
    return {'engine': 'kopia', 'installed': True, 'connected': ok,
            'credentials_exposed': False, 'storage': 'OWNER_CONFIGURED_EXTERNAL_REPOSITORY'}


def _kopia_entries(self: DeLorean, source: str, project: str) -> list[dict]:
    # Kopia is scoped by repository identity AND source AND per-owner/project
    # tags. A trusted on-disk repo alone does not grant any owner access.
    project = _identifier(project)
    path = self._grant(source, self.read_roots, existing=False)
    if not kopia_status(self)['connected']:
        raise Denied('Connect an existing encrypted Kopia repository on executor first')
    raw = json.loads(_kopia_checked(['snapshot','list','--json',
             '--tags','delorean-owner:'+self.owner,
             '--tags','delorean-project:'+project,str(path)], 90))
    if not isinstance(raw, list):
        raise Denied('Unexpected Kopia snapshot list format')
    items = []
    for candidate in raw:
        if not isinstance(candidate, dict):
            continue
        # CLI versions may return direct snapshots or grouped sources.
        group = candidate.get('snapshots')
        rows = group if isinstance(group, list) else [candidate]
        for m in rows:
            if not isinstance(m, dict):
                continue
            tags = m.get('tags')
            if not isinstance(tags, dict):
                continue  # Never infer cross-tenant grants from names/IDs.
            if tags.get('delorean-owner') != self.owner or tags.get('delorean-project') != project:
                continue
            snapshot_id = m.get('id')
            root_id = m.get('rootID')
            if not (isinstance(snapshot_id, str) and _kopia_re.fullmatch('[0-9a-f]{32,64}', snapshot_id)
                    and isinstance(root_id, str) and _kopia_re.fullmatch('k[0-9a-f]{32,64}', root_id)):
                continue
            items.append({'snapshot_id':snapshot_id,'root_id':root_id,
                          'project':project,'owner':self.owner,'time':m.get('endTime'),
                          'engine':'kopia','status':'BACKUP_REFERENCE_NOT_RESTORE_TESTED'})
    return items


def kopia_snapshots(self: DeLorean, source: str, project: str) -> list[dict]:
    return _kopia_entries(self, source, project)


def kopia_backup(self: DeLorean, source: str, project: str, confirmation: str) -> dict:
    if confirmation != 'ENCRYPTED KOPIA BACKUP':
        raise Denied('Kopia snapshot requires exact confirmation')
    project = _identifier(project)
    p = self._grant(source, self.read_roots)
    if not (p.is_file() or p.is_dir()):
        raise Denied('Kopia source must be a real file or directory')
    if not kopia_status(self)['connected']:
        raise Denied('Kopia encrypted repository is not configured on executor')
    # Explicitly DISABLE backup hooks: untrusted repository policies must not
    # execute actions as a consequence of an AI tool invocation.
    result = json.loads(_kopia_checked(['snapshot','create','--json',
        '--force-disable-actions', '--no-send-snapshot-report',
        '--tags','delorean-owner:'+self.owner,
        '--tags','delorean-project:'+project,str(p)],3600))
    if not isinstance(result, dict) or not _kopia_re.fullmatch('[0-9a-f]{32,64}',str(result.get('id',''))):
        raise Denied('Kopia did not provide a valid snapshot receipt')
    if result.get('incomplete'):
        raise Denied('Kopia reported an incomplete snapshot; do not accept as backup')
    return {'engine':'kopia', 'snapshot_id':result['id'], 'project':project,
            'encrypted_by_engine':True, 'verified_restore':False,
            'status':'ENGINE_REPORTED_BACKUP_RESTORE_REHEARSAL_REQUIRED'}


def _authorized_kopia(self: DeLorean, source: str, project: str, snapshot: str) -> dict:
    matches = [x for x in _kopia_entries(self,source,project) if x['snapshot_id']==snapshot]
    if len(matches)!=1:
        raise Denied('Kopia snapshot not found for exact owner, project and source grant')
    return matches[0]


def kopia_verify(self: DeLorean, source: str, project: str, snapshot: str) -> dict:
    m = _authorized_kopia(self,source,project,snapshot)
    # Metadata/index validation, not full blob download/decryption.
    _kopia_checked(['snapshot','verify','--verify-files-percent=0',m['snapshot_id']],3600)
    return {'engine':'kopia','snapshot_id':m['snapshot_id'],
            'status':'INDEX_VERIFIED_BLOB_BYTES_NOT_FULLY_READ',
            'full_restore_tested':False}


def kopia_restore(self: DeLorean, source: str, project: str, snapshot: str,
                  target: str, confirmation: str) -> dict:
    if confirmation != 'RESTORE KOPIA TO NEW DIRECTORY':
        raise Denied('Explicit isolated Kopia restore confirmation required')
    m = _authorized_kopia(self,source,project,snapshot)
    dest = self._grant(target,self.restore_roots,existing=False)
    _must_be_new(dest)
    dest.parent.mkdir(parents=True,exist_ok=True)
    temp = dest.parent / ('.delorean-kopia-stage-' + uuid.uuid4().hex)
    _must_be_new(temp)
    try:
        # Restore into a NEW path, with overwrite and delete disabled. The
        # engine never receives a live application or user working directory.
        _kopia_checked(['snapshot','restore',m['root_id'],str(temp),
          '--no-overwrite-files','--no-overwrite-directories',
          '--no-overwrite-symlinks','--no-delete-extra','--no-ignore-errors',
          '--write-files-atomically'],3600)
        if not temp.exists() or not temp.is_dir():
            raise Denied('Kopia did not create a restored directory')
        files = history.scan(temp) # rejects symlinks and special objects
        _must_be_new(dest)
        temp.rename(dest)
        return {'engine':'kopia','snapshot_id':m['snapshot_id'],
                'status':'ISOLATED_RESTORE_SCANNED_NOT_APP_ACCEPTED',
                'restored_files':len(files),'destination':str(dest),
                'promotion_requires_separate_approval':True}
    finally:
        if temp.exists() and not temp.is_symlink():
            shutil.rmtree(temp)


DeLorean.kopia_status = kopia_status
DeLorean.kopia_snapshots = kopia_snapshots
DeLorean.kopia_backup = kopia_backup
DeLorean.kopia_verify = kopia_verify
DeLorean.kopia_restore = kopia_restore

# Optional PENELOPE interoperability: import non-secret identity references only.
# Deliberately does not invoke, install, or subsume PENELOPE's analysis runtime.
def penelope_import(self: DeLorean, source: str) -> dict:
    p=self._grant(source,self.read_roots)
    if not p.is_file() or p.stat().st_size > 2*1024*1024:
        raise Denied('PENELOPE export must be a regular JSON file under 2 MiB')
    data=json.loads(p.read_text(encoding='utf-8'))
    if data.get('schema') != 'eden.penelope.references.v1' or data.get('owner') != self.owner:
        raise Denied('PENELOPE schema or owner mismatch')
    items=data.get('items')
    if not isinstance(items,list) or len(items)>1000:
        raise Denied('Invalid PENELOPE item count')
    # Validate complete import before first side effect.
    for x in items:
        if not isinstance(x,dict) or not all(isinstance(x.get(k),str) and x.get(k) for k in ('project','reference','time')):
            raise Denied('Incomplete PENELOPE reference')
        _identifier(x['project'])
        if len(x['reference'])>512 or len(x['time'])>64:
            raise Denied('PENELOPE reference too long')
        # Timestamp validation without side effects.
        from datetime import datetime
        t=datetime.fromisoformat(x['time'].replace('Z','+00:00'))
        if t.tzinfo is None:
            raise Denied('PENELOPE timestamps require timezone')
    for x in items:
        self.reference_event(x['project'],'PENELOPE','FILE_RELATIONSHIP_REFERENCE',x['reference'],x['time'])
    return {'imported_references':len(items),'owner':self.owner, 'state':'REFERENCES_ONLY_NO_FILE_BACKUP'}

DeLorean.penelope_import=penelope_import


def _restic_checked(self: DeLorean, argv: list[str], timeout:int=300) -> str:
    if not self.restic_status()['configured']:
        raise Denied('restic must be installed/configured on the executor host')
    proc=subprocess.run(['restic',*argv],env=os.environ.copy(),stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True,timeout=timeout,check=False)
    if proc.returncode:
        raise Denied('restic operation failed; inspect protected local engine logs')
    return proc.stdout


def restic_snapshots(self: DeLorean, project:str) -> list[dict]:
    name=_identifier(project)
    items=json.loads(_restic_checked(self,['snapshots','--json']))
    if not isinstance(items,list):
        raise Denied('Invalid restic snapshot listing')
    allowed=[]
    for x in items:
        if not isinstance(x,dict):continue
        tags=x.get('tags',[])
        if 'delorean:'+name in tags and 'delorean-owner:'+self.owner in tags:
            sid=x.get('id')
            if isinstance(sid,str) and len(sid)>=8 and all(ch in '0123456789abcdef' for ch in sid):
                allowed.append({'snapshot_id':sid,'project':name,'time':x.get('time'),'status':'BACKUP_ENGINE_REFERENCE_NOT_RESTORE_TESTED'})
    return allowed


def restic_restore(self: DeLorean, project:str, snapshot:str, target:str, confirmation:str) -> dict:
    if confirmation!='RESTORE CLOUD SNAPSHOT TO NEW DIRECTORY':
        raise Denied('Requires exact RESTORE CLOUD SNAPSHOT TO NEW DIRECTORY confirmation')
    candidates=restic_snapshots(self,project)
    matches=[s for s in candidates if s['snapshot_id']==snapshot]
    if len(matches)!=1:
        raise Denied('Requested restic snapshot is not authorized for current owner/project')
    dest=self._grant(target,self.restore_roots,existing=False)
    _must_be_new(dest)
    dest.parent.mkdir(parents=True,exist_ok=True)
    temporary=dest.parent/('.delorean-restic-stage-'+uuid.uuid4().hex)
    _must_be_new(temporary)
    try:
        temporary.mkdir(mode=0o700)
        _restic_checked(self,['restore',snapshot,'--target',str(temporary),'--overwrite','never'],timeout=3600)
        # Do not promote an unexpected symlink, special file or corrupt tree.
        files=history.scan(temporary)
        _must_be_new(dest)
        temporary.rename(dest)
        return {'status':'ISOLATED_ENGINE_RESTORE_FILES_SCANNED','destination':str(dest),
                'snapshot_id':snapshot,'files':len(files),
                'note':'Independent hash comparison/recovery rehearsal against source needed before production promotion'}
    finally:
        if temporary.exists():shutil.rmtree(temporary)


def restic_check(self: DeLorean) -> dict:
    _restic_checked(self,['check'],timeout=3600)
    return {'engine':'restic','status':'REPOSITORY_CONSISTENCY_CHECK_PASSED','full_restoration':'NOT_PROVEN'}


DeLorean.restic_snapshots=restic_snapshots
DeLorean.restic_restore=restic_restore
DeLorean.restic_check=restic_check
