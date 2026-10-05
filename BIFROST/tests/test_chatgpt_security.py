import json
import time
import unittest
from types import SimpleNamespace as NS
from unittest.mock import patch
import httpx
from openai import OpenAI
from authlib.jose import JsonWebKey, JsonWebToken
from bifrost.chatgpt_auth import ChatAuth, verify_identity, validate_callback, ISSUER
from bifrost.chatgpt_provider import ChatProvider, ProviderError
from bifrost.chatgpt_secrets import AppleSecrets
from bifrost.chatgpt_mcp import KeychainMCPStorage
from bifrost.chatgpt_stdio import ProviderHost

class Store:
    def __init__(self): self.data={}
    def read(self,key): return self.data.get(key)
    def write(self,key,value): self.data[key]=value

class SecurityTests(unittest.TestCase):
    def test_identity_only_scope_never_reports_connected(self):
        store=Store()
        store.write("connection",{"token":{"scope":"chatgpt.tokens.use.direct"}})
        self.assertEqual(ChatAuth(store).status()["state"],"permission_required")

    def test_callback_wrong_issuer_rejected(self):
        with self.assertRaises(ProviderError):
            validate_callback({"state":["s"],"code":["c"],"client_id":["x"],"iss":["https://evil.example"]},"s",None)

    def test_real_signed_identity_validation(self):
        key=JsonWebKey.generate_key("RSA",2048,is_private=True)
        claims={"iss":ISSUER,"aud":"oaiapp_test","sub":"person","iat":int(time.time()),
                "exp":int(time.time())+300,"nonce":"nonce"}
        token=JsonWebToken(["RS256"]).encode({"alg":"RS256"},claims,key).decode()
        response=NS(json=lambda:{"keys":[key.as_dict(is_private=False)]},raise_for_status=lambda:None)
        with patch("bifrost.chatgpt_auth.requests.get",return_value=response):
            config={"jwks_uri":ISSUER+"/jwks"}
            self.assertEqual(verify_identity(token,"oaiapp_test",config,"nonce")["sub"],"person")
            for client,nonce in [("different","nonce"),("oaiapp_test","wrong")]:
                with self.assertRaises(Exception): verify_identity(token,client,config,nonce)
            with self.assertRaises(Exception):
                verify_identity(token,"oaiapp_test",config,"nonce",now=int(time.time())+1000)

    def test_real_sdk_stream_and_request_contract(self):
        sent=[]
        def transport(request):
            sent.append(json.loads(request.content))
            payload='data: {"type":"response.output_text.delta","delta":"hi","item_id":"m","output_index":0,"content_index":0,"sequence_number":1}\n\n'
            payload+='data: {"type":"response.completed","response":{"id":"r","output":[],"status":"completed","object":"response","created_at":1,"model":"test"},"sequence_number":2}\n\n'
            return httpx.Response(200,headers={"content-type":"text/event-stream"},content=payload)
        with OpenAI(api_key="test-only",http_client=httpx.Client(transport=httpx.MockTransport(transport))) as client:
            p=ChatProvider(lambda:("account",client),model="test")
            chunks=[]
            self.assertEqual(p.chat("thread","hello",on_delta=chunks.append),"hi")
            self.assertEqual(chunks,["hi"])
        self.assertEqual(sent[0]["input"][0]["content"][0]["text"],"hello")
        self.assertFalse(sent[0]["store"])
        self.assertTrue(sent[0]["stream"])

    def test_non_apple_storage_fails_closed(self):
        with patch("bifrost.chatgpt_secrets.sys.platform","linux"):
            with self.assertRaises(ProviderError): AppleSecrets()

    def test_host_requires_login_and_file_confirmation(self):
        host=ProviderHost(Store())
        for request in [{"op":"connect"},{"op":"rdc.connect"},
                        {"op":"chat","thread":"t","prompt":"p","files":["private.pdf"]}]:
            with self.assertRaises(ProviderError): host.dispatch(request)

    def test_disconnect_preserves_registration_clears_secrets(self):
        store=Store()
        store.write("connection",{"client_id":"issued","token":{"access_token":"secret"},"id_token":"secret"})
        ChatAuth(store).disconnect()
        self.assertEqual(store.read("connection"),{"client_id":"issued"})

    def test_accounts_do_not_share_context(self):
        account=["a"]
        class Events:
            def __iter__(self): return iter([NS(type="response.completed")])
            def close(self): pass
        sent=[]
        client=NS(responses=NS(create=lambda **kw:sent.append(kw) or Events()))
        p=ChatProvider(lambda:(account[0],client),model="test")
        p.chat("t","first");account[0]="b";p.chat("t","second")
        self.assertEqual(len(sent[1]["input"]),1)

    def test_mcp_storage_round_trip(self):
        import asyncio
        from mcp.shared.auth import OAuthToken
        store=Store();storage=KeychainMCPStorage(store)
        async def check():
            self.assertIsNone(await storage.get_tokens())
            await storage.set_tokens(OAuthToken(access_token="test-token",token_type="Bearer"))
            self.assertEqual((await storage.get_tokens()).access_token,"test-token")
        asyncio.run(check())
