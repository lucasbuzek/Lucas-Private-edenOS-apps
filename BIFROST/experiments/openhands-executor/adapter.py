"""OpenHands Agent Canvas endpoint preflight: strictly local and disabled."""

import ipaddress
from urllib.parse import urlsplit


def inspect_endpoint(url):
    if not isinstance(url, str) or not 1 <= len(url) <= 256:
        raise ValueError("invalid endpoint")
    try:
        parts = urlsplit(url)
        port = parts.port
    except ValueError as exc:
        raise ValueError("invalid endpoint port") from exc
    if parts.scheme != "http" or not parts.hostname or not port:
        raise ValueError("only explicit loopback HTTP supported")
    if parts.username is not None or parts.password is not None or parts.query or parts.fragment:
        raise ValueError("no credentials, query or fragment allowed")
    if parts.path not in ("", "/"):
        raise ValueError("endpoint path not allowed")
    try:
        address = ipaddress.ip_address(parts.hostname)
    except ValueError as exc:
        raise ValueError("IP literal required") from exc
    if address != ipaddress.ip_address("127.0.0.1"):
        raise ValueError("only IPv4 loopback allowed")
    return {"schema": "bifrost.candidate.openhands.v1", "endpoint": f"http://127.0.0.1:{port}",
            "enabled": False, "authenticated": "unverified", "sandbox": "unverified"}
