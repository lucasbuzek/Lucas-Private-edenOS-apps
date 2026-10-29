#!/usr/bin/env python3
"""DeLorean on-demand standalone stdio MCP server (no third-party deps).

Implements JSON-RPC 2.0 line transport, tools/list, tools/call, initialize
(legacy clients) and ping. Does not run a daemon or use the network. An optional
SDK-backed HTTP adapter can be added to the SAME product without replacing this.
"""
from __future__ import annotations
import argparse
import json
import os
from pathlib import Path
import sys
from typing import Callable

try:
    from .standalone_backup import DeLorean, Denied, history
    from .bridge_contract import platform_matrix
except ImportError:
    from standalone_backup import DeLorean, Denied, history
    from bridge_contract import platform_matrix

VERSION='0.2.5-candidate'
PROTOCOL='2025-06-18'
MAX_REQUEST_BYTES=1024*1024
UI_RESOURCE='ui://edenos-delorean/timeline'


def tool(name, description, properties=None, required=None, readonly=True):
    return {'name':name,'description':description,'inputSchema':{'type':'object','properties':properties or {},'required':required or [],'additionalProperties':False},
            'annotations':{'readOnlyHint':readonly,'destructiveHint':False,'openWorldHint':False}}

def field(desc):return {'type':'string','description':desc}
def string_array(desc):return {'type':'array','items':{'type':'string'},'description':desc}

TOOLS=[
    tool('delorean_dashboard','Read live owner-scoped snapshot index for the established DeLorean interactive timeline.'),
    tool('delorean_status','Read host, grants, backend availability.'),
    tool('delorean_platform_matrix','Read truthful multi-agent and cross-OS client target/evidence matrix; no installed client or connector is implied.'),
    tool('delorean_capabilities','Read implemented and unimplemented backup/recovery capabilities.'),
    tool('delorean_backup_plan','Plan local existing file/folder, project, app or device-data backup. A device-data backup is NOT a bootable system image.',{'source':field('File/directory on explicitly granted source root'),'scope':{'type':'string','enum':['file','folder','project','app','device-data']},'project':field('Existing project, app or device identifier')},['source','scope','project']),
    tool('delorean_backup_create','Create and hash-verify a new local file-tree snapshot, retaining the original. Requires explicit confirmation; does not capture running DB consistency or bootable OS.',{'source':field('Allowed source directory or file'),'scope':{'type':'string','enum':['file','folder','project','app','device-data']},'project':field('Name of existing project/app/device'), 'confirmation':{'type':'string','const':'BACKUP NOW'}},['source','scope','project','confirmation'],False),
    tool('delorean_snapshots','List only snapshots belonging to configured owner.'),
    tool('delorean_timeline','Unified local snapshots and explicitly recorded provider events, no provider data fabricated.',{'project':field('Optional project filter')}),
    tool('delorean_compare','Compare two verified managed snapshots within the same project/owner.',{'old':field('Earlier snapshot ID'),'new':field('Later snapshot ID')},['old','new']),
    tool('delorean_verify','Verify SHA-256 and completeness against a managed snapshot.',{'snapshot':field('Snapshot ID')},['snapshot']),
    tool('delorean_plan_restore','Preview a selected or full restore into a NEW directory within an allowed restore root.',{'snapshot':field('Snapshot ID'),'target':field('New destination directory'),'include':string_array('Optional selected paths, otherwise all')},['snapshot','target']),
    tool('delorean_stage_restore','Copy selected or all snapshot files into a NEW directory, hash-verify, never overwrite existing content.',{'snapshot':field('Snapshot ID'),'target':field('New destination directory'),'confirmation':{'type':'string','const':'RESTORE TO NEW DIRECTORY'},'include':string_array('Optional selected paths')},['snapshot','target','confirmation'],False),
    tool('delorean_record_event','Record an external Git, cloud revision, or native snapshot REFERENCE; this does not verify or back up its bytes.',{'project':field('Project identifier'),'provider':field('Provider e.g. GitHub'),'kind':field('Event type'),'ref':field('Immutable provider ref'),'occurred_at':field('Timezone-aware ISO-8601')},['project','provider','kind','ref','occurred_at'],False),
    tool('delorean_penelope_import','Import an explicitly authorized PENELOPE references JSON export without requiring PENELOPE service or copying file payloads.',{'source':field('Allowed local PENELOPE JSON export')},['source'],False),
    tool('delorean_sqlite_backup_plan','Plan native SQLite online primary database backup; WAL-consistent, attachments excluded.',{'source':field('Allowed existing SQLite database'),'project':field('Project/app identifier')},['source','project']),
    tool('delorean_sqlite_backup_create','Create transactionally consistent primary SQLite backup; stage and verify without overwriting live DB.',{'source':field('Allowed existing SQLite database'),'project':field('Project/app identifier'),'confirmation':{'type':'string','const':'BACKUP SQLITE DATABASE'}},['source','project','confirmation'],False),
    tool('delorean_device_recovery_plan','Read-only platform-native complete device recovery plan. Does NOT perform OS imaging.',{'device':{'type':'string','enum':['auto','mac','iphone','ipad','windows','linux','android']}},[]),
    tool('delorean_restic_status','Check optional encrypted restic backup engine readiness without returning repository secrets.'),
    tool('delorean_restic_backup','Delegate encrypted backup to independently configured restic repository (including cloud), not enabled by default.',{'source':field('Allowed source file/folder'),'project':field('Project identifier'),'confirmation':{'type':'string','const':'CLOUD BACKUP'}},['source','project','confirmation'],False),
    tool('delorean_restic_snapshots','List optional encrypted restic snapshots belonging to the current project and owner.',{'project':field('Existing project identifier')},['project']),
    tool('delorean_restic_check','Run restic repository integrity check (not proof of full restore).'),
    tool('delorean_restic_restore','Restore exact owner-scoped restic snapshot into a NEW grant-limited directory; no overwrites.',{'project':field('Project identifier'),'snapshot':field('Exact full snapshot id'),'target':field('New isolated destination'),'confirmation':{'type':'string','const':'RESTORE CLOUD SNAPSHOT TO NEW DIRECTORY'}},['project','snapshot','target','confirmation'],False),
    tool('delorean_kopia_status','Read readiness of externally configured encrypted Kopia repository without exposing credentials.'),
    tool('delorean_kopia_snapshots','List owner/project-tagged Kopia snapshots for an explicitly granted source.',{'source':field('Exact granted source'),'project':field('Project identity')},['source','project']),
    tool('delorean_kopia_backup','Create encrypted Kopia snapshot with repository actions disabled; requires local write-enabled MCP session.',{'source':field('Granted source'),'project':field('Project identity'),'confirmation':{'type':'string','const':'ENCRYPTED KOPIA BACKUP'}},['source','project','confirmation'],False),
    tool('delorean_kopia_verify','Check metadata for exact owner-scoped Kopia snapshot (not a full blob/restore test).',{'source':field('Granted source'),'project':field('Project identity'),'snapshot':field('Full snapshot ID')},['source','project','snapshot']),
    tool('delorean_kopia_restore','Stage owner-scoped encrypted Kopia snapshot into a NEW isolated destination, without overwriting.',{'source':field('Granted source'),'project':field('Project identity'),'snapshot':field('Full snapshot ID'),'target':field('New restore destination'),'confirmation':{'type':'string','const':'RESTORE KOPIA TO NEW DIRECTORY'}},['source','project','snapshot','target','confirmation'],False),
    tool('delorean_time_machine_status','Read status of existing macOS Time Machine backups; Mac only.'),
    tool('delorean_time_machine_start','Start preconfigured native Apple Time Machine backup; does not format backup disk or automate full system restoration.',{'confirmation':{'type':'string','const':'START EXISTING TIME MACHINE BACKUP'}},['confirmation'],False),
]
# Only the read-only dashboard has a host-renderable UI.
TOOLS[0]['_meta']={'ui':{'resourceUri':UI_RESOURCE,'visibility':['model','app']}}
TOOL_BY_NAME={t['name']:t for t in TOOLS}

class Server:
    def __init__(self, core:DeLorean, *, allow_writes:bool=False):
        self.core=core
        self.allow_writes=bool(allow_writes)

    def visible_tools(self):
        # User launch, not an LLM-supplied magic phrase, gates write-capable tools.
        return TOOLS if self.allow_writes else [t for t in TOOLS if t['annotations']['readOnlyHint']]
    def invoke(self, name:str, args:dict):
        if name not in TOOL_BY_NAME:
            raise ValueError('Unknown MCP tool')
        if not self.allow_writes and not TOOL_BY_NAME[name]['annotations']['readOnlyHint']:
            raise Denied('Write-capable MCP tools disabled for this session; requires locally approved --enable-writes launch')
        if not isinstance(args,dict):raise ValueError('Tool arguments must be object')
        schema=TOOL_BY_NAME[name]['inputSchema'];props=schema['properties']
        if set(args)-set(props):raise ValueError('Unexpected arguments')
        if set(schema['required'])-set(args):raise ValueError('Missing required arguments')
        for k,v in args.items():
            t=props[k]
            if t.get('type')=='string' and not isinstance(v,str):raise ValueError('Argument '+k+' must be string')
            if t.get('type')=='array' and (not isinstance(v,list) or not all(isinstance(x,str) for x in v)):
                raise ValueError('Argument '+k+' must be list of strings')
            if 'const' in t and v!=t['const']:raise Denied('Confirmation requirement not satisfied')
            if 'enum' in t and v not in t['enum']:raise ValueError('Invalid scope')
        c=self.core
        return {
            'delorean_dashboard':lambda:c.dashboard_catalog(),
            'delorean_status':lambda:c.status(),
            'delorean_platform_matrix':lambda:platform_matrix(),
            'delorean_capabilities':lambda:c.capabilities(),
            'delorean_backup_plan':lambda:c.backup_plan(args['source'],args['scope'],args['project']),
            'delorean_backup_create':lambda:c.backup_create(args['source'],args['scope'],args['project'],args['confirmation']),
            'delorean_snapshots':lambda:c.snapshots(),
            'delorean_timeline':lambda:c.timeline(args.get('project','')),
            'delorean_compare':lambda:c.compare(args['old'],args['new']),
            'delorean_verify':lambda:c.verify_snapshot(args['snapshot']),
            'delorean_plan_restore':lambda:c.recovery_plan(args['snapshot'],args['target'],args.get('include')),
            'delorean_stage_restore':lambda:c.recovery_stage(args['snapshot'],args['target'],args['confirmation'],args.get('include')),
            'delorean_record_event':lambda:c.reference_event(args['project'],args['provider'],args['kind'],args['ref'],args['occurred_at']),
            'delorean_penelope_import':lambda:c.penelope_import(args['source']),
            'delorean_sqlite_backup_plan':lambda:c.sqlite_backup_plan(args['source'],args['project']),
            'delorean_sqlite_backup_create':lambda:c.sqlite_backup_create(args['source'],args['project'],args['confirmation']),
            'delorean_device_recovery_plan':lambda:c.device_recovery_plan(args.get('device','auto')),
            'delorean_restic_status':lambda:c.restic_status(),
            'delorean_restic_backup':lambda:c.restic_backup(args['source'],args['project'],args['confirmation']),
            'delorean_restic_snapshots':lambda:c.restic_snapshots(args['project']),
            'delorean_restic_check':lambda:c.restic_check(),
            'delorean_restic_restore':lambda:c.restic_restore(args['project'],args['snapshot'],args['target'],args['confirmation']),
            'delorean_kopia_status':lambda:c.kopia_status(),
            'delorean_kopia_snapshots':lambda:c.kopia_snapshots(args['source'],args['project']),
            'delorean_kopia_backup':lambda:c.kopia_backup(args['source'],args['project'],args['confirmation']),
            'delorean_kopia_verify':lambda:c.kopia_verify(args['source'],args['project'],args['snapshot']),
            'delorean_kopia_restore':lambda:c.kopia_restore(args['source'],args['project'],args['snapshot'],args['target'],args['confirmation']),
            'delorean_time_machine_status':lambda:c.time_machine_status(),
            'delorean_time_machine_start':lambda:c.time_machine_start(args['confirmation']),
        }[name]()

    def handle(self, req:dict):
        if not isinstance(req,dict) or req.get('jsonrpc')!='2.0' or not isinstance(req.get('method'),str):
            return {'jsonrpc':'2.0','id':req.get('id') if isinstance(req,dict) else None,'error':{'code':-32600,'message':'Invalid JSON-RPC request'}}
        method=req['method']; ident=req.get('id')
        if ident is None:return None  # ignore notifications including notifications/initialized
        reply={'jsonrpc':'2.0','id':ident}
        if method=='resources/list':
            reply['result']={'resources':[{'uri':UI_RESOURCE,'name':'DeLorean Timeline',
                'description':'Read-only unified project, app and backup history dashboard',
                'mimeType':'text/html;profile=mcp-app'}]}
        elif method=='resources/read':
            uri=(req.get('params') or {}).get('uri')
            if uri != UI_RESOURCE:
                reply['error']={'code':-32602,'message':'Unknown UI resource'}
            else:
                file=Path(__file__).resolve().parents[1]/'platforms'/'web'/'index.html'
                if not file.is_file():
                    reply['error']={'code':-32603,'message':'UI resource not installed'}
                else:
                    reply['result']={'contents':[{'uri':UI_RESOURCE,
                       'mimeType':'text/html;profile=mcp-app',
                       'text':file.read_text(encoding='utf-8'),
                       '_meta':{'ui':{'prefersBorder':False}}}]}
        elif method=='initialize':
            params=req.get('params') or {}
            version=params.get('protocolVersion',PROTOCOL)
            if version not in ('2025-03-26','2025-06-18','2026-07-28'):
                version=PROTOCOL
            reply['result']={'protocolVersion':version,'capabilities':{'tools':{},'resources':{}},'serverInfo':{'name':'edenos-delorean','version':VERSION},'instructions':'Local owner-granted on-demand backup/recovery. Confirm writes; no destructive in-place restore.'}
        elif method=='ping':reply['result']={}
        elif method=='tools/list':reply['result']={'tools':self.visible_tools()}
        elif method=='tools/call':
            params=req.get('params') or {}
            name=params.get('name')
            if name not in TOOL_BY_NAME:
                reply['error']={'code':-32602,'message':'Unknown MCP tool'}
            else:
                try:
                    result=self.invoke(name,params.get('arguments') or {})
                    reply['result']={'content':[{'type':'text','text':json.dumps(result,ensure_ascii=False)}],
                                     'structuredContent':{'result':result}, 'isError':False}
                except (history.RecoveryError,ValueError,OSError,TimeoutError,RuntimeError) as e:
                    reply['result']={'content':[{'type':'text','text':str(e)[:320]}],'isError':True}
        else:reply['error']={'code':-32601,'message':'Method not implemented'}
        return reply


def build_parser():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--home',default=os.environ.get('DELOREAN_HOME',str(Path.home()/'.local/share/edenos-delorean')))
    ap.add_argument('--allow-source',action='append',default=[],help='Explicit source directory grant (may repeat)')
    ap.add_argument('--allow-restore',action='append',default=[],help='Explicit isolated destination root grant (may repeat)')
    ap.add_argument('--owner',default=os.environ.get('DELOREAN_OWNER','LucasPRIVATE'))
    ap.add_argument('--enable-writes',action='store_true',help='Explicit local owner startup consent for write-capable tools; not a ChatGPT approval or multi-user authorization mechanism')
    return ap


def main(argv=None):
    args=build_parser().parse_args(argv)
    try:core=DeLorean(args.home,args.allow_source,args.allow_restore,owner=args.owner)
    except Denied as e:
        print('DeLorean startup refusal: '+str(e),file=sys.stderr);return 2
    server=Server(core, allow_writes=args.enable_writes)
    for line in sys.stdin.buffer:
        if len(line)>MAX_REQUEST_BYTES:
            sys.stdout.write(json.dumps({'jsonrpc':'2.0','id':None,'error':{'code':-32700,'message':'Oversize JSON-RPC request'}})+'\n');sys.stdout.flush();continue
        try:
            req=json.loads(line.decode('utf-8'))
            response=server.handle(req)
        except (ValueError,UnicodeDecodeError,json.JSONDecodeError):
            response={'jsonrpc':'2.0','id':None,'error':{'code':-32700,'message':'Invalid JSON'}}
        except Exception as e:
            # Never expose traceback, paths or secrets to model-visible channels.
            print('Unexpected handler error: '+type(e).__name__,file=sys.stderr)
            response={'jsonrpc':'2.0','id':req.get('id') if isinstance(req,dict) else None,'error':{'code':-32603,'message':'Internal error'}}
        if response is not None:
            sys.stdout.write(json.dumps(response,ensure_ascii=False,separators=(',',':'))+'\n');sys.stdout.flush()
    return 0

if __name__=='__main__':sys.exit(main())
