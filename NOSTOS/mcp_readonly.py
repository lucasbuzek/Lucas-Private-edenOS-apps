#!/usr/bin/env python3
"""Optional read-only MCP adapter for the authenticated local NOSTOS service.
Uses official MCP Python SDK v2. No direct SQLite access and no write tools.
"""
import json
import os
from urllib.parse import urlencode, urlsplit
from urllib.request import Request, urlopen

from mcp.server import MCPServer

mcp = MCPServer("NOSTOS household read-only")
KINDS = {"members", "spaces", "assets", "supplies", "chores", "maintenance", "records"}


def _settings():
    base = os.environ.get("NOSTOS_API_URL", "http://127.0.0.1:8787").rstrip("/")
    parsed = urlsplit(base)
    if (parsed.scheme != "http" or parsed.hostname not in {"127.0.0.1", "localhost", "::1"}
            or parsed.username or parsed.password or parsed.query or parsed.fragment
            or parsed.path not in {"", "/"}):
        raise ValueError("NOSTOS MCP may only contact an explicit local loopback API")
    token = os.environ.get("NOSTOS_OWNER_TOKEN", "")
    if len(token) < 32:
        raise ValueError("NOSTOS_OWNER_TOKEN is required for the local MCP adapter")
    return base, token


def _read(endpoint, params=None):
    base, token = _settings()
    path = endpoint + (("?" + urlencode(params)) if params else "")
    request = Request(base + path, headers={"Authorization": "Bearer " + token,
                                            "Accept": "application/json"})
    with urlopen(request, timeout=8) as response:
        if response.status != 200:
            raise RuntimeError("NOSTOS local service unavailable")
        return json.load(response)


@mcp.tool()
def household_summary() -> dict:
    """Read counts for household categories, due tasks and attention markers."""
    return _read("/api/summary")


@mcp.tool()
def search_household(kind: str = "", query: str = "", limit: int = 25) -> dict:
    """Search household-owned records. Read-only; no cross-household grants."""
    if kind and kind not in KINDS:
        raise ValueError("Unsupported NOSTOS household category")
    if not 1 <= limit <= 100:
        raise ValueError("Limit must be between 1 and 100")
    if len(query) > 200:
        raise ValueError("Search term too long")
    params = {}
    if kind: params["kind"] = kind
    if query: params["q"] = query
    result = _read("/api/items", params)
    return {"items": result.get("items", [])[:limit], "limit": limit}


if __name__ == "__main__":
    _settings()  # fail closed before advertising tools
    mcp.run()  # local stdio only; never a public MCP HTTP listener
