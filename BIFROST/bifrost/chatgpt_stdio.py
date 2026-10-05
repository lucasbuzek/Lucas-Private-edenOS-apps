"""Private parent-owned IPC. Never expose this process's stdin as a remote API."""
import asyncio
import json
import sys
from .chatgpt_auth import ChatAuth
from .chatgpt_mcp import RDCClient
from .chatgpt_provider import ChatProvider, ProviderError
from .chatgpt_secrets import AppleSecrets

def emit(value):
    print(json.dumps(value,separators=(",",":")),flush=True)

class ProviderHost:
    def __init__(self,store):
        self.auth=ChatAuth(store)
        self.chat=ChatProvider(self.auth.client)
        self.rdc=RDCClient(store)

    def dispatch(self,request,delta=lambda value:None):
        op=request.get("op")
        if op=="status": return self.auth.status()
        if op=="connect":
            if request.get("confirmed") is not True: raise ProviderError("login_confirmation_required")
            result=self.auth.connect(); self.chat.forget(); return result
        if op=="disconnect":
            self.auth.disconnect(); self.chat.forget(); return {"state":"connect"}
        if op=="forget":
            self.chat.forget(request.get("thread")); return {"forgotten":True}
        if op=="chat":
            files=request.get("files",[])
            if files and request.get("files_confirmed") is not True: raise ProviderError("file_confirmation_required")
            return {"text":self.chat.chat(request.get("thread"),request.get("prompt"),files,on_delta=delta)}
        if op in {"rdc.connect","rdc.tools","rdc.call"}:
            if op=="rdc.connect" and request.get("confirmed") is not True:
                raise ProviderError("login_confirmation_required")
            return asyncio.run(self.rdc.request(name=request.get("tool") if op=="rdc.call" else None,
                arguments=request.get("arguments"),
                allowed=set(request.get("authorized_tools",[])),
                connect=op=="rdc.connect"))
        raise ProviderError("unknown_operation")

def main():
    try: host=ProviderHost(AppleSecrets())
    except Exception:
        emit({"error":"apple_keychain_unavailable"}); return
    # Exactly one Core-owned process. Core authenticates HEIMDALL before forwarding.
    while True:
        line=sys.stdin.buffer.readline(1024*1024+1)
        if not line: break
        request_id=None
        try:
            if len(line)>1024*1024: raise ProviderError("request_too_large")
            request=json.loads(line)
            if not isinstance(request,dict): raise ProviderError("invalid_request")
            request_id=request.get("id")
            if not isinstance(request_id,str) or len(request_id)>200: raise ProviderError("invalid_request")
            result=host.dispatch(request,lambda text:emit({"id":request_id,"delta":text}))
            emit({"id":request_id,"result":result})
        except ProviderError as e:
            emit({"id":request_id,"error":str(e)})
        except Exception:
            # SDK exception bodies can include prompts or credentials; never forward them.
            emit({"id":request_id,"error":"provider_request_failed"})
        if len(line)>1024*1024: break

if __name__=="__main__": main()
