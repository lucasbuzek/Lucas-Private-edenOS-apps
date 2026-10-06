#!/usr/bin/env python3
from http.server import ThreadingHTTPServer, SimpleHTTPRequestHandler
from pathlib import Path
import json, uuid, datetime, urllib.parse, os
BASE=Path(__file__).resolve().parents[1]
DATA=BASE/'data'; DATA.mkdir(exist_ok=True)
SPECS=BASE/'specs'/'assistants'
def now(): return datetime.datetime.now(datetime.timezone.utc).isoformat()
def project_dir(pid): return DATA/pid
def load_specs():
 out=[]
 for p in sorted(SPECS.glob('*.json')):
  d=json.loads(p.read_text()); out.append({'id':d['id'],'name':d['name'],'symbol':d.get('symbol','')})
 return out
def create_project(name,goal,assistant):
 pid=str(uuid.uuid4())[:8]; p=project_dir(pid); (p/'checkpoints').mkdir(parents=True)
 m={'id':pid,'name':name or 'Untitled Project','goal':goal,'assistant':assistant or 'conductor','created_at':now(),'status':'READY','version':1}
 (p/'manifest.json').write_text(json.dumps(m,indent=2)); (p/'events.jsonl').write_text('')
 event(pid,'PROJECT_CREATED',m); return m
def event(pid,t,payload):
 rec={'time':now(),'type':t,'payload':payload}
 with (project_dir(pid)/'events.jsonl').open('a') as f: f.write(json.dumps(rec)+'\n')
def run_job(pid):
 p=project_dir(pid); m=json.loads((p/'manifest.json').read_text()); steps=['INPUT','ANALYZE','PLAN','EXECUTE','SAVE','VERIFY','CHECKPOINT','CONTINUE','CONSOLIDATE','FINAL QA','RELEASE']
 for i,s in enumerate(steps,1):
  event(pid,'STEP',{'step':s,'index':i,'total':len(steps),'status':'COMPLETE'})
  if s in ('SAVE','CHECKPOINT','RELEASE'):
   cp={'project_id':pid,'step':s,'time':now(),'goal':m['goal'],'assistant':m['assistant'],'verified':s in ('CHECKPOINT','RELEASE')}
   (p/'checkpoints'/f'{i:02d}_{s.replace(" ","_")}.json').write_text(json.dumps(cp,indent=2))
 m['status']='RELEASED'; m['updated_at']=now(); (p/'manifest.json').write_text(json.dumps(m,indent=2)); event(pid,'JOB_RELEASED',{'note':'Reference lifecycle completed; no external AI provider was invoked.'}); return m
def list_projects():
 out=[]
 for p in DATA.iterdir():
  if p.is_dir() and (p/'manifest.json').exists(): out.append(json.loads((p/'manifest.json').read_text()))
 return sorted(out,key=lambda x:x.get('created_at',''),reverse=True)
class H(SimpleHTTPRequestHandler):
 def sendj(self,obj,code=200):
  b=json.dumps(obj).encode(); self.send_response(code); self.send_header('Content-Type','application/json'); self.send_header('Content-Length',len(b)); self.end_headers(); self.wfile.write(b)
 def do_GET(self):
  if self.path=='/api/assistants': return self.sendj(load_specs())
  if self.path=='/api/projects': return self.sendj(list_projects())
  if self.path.startswith('/api/project/'):
   pid=self.path.split('/')[-1]; p=project_dir(pid)
   if not p.exists(): return self.sendj({'error':'not found'},404)
   m=json.loads((p/'manifest.json').read_text()); ev=[json.loads(x) for x in (p/'events.jsonl').read_text().splitlines() if x.strip()]; return self.sendj({'manifest':m,'events':ev})
  if self.path=='/' or self.path.startswith('/?'): self.path='/web/index.html'
  return super().do_GET()
 def do_POST(self):
  n=int(self.headers.get('Content-Length','0')); body=json.loads(self.rfile.read(n) or b'{}')
  if self.path=='/api/projects': return self.sendj(create_project(body.get('name'),body.get('goal',''),body.get('assistant')))
  if self.path.startswith('/api/run/'):
   pid=self.path.split('/')[-1]
   if not project_dir(pid).exists(): return self.sendj({'error':'not found'},404)
   return self.sendj(run_job(pid))
  self.sendj({'error':'unknown'},404)
os.chdir(BASE)
if __name__=='__main__':
 srv=ThreadingHTTPServer(('127.0.0.1',8765),H); print('LUCAS Local: http://127.0.0.1:8765'); srv.serve_forever()
