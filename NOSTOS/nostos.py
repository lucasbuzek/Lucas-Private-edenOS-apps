#!/usr/bin/env python3
"""NOSTOS local-first household service candidate (stdlib only)."""
from __future__ import annotations
import json, os, sqlite3, tempfile, threading, hmac, math, secrets
from contextlib import contextmanager
from datetime import datetime, timezone, date
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse, parse_qs

VERSION = "0.1.0-dev.2-security-candidate"
OWNER_TOKEN = os.environ.get("NOSTOS_OWNER_TOKEN", "")
RESTORE_ENABLED = os.environ.get("NOSTOS_ENABLE_RESTORE") == "1"
PORT = int(os.environ.get("NOSTOS_PORT", "8787"))
HOST = os.environ.get("NOSTOS_HOST", "127.0.0.1")
DATA_DIR = Path(os.environ.get("NOSTOS_DATA_DIR", str(Path.home()/"Library/Application Support/NOSTOS"))).expanduser()
DB_PATH = DATA_DIR / "nostos.sqlite3"
WEB_ROOT = Path(__file__).resolve().parent / "web"
LOCK = threading.RLock()
KINDS = {"members", "spaces", "assets", "supplies", "chores", "maintenance", "records"}
MAX_BODY = 16 * 1024 * 1024

def now(): return datetime.now(timezone.utc).isoformat(timespec="seconds")
def connect(path=None):
    c=sqlite3.connect(str(path or DB_PATH), timeout=10)
    c.row_factory=sqlite3.Row
    c.execute("PRAGMA foreign_keys=ON")
    c.execute("PRAGMA busy_timeout=10000")
    return c

@contextmanager
def db(path=None):
    c=connect(path)
    try:
        yield c
        c.commit()
    except Exception:
        c.rollback()
        raise
    finally:
        c.close()

def init_db(path=None):
    if path is None: DATA_DIR.mkdir(parents=True, exist_ok=True)
    with db(path) as c:
        c.execute("PRAGMA journal_mode=WAL")
        c.execute("CREATE TABLE IF NOT EXISTS items (id INTEGER PRIMARY KEY AUTOINCREMENT, kind TEXT NOT NULL, title TEXT NOT NULL, details TEXT NOT NULL DEFAULT '', status TEXT NOT NULL DEFAULT 'active', quantity REAL, location TEXT NOT NULL DEFAULT '', due_date TEXT NOT NULL DEFAULT '', created_at TEXT NOT NULL, updated_at TEXT NOT NULL, data_json TEXT NOT NULL DEFAULT '{}')")
        c.execute("CREATE INDEX IF NOT EXISTS items_kind_updated ON items(kind, updated_at DESC)")
        c.execute("CREATE TABLE IF NOT EXISTS meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)")
        c.execute("INSERT OR IGNORE INTO meta(key,value) VALUES('schema_version','1')")

def item_dict(row):
    d=dict(row); d['data']=json.loads(d.pop('data_json') or '{}'); return d

def parse_item(body, existing=None):
    data=body if isinstance(body,dict) else {}
    title=str(data.get('title', (existing or {}).get('title',''))).strip()
    if not title or len(title)>240: raise ValueError('title is required and must be 240 characters or fewer')
    kind=str(data.get('kind',(existing or {}).get('kind',''))).strip().lower()
    if kind not in KINDS: raise ValueError('kind must be one of: '+', '.join(sorted(KINDS)))
    details=str(data.get('details',(existing or {}).get('details',''))).strip()[:10000]
    status=str(data.get('status',(existing or {}).get('status','active'))).strip().lower()
    if status not in {'active','open','in_progress','done','archived','needs_attention'}: raise ValueError('unsupported status')
    quantity=data.get('quantity',(existing or {}).get('quantity'))
    if quantity is not None:
        try: quantity=float(quantity)
        except (TypeError,ValueError): raise ValueError('quantity must be numeric')
        if not math.isfinite(quantity): raise ValueError('quantity must be finite')
        if quantity<0: raise ValueError('quantity cannot be negative')
    location=str(data.get('location',(existing or {}).get('location',''))).strip()[:500]
    due_date=str(data.get('due_date',(existing or {}).get('due_date',''))).strip()
    if due_date:
        try:
            if date.fromisoformat(due_date).isoformat() != due_date: raise ValueError('date must use YYYY-MM-DD')
        except ValueError: raise ValueError('due_date must be a real date in YYYY-MM-DD format')
    extra=data.get('data',(existing or {}).get('data',{}))
    if not isinstance(extra,dict): raise ValueError('data must be an object')
    return kind,title,details,status,quantity,location,due_date,json.dumps(extra,ensure_ascii=False),now()

class Handler(BaseHTTPRequestHandler):
    server_version='NOSTOS/'+VERSION
    def guard(self):
        """Reject DNS rebinding, cross-origin requests and unauthenticated API access."""
        host=self.headers.get('Host','').lower()
        port=self.server.server_address[1]
        allowed={f'127.0.0.1:{port}', f'localhost:{port}', f'[::1]:{port}'}
        if host not in allowed:
            self.send_json(403,{'error':'untrusted host'}); return False
        origin=self.headers.get('Origin')
        if origin and origin.lower() != 'http://'+host:
            self.send_json(403,{'error':'cross-origin request rejected'}); return False
        if self.headers.get('Sec-Fetch-Site','').lower() == 'cross-site':
            self.send_json(403,{'error':'cross-site request rejected'}); return False
        if urlparse(self.path).path.startswith('/api/'):
            if len(OWNER_TOKEN) < 32:
                self.send_json(503,{'error':'owner token is not configured'}); return False
            if not hmac.compare_digest(self.headers.get('Authorization',''), 'Bearer '+OWNER_TOKEN):
                self.send_bytes(401,b'{"error":"owner authentication required"}',headers={'WWW-Authenticate':'Bearer realm="NOSTOS"'})
                return False
        return True
    def log_message(self, fmt, *args):
        if os.environ.get('NOSTOS_ACCESS_LOG')=='1': super().log_message(fmt,*args)
    def send_bytes(self, status, payload, ctype='application/json; charset=utf-8', headers=None):
        self.send_response(status); self.send_header('Content-Type',ctype); self.send_header('X-Content-Type-Options','nosniff'); self.send_header('Cache-Control','no-store')
        for k,v in (headers or {}).items(): self.send_header(k,v)
        self.send_header('Content-Length',str(len(payload))); self.end_headers()
        try: self.wfile.write(payload)
        except (BrokenPipeError, ConnectionResetError): pass
    def send_json(self,status,obj): self.send_bytes(status,json.dumps(obj,ensure_ascii=False).encode())
    def body(self):
        n=int(self.headers.get('Content-Length','0'))
        if n<0 or n>MAX_BODY: raise ValueError('request body too large')
        raw=self.rfile.read(n)
        return json.loads(raw.decode('utf-8')) if raw else {}
    def do_OPTIONS(self):
        self.send_json(405,{'error':'cross-origin access is not enabled'})
    def do_GET(self):
        if not self.guard(): return
        p=urlparse(self.path); path=p.path
        if path=='/' or path=='/index.html':
            f=WEB_ROOT/'index.html'; self.send_bytes(200,f.read_bytes(),'text/html; charset=utf-8',{'Content-Security-Policy':"default-src 'self'; style-src 'self' 'unsafe-inline'; script-src 'self'; connect-src 'self'; base-uri 'none'; frame-ancestors 'none'"}); return
        if path=='/app.js':
            self.send_bytes(200,(WEB_ROOT/'app.js').read_bytes(),'application/javascript; charset=utf-8'); return
        if path=='/api/health':
            try:
                with LOCK, db() as c: c.execute('SELECT 1').fetchone(); count=c.execute('SELECT COUNT(*) FROM items').fetchone()[0]
                self.send_json(200,{'app':'NOSTOS','version':VERSION,'status':'ready','database':'connected','items':count,'host':HOST,'port':PORT})
            except Exception: self.send_json(503,{'app':'NOSTOS','status':'unavailable'})
            return
        if path=='/api/summary':
            with LOCK, db() as c:
                rows=c.execute('SELECT kind, COUNT(*) n FROM items GROUP BY kind').fetchall()
                due=c.execute("SELECT COUNT(*) FROM items WHERE due_date<>'' AND due_date<=? AND status NOT IN ('done','archived')",(datetime.now().date().isoformat(),)).fetchone()[0]
                attention=c.execute("SELECT COUNT(*) FROM items WHERE status='needs_attention'").fetchone()[0]
            counts={k:0 for k in sorted(KINDS)}; counts.update({r['kind']:r['n'] for r in rows})
            self.send_json(200,{'counts':counts,'total':sum(counts.values()),'overdue':due,'needs_attention':attention}); return
        if path=='/api/items':
            q=parse_qs(p.query); kind=q.get('kind',[''])[0].lower(); search=q.get('q',[''])[0].strip()[:200]
            if kind and kind not in KINDS: self.send_json(400,{'error':'unsupported kind'}); return
            sql='SELECT * FROM items'; clauses=[]; args=[]
            if kind: clauses.append('kind=?'); args.append(kind)
            if search: clauses.append('(title LIKE ? OR details LIKE ? OR location LIKE ?)'); args.extend([f'%{search}%']*3)
            if clauses: sql+=' WHERE '+' AND '.join(clauses)
            sql+=' ORDER BY CASE WHEN due_date="" THEN 1 ELSE 0 END, due_date, updated_at DESC LIMIT 500'
            with LOCK, db() as c: rows=c.execute(sql,args).fetchall()
            self.send_json(200,{'items':[item_dict(r) for r in rows]}); return
        if path=='/api/backup':
            DATA_DIR.mkdir(parents=True,exist_ok=True)
            with LOCK:
                fd,tmp=tempfile.mkstemp(prefix='nostos-backup-',suffix='.sqlite3',dir=str(DATA_DIR)); os.close(fd)
                try:
                    src=connect(); dst=sqlite3.connect(tmp)
                    try: src.backup(dst)
                    finally: dst.close(); src.close()
                    payload=Path(tmp).read_bytes()
                finally: Path(tmp).unlink(missing_ok=True)
            self.send_bytes(200,payload,'application/vnd.sqlite3',{'Content-Disposition':'attachment; filename="nostos-backup.sqlite3"'}); return
        self.send_json(404,{'error':'not found'})
    def do_POST(self):
        if not self.guard(): return
        path=urlparse(self.path).path
        if path=='/api/restore':
            if not RESTORE_ENABLED:
                self.send_json(403,{'error':'restore is disabled; enable explicitly on the owner host'}); return
            if self.headers.get('X-NOSTOS-Restore-Confirm') != 'RESTORE NOSTOS':
                self.send_json(409,{'error':'restore requires explicit confirmation'}); return
            self.restore_from_body(); return
        try: body=self.body()
        except (ValueError,UnicodeDecodeError,json.JSONDecodeError) as e: self.send_json(400,{'error':str(e)}); return
        if path=='/api/items':
            try: values=parse_item(body)
            except ValueError as e: self.send_json(400,{'error':str(e)}); return
            with LOCK, db() as c:
                cur=c.execute('INSERT INTO items(kind,title,details,status,quantity,location,due_date,created_at,updated_at,data_json) VALUES(?,?,?,?,?,?,?,?,?,?)',values[:7]+(values[8],values[8],values[7]))
                row=c.execute('SELECT * FROM items WHERE id=?',(cur.lastrowid,)).fetchone()
            self.send_json(201,{'item':item_dict(row)}); return
        self.send_json(404,{'error':'not found'})
    def restore_from_body(self):
        try:
            n=int(self.headers.get('Content-Length','0'))
            if n<=0 or n>MAX_BODY: raise ValueError('backup must be between 1 byte and 16 MiB')
            raw=self.rfile.read(n)
            if len(raw)!=n: raise ValueError('incomplete backup upload')
            DATA_DIR.mkdir(parents=True,exist_ok=True)
            fd,uploaded=tempfile.mkstemp(prefix='nostos-restore-upload-',suffix='.sqlite3',dir=str(DATA_DIR)); os.close(fd)
            fd,rebuilt=tempfile.mkstemp(prefix='nostos-restore-validated-',suffix='.sqlite3',dir=str(DATA_DIR)); os.close(fd); Path(rebuilt).unlink(missing_ok=True)
            Path(uploaded).write_bytes(raw)
            try:
                src=sqlite3.connect(f'file:{uploaded}?mode=ro',uri=True)
                try:
                    if src.execute('PRAGMA integrity_check').fetchone()[0] != 'ok': raise ValueError('backup integrity check failed')
                    tables={r[0] for r in src.execute("SELECT name FROM sqlite_master WHERE type='table'")}
                    if not {'items','meta'}.issubset(tables): raise ValueError('backup is not a NOSTOS database')
                    schema=src.execute("SELECT value FROM meta WHERE key='schema_version'").fetchone()
                    if not schema or schema[0] != '1': raise ValueError('unsupported database schema version')
                    cols={r[1] for r in src.execute('PRAGMA table_info(items)')}
                    required={'id','kind','title','details','status','quantity','location','due_date','created_at','updated_at','data_json'}
                    if not required.issubset(cols): raise ValueError('backup has an incompatible items table')
                    rows=src.execute('SELECT id,kind,title,details,status,quantity,location,due_date,created_at,updated_at,data_json FROM items ORDER BY id LIMIT 100001').fetchall()
                    if len(rows)>100000: raise ValueError('backup contains too many records')
                    clean=[]
                    for row in rows:
                        extra=json.loads(row[10] or '{}')
                        values=parse_item({'kind':row[1],'title':row[2],'details':row[3],'status':row[4],'quantity':row[5],'location':row[6],'due_date':row[7],'data':extra})
                        clean.append((int(row[0]),*values[:7],str(row[8]),str(row[9]),values[7]))
                finally: src.close()
                init_db(rebuilt)
                with db(rebuilt) as dst:
                    dst.executemany('INSERT INTO items(id,kind,title,details,status,quantity,location,due_date,created_at,updated_at,data_json) VALUES(?,?,?,?,?,?,?,?,?,?,?)',clean)
                    dst.execute("UPDATE sqlite_sequence SET seq=MAX(seq, COALESCE((SELECT MAX(id) FROM items),0)) WHERE name='items'")
                with LOCK:
                    # Durable preimage: failure to create it aborts the data replacement.
                    recovery_dir=DATA_DIR/'recovery'
                    recovery_dir.mkdir(parents=True,exist_ok=True,mode=0o700)
                    snapshot=recovery_dir/('before-restore-'+datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')+'-'+secrets.token_hex(5)+'.sqlite3')
                    old=connect()
                    before=sqlite3.connect(str(snapshot))
                    try:
                        old.backup(before)
                        if before.execute('PRAGMA integrity_check').fetchone()[0] != 'ok':
                            raise ValueError('pre-restore snapshot integrity failed')
                    finally:
                        before.close(); old.close()
                    with snapshot.open('rb') as f: os.fsync(f.fileno())
                    current=connect()
                    try: current.execute('PRAGMA wal_checkpoint(TRUNCATE)')
                    finally: current.close()
                    Path(str(DB_PATH)+'-wal').unlink(missing_ok=True)
                    Path(str(DB_PATH)+'-shm').unlink(missing_ok=True)
                    os.replace(rebuilt,DB_PATH)
                self.send_json(200,{'restored':True,'records':len(clean),'database':'validated'})
            finally:
                Path(uploaded).unlink(missing_ok=True); Path(rebuilt).unlink(missing_ok=True)
        except (ValueError,sqlite3.Error,json.JSONDecodeError,OSError) as e:
            self.send_json(400,{'restored':False,'error':str(e)})
    def do_PATCH(self):
        if not self.guard(): return
        path=urlparse(self.path).path
        if not path.startswith('/api/items/'): self.send_json(404,{'error':'not found'}); return
        try: ident=int(path.rsplit('/',1)[1]); body=self.body()
        except Exception as e: self.send_json(400,{'error':str(e)}); return
        with LOCK, db() as c: row=c.execute('SELECT * FROM items WHERE id=?',(ident,)).fetchone()
        if not row: self.send_json(404,{'error':'item not found'}); return
        old=item_dict(row)
        try: values=parse_item(body,old)
        except ValueError as e: self.send_json(400,{'error':str(e)}); return
        with LOCK, db() as c:
            c.execute('UPDATE items SET kind=?,title=?,details=?,status=?,quantity=?,location=?,due_date=?,updated_at=?,data_json=? WHERE id=?',values[:7]+(values[8],values[7],ident))
            row=c.execute('SELECT * FROM items WHERE id=?',(ident,)).fetchone()
        self.send_json(200,{'item':item_dict(row)})
    def do_DELETE(self):
        if not self.guard(): return
        path=urlparse(self.path).path
        if not path.startswith('/api/items/'): self.send_json(404,{'error':'not found'}); return
        try: ident=int(path.rsplit('/',1)[1])
        except ValueError: self.send_json(400,{'error':'invalid item id'}); return
        with LOCK, db() as c: cur=c.execute('DELETE FROM items WHERE id=?',(ident,))
        self.send_json(200,{'deleted':cur.rowcount==1,'id':ident})

def main():
    if HOST not in {'127.0.0.1','::1','localhost'}:
        raise SystemExit('Refusing non-loopback binding; private remote routing requires separate authorization')
    if len(OWNER_TOKEN) < 32:
        raise SystemExit('Set a random NOSTOS_OWNER_TOKEN of at least 32 characters before starting')
    init_db()
    httpd=ThreadingHTTPServer((HOST,PORT),Handler)
    print(f'NOSTOS {VERSION} listening at http://{HOST}:{PORT}/; database={DB_PATH}',flush=True)
    try: httpd.serve_forever(poll_interval=0.25)
    except KeyboardInterrupt: pass
    finally: httpd.server_close()
if __name__=='__main__': main()

