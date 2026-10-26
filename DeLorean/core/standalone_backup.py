"""DeLorean standalone on-demand backup/restore facade, independent of PENELOPE/cloud.

The file-tree adapter is deliberately scoped to explicitly allowed directories; it
is NOT a disk image, application-consistent database snapshot or OS recovery tool.
Optional restic/Time Machine adapters delegate those jobs to existing engines.
No daemon, key escrow, implicit cloud upload, service install or destructive restore.
"""
from __future__ import annotations

import json
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
except ImportError:
    import timemachine as history


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
            'identity': 'EDEN/edenOS TimeMachine—DeLorean',
            'runtime': 'standalone-stdio-on-demand', 'owner': self.owner,
            'system': platform.system(),
            'catalog_exists': self.catalog.is_dir(),
            'read_grants': len(self.read_roots), 'restore_grants': len(self.restore_roots),
            'cloud_enabled': bool(os.environ.get('RESTIC_REPOSITORY') and os.environ.get('RESTIC_PASSWORD_FILE')),
            'restic_available': shutil.which('restic') is not None,
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

    def timeline(self, project: str = '') -> list[dict]:
        return history.timeline(self.catalog,project or None,self.owner)

    def capabilities(self) -> dict:
        return {
            'native': ['file-tree backup with hash verification', 'isolated restore','manifest/timeline/compare'],
            'optional': ['restic external encrypted remote repository', 'Apple Time Machine for supported device data','PENELOPE recognition (external separately permitted integration)'],
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
