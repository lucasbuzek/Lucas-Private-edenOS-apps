import importlib.util, json, os, tempfile, threading, unittest, urllib.request, urllib.error
from pathlib import Path

MODULE_PATH=Path(__file__).resolve().parents[1]/'nostos.py'
spec=importlib.util.spec_from_file_location('nostos_candidate',MODULE_PATH)
app=importlib.util.module_from_spec(spec); spec.loader.exec_module(app)

class NostosServiceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp=tempfile.TemporaryDirectory(); app.OWNER_TOKEN='test-owner-token-'+'x'*48; app.RESTORE_ENABLED=True; app.DATA_DIR=Path(cls.temp.name); app.DB_PATH=app.DATA_DIR/'test.sqlite3'; app.init_db()
        cls.server=app.ThreadingHTTPServer(('127.0.0.1',0),app.Handler); cls.port=cls.server.server_address[1]
        cls.thread=threading.Thread(target=cls.server.serve_forever,daemon=True); cls.thread.start()
        cls.base=f'http://127.0.0.1:{cls.port}'
    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown(); cls.server.server_close(); cls.thread.join(timeout=2); cls.temp.cleanup()
    def request(self,path,method='GET',data=None):
        raw=None if data is None else json.dumps(data).encode()
        req=urllib.request.Request(self.base+path,data=raw,method=method,headers={'Authorization':'Bearer '+app.OWNER_TOKEN, **({'Content-Type':'application/json'} if raw is not None else {})})
        with urllib.request.urlopen(req,timeout=3) as r: return r.status,r.read(),r.headers
    def test_health_and_summary(self):
        status,raw,_=self.request('/api/health'); self.assertEqual(status,200); self.assertEqual(json.loads(raw)['database'],'connected')
        _,raw,_=self.request('/api/summary'); d=json.loads(raw); self.assertEqual(d['total'],sum(d['counts'].values()))
    def test_create_search_update_delete(self):
        _,raw,_=self.request('/api/items','POST',{'kind':'spaces','title':'Kitchen','location':'Ground floor'})
        item=json.loads(raw)['item']; ident=item['id']; self.assertEqual(item['kind'],'spaces')
        _,raw,_=self.request('/api/items?kind=spaces&q=kit'); self.assertEqual(len(json.loads(raw)['items']),1)
        _,raw,_=self.request(f'/api/items/{ident}','PATCH',{'kind':'spaces','title':'Kitchen','status':'done','location':'Ground floor','data':{}})
        self.assertEqual(json.loads(raw)['item']['status'],'done')
        _,raw,_=self.request(f'/api/items/{ident}','DELETE'); self.assertTrue(json.loads(raw)['deleted'])
    def test_invalid_records_rejected(self):
        req=urllib.request.Request(self.base+'/api/items',data=json.dumps({'kind':'bogus','title':'Bad'}).encode(),method='POST',headers={'Content-Type':'application/json','Authorization':'Bearer '+app.OWNER_TOKEN})
        with self.assertRaises(urllib.error.HTTPError) as e: urllib.request.urlopen(req,timeout=3)
        self.assertEqual(e.exception.code,400)
    def test_backup_is_valid_sqlite_and_restore_roundtrip(self):
        self.request('/api/items','POST',{'kind':'assets','title':'First aid kit'})
        status,payload,headers=self.request('/api/backup'); self.assertEqual(status,200); self.assertIn('sqlite3',headers.get('Content-Type',''))
        backup=Path(self.temp.name)/'download.sqlite3'; backup.write_bytes(payload)
        import sqlite3
        c=sqlite3.connect(backup)
        try:
            self.assertEqual(c.execute('PRAGMA integrity_check').fetchone()[0],'ok')
            self.assertGreaterEqual(c.execute('SELECT COUNT(*) FROM items').fetchone()[0],1)
        finally: c.close()
        self.request('/api/items','POST',{'kind':'spaces','title':'Temporary record'})
        req=urllib.request.Request(self.base+'/api/restore',data=payload,method='POST',headers={'Content-Type':'application/vnd.sqlite3','Authorization':'Bearer '+app.OWNER_TOKEN,'X-NOSTOS-Restore-Confirm':'RESTORE NOSTOS'})
        with urllib.request.urlopen(req,timeout=5) as response: result=json.loads(response.read())
        self.assertTrue(result['restored'])
        self.assertTrue(list((app.DATA_DIR/'recovery').glob('before-restore-*.sqlite3')),'pre-restore snapshot required')
        _,raw,_=self.request('/api/items?kind=assets'); self.assertTrue(any(i['title']=='First aid kit' for i in json.loads(raw)['items']))
        _,raw,_=self.request('/api/items?kind=spaces'); self.assertFalse(any(i['title']=='Temporary record' for i in json.loads(raw)['items']))


    def _expect_http(self,path,code,method='GET',data=None,headers=None):
        payload=data if isinstance(data,bytes) or data is None else json.dumps(data).encode()
        req=urllib.request.Request(self.base+path,method=method,data=payload,headers=headers or {})
        with self.assertRaises(urllib.error.HTTPError) as caught:
            urllib.request.urlopen(req,timeout=3)
        self.assertEqual(caught.exception.code,code)

    def test_auth_denied_without_or_wrong_token(self):
        self._expect_http('/api/summary',401)
        self._expect_http('/api/items',401,headers={'Authorization':'Bearer incorrect'})
        self._expect_http('/api/backup',401)

    def test_cross_origin_and_dns_rebinding_denied(self):
        headers={'Authorization':'Bearer '+app.OWNER_TOKEN,'Origin':'https://example.invalid'}
        self._expect_http('/api/items',403,headers=headers)
        self._expect_http('/api/items',403,headers={'Authorization':'Bearer '+app.OWNER_TOKEN,'Host':'evil.example'})

    def test_invalid_quantity_and_date_denied(self):
        for payload in (
            {'kind':'supplies','title':'Test','quantity':float('nan')},
            {'kind':'supplies','title':'Test','quantity':float('inf')},
            {'kind':'chores','title':'Test','due_date':'2026-02-30'},
            {'kind':'chores','title':'Test','due_date':'2026-1-1'},
        ):
            self._expect_http('/api/items',400,'POST',payload,{'Authorization':'Bearer '+app.OWNER_TOKEN,'Content-Type':'application/json'})

    def test_restore_needs_explicit_gate_and_confirmation(self):
        self._expect_http('/api/restore',409,'POST',b'not valid sqlite',{'Authorization':'Bearer '+app.OWNER_TOKEN})
        app.RESTORE_ENABLED=False
        try: self._expect_http('/api/restore',403,'POST',b'not valid sqlite',{'Authorization':'Bearer '+app.OWNER_TOKEN,'X-NOSTOS-Restore-Confirm':'RESTORE NOSTOS'})
        finally: app.RESTORE_ENABLED=True

if __name__=='__main__': unittest.main(verbosity=2)

