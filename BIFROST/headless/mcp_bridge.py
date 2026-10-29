#!/usr/bin/env python3
"""BIFROSTbridge local stdio MCP, legacy 2025-06-18 plus modern 2026-07-28.

Uses existing owners. No remote listener, shell execution, or implicit online read.
The launching local client grants access by starting this process as its user.
"""
import contextlib
import json
import sys
import shortcalls
import storage_adapter

VERSION = '2025-06-18'
MODERN_VERSION = '2026-07-28'
VERSION_KEY = 'io.modelcontextprotocol/protocolVersion'
CAPABILITIES_KEY = 'io.modelcontextprotocol/clientCapabilities'
SERVER_INFO_KEY = 'io.modelcontextprotocol/serverInfo'
LIMIT = 65536
EMPTY = {'type':'object','properties':{},'additionalProperties':False}

def tools():
    result = []
    for entry in shortcalls.catalog()['actions']:
        if shortcalls.resolve(entry['id'])['available']:
            result.append({'name':entry['id'], 'description':entry['title'], 'inputSchema':EMPTY,
                           'annotations':{'readOnlyHint':True,'destructiveHint':False}})
    result.append({'name':'bifrost.storage.profiles','description':'List saved storage profile names and providers; no online requests.', 'inputSchema':EMPTY,'annotations':{'readOnlyHint':True}})
    return result

class Session:
    def __init__(self):
        self.initialized = False
        self.ready = False

    def handle(self, message):
        if not isinstance(message,dict) or message.get('jsonrpc')!='2.0' or not isinstance(message.get('method'),str):
            return self.error(None,-32600,'Invalid request')
        ident=message.get('id'); method=message['method']; params=message.get('params',{})
        if 'id' not in message:
            if method=='notifications/initialized' and self.initialized:self.ready=True
            return None
        if not isinstance(ident,(str,int)) or isinstance(ident,bool):return self.error(None,-32600,'Invalid request id')
        if not isinstance(params,dict):return self.error(ident,-32602,'Invalid parameters')
        if method == 'server/discover' or '_meta' in params:
            return self.modern(ident, method, params)
        if method=='initialize':
            if self.initialized:return self.error(ident,-32600,'Already initialized')
            if not isinstance(params.get('protocolVersion'),str) or not isinstance(params.get('capabilities'),dict) or not isinstance(params.get('clientInfo'),dict):
                return self.error(ident,-32602,'Missing initialization fields')
            self.initialized=True
            return self.result(ident,{'protocolVersion':VERSION,'capabilities':{'tools':{'listChanged':False}},'serverInfo':{'name':'BIFROSTbridge-local','version':'0.1.0'}})
        if method=='ping':return self.result(ident,{})
        if not self.ready:return self.error(ident,-32000,'Initialize the session first')
        if method=='tools/list':return self.result(ident,{'tools':tools()})
        if method=='tools/call':
            return self.run_tool(ident,params,modern=False)
        return self.error(ident,-32601,'Method not found')

    def modern(self, ident, method, params):
        """Stateless 2026 RPC; each request supplies its own version/capabilities."""
        meta = params.get('_meta')
        if not isinstance(meta, dict):
            return self.error(ident,-32602,'Modern request requires _meta')
        version = meta.get(VERSION_KEY)
        if not isinstance(version, str):
            return self.error(ident,-32602,'Missing protocol version')
        if version != MODERN_VERSION:
            return self.error(ident,-32022,'Unsupported protocol version',
                              {'supported':[MODERN_VERSION],'requested':version})
        if not isinstance(meta.get(CAPABILITIES_KEY),dict):
            return self.error(ident,-32602,'Missing client capabilities')
        def payload(fields):
            return {'resultType':'complete',**fields,
                    '_meta':{SERVER_INFO_KEY:{'name':'BIFROSTbridge-local','version':'0.2.0'}}}
        if method=='server/discover':
            if set(params) != {'_meta'}:
                return self.error(ident,-32602,'Unexpected discovery parameters')
            return self.result(ident,payload({
                'supportedVersions':[MODERN_VERSION],
                'capabilities':{'tools':{}},
                'ttlMs':0,'cacheScope':'private'}))
        # MCP 2026-07-28 removed ping; retain it only in the legacy session path.
        if method=='tools/list':
            if set(params) != {'_meta'}:
                return self.error(ident,-32602,'Unsupported tool list pagination')
            return self.result(ident,payload({'tools':tools(),'ttlMs':0,'cacheScope':'private'}))
        if method=='tools/call':
            if not set(params).issubset({'_meta','name','arguments'}):
                return self.error(ident,-32602,'Unexpected tool parameters')
            return self.run_tool(ident,params,modern=True)
        return self.error(ident,-32601,'Method not found')

    def run_tool(self, ident, params, modern=False):
        name=params.get('name'); arguments=params.get('arguments',{})
        if arguments != {} or not isinstance(arguments,dict):
            return self.error(ident,-32602,'This tool accepts no arguments')
        # Untrusted JSON can supply arrays or objects as tool names. Reject with a
        # typed parameters error rather than propagating an unhashable-type fault.
        if not isinstance(name,str) or name not in {t['name'] for t in tools()}:
            return self.error(ident,-32602,'Unknown or unavailable tool')
        try:
            with contextlib.redirect_stdout(sys.stderr):
                value=storage_adapter.profiles() if name=='bifrost.storage.profiles' else shortcalls.call(name)
            payload={'content':[{'type':'text','text':json.dumps(value)}],'isError':False}
        except Exception:
            payload={'content':[{'type':'text','text':'Local capability failed; check the local installation.'}],'isError':True}
        if modern:
            payload={'resultType':'complete',**payload,
                     '_meta':{SERVER_INFO_KEY:{'name':'BIFROSTbridge-local','version':'0.2.0'}}}
        return self.result(ident,payload)

    @staticmethod
    def result(ident,result):return {'jsonrpc':'2.0','id':ident,'result':result}
    @staticmethod
    def error(ident,code,message,data=None):
        err={'code':code,'message':message}
        if data is not None:err['data']=data
        return {'jsonrpc':'2.0','id':ident,'error':err}

def main():
    session=Session()
    while True:
        line=sys.stdin.buffer.readline(LIMIT+1)
        if not line:break
        if len(line)>LIMIT:
            print(json.dumps(session.error(None,-32600,'Message too large')),flush=True)
            return 1
        try:response=session.handle(json.loads(line))
        except (ValueError,UnicodeError):response=session.error(None,-32700,'Invalid JSON')
        except Exception:response=session.error(None,-32603,'Internal error')
        if response is not None:print(json.dumps(response,ensure_ascii=True),flush=True)
    return 0

if __name__=='__main__':raise SystemExit(main())
