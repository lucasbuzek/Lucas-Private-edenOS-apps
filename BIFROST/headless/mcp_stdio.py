#!/usr/bin/env python3
"""BIFROST's existing Headless/Core functionality over on-demand stdio MCP.

This is a transport adapter, NOT a second server, account store, or executor.
It deliberately exposes only existing read-only BIFROST capability adapters.
The calling MCP host owns process trust and any secure-tunnel authentication.
"""
from __future__ import annotations
import json
import sys

VERSION = "0.1.0-candidate"
MAX_LINE = 65536
PROTOCOLS = ("2025-11-25", "2025-06-18")
MODERN = "2026-07-28"
SERVER_INFO = {"name": "BIFROSTcore MCP", "version": VERSION}
CALLS = {
    "bifrost_status": "Inspect existing BIFROSTcore and Headless identity; no connection claims.",
    "bifrost_storage_providers": "Read the existing BIFROSTcore storage provider catalog.",
    "bifrost_storage_accounts": "Read existing BIFROSTcore remote labels, not tokens.",
    "bifrost_storage_preview": "Preview a saved BIFROSTcore storage profile without network access.",
    "bifrost_inspector": "Inspect existing BIFROST runtime state (no OS control).",
    "bifrost_installer": "Read the existing BIFROST setup catalog; no installation.",
    "bifrost_specialists": "Show read-only PENELOPE/JANITOR handoff readiness; no invocation.",
    "bifrost_first_use_accounts": "Inspect already-configured storage and RDC label metadata only.",
}


def descriptors():
    preview = {"type": "object", "properties": {
        "profile": {"type": "string", "minLength": 1, "maxLength": 80},
        "folder": {"type": "string", "maxLength": 480}},
        "required": ["profile"], "additionalProperties": False}
    empty = {"type": "object", "properties": {}, "additionalProperties": False}
    return [{"name": name, "description": description,
             "inputSchema": preview if name == "bifrost_storage_preview" else empty,
             "annotations": {"readOnlyHint": True, "destructiveHint": False,
                             "openWorldHint": False}}
            for name, description in CALLS.items()]


def run(name, arguments=None):
    """Dispatch to the *existing* BIFROST Headless Python adapters."""
    if name not in CALLS:
        raise ValueError("Unsupported BIFROST tool")
    if arguments is None:
        arguments = {}
    if not isinstance(arguments, dict):
        raise ValueError("Tool arguments must be an object")
    if name != "bifrost_storage_preview" and arguments:
        raise ValueError("This tool accepts no arguments")
    if name == "bifrost_storage_preview":
        if set(arguments) - {"profile", "folder"}:
            raise ValueError("Unsupported storage arguments")
        profile, folder = arguments.get("profile"), arguments.get("folder", "")
        if not isinstance(profile, str) or not 1 <= len(profile) <= 80:
            raise ValueError("Select an existing named storage profile")
        if not isinstance(folder, str) or len(folder) > 480:
            raise ValueError("Invalid profile-relative folder")
        import storage_adapter
        # No provider read here: explicit online reads belong to the existing
        # authenticated Headless UI with a separate owner action.
        return storage_adapter.preview(profile, folder=folder, read_remote=False)
    if name in ("bifrost_status", "bifrost_inspector"):
        import core_runtime
        result = core_runtime.snapshot()
        return {"source": "existing-BIFROSTcore", "readOnly": True,
                "connectionAcceptance": "NOT_ATTESTED_BY_LOCAL_PROCESS",
                "state": result}
    if name == "bifrost_storage_providers":
        import storage_adapter
        return storage_adapter.catalog()
    if name == "bifrost_storage_accounts":
        import storage_adapter
        return storage_adapter.accounts()
    if name == "bifrost_installer":
        import setup_manager
        return {"readOnly": True, "installerExecuted": False,
                "catalog": setup_manager.catalog()}
    if name == "bifrost_first_use_accounts":
        import first_use_accounts
        return first_use_accounts.snapshot()
    # Avoid guessing live ports, invoking specialist code or opening private
    # files belonging to separately governed applications.
    return {"owner": "BIFROST connection fabric", "readOnly": True,
            "handoffs": [
                {"specialist": "PENELOPE", "role": "backup and custody",
                 "executionReady": False, "acceptance": "NOT_VERIFIED"},
                {"specialist": "JANITOR", "role": "on-demand cleanup",
                 "executionReady": False, "acceptance": "NOT_VERIFIED"}],
            "delegationPerformed": False}


def _result(req_id, obj):
    return {"jsonrpc": "2.0", "id": req_id, "result": obj}


def _modern_meta(params):
    """Recognize and validate the MCP 2026-07-28 per-request envelope."""
    meta = params.get("_meta")
    if meta is None:
        return False, None
    if not isinstance(meta, dict):
        return None, "Invalid modern metadata"
    version = meta.get("io.modelcontextprotocol/protocolVersion")
    if version is None:
        return False, None
    if version != MODERN:
        return None, "Unsupported protocol version"
    if not isinstance(meta.get("io.modelcontextprotocol/clientCapabilities"), dict):
        return None, "Missing client capabilities"
    client = meta.get("io.modelcontextprotocol/clientInfo")
    if client is not None and (not isinstance(client, dict) or
                               not all(isinstance(client.get(k), str) and client[k]
                                       for k in ("name", "version"))):
        return None, "Malformed client identity"
    return True, None


def _modern_result(payload):
    return {"resultType": "complete", **payload,
            "_meta": {"io.modelcontextprotocol/serverInfo": SERVER_INFO}}


def _error(req_id, code, message):
    return {"jsonrpc": "2.0", "id": req_id,
            "error": {"code": code, "message": message}}


def rpc(request):
    if not isinstance(request, dict) or request.get("jsonrpc") != "2.0":
        return _error(None, -32600, "Invalid Request")
    method = request.get("method")
    req_id = request.get("id")
    if "id" in request and (isinstance(req_id, bool) or
                            not isinstance(req_id, (str, int))):
        return _error(None, -32600, "Invalid Request id")
    if "id" not in request:
        return None  # MCP client notifications; never run a tool via notification
    params = request.get("params", {})
    if not isinstance(params, dict):
        return _error(req_id, -32602, "Invalid params")
    modern, invalid = _modern_meta(params)
    if invalid:
        return _error(req_id, -32602, invalid)
    if method == "server/discover":
        if modern is not True:
            return _error(req_id, -32602, "Modern discovery metadata required")
        return _result(req_id, _modern_result({
            "supportedVersions": [MODERN, *PROTOCOLS],
            "capabilities": {"tools": {"listChanged": False}},
            "ttlMs": 0, "cacheScope": "private",
            "instructions": "Read-only access to existing BIFROSTcore. Device, provider and specialist operations require separate grants."}))
    if method == "initialize":
        requested = params.get("protocolVersion")
        selected = requested if requested in PROTOCOLS else PROTOCOLS[0]
        return _result(req_id, {"protocolVersion": selected,
                                "capabilities": {"tools": {"listChanged": False}},
                                "serverInfo": SERVER_INFO})
    if method == "ping":
        return _result(req_id, _modern_result({}) if modern else {})
    if method == "tools/list":
        result = {"tools": descriptors()}
        return _result(req_id, _modern_result(result) if modern else result)
    if method == "tools/call":
        name = params.get("name")
        if name not in CALLS:
            return _error(req_id, -32602, "Unsupported tool")
        try:
            outcome = run(name, params.get("arguments", {}))
            result = {"content": [
                {"type": "text", "text": json.dumps(outcome, ensure_ascii=False)}],
                "structuredContent": outcome, "isError": False}
            return _result(req_id, _modern_result(result) if modern else result)
        except (OSError, ValueError, TypeError, RuntimeError, KeyError):
            # Do not emit local paths/secret-bearing downstream error strings.
            result = {"content": [{"type": "text",
                              "text": "BIFROST tool denied or unavailable"}], "isError": True}
            return _result(req_id, _modern_result(result) if modern else result)
    return _error(req_id, -32601, "Method not found")


def serve_stdin(instream=None, outstream=None):
    incoming = instream if instream is not None else sys.stdin
    outgoing = outstream if outstream is not None else sys.stdout
    for line in incoming:
        if len(line) > MAX_LINE:
            answer = _error(None, -32600, "Request too large")
        else:
            try:
                answer = rpc(json.loads(line))
            except (ValueError, UnicodeError):
                answer = _error(None, -32700, "Parse error")
        if answer is not None:
            outgoing.write(json.dumps(answer, separators=(",", ":")) + "\n")
            outgoing.flush()


if __name__ == "__main__":
    serve_stdin()
