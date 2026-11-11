"""Connector-neutral event ingress for the ONE DeLorean recovery catalog.

Host agents may fetch authorized revision metadata through their own connectors,
then submit narrowly typed, untrusted references. This module does NOT authenticate
providers or mark a reference as a backed-up, restorable snapshot. No provider
credentials, URLs, file payloads, paths or arbitrary raw connector responses.
"""
from __future__ import annotations

from datetime import datetime, timezone
from hashlib import sha256
import json
import os
from pathlib import Path
import re

try:
    from .timemachine import RecoveryError
except ImportError:
    from timemachine import RecoveryError

SCHEMA = 'eden.delorean.connector-events.v1'
EVENT_SCHEMA = 'eden.delorean.connector-event.v1'
EVIDENCE = 'CONNECTOR_REFERENCE_RECORDED_NOT_BACKUP_VERIFIED'
PROVIDERS = {'github','google-drive','dropbox','other'}
KINDS = {'commit','tag','file-revision','cloud-snapshot-reference','release','backup-reference'}
MAX_BATCH = 100
MAX_BUNDLE_BYTES = 128 * 1024
MAX_REF_LENGTH = 256
REF_PATTERN = re.compile(r'^[A-Za-z0-9][A-Za-z0-9._:/+-]{0,255}$')
ID_PATTERN = re.compile(r'^[A-Za-z0-9][A-Za-z0-9_.-]{0,119}$')
ENTRY_KEYS = {'provider','project','account_alias','kind','ref','occurred_at'}
TOP_KEYS = {'schema','owner','entries'}


def _id(value, name):
    if not isinstance(value,str) or not ID_PATTERN.fullmatch(value) or value in ('.','..'):
        raise RecoveryError('Invalid '+name+' identifier')
    return value


def _ref(value):
    # No URL query strings, whitespace, credentials, or raw provider output.
    if not isinstance(value,str) or len(value)>MAX_REF_LENGTH or not REF_PATTERN.fullmatch(value) or '://' in value or '//' in value:
        raise RecoveryError('Unsafe connector reference (opaque ID only, no URL or token)')
    return value


def _time(value):
    if not isinstance(value,str) or len(value)>60:
        raise RecoveryError('Invalid connector event time')
    try:
        dt=datetime.fromisoformat(value.replace('Z','+00:00'))
    except ValueError as exc:
        raise RecoveryError('Invalid connector event time') from exc
    if dt.tzinfo is None:
        raise RecoveryError('Connector event time must contain timezone')
    return dt.astimezone(timezone.utc).isoformat()


def canonical_records(bundle:dict, owner:str) -> list[dict]:
    _id(owner,'owner')
    if not isinstance(bundle,dict) or set(bundle)!=TOP_KEYS or bundle.get('schema')!=SCHEMA:
        raise RecoveryError('Invalid connector evidence bundle schema/fields')
    if bundle.get('owner')!=owner:
        raise RecoveryError('Cross-owner connector event import denied')
    entries=bundle.get('entries')
    if not isinstance(entries,list) or not 1<=len(entries)<=MAX_BATCH:
        raise RecoveryError('Connector events batch must have 1-100 entries')
    try:
        encoded=json.dumps(bundle,ensure_ascii=False,sort_keys=True).encode('utf-8')
    except (TypeError,ValueError) as exc:
        raise RecoveryError('Invalid connector bundle types') from exc
    if len(encoded)>MAX_BUNDLE_BYTES:
        raise RecoveryError('Connector bundle exceeds size cap')
    records=[]
    for item in entries:
        if not isinstance(item,dict) or set(item)!=ENTRY_KEYS:
            raise RecoveryError('Invalid event fields: URLs, token and raw payloads forbidden')
        if (not isinstance(item['provider'],str) or not isinstance(item['kind'],str) or
                item['provider'] not in PROVIDERS or item['kind'] not in KINDS):
            raise RecoveryError('Unsupported provider or event kind')
        identity={
            'schema':EVENT_SCHEMA,
            'owner':owner,
            'project':_id(item['project'],'project'),
            'provider':item['provider'],
            'account_alias':_id(item['account_alias'],'account alias'),
            'kind':item['kind'],
            'provider_ref':_ref(item['ref']),
            'occurred_at':_time(item['occurred_at']),
        }
        raw=json.dumps(identity,sort_keys=True,separators=(',',':'),ensure_ascii=False).encode()
        identity['event_id']=sha256(raw).hexdigest()[:24]
        identity['evidence']=EVIDENCE
        identity['recoverability']='UNKNOWN_SOURCE_REFERENCE_ONLY'
        records.append(identity)
    dedup={x['event_id']:x for x in records}
    return [dedup[k] for k in sorted(dedup)]


def preview(bundle:dict,owner:str) -> dict:
    records=canonical_records(bundle,owner)
    return {'schema':SCHEMA,'owner':owner,'valid':True,'unique_events':len(records),
            'providers':sorted({x['provider'] for x in records}),
            'projects':sorted({x['project'] for x in records}),
            'would_write':False,'evidence':EVIDENCE,'recoverability':'NOT_VERIFIED',
            'provider_authentication':'PERFORMED_OUTSIDE_DELOREAN_NOT_VERIFIED_HERE'}


def _folder(catalog:Path) -> Path:
    folder=catalog/'connector-events'
    if catalog.is_symlink() or folder.is_symlink() or any(x.is_symlink() for x in catalog.parents):
        raise RecoveryError('Symlinked connector catalog denied')
    return folder


def import_events(catalog:Path,bundle:dict,owner:str) -> dict:
    records=canonical_records(bundle,owner) # validate everything BEFORE any mutation
    folder=_folder(catalog)
    folder.mkdir(parents=True,exist_ok=True,mode=0o700)
    existing=0
    new=[]
    for item in records:
        dest=folder/(item['event_id']+'.json')
        if dest.is_symlink():
            raise RecoveryError('Symlinked existing connector event denied')
        if dest.exists():
            try:
                previous=json.loads(dest.read_text(encoding='utf-8'))
            except (ValueError,OSError) as exc:
                raise RecoveryError('Corrupt connector event on disk') from exc
            if previous!=item:
                raise RecoveryError('Event identity collision or changed record')
            existing+=1
        else:
            new.append((dest,item))
    # Exclusive creation: no overwrite if another process creates same event.
    committed=0
    for dest,item in new:
        try:
            with os.fdopen(os.open(dest,os.O_WRONLY | os.O_CREAT | os.O_EXCL,0o600),'w',encoding='utf-8') as f:
                json.dump(item,f,ensure_ascii=False,sort_keys=True)
                f.write('\n')
                f.flush();os.fsync(f.fileno())
        except FileExistsError as exc:
            raise RecoveryError('Concurrent event change; retry after readback') from exc
        committed+=1
    return {'schema':SCHEMA,'owner':owner,'created':committed,'reused':existing,
            'total_unique':len(records),'evidence':EVIDENCE,
            'source_provider_was_called_by_delorean':False,
            'backup_or_restore_verified':False}


def list_events(catalog:Path,owner:str,project:str='') -> list[dict]:
    _id(owner,'owner')
    if project: _id(project,'project')
    folder=_folder(catalog)
    if not folder.is_dir():return []
    result=[]
    # Limit user-visible results and metadata traversal for this review candidate.
    for path in sorted(folder.glob('*.json')):
        if path.is_symlink() or path.stat().st_size>8192:
            raise RecoveryError('Unsafe stored connector evidence')
        try: item=json.loads(path.read_text(encoding='utf-8'))
        except (OSError,ValueError) as exc:raise RecoveryError('Corrupt connector event') from exc
        if (set(item)!= {'schema','owner','project','provider','account_alias','kind','provider_ref','occurred_at','event_id','evidence','recoverability'}
                or item.get('schema')!=EVENT_SCHEMA or path.stem!=item.get('event_id')
                or item.get('evidence')!=EVIDENCE or item.get('recoverability')!='UNKNOWN_SOURCE_REFERENCE_ONLY'):
            raise RecoveryError('Invalid connector event identity')
        identity={k:item[k] for k in ('schema','owner','project','provider','account_alias','kind','provider_ref','occurred_at')}
        if sha256(json.dumps(identity,sort_keys=True,separators=(',',':'),ensure_ascii=False).encode()).hexdigest()[:24]!=item['event_id']:
            raise RecoveryError('Connector event fingerprint mismatch')
        if item.get('owner')==owner and (not project or item.get('project')==project):
            result.append(item)
        if len(result)>1000:raise RecoveryError('Too many connector events; use scoped project')
    return sorted(result,key=lambda x:(x['occurred_at'],x['event_id']))
