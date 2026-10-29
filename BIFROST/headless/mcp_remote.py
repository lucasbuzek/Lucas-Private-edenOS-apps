#!/usr/bin/env python3
"""BIFROST's optional independent authenticated remote MCP representation.

This is an adapter to the existing shortNameCall executor, NOT a second
BIFROSTcore, Mac connection, authentication server, or generic command runner.
Requires the official MCP Python SDK v2 and an approved OAuth issuer.
"""
import asyncio
import os
from urllib.parse import urlsplit

from mcp.server import MCPServer
from mcp.server.auth.middleware.auth_context import get_access_token
from mcp.server.auth.provider import AccessToken
from mcp.server.auth.settings import AuthSettings
from mcp.server.transport_security import TransportSecuritySettings
from pydantic import AnyHttpUrl

from mcp_remote_auth import ConfigurationError, SCOPE, from_environment, inspect_token
import shortcalls


class BifrostTokenVerifier:
    def __init__(self, config):
        self.config = config

    async def verify_token(self, bearer: str) -> AccessToken | None:
        result = await asyncio.to_thread(inspect_token, self.config, bearer)
        if result is None:
            return None
        return AccessToken(
            token=bearer, client_id=result["client_id"],
            subject=result["subject"], scopes=result["scopes"],
            resource=result["resource"], expires_at=result["expires_at"],
            claims={"iss": self.config.issuer},
        )


def create_server(config):
    server = MCPServer(
        "BIFROSTbridge",
        token_verifier=BifrostTokenVerifier(config),
        auth=AuthSettings(
            issuer_url=AnyHttpUrl(config.issuer),
            resource_server_url=AnyHttpUrl(config.resource),
            required_scopes=[SCOPE],
            validate_token_resource=True,
        ),
    )

    @server.tool(name="bifrost.system.platform.read")
    def read_platform() -> dict:
        """Read the local BIFROST node's platform through its approved dispatcher."""
        identity = get_access_token()
        if identity is None or SCOPE not in identity.scopes:
            raise PermissionError("Authenticated capability scope required")
        return shortcalls.call("bifrost.system.platform.read")

    return server


def run():
    config = from_environment()
    bind = os.environ.get("BIFROST_MCP_BIND_HOST", "127.0.0.1")
    if bind not in ("127.0.0.1", "0.0.0.0"):
        raise ConfigurationError("Bind address must be loopback or explicit reverse-proxy mode")
    if bind == "0.0.0.0" and os.environ.get("BIFROST_MCP_TRUSTED_REVERSE_PROXY") != "yes":
        raise ConfigurationError("External binding requires an explicitly configured TLS reverse proxy")
    port_text = os.environ.get("BIFROST_MCP_PORT", "8799")
    if not port_text.isdecimal() or not 1 <= int(port_text) <= 65535:
        raise ConfigurationError("Invalid BIFROST MCP port")
    host = urlsplit(config.resource).netloc
    allowed_origins = [
        x.strip() for x in os.environ.get("BIFROST_MCP_ALLOWED_ORIGINS", "").split(",")
        if x.strip()
    ]
    if any(urlsplit(x).scheme != "https" or not urlsplit(x).hostname for x in allowed_origins):
        raise ConfigurationError("Browser origin allowlist must use explicit HTTPS origins")
    security = TransportSecuritySettings(
        allowed_hosts=[host], allowed_origins=allowed_origins)
    create_server(config).run(
        transport="streamable-http", host=bind, port=int(port_text),
        json_response=True, transport_security=security,
        max_request_body_size=65536,
    )


if __name__ == "__main__":
    run()
