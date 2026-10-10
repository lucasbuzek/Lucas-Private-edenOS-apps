"""Portable BIFROST DP0.1 kernel: filesystem -> stable IDs -> SQLite -> API/CLI.
Standard-library Python 3.9+. No OS service, app, cloud or AI dependency.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import mimetypes
import os
from pathlib import Path
import sqlite3
import stat
import sys
import time

VERSION = 1
BLOCK = 1024 * 1024
SKIP = frozenset(('.git','.svn','.hg','.ssh','.aws','.gnupg','.venv',
                  '.cache','node_modules','__pycache__','.env','.npmrc',
                  '.netrc','headless.token','id_rsa','id_ed25519','.DS_Store'))
CLASS = {'.jpg':'image','.jpeg':'image','.png':'image','.webp':'image',
         '.heic':'image','.pdf':'document','.docx':'document','.md':'document',
         '.txt':'document','.xlsx':'document','.pptx':'document',
         '.mp4':'video','.mov':'video','.mkv':'video',
         '.mp3':'audio','.flac':'audio','.wav':'audio',
         '.zip':'archive','.tar':'archive','.7z':'archive',
         '.py':'source','.swift':'source','.js':'source','.json':'source',
         '.html':'source','.css':'source','.ts':'source','.rs':'source'}
# Canonical MIME assignments take precedence over OS-specific registries.
MIME = {
    '.md':'text/markdown','.txt':'text/plain','.json':'application/json',
    '.py':'text/x-python','.swift':'text/x-swift','.js':'text/javascript',
    '.ts':'text/typescript','.html':'text/html','.css':'text/css',
    '.pdf':'application/pdf','.png':'image/png','.jpg':'image/jpeg',
    '.jpeg':'image/jpeg','.webp':'image/webp','.heic':'image/heic',
    '.mp4':'video/mp4','.mov':'video/quicktime','.mkv':'video/x-matroska',
    '.mp3':'audio/mpeg','.flac':'audio/flac','.wav':'audio/wav',
    '.zip':'application/zip','.tar':'application/x-tar'
}

class KernelError(ValueError):
    pass

def digest(text):
    return hashlib.sha256(text.encode('utf-8')).hexdigest()

def now():
    return time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime())

def hash_file(path,maximum):
    flags = os.O_RDONLY | getattr(os,'O_NOFOLLOW',0) | getattr(os,'O_BINARY',0)
    fd = os.open(str(path), flags)
    try:
        before = os.fstat(fd)
        if not stat.S_ISREG(before.st_mode) or before.st_size>maximum:
            raise KernelError('not regular or exceeds max bytes')
        h=hashlib.sha256()
        total=0
        while True:
            chunk=os.read(fd,BLOCK)
            if not chunk: break
            total+=len(chunk)
            if total>maximum: raise KernelError('file exceeded max bytes while reading')
            h.update(chunk)
        after=os.fstat(fd)
        if (before.st_ino,before.st_size,before.st_mtime_ns)!=(after.st_ino,after.st_size,after.st_mtime_ns) or total!=after.st_size:
            raise KernelError('file changed while reading')
        return h.hexdigest(),total,after.st_mtime_ns
    finally:
        os.close(fd)

class Kernel:
    def __init__(self,database):
        self.database=Path(database).expanduser()
        self.database.parent.mkdir(parents=True,exist_ok=True)
        self.db=sqlite3.connect(str(self.database),timeout=10,isolation_level=None)
        self.db.row_factory=sqlite3.Row
        self.db.execute('PRAGMA foreign_keys=ON')
        self.db.execute('PRAGMA journal_mode=WAL')
        self.db.execute('PRAGMA busy_timeout=10000')
        version=self.db.execute('PRAGMA user_version').fetchone()[0]
        if version>VERSION or version not in (0,VERSION):
            self.db.close()
            raise KernelError('unsupported/newer schema')
        if version==0:
            self.db.executescript("""
              CREATE TABLE IF NOT EXISTS sources(
                id TEXT PRIMARY KEY,provider TEXT NOT NULL,root TEXT NOT NULL,
                platform TEXT NOT NULL,last_completed TEXT);
              CREATE TABLE IF NOT EXISTS objects(
                id TEXT PRIMARY KEY,kind TEXT NOT NULL,digest TEXT,
                mime TEXT NOT NULL,classification TEXT NOT NULL,bytes INTEGER NOT NULL);
              CREATE TABLE IF NOT EXISTS locations(
                id TEXT PRIMARY KEY,source TEXT NOT NULL REFERENCES sources(id),
                object TEXT NOT NULL REFERENCES objects(id),
                relative TEXT NOT NULL,mtime_ns INTEGER,active INTEGER NOT NULL,
                seen TEXT NOT NULL,UNIQUE(source,relative));
              CREATE INDEX IF NOT EXISTS ix_locations_object ON locations(object);
              CREATE TABLE IF NOT EXISTS relations(
                parent TEXT NOT NULL REFERENCES objects(id),
                child TEXT NOT NULL REFERENCES objects(id),
                source TEXT NOT NULL REFERENCES sources(id),
                type TEXT NOT NULL,PRIMARY KEY(parent,child,source,type));
              CREATE TABLE IF NOT EXISTS provenance(
                id INTEGER PRIMARY KEY AUTOINCREMENT,object TEXT REFERENCES objects(id),
                location TEXT REFERENCES locations(id),source TEXT REFERENCES sources(id),
                event TEXT NOT NULL,at TEXT NOT NULL,details TEXT NOT NULL);
              CREATE TABLE IF NOT EXISTS runs(
                id INTEGER PRIMARY KEY AUTOINCREMENT,source TEXT NOT NULL REFERENCES sources(id),
                state TEXT NOT NULL,files INTEGER NOT NULL,skipped INTEGER NOT NULL,at TEXT NOT NULL);
              PRAGMA user_version=1;
            """)

    def __enter__(self): return self
    def __exit__(self,*_): self.db.close()
    def close(self): self.db.close()

    def scan(self,path,*,max_files=2000,max_bytes=512*1024*1024,max_depth=16,
             max_total_bytes=1024*1024*1024):
        if (not 1<=max_files<=100000 or not 1<=max_bytes<=8*1024**3 or
            not 1<=max_total_bytes<=64*1024**3 or not 0<=max_depth<=256):
            raise KernelError('limits out of range')
        source=Path(path).expanduser()
        if source.is_symlink() or not source.is_dir():
            raise KernelError('source must be a non-symlink directory')
        root=source.resolve(strict=True)
        if self.database.resolve()==root or root in self.database.resolve().parents:
            raise KernelError('index must be outside scanned tree')
        sid='src_'+digest(os.path.normcase(str(root)))[:32]
        at=now()
        files=0
        bytes_hashed=0
        budget_exhausted=False
        skipped=0
        incomplete=False
        errors=[]
        visited=set()
        relations=set()
        db=self.db
        db.execute('BEGIN IMMEDIATE')
        try:
            db.execute('INSERT INTO sources(id,provider,root,platform) VALUES(?,?,?,?) '
                       'ON CONFLICT(id) DO UPDATE SET root=excluded.root,platform=excluded.platform',
                       (sid,'filesystem',str(root),sys.platform))
            def obj(oid,kind,hashval,mime,classification,size):
                db.execute('INSERT OR IGNORE INTO objects VALUES(?,?,?,?,?,?)',
                           (oid,kind,hashval,mime,classification,size))
            def location(oid,relative,mtime=None):
                lid='loc_'+digest(sid+'\x00'+relative)[:40]
                previous=db.execute('SELECT object,active FROM locations WHERE id=?',(lid,)).fetchone()
                db.execute('INSERT INTO locations VALUES(?,?,?,?,?,?,?) '
                           'ON CONFLICT(id) DO UPDATE SET object=excluded.object, '
                           'mtime_ns=excluded.mtime_ns,active=1,seen=excluded.seen',
                           (lid,sid,oid,relative,mtime,1,at))
                visited.add(lid)
                if previous is not None and previous['object']!=oid:
                    db.execute('INSERT OR IGNORE INTO relations VALUES(?,?,?,?)',
                               (oid,previous['object'],sid,'supersedes'))
                if previous is None or previous['object']!=oid or not previous['active']:
                    db.execute('INSERT INTO provenance(object,location,source,event,at,details) '
                               'VALUES(?,?,?,?,?,?)',
                               (oid,lid,sid,'observed' if previous is None else 'changed',at,
                                '{"provider":"filesystem"}'))
            def dirid(rel):
                return 'dir_'+digest(sid+'\x00'+rel)[:40]
            obj(dirid('.'),'directory',None,'inode/directory','directory',0)
            location(dirid('.'),'.')
            def walk_error(exc):
                nonlocal incomplete
                incomplete=True
                if len(errors)<10: errors.append(type(exc).__name__)
            for current,subdirs,filenames in os.walk(str(root),topdown=True,followlinks=False,onerror=walk_error):
                current_path=Path(current)
                if current_path.is_symlink() or root not in (current_path.resolve(),*current_path.resolve().parents):
                    incomplete=True
                    subdirs[:]=[]
                    continue
                rel=os.path.relpath(current,str(root)).replace(os.sep,'/')
                depth=0 if rel=='.' else len(Path(rel).parts)
                parent=dirid(rel)
                chosen=[]
                for name in sorted(subdirs):
                    candidate=current_path/name
                    if name in SKIP or name.startswith('.') or candidate.is_symlink():
                        skipped+=1
                        continue
                    if depth>=max_depth:
                        incomplete=True
                        continue
                    chosen.append(name)
                subdirs[:]=chosen
                for name in chosen:
                    childrel=name if rel=='.' else rel+'/'+name
                    child=dirid(childrel)
                    obj(child,'directory',None,'inode/directory','directory',0)
                    location(child,childrel)
                    relations.add((parent,child,sid,'contains'))
                    db.execute('INSERT OR IGNORE INTO relations VALUES(?,?,?,?)',
                               (parent,child,sid,'contains'))
                for name in sorted(filenames):
                    if files>=max_files:
                        incomplete=True
                        break
                    if name in SKIP or name.startswith('.'):
                        skipped+=1
                        continue
                    file=current_path/name
                    relative=name if rel=='.' else rel+'/'+name
                    if file.is_symlink():
                        skipped+=1
                        continue
                    try:
                        actual=file.resolve(strict=True)
                        if root not in actual.parents:
                            raise KernelError('outside authorized root')
                        if bytes_hashed + os.stat(str(file),follow_symlinks=False).st_size > max_total_bytes:
                            incomplete=True
                            budget_exhausted=True
                            errors.append('total read budget reached')
                            break
                        finger,size,mtime=hash_file(file,max_bytes)
                        oid='sha256_'+finger
                        mime=MIME.get(file.suffix.lower()) or mimetypes.guess_type(name)[0] or 'application/octet-stream'
                        classification=CLASS.get(file.suffix.lower(),'unknown')
                        obj(oid,'file',finger,mime,classification,size)
                        location(oid,relative,mtime)
                        relations.add((parent,oid,sid,'contains'))
                        db.execute('INSERT OR IGNORE INTO relations VALUES(?,?,?,?)',
                                   (parent,oid,sid,'contains'))
                        files+=1
                        bytes_hashed+=size
                    except (KernelError,OSError) as err:
                        incomplete=True
                        skipped+=1
                        if len(errors)<10: errors.append(relative+': '+type(err).__name__)
                if budget_exhausted or (incomplete and files>=max_files):
                    break
            if not incomplete:
                for row in list(db.execute('SELECT id,object FROM locations WHERE source=? AND active=1',(sid,))):
                    if row['id'] not in visited:
                        db.execute('UPDATE locations SET active=0 WHERE id=?',(row['id'],))
                        db.execute('INSERT INTO provenance(object,location,source,event,at,details) '
                                   'VALUES(?,?,?,?,?,?)',
                                   (row['object'],row['id'],sid,'location_missing',at,'{}'))
                for row in list(db.execute("SELECT parent,child,source,type FROM relations WHERE source=? AND type='contains'",(sid,))):
                    if tuple(row) not in relations:
                        db.execute('DELETE FROM relations WHERE parent=? AND child=? AND source=? AND type=?',
                                   tuple(row))
                db.execute('UPDATE sources SET last_completed=? WHERE id=?',(at,sid))
            state='PARTIAL' if incomplete else 'COMPLETE'
            rid=db.execute('INSERT INTO runs(source,state,files,skipped,at) VALUES(?,?,?,?,?)',
                           (sid,state,files,skipped,at)).lastrowid
            db.commit()
            return dict(schema='bifrost.dp0.1',version=VERSION,source_id=sid,run_id=rid,
                        state=state,indexed_files=files,bytes_hashed=bytes_hashed,
                        skipped=skipped,errors=errors)
        except BaseException:
            db.rollback()
            raise

    def status(self):
        db=self.db
        count=lambda table: db.execute('SELECT COUNT(*) FROM '+table).fetchone()[0]
        last=db.execute('SELECT id,source,state,files,skipped,at FROM runs ORDER BY id DESC LIMIT 1').fetchone()
        return dict(schema='bifrost.dp0.1',version=VERSION,sources=count('sources'),
                    objects=count('objects'),locations=count('locations'),
                    relationships=count('relations'),provenance=count('provenance'),
                    last_run=dict(last) if last else None)

    def search(self,term,limit=25):
        if not isinstance(term,str) or not term.strip() or not 1<=len(term)<=128 or not isinstance(limit,int) or not 1<=limit<=100:
            raise KernelError('invalid search query/limit')
        escaped=term.replace('\\','\\\\').replace('%','\\%').replace('_','\\_')
        needle='%'+escaped+'%'
        rows=self.db.execute("""
          SELECT o.id AS object_id,o.classification,o.mime,o.bytes,l.source,l.relative
          FROM locations l JOIN objects o ON l.object=o.id
          WHERE l.active=1 AND (l.relative LIKE ? ESCAPE '\\'
             OR o.classification LIKE ? ESCAPE '\\')
          ORDER BY l.relative COLLATE NOCASE,l.source LIMIT ?
        """,(needle,needle,limit)).fetchall()
        return [dict(row) for row in rows]

    def detail(self,oid):
        found=self.db.execute('SELECT * FROM objects WHERE id=?',(oid,)).fetchone()
        if found is None: return None
        return dict(object=dict(found),
                    locations=[dict(r) for r in self.db.execute(
                        'SELECT source,relative,active,seen FROM locations WHERE object=? ORDER BY source,relative',(oid,))],
                    provenance=[dict(r) for r in self.db.execute(
                        'SELECT event,at,details FROM provenance WHERE object=? ORDER BY id DESC LIMIT 50',(oid,))],
                    relations=[dict(r) for r in self.db.execute(
                        'SELECT parent,child,source,type FROM relations WHERE parent=? OR child=?',(oid,oid))])

def main(argv=None):
    parser=argparse.ArgumentParser(description='BIFROST offline DP0.1 core')
    parser.add_argument('--db',required=True)
    sub=parser.add_subparsers(dest='command',required=True)
    scan=sub.add_parser('scan')
    scan.add_argument('directory')
    scan.add_argument('--max-files',type=int,default=2000)
    scan.add_argument('--max-bytes',type=int,default=512*1024*1024)
    scan.add_argument('--max-depth',type=int,default=16)
    scan.add_argument('--max-total-bytes',type=int,default=1024*1024*1024)
    sub.add_parser('status')
    search=sub.add_parser('search')
    search.add_argument('term')
    detail=sub.add_parser('object')
    detail.add_argument('id')
    args=parser.parse_args(argv)
    try:
        with Kernel(args.db) as core:
            if args.command=='scan':
                value=core.scan(args.directory,max_files=args.max_files,
                                max_bytes=args.max_bytes,max_depth=args.max_depth,
                                max_total_bytes=args.max_total_bytes)
            elif args.command=='status': value=core.status()
            elif args.command=='search': value=core.search(args.term)
            else: value=core.detail(args.id)
        print(json.dumps(value,indent=2))
        return 2 if isinstance(value,dict) and value.get('state')=='PARTIAL' else 0
    except (OSError,sqlite3.Error,KernelError) as error:
        print(type(error).__name__+': '+str(error),file=sys.stderr)
        return 1
if __name__=='__main__':
    raise SystemExit(main())
