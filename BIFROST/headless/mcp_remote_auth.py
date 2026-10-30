"""OAuth introspection guard for independent BIFROST remote MCP.

No Mac services, EDEN apps, or runtime registry are imported. Network verification
is always fail-closed; remote access cannot start without approved OAuth settings.
"""
from dataclasses import dataclass
from pathlib import Path
from urllib.parse import urlencode, urlsplit
from urllib.request import Request, build_opener, HTTPRedirectHandler
from urllib.error import HTTPError, URLError
import base64
import json
import math
import os
import stat
import time

SCOPE = "bifrost:read"
MAX_RESPONSE = 65536

class ConfigurationError(ValueError):
    pass

@dataclass(frozen=True)
class Settings:
    issuer: str
    resource: str
    introspection: str
    client_id: str
    client_secret: str

def _https_url(value, name):
    parsed = urlsplit(value)
    if parsed.scheme != "https" or not parsed.hostname or parsed.username or parsed.password or parsed.fragment:
        raise ConfigurationError(f"{name} must be an HTTPS URL without embedded credentials or fragment")
    return value

def from_environment(env=None):
    env = dict(os.environ if env is None else env)
    keys = ("BIFROST_MCP_ISSUER_URL", "BIFROST_MCP_RESOURCE_URL",
            "BIFROST_MCP_INTROSPECTION_URL", "BIFROST_MCP_OAUTH_CLIENT_ID",
            "BIFROST_MCP_SECRET_FILE")
    if any(not env.get(k) for k in keys):
        raise ConfigurationError("Independent remote BIFROST requires an OAuth issuer, resource, introspection endpoint, client ID and private client-secret file")
    path = Path(env["BIFROST_MCP_SECRET_FILE"])
    if not path.is_file() or path.is_symlink():
        raise ConfigurationError("Client-secret file must be an existing regular file")
    if os.name == "posix" and stat.S_IMODE(path.stat().st_mode) & 0o077:
        raise ConfigurationError("Client-secret file must not be accessible to group or others")
    secret = path.read_text(encoding="utf-8").strip()
    if not secret or len(secret) > 8192:
        raise ConfigurationError("Invalid OAuth client secret")
    resource = _https_url(env[keys[1]], keys[1])
    if urlsplit(resource).path.rstrip("/") != "/mcp":
        raise ConfigurationError("Resource URL must identify the /mcp endpoint")
    return Settings(
        issuer=_https_url(env[keys[0]], keys[0]),
        resource=resource,
        introspection=_https_url(env[keys[2]], keys[2]),
        client_id=env[keys[3]],
        client_secret=secret
    )

class _NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        return None

def inspect_token(config, bearer, *, opener=None, now=None):
    """Return a minimal validated identity dict or None. Never raise provider details."""
    if not isinstance(bearer, str) or not 1 <= len(bearer) <= 4096 or any(ord(c) < 33 or ord(c) > 126 for c in bearer):
        return None
    encoded = base64.b64encode(f"{config.client_id}:{config.client_secret}".encode()).decode("ascii")
    request = Request(
        config.introspection,
        data=urlencode({"token": bearer, "token_type_hint": "access_token"}).encode("ascii"),
        headers={"Authorization": "Basic " + encoded,
                 "Content-Type": "application/x-www-form-urlencoded",
                 "Accept": "application/json"},
        method="POST")
    try:
        client = opener if opener is not None else build_opener(_NoRedirect())
        with client.open(request, timeout=4) as response:
            body = response.read(MAX_RESPONSE + 1)
            if len(body) > MAX_RESPONSE or response.status != 200:
                return None
        obj = json.loads(body)
    except (OSError, URLError, HTTPError, ValueError, UnicodeError, TypeError, RecursionError):
        return None
    if not isinstance(obj, dict) or obj.get("active") is not True or obj.get("iss") != config.issuer:
        return None
    audience = obj.get("aud")
    if config.resource not in ([audience] if isinstance(audience, str) else audience if isinstance(audience,list) else []):
        return None
    exp = obj.get("exp")
    now = time.time() if now is None else now
    if (type(exp) not in (int, float)
            or (isinstance(exp, float) and not math.isfinite(exp))
            or exp <= now or exp > now + 86400 * 2):
        return None
    scopes = obj.get("scope", [])
    scopes = scopes.split() if isinstance(scopes, str) else scopes
    if not isinstance(scopes, list) or any(not isinstance(s,str) for s in scopes) or SCOPE not in scopes:
        return None
    subject, client_id = obj.get("sub"), obj.get("client_id")
    if not isinstance(subject,str) or not subject or not isinstance(client_id,str) or not client_id:
        return None
    return {"subject": subject, "client_id": client_id, "scopes": scopes,
            "resource": config.resource, "expires_at": int(exp)}
