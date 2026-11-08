"""Local-only HTTP interface over the original THEMIS store; not a public/authenticated deployment."""
import json, os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse,parse_qs
from .store import ThemisStore,KINDS
class Handler(BaseHTTPRequestHandler):
    store=None
    def respond(self,code,payload):
        body=json.dumps(payload).encode()
        self.send_response(code)
        self.send_header('Content-Type','application/json')
        self.send_header('Content-Length',str(len(body)))
        self.end_headers()
        self.wfile.write(body)
    def do_GET(self):
        route=urlparse(self.path);parts=route.path.strip('/').split('/')
        if route.path=='/api/health':return self.respond(200,{'service':'THEMIS','status':'ok','kinds':sorted(KINDS)})
        if route.path=='/api/records':
            kind=parse_qs(route.query).get('kind',[None])[0]
            if kind is not None and kind not in KINDS:return self.respond(400,{'error':'unsupported kind'})
            return self.respond(200,{'records':self.store.list(kind)})
        if len(parts)==3 and parts[:2]==['api','records']:
            rec=self.store.get(parts[2])
            return self.respond(200,rec) if rec else self.respond(404,{'error':'not found'})
        return self.respond(404,{'error':'not found'})
    def do_POST(self):
        if self.path!='/api/records':return self.respond(404,{'error':'not found'})
        try:
            size=int(self.headers.get('Content-Length','0'))
            if not 0<size<=65536:return self.respond(413,{'error':'invalid body size'})
            data=json.loads(self.rfile.read(size));kind=data['kind'];title=data['title']
            if kind not in KINDS or not isinstance(title,str) or not title.strip():return self.respond(400,{'error':'invalid kind/title'})
            fields=data.get('fields',{});provenance=data.get('provenance',{})
            if not isinstance(fields,dict) or not isinstance(provenance,dict):return self.respond(400,{'error':'invalid fields/provenance'})
            return self.respond(201,self.store.add(kind,title,fields,provenance))
        except (ValueError,KeyError,TypeError):return self.respond(400,{'error':'invalid JSON record'})
    def log_message(self,*args):pass
def serve(db='data/themis.json',host='127.0.0.1',port=8765):
    Handler.store=ThemisStore(db)
    ThreadingHTTPServer((host,port),Handler).serve_forever()
if __name__=='__main__':serve(os.getenv('THEMIS_DB','data/themis.json'))
