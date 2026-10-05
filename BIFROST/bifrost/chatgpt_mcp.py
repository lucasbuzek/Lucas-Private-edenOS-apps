"""Optional RDC provider through the mature MCP SDK; never a new MCP host."""
import asyncio
import hmac
import webbrowser
from urllib.parse import urlsplit, parse_qs
import httpx
from mcp import ClientSession
from mcp.client.auth import OAuthClientProvider, TokenStorage
from mcp.client.streamable_http import streamable_http_client
from mcp.shared.auth import OAuthClientInformationFull, OAuthClientMetadata, OAuthToken
from .chatgpt_callback import Callback
from .chatgpt_provider import ProviderError

RDC_URL="https://mcp.desktopcommander.app/mcp"

def authorize_tool(name,allowed):
    if not isinstance(name,str) or name not in allowed: raise ProviderError("tool_not_authorized")

class KeychainMCPStorage(TokenStorage):
    def __init__(self,store): self.store=store
    async def get_tokens(self):
        value=self.store.read("rdc.tokens")
        return OAuthToken.model_validate(value) if value else None
    async def set_tokens(self,tokens):
        self.store.write("rdc.tokens",tokens.model_dump(mode="json"))
    async def get_client_info(self):
        value=self.store.read("rdc.client")
        return OAuthClientInformationFull.model_validate(value) if value else None
    async def set_client_info(self,client_info):
        self.store.write("rdc.client",client_info.model_dump(mode="json"))

class RDCClient:
    def __init__(self,store): self.store=store

    async def request(self,name=None,arguments=None,allowed=frozenset(),connect=False):
        if name is not None: authorize_tool(name,allowed)
        storage=KeychainMCPStorage(self.store)
        # A fixed loopback port preserves the exact registered callback across launches.
        with Callback(port=17878) as callback:
            async def redirect(url):
                target=urlsplit(url)
                if not connect: raise ProviderError("rdc_connect_required")
                if target.scheme!="https" or target.netloc not in {"auth.desktopcommander.app","mcp.desktopcommander.app"}:
                    raise ProviderError("untrusted_rdc_login")
                expected=parse_qs(target.query).get("state",[""])[0]
                if not expected: raise ProviderError("invalid_rdc_state")
                callback.accept=lambda data: len(data.get("state",[]))==1 and hmac.compare_digest(data["state"][0],expected)
                if not webbrowser.open(url): raise ProviderError("browser_unavailable")
            async def receive():
                params=await asyncio.to_thread(callback.wait)
                if "error" in params: raise ProviderError("rdc_sign_in_declined")
                if any(len(v)!=1 for v in params.values()): raise ProviderError("invalid_callback")
                code=params.get("code",[""])[0]
                state=params.get("state",[""])[0]
                if not code or not state: raise ProviderError("invalid_callback")
                return code,state
            metadata=OAuthClientMetadata(client_name="BIFROST ChatGPT Apple Plugin",
                redirect_uris=[callback.uri],grant_types=["authorization_code","refresh_token"],
                response_types=["code"],token_endpoint_auth_method="none")
            auth=OAuthClientProvider(server_url=RDC_URL,client_metadata=metadata,
                storage=storage,redirect_handler=redirect,callback_handler=receive)
            async with httpx.AsyncClient(auth=auth,timeout=60,follow_redirects=False) as http:
                async with streamable_http_client(RDC_URL,http_client=http) as (read,write,_):
                    async with ClientSession(read,write) as session:
                        await session.initialize()
                        tools=await session.list_tools()
                        if name is None: return tools.model_dump(mode="json")
                        if name not in {tool.name for tool in tools.tools}: raise ProviderError("tool_unavailable")
                        result=await session.call_tool(name,arguments or {})
                        if result.isError: raise ProviderError("rdc_tool_failed")
                        return result.model_dump(mode="json")
