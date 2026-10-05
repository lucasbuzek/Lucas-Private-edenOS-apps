"""Official SIWC public-client integration; Authlib handles OAuth and JOSE."""
from __future__ import annotations
import hmac
import secrets
import threading
import time
import uuid
import webbrowser
from urllib.parse import urlsplit
import requests
from authlib.integrations.requests_client import OAuth2Session
from authlib.jose import JsonWebToken
from .chatgpt_callback import Callback
from .chatgpt_provider import ProviderError

ISSUER="https://auth.openai.com"
RESOURCE="https://api.openai.com/v1"
SCOPE="openid profile email offline_access resource.invoke chatgpt.tokens.use.direct"
PLAN="chatgpt.tokens.use.direct"

def require_plan_scope(scope):
    if PLAN not in scope.split() or "resource.invoke" not in scope.split():
        raise ProviderError("chatgpt_plan_not_authorized")

def validate_callback(params,state,client_id):
    if any(len(v)!=1 for v in params.values()): raise ProviderError("invalid_callback")
    returned=params.get("state",[""])[0]
    if not hmac.compare_digest(returned,state): raise ProviderError("invalid_state")
    if "error" in params: raise ProviderError("sign_in_declined")
    code=params.get("code",[""])[0]
    issued=params.get("client_id",[client_id])[0]
    if not code or not issued or issued=="dynamic_agent_client": raise ProviderError("registration_incomplete")
    if client_id and issued!=client_id: raise ProviderError("client_mismatch")
    if len(issued)>200 or not all(c.isalnum() or c in "_-" for c in issued):
        raise ProviderError("invalid_client")
    return code,issued

def discovery():
    response=requests.get(ISSUER+"/.well-known/openid-configuration",timeout=20,allow_redirects=False)
    response.raise_for_status()
    data=response.json()
    if data.get("issuer")!=ISSUER: raise ProviderError("invalid_issuer")
    for key in ("authorization_endpoint","token_endpoint","jwks_uri"):
        target=urlsplit(data.get(key,""))
        if target.scheme!="https" or target.netloc!="auth.openai.com":
            raise ProviderError("invalid_auth_endpoint")
    return data

def verify_identity(token,client_id,config,nonce=None,now=None):
    response=requests.get(config["jwks_uri"],timeout=20,allow_redirects=False)
    response.raise_for_status()
    options={k:{"essential":True} for k in ("iss","aud","exp","iat","sub")}
    options["iss"]["value"]=ISSUER
    options["aud"]["value"]=client_id
    claims=JsonWebToken(["RS256"]).decode(token,response.json(),claims_options=options)
    claims.validate(now=now,leeway=5)
    if not isinstance(claims["sub"],str) or not claims["sub"]: raise ProviderError("invalid_identity")
    if nonce is not None and claims.get("nonce")!=nonce: raise ProviderError("invalid_nonce")
    if claims.get("azp") not in (None,client_id): raise ProviderError("invalid_audience")
    if isinstance(claims["aud"],list) and len(claims["aud"])>1 and claims.get("azp")!=client_id:
        raise ProviderError("invalid_audience")
    return dict(claims)

class ChatAuth:
    def __init__(self,store):
        self.store=store
        self.lock=threading.RLock()

    def status(self):
        with self.lock:
            record=self.store.read("connection")
            if not record or not record.get("token"): return {"state":"connect"}
            token=record["token"]
            permitted=PLAN in token.get("scope","").split()
            return {"state":"connected" if permitted else "permission_required",
                    "plan_authorized":permitted,"account":record.get("email")}

    def connect(self):
        with self.lock:
            config=discovery()
            old=self.store.read("connection") or {}
            host=self.store.read("host")
            if host is None:
                host="urn:uuid:"+str(uuid.uuid4()); self.store.write("host",host)
            client_id=old.get("client_id")
            nonce=secrets.token_urlsafe(32)
            verifier=secrets.token_urlsafe(64)
            with Callback() as callback:
                oauth=OAuth2Session(client_id or "dynamic_agent_client",
                    scope=SCOPE,redirect_uri=callback.uri,code_challenge_method="S256",
                    token_endpoint_auth_method="none")
                kwargs={"nonce":nonce,"ext_agent_host_id":host,"resource":RESOURCE}
                if not client_id: kwargs["agent_name_hint"]="BIFROST ChatGPT Apple Plugin"
                if old.get("id_token"): kwargs["id_token_hint"]=old["id_token"]
                url,state=oauth.create_authorization_url(config["authorization_endpoint"],
                    code_verifier=verifier,**kwargs)
                callback.accept=lambda data: len(data.get("state",[]))==1 and hmac.compare_digest(data["state"][0],state)
                if not webbrowser.open(url): raise ProviderError("browser_unavailable")
                code,issued=validate_callback(callback.wait(),state,client_id)
                # Preserve registration even if exchange/validation is unavailable.
                pending=dict(old,client_id=issued)
                self.store.write("connection",pending)
                oauth.client_id=issued
                token=oauth.fetch_token(config["token_endpoint"],code=code,
                    code_verifier=verifier,resource=RESOURCE,timeout=30,allow_redirects=False)
                identity=verify_identity(token["id_token"],issued,config,nonce)
                if old.get("subject") and old["subject"]!=identity["sub"]:
                    raise ProviderError("account_mismatch")
                saved={"client_id":issued,"subject":identity["sub"],"email":identity.get("email"),
                       "id_token":token["id_token"],"token":dict(token)}
                self.store.write("connection",saved)
                return self.status()

    def client(self):
        from openai import OpenAI
        with self.lock:
            record=self.store.read("connection")
            if not record or not record.get("token"): raise ProviderError("sign_in_required")
            token=record["token"]
            require_plan_scope(token.get("scope",""))
            if token.get("expires_at",0)<=time.time()+60 or record.get("pending"):
                config=discovery()
                pending=record.get("pending")
                if pending is None:
                    if not token.get("refresh_token"): raise ProviderError("sign_in_required")
                    earliest=token.get("earliest_refresh_at",0)
                    if isinstance(earliest,str):
                        from datetime import datetime
                        earliest=datetime.fromisoformat(earliest.replace("Z","+00:00")).timestamp()
                    if earliest and earliest>time.time(): raise ProviderError("refresh_not_ready")
                    oauth=OAuth2Session(record["client_id"],token=token,token_endpoint_auth_method="none")
                    rotated=oauth.refresh_token(config["token_endpoint"],resource=RESOURCE,
                        timeout=30,allow_redirects=False)
                    pending={"token":dict(rotated),"received_at":time.time()}
                    # Rotation is durable before JWKS retrieval; never lose replacement refresh token.
                    self.store.write("connection",dict(record,pending=pending))
                fresh=pending["token"]
                identity=verify_identity(fresh["id_token"],record["client_id"],config,now=pending["received_at"])
                if identity["sub"]!=record["subject"]: raise ProviderError("account_mismatch")
                require_plan_scope(fresh.get("scope",token.get("scope","")))
                fresh["scope"]=fresh.get("scope",token.get("scope",""))
                record=dict(record,token=fresh,id_token=fresh["id_token"])
                record.pop("pending",None); self.store.write("connection",record); token=fresh
            if token.get("expires_at",0)<=time.time(): raise ProviderError("refresh_not_ready")
            return (record["subject"]+":"+record["client_id"],
                    OpenAI(api_key=token["access_token"],base_url=RESOURCE,max_retries=0,timeout=180))

    def disconnect(self):
        with self.lock:
            record=self.store.read("connection") or {}
            # Local sign-out clears credentials; provider grant remains managed in ChatGPT settings.
            self.store.write("connection",{"client_id":record["client_id"]} if record.get("client_id") else {})
