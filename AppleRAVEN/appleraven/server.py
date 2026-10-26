"""AppleRAVEN local MCP JSON-RPC 2025-06-18 stdio; no listener."""
import argparse,json,sys
from pathlib import Path
from .core import AppleRaven,AccessDenied,Unavailable,read_config,init_config
VERSION='2025-06-18';LIMIT=65536
TOOLS={
'appleraven.status':('Status and fixed identity grants',{},'status'),
'appleraven.shortcuts.list':('List native macOS Shortcuts',{},'shortcuts_list'),
'appleraven.shortcuts.run':('Run preapproved native Shortcut',{'name':str,'input':str},'shortcuts_run'),
'appleraven.icloud.list':('List permitted local Files/iCloud folder',{'root':str,'path':str},'icloud_list'),
'appleraven.icloud.read_text':('Read small scoped Files/iCloud text',{'root':str,'path':str},'icloud_read'),
'appleraven.devices.list':('List Xcode developer devices',{},'devices')}
def catalog():
    out=[]
    for name,(desc,fields,_) in TOOLS.items():
        req=sorted(({'name','root'}&set(fields))|({'path'} if name.endswith('read_text') else set()))
        out.append({'name':name,'description':desc,'inputSchema':{
          'type':'object','properties':{k:{'type':'string','maxLength':8192 if k=='input' else 512} for k in fields},
          'required':req,'additionalProperties':False},
          'annotations':{'readOnlyHint':name!='appleraven.shortcuts.run','destructiveHint':False}})
    return out
def ok(id,payload):return {'jsonrpc':'2.0','id':id,'result':payload}
def err(id,code,msg):return {'jsonrpc':'2.0','id':id,'error':{'code':code,'message':msg}}
class Session:
    def __init__(self,bridge):self.bridge=bridge;self.initialized=False;self.ready=False
    def handle(self,req):
        if not isinstance(req,dict) or req.get('jsonrpc')!='2.0' or not isinstance(req.get('method'),str):return err(None,-32600,'Invalid request')
        method=req['method'];id=req.get('id');params=req.get('params',{})
        if 'id' not in req:
            if method=='notifications/initialized' and self.initialized:self.ready=True
            return None
        if isinstance(id,bool) or not isinstance(id,(str,int)):return err(None,-32600,'Invalid id')
        if not isinstance(params,dict):return err(id,-32602,'Invalid params')
        if method=='initialize':
            if self.initialized:return err(id,-32600,'Already initialized')
            if not isinstance(params.get('protocolVersion'),str) or not isinstance(params.get('capabilities'),dict) or not isinstance(params.get('clientInfo'),dict):return err(id,-32602,'Invalid initialization')
            self.initialized=True
            return ok(id,{'protocolVersion':VERSION,'capabilities':{'tools':{'listChanged':False}},'serverInfo':{'name':'AppleRAVEN-private','version':'0.1.0'}})
        if method=='ping':return ok(id,{})
        if not self.ready:return err(id,-32000,'Session not ready')
        if method=='tools/list':return ok(id,{'tools':catalog()})
        if method=='tools/call':
            name=params.get('name');kwargs=params.get('arguments',{})
            if name not in TOOLS or not isinstance(kwargs,dict):return err(id,-32602,'Unknown tool or invalid arguments')
            allowed=TOOLS[name][1];required=set(catalog()[list(TOOLS).index(name)]['inputSchema']['required'])
            if set(kwargs)-set(allowed) or not required.issubset(kwargs) or any(not isinstance(v,str) or len(v)>(8192 if k=='input' else 512) for k,v in kwargs.items()):return err(id,-32602,'Invalid arguments')
            try:
                val=getattr(self.bridge,TOOLS[name][2])(kwargs)
                return ok(id,{'content':[{'type':'text','text':json.dumps(val,ensure_ascii=False)}],'isError':False})
            except (AccessDenied,Unavailable,ValueError,OSError,UnicodeError) as e:
                return ok(id,{'content':[{'type':'text','text':json.dumps({'error':str(e)})}],'isError':True})
            except Exception:
                return ok(id,{'content':[{'type':'text','text':'Internal operation failed'}],'isError':True})
        return err(id,-32601,'Method not found')
def serve(session,inp=None,out=None):
    inp=inp or sys.stdin.buffer;out=out or sys.stdout
    while True:
        raw=inp.readline(LIMIT+1)
        if not raw:break
        if len(raw)>LIMIT:
            print(json.dumps(err(None,-32600,'Message too large')),file=out,flush=True);return 1
        try:reply=session.handle(json.loads(raw))
        except (json.JSONDecodeError,UnicodeError,ValueError):reply=err(None,-32700,'Invalid JSON')
        if reply is not None:print(json.dumps(reply,ensure_ascii=True),file=out,flush=True)
    return 0
def main():
    p=argparse.ArgumentParser()
    p.add_argument('--config',default=str(Path.home()/'.config/appleraven/config.json'))
    p.add_argument('--profile',default='lucascouncil')
    p.add_argument('--init-config',action='store_true')
    args=p.parse_args();file=Path(args.config).expanduser()
    if args.init_config:
        init_config(file);print('Created private config: '+str(file),file=sys.stderr);return 0
    try:instance=AppleRaven(read_config(file),args.profile)
    except (OSError,AccessDenied,ValueError,json.JSONDecodeError) as e:
        print('AppleRAVEN setup: '+str(e),file=sys.stderr);return 2
    return serve(Session(instance))
if __name__=='__main__':raise SystemExit(main())
