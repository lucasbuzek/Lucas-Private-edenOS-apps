import json,sys,tempfile,threading
from pathlib import Path
from urllib.request import urlopen,Request
from urllib.error import HTTPError
from http.server import ThreadingHTTPServer
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'src'))
from themis.api import Handler
from themis.store import ThemisStore
with tempfile.TemporaryDirectory() as td:
    Handler.store=ThemisStore(Path(td)/'db.json')
    server=ThreadingHTTPServer(('127.0.0.1',0),Handler)
    thread=threading.Thread(target=server.serve_forever,daemon=True);thread.start()
    base=f'http://127.0.0.1:{server.server_port}'
    try:
        with urlopen(base+'/api/health') as r:assert json.load(r)['status']=='ok'
        req=Request(base+'/api/records',data=json.dumps({'kind':'matter','title':'Electrical installation','fields':{'status':'draft'}}).encode(),headers={'Content-Type':'application/json'})
        with urlopen(req) as r:assert r.status==201;rec=json.load(r)
        with urlopen(base+'/api/records/'+rec['id']) as r:assert json.load(r)['title']=='Electrical installation'
        with urlopen(base+'/api/records?kind=matter') as r:assert len(json.load(r)['records'])==1
        try:urlopen(base+'/api/records?kind=invalid');assert False
        except HTTPError as e:assert e.code==400
        assert ThemisStore(Path(td)/'db.json').get(rec['id']) is not None
    finally:server.shutdown();server.server_close()
print('PASS: HTTP create/list/get/validation + persistent original store')
