#!/usr/bin/env python3
"""DeLorean offline federated snapshot INDEX + verified isolated restore adapter.

Does not create backup payloads, schedule backups, mutate existing sources,
manage credentials, or replace PENELOPE/Time Machine/Git. Python >=3.10.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import stat
import sys
import tempfile
from datetime import datetime, timezone

SCHEMA = 'eden.delorean.snapshot.v1'
CATALOG_SCHEMA = 'eden.delorean.catalog.v1'
MAX_MANIFEST_BYTES = 16 * 1024 * 1024

class RecoveryError(Exception):
    pass

def stamp():
    return datetime.now(timezone.utc).isoformat(timespec='seconds')

def _hash(file: Path) -> str:
    h = hashlib.sha256()
    with file.open('rb') as f:
        while data := f.read(1024 * 1024):
            h.update(data)
    return h.hexdigest()

def _is_within(path: Path, parent: Path) -> bool:
    try:
        path.relative_to(parent)
        return True
    except ValueError:
        return False

def _safe_relpath(value: str) -> Path:
    # Treat manifest paths as POSIX-independent '/' paths, never OS absolutes.
    if not isinstance(value, str) or not value or '\\' in value or '\x00' in value:
        raise RecoveryError('Invalid snapshot file path')
    rel = Path(value)
    if rel.is_absolute() or any(x in ('.', '..', '') for x in value.split('/')):
        raise RecoveryError('Unsafe relative path')
    return rel

def _root(path: str) -> Path:
    p = Path(path).expanduser().absolute()
    if not p.is_dir() or p.is_symlink():
        raise RecoveryError('Source must be an existing non-symlink folder')
    return p.resolve(strict=True)

def scan(root: Path) -> list[dict]:
    files = []
    for directory, subdirs, names in os.walk(root, topdown=True, followlinks=False):
        subdirs.sort()
        names.sort()
        d = Path(directory)
        for dirname in subdirs:
            target = d / dirname
            if target.is_symlink():
                raise RecoveryError('Symlink directory not supported: ' + str(target))
        for name in names:
            f = d / name
            if f.is_symlink() or not f.is_file():
                raise RecoveryError('Symlink or special file rejected: ' + str(f))
            mode = f.stat().st_mode
            if not stat.S_ISREG(mode):
                raise RecoveryError('Non-regular file rejected')
            rel = f.relative_to(root).as_posix()
            _safe_relpath(rel)
            files.append({'path': rel, 'sha256': _hash(f), 'size': f.stat().st_size})
    return files

def catalogue_files(folder: Path) -> list[Path]:
    if not folder.exists():
        return []
    return sorted(p for p in folder.glob('*.json') if p.is_file() and not p.is_symlink())

def load_manifest(path: Path) -> dict:
    if path.stat().st_size > MAX_MANIFEST_BYTES:
        raise RecoveryError('Manifest exceeds size limit')
    try:
        m = json.loads(path.read_text(encoding='utf-8'))
    except (OSError, ValueError) as exc:
        raise RecoveryError('Invalid manifest JSON') from exc
    if m.get('schema') != SCHEMA or not isinstance(m.get('files'), list):
        raise RecoveryError('Unsupported snapshot schema')
    seen = set()
    for f in m['files']:
        if not isinstance(f, dict):
            raise RecoveryError('Invalid file entry')
        p = str(_safe_relpath(f.get('path')))
        if p in seen:
            raise RecoveryError('Duplicate file path in manifest')
        seen.add(p)
        h = f.get('sha256')
        if not isinstance(h, str) or len(h) != 64 or any(c not in '0123456789abcdef' for c in h):
            raise RecoveryError('Invalid SHA-256')
        if type(f.get('size')) is not int or f['size'] < 0:
            raise RecoveryError('Invalid file size')
    return m

def register(catalog: Path, project: str, source: str, provider: str = 'local-backup', ref: str = '', owner: str = 'LucasPRIVATE') -> dict:
    if not project.strip() or not owner.strip() or not provider.strip():
        raise RecoveryError('Project, owner and provider are required')
    root = _root(source)
    catalog = catalog.expanduser().absolute().resolve()
    if _is_within(catalog, root) or _is_within(root, catalog):
        raise RecoveryError('Catalog and backup must be separate')
    files = scan(root)
    digest = hashlib.sha256(json.dumps({'project': project, 'root': str(root), 'files': files, 'ref': ref, 'owner': owner}, sort_keys=True).encode()).hexdigest()
    m = {'schema': SCHEMA, 'snapshot_id': digest[:24], 'project': project, 'owner': owner,
         'provider': provider, 'provider_ref': ref, 'source_root': str(root),
         'recorded_at': stamp(), 'files': files, 'content_sha256': digest,
         'evidence': 'INDEXED_HASHED_NOT_RESTORE_TESTED', 'backup_created_by_delorean': False}
    catalog.mkdir(parents=True, exist_ok=True)
    dest = catalog / (m['snapshot_id'] + '.json')
    if dest.exists():
        old = load_manifest(dest)
        if old.get('content_sha256') != m['content_sha256']:
            raise RecoveryError('Snapshot ID collision')
        return old
    data = (json.dumps(m, ensure_ascii=False, indent=2, sort_keys=True) + '\n').encode()
    fd, tmp = tempfile.mkstemp(prefix='.delorean_', dir=str(catalog))
    try:
        with os.fdopen(fd, 'wb') as f:
            f.write(data)
            f.flush()
            os.fsync(f.fileno())
        os.replace(tmp, dest)
    finally:
        if os.path.exists(tmp):
            os.unlink(tmp)
    return m

def find(catalog: Path, ident: str) -> dict:
    if not ident or any(x not in '0123456789abcdef' for x in ident):
        raise RecoveryError('Snapshot ID must be hexadecimal')
    matches = []
    for f in catalogue_files(catalog):
        if f.stem.startswith(ident):
            matches.append(f)
    if len(matches) != 1:
        raise RecoveryError('Snapshot missing or ambiguous')
    return load_manifest(matches[0])

def verify(m: dict) -> dict:
    root = _root(m['source_root'])
    expected = {f['path']: f for f in m['files']}
    current = {f['path']: f for f in scan(root)}
    changed = sorted(k for k in expected.keys() & current.keys() if expected[k] != current[k])
    missing = sorted(expected.keys() - current.keys())
    extra = sorted(current.keys() - expected.keys())
    return {'snapshot_id': m['snapshot_id'], 'ok': not(changed or missing or extra), 'changed': changed, 'missing': missing, 'extra': extra, 'files_checked': len(expected)}

def compare(a: dict, b: dict) -> dict:
    if a['project'] != b['project'] or a['owner'] != b['owner']:
        raise RecoveryError('Cross-project or cross-owner comparison denied')
    x = {f['path']: f for f in a['files']}
    y = {f['path']: f for f in b['files']}
    return {'project': a['project'], 'owner': a['owner'], 'from': a['snapshot_id'], 'to': b['snapshot_id'],
            'added': sorted(y.keys() - x.keys()), 'removed': sorted(x.keys() - y.keys()),
            'modified': sorted(k for k in x.keys() & y.keys() if x[k] != y[k])}

def plan(m: dict, target: str) -> dict:
    dst = Path(target).expanduser().absolute()
    src = _root(m['source_root'])
    if _is_within(dst, src) or _is_within(src, dst):
        raise RecoveryError('Restore target must not contain source or be inside source')
    if dst.is_symlink() or any(p.is_symlink() for p in dst.parents):
        raise RecoveryError('Symlinked destination path denied')
    if dst.exists():
        raise RecoveryError('Restore destination already exists; no overwrite, even if empty')
    v = verify(m)
    if not v['ok']:
        raise RecoveryError('Source backup no longer matches manifest')
    return {'action': 'STAGE_ONLY_NO_OVERWRITE', 'snapshot_id': m['snapshot_id'], 'project': m['project'],
            'owner': m['owner'], 'target': str(dst), 'files': len(m['files']),
            'bytes': sum(f['size'] for f in m['files']), 'source_verified': True,
            'promotion_to_live': 'NOT_AUTHORIZED_BY_THIS_TOOL'}

def stage(m: dict, target: str) -> dict:
    instructions = plan(m, target)
    src = _root(m['source_root'])
    dst = Path(instructions['target'])
    dst.parent.mkdir(parents=True, exist_ok=True)
    temp = Path(tempfile.mkdtemp(prefix='.delorean-stage-', dir=str(dst.parent)))
    try:
        for file in m['files']:
            rel = _safe_relpath(file['path'])
            from_path = src / rel
            # Verify live content directly before copy, never follow source symlinks.
            if from_path.is_symlink() or not from_path.is_file() or _hash(from_path) != file['sha256']:
                raise RecoveryError('Source changed during restore; refusing stage')
            destination = temp / rel
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(from_path, destination, follow_symlinks=False)
            if _hash(destination) != file['sha256']:
                raise RecoveryError('Copied file integrity failure')
        staged = {f['path']: f for f in scan(temp)}
        if staged != {f['path']: f for f in m['files']}:
            raise RecoveryError('Staged content differs from manifest')
        if dst.exists():
            raise RecoveryError('Destination became occupied before promotion')
        temp.rename(dst)
        return {'restored_to': str(dst), 'snapshot_id': m['snapshot_id'], 'status': 'ISOLATED_RESTORE_VERIFIED', 'files': len(m['files'])}
    finally:
        if temp.exists():
            shutil.rmtree(temp)

def export(catalog: Path, path: Path):
    manifests = [load_manifest(p) for p in catalogue_files(catalog)]
    # Strip physical source paths for sharing with the mobile read-only companion.
    sanitized = []
    for m in manifests:
        public = {k:v for k,v in m.items() if k not in ('source_root',)}
        sanitized.append(public)
    data = {'schema': CATALOG_SCHEMA, 'exported_at': stamp(), 'snapshots': sorted(sanitized, key=lambda m:m['recorded_at'])}
    dst = path.expanduser().absolute()
    if dst.exists():
        raise RecoveryError('Export already exists; no-clobber')
    dst.parent.mkdir(parents=True, exist_ok=True)
    with dst.open('x', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write('\n')
    return data

def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--catalog', required=True, help='Dedicated JSON manifest directory (never backup payload storage)')
    commands = parser.add_subparsers(dest='action', required=True)
    r = commands.add_parser('register', help='Hash and index an ALREADY EXISTING backup directory; no backup copy')
    r.add_argument('--project', required=True)
    r.add_argument('--root', required=True)
    r.add_argument('--provider', default='local-backup')
    r.add_argument('--ref', default='')
    r.add_argument('--owner', default='LucasPRIVATE')
    commands.add_parser('list')
    v = commands.add_parser('verify'); v.add_argument('snapshot')
    c = commands.add_parser('compare'); c.add_argument('old'); c.add_argument('new')
    p = commands.add_parser('plan-restore'); p.add_argument('snapshot'); p.add_argument('--target', required=True)
    t = commands.add_parser('stage-restore'); t.add_argument('snapshot'); t.add_argument('--target', required=True)
    e = commands.add_parser('export'); e.add_argument('--output', required=True)
    args = parser.parse_args(argv)
    catalog = Path(args.catalog)
    try:
        if args.action == 'register': result = register(catalog, args.project, args.root, args.provider, args.ref, args.owner)
        elif args.action == 'list': result = [{'snapshot_id':m['snapshot_id'], 'project':m['project'], 'owner':m['owner'], 'provider':m['provider'], 'recorded_at':m['recorded_at'], 'files':len(m['files'])} for m in [load_manifest(f) for f in catalogue_files(catalog)]]
        elif args.action == 'verify': result = verify(find(catalog, args.snapshot))
        elif args.action == 'compare': result = compare(find(catalog,args.old), find(catalog,args.new))
        elif args.action == 'plan-restore': result = plan(find(catalog,args.snapshot),args.target)
        elif args.action == 'stage-restore': result = stage(find(catalog,args.snapshot),args.target)
        else: result = export(catalog,Path(args.output))
    except (RecoveryError, OSError, ValueError) as exc:
        print(json.dumps({'ok': False, 'error': str(exc)}), file=sys.stderr)
        return 2
    print(json.dumps(result, indent=2))
    return 0

if __name__ == '__main__':
    sys.exit(main())
