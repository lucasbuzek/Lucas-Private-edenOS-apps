"""Private standalone AppleRAVEN MCP adapters; no BIFROST dependency or shell."""
from __future__ import annotations
import json,os,platform,shutil,subprocess,tempfile
from pathlib import Path
MAX_OUTPUT=16384
MAX_INPUT=8192
MAX_READ=65536
ALLOWED_EXT={'.txt','.md','.json','.csv','.yaml','.yml','.log','.swift','.py','.sh','.plist','.html'}
EXCLUDED_NAMES={'.env','id_rsa','id_ed25519','.netrc','.git-credentials','login.keychain-db'}
class AccessDenied(Exception):pass
class Unavailable(Exception):pass
def safe_label(s):
    if not isinstance(s,str) or not 1<=len(s)<=120 or '\x00' in s or '/' in s or '\\' in s:raise ValueError('Invalid label')
    return s
def read_config(path):
    if path.is_symlink():raise AccessDenied('Configuration symlink not allowed')
    data=json.loads(path.read_text(encoding='utf8'))
    if not isinstance(data,dict) or data.get('schema')!=1 or not isinstance(data.get('profiles'),dict):raise ValueError('Invalid configuration schema')
    return data
def default_config():
    return {'schema':1,'profiles':{'lucascouncil':{'allow_shortcuts':[],'allow_roots':{},'allow_file_read':False}}}
def init_config(path):
    path.parent.mkdir(parents=True,exist_ok=True)
    fd=os.open(path,os.O_WRONLY|os.O_CREAT|os.O_EXCL,0o600)
    with os.fdopen(fd,'w',encoding='utf8') as f:
        json.dump(default_config(),f,indent=2);f.write('\n')
class AppleRaven:
    def __init__(self,config,profile,*,run=None,which=None,mac=None):
        if profile not in config.get('profiles',{}):raise AccessDenied('Unknown profile: identity fixed at server startup')
        p=config['profiles'][profile]
        if not isinstance(p,dict) or not isinstance(p.get('allow_roots',{}),dict) or not isinstance(p.get('allow_shortcuts',[]),list):raise ValueError('Malformed profile')
        self.p=p;self.profile=profile;self.run=run or subprocess.run;self.which=which or shutil.which
        self.mac=platform.system()=='Darwin' if mac is None else mac
    def status(self,_):
        return {'server':'AppleRAVEN','version':'0.1.0','profile':self.profile,'host_platform':platform.system(),
          'macos':self.mac,'local_first':True,'remote_listener':False,'network_required':False,
          'shortcuts_cli':bool(self.which('shortcuts')) if self.mac else False,
          'xcode_cli':bool(self.which('xcrun')) if self.mac else False,
          'configured_root_aliases':sorted(self.p.get('allow_roots',{})),
          'approved_shortcuts':len(self.p['allow_shortcuts']),
          'note':'No unrestricted iOS control, Keychain secrets, remote iCloud API or automatic Apple ID switching.'}
    def _mac(self):
        if not self.mac:raise Unavailable('Requires macOS')
    def _tool(self,name):
        if not self.which(name):raise Unavailable(name+' unavailable')
    def _cmd(self,args,timeout=10):
        try:r=self.run(args,check=False,text=True,capture_output=True,timeout=timeout)
        except subprocess.TimeoutExpired as e:raise Unavailable('Native operation timed out') from e
        if r.returncode:raise Unavailable('Native operation failed: check Apple permissions')
        return r.stdout[:MAX_OUTPUT]
    def shortcuts_list(self,_):
        self._mac();self._tool('shortcuts');out=self._cmd(['shortcuts','list'])
        return {'names':out.splitlines()[:100],'truncated':len(out)>=MAX_OUTPUT}
    def shortcuts_run(self,args):
        self._mac();self._tool('shortcuts');name=safe_label(args.get('name'))
        if name not in self.p['allow_shortcuts']:raise AccessDenied('Shortcut not granted by fixed profile')
        payload=args.get('input','')
        if not isinstance(payload,str) or len(payload.encode('utf8'))>MAX_INPUT:raise ValueError('Input too large')
        if payload:
            with tempfile.TemporaryDirectory(prefix='appleraven-') as tmp:
                p=Path(tmp)/'input.txt';p.write_text(payload,encoding='utf8');os.chmod(p,0o600)
                out=self._cmd(['shortcuts','run',name,'--input-path',str(p)],timeout=30)
        else:out=self._cmd(['shortcuts','run',name],timeout=30)
        return {'shortcut':name,'output':out,'completed_by_cli':True,'note':'Effects still require verification'}
    def _path(self,alias,rel):
        raw=self.p.get('allow_roots',{}).get(alias)
        if not isinstance(raw,str) or not raw:raise AccessDenied('Root alias not granted')
        if not isinstance(rel,str) or len(rel)>512 or '\x00' in rel or Path(rel).is_absolute() or any(x in ('.','..') for x in Path(rel).parts):raise AccessDenied('Invalid relative path')
        root=Path(os.path.expanduser(raw)).resolve(strict=True)
        path=(root/rel).resolve(strict=True)
        if not path.is_relative_to(root):raise AccessDenied('Outside authorized root')
        return root,path
    def icloud_list(self,args):
        alias=safe_label(args.get('root'));rel=args.get('path','')
        root,path=self._path(alias,rel)
        if not path.is_dir():raise ValueError('Not directory')
        files=[]
        for child in sorted(path.iterdir(),key=lambda x:x.name.casefold()):
            if child.name.startswith('.') or child.name in EXCLUDED_NAMES or child.is_symlink():continue
            try:
                if not child.resolve().is_relative_to(root):continue
                stat=child.stat()
                files.append({'name':child.name[:160],'directory':child.is_dir(),'size':stat.st_size if child.is_file() else None})
            except OSError:continue
            if len(files)>=100:break
        return {'root':alias,'path':rel,'entries':files,'limited_to':100,'note':'Local File Provider folder, not remote iCloud API'}
    def icloud_read(self,args):
        if self.p.get('allow_file_read') is not True:raise AccessDenied('File reading not enabled')
        alias=safe_label(args.get('root'));rel=args.get('path')
        root,path=self._path(alias,rel)
        if path.suffix.lower() not in ALLOWED_EXT or path.name.startswith('.') or path.name in EXCLUDED_NAMES:raise AccessDenied('Restricted file')
        if not path.is_file() or path.stat().st_size>MAX_READ:raise ValueError('Not an available small text file')
        return {'root':alias,'path':rel,'text':path.read_text(encoding='utf8')[:MAX_READ]}
    def devices(self,_):
        self._mac();self._tool('xcrun')
        out=self._cmd(['xcrun','devicectl','list','devices'],timeout=15)
        return {'output':out,'truncated':len(out)>=MAX_OUTPUT,'note':'Device inventory only; pairing and control unverified'}
