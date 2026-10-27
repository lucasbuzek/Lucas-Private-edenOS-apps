"""Authorized adapter for preinstalled, independent Apple MCP servers.

No package download, no shell, no dynamic executable selection by model,
no unsigned network listener and no inherited AI-provider API secrets.
"""
from __future__ import annotations

import json
import os
import selectors
import shutil
import subprocess
import time
from pathlib import Path

MAX_OUTPUT = 65536
MAX_ARGUMENTS = 16384
ALLOWED_EXECUTABLES = frozenset({'node', 'npx', 'uv', 'python3'})


class UpstreamDenied(ValueError):
    pass


def _valid_name(value: str) -> bool:
    return isinstance(value, str) and 1 <= len(value) <= 100 and all(
        c.isalnum() or c in '._-' for c in value
    )


def _approved_command(config: dict) -> list[str]:
    if not isinstance(config, dict):
        raise UpstreamDenied('Malformed MCP server entry')
    program = config.get('command')
    args = config.get('args', [])
    if program not in ALLOWED_EXECUTABLES or not isinstance(args, list):
        raise UpstreamDenied('Unapproved MCP executable')
    if len(args) > 12 or any(not isinstance(x, str) or not x or len(x) > 1024 or '\x00' in x for x in args):
        raise UpstreamDenied('Unapproved MCP launch arguments')
    if program == 'npx' and ('-y' in args or '--yes' in args):
        raise UpstreamDenied('Automatic npm package installation is disabled')
    exe = shutil.which(program)
    if not exe:
        raise UpstreamDenied('Approved executable not installed: ' + program)
    return [exe, *args]


class ProvenMCP:
    """Proxy exactly approved MCP tools from an independently installed donor server."""

    def __init__(self, profile: dict, *, timeout: float = 30.0):
        self.entries = profile.get('allow_proven_mcp', {})
        if not isinstance(self.entries, dict):
            raise UpstreamDenied('Invalid per-profile MCP authorization')
        if not 1 <= timeout <= 60:
            raise UpstreamDenied('Invalid timeout')
        self.timeout = timeout

    def _entry(self, alias: str, tool: str | None = None, approved: bool = False):
        if not _valid_name(alias) or alias not in self.entries:
            raise UpstreamDenied('MCP server not approved by this profile')
        entry = self.entries[alias]
        if not isinstance(entry, dict):
            raise UpstreamDenied('Invalid upstream entry')
        read = entry.get('read_only_tools', [])
        effects = entry.get('effectful_tools', [])
        if not isinstance(read, list) or not isinstance(effects, list) or any(
            not _valid_name(t) for t in read + effects
        ) or set(read) & set(effects):
            raise UpstreamDenied('Invalid per-tool authorizations')
        if tool is not None:
            if tool in effects and not approved:
                raise UpstreamDenied('Effectful tool requires explicit APPROVE')
            if tool not in read and tool not in effects:
                raise UpstreamDenied('MCP tool not approved by this profile')
        return entry, read, effects

    @staticmethod
    def _safe_env():
        return {k: os.environ[k] for k in ('HOME', 'PATH', 'LANG', 'TMPDIR', 'XDG_CONFIG_HOME') if k in os.environ}

    def _exchange(self, entry: dict, method: str, params: dict):
        cmd = _approved_command(entry)
        proc = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                stderr=subprocess.DEVNULL, env=self._safe_env(),
                                shell=False, bufsize=0)
        selector = selectors.DefaultSelector()
        deadline = time.monotonic() + self.timeout
        try:
            selector.register(proc.stdout, selectors.EVENT_READ)
            pending = b''
            received_bytes = 0
            def send(request):
                proc.stdin.write((json.dumps(request, separators=(',', ':')) + '\n').encode())
                proc.stdin.flush()
            def read_reply(expected_id):
                nonlocal pending, received_bytes
                while True:
                    while b'\n' in pending:
                        line, pending = pending.split(b'\n', 1)
                        try:
                            response = json.loads(line)
                        except (ValueError, UnicodeError):
                            continue
                        if isinstance(response, dict) and response.get('id') == expected_id:
                            return response
                    remaining = deadline - time.monotonic()
                    if remaining <= 0 or not selector.select(remaining):
                        raise UpstreamDenied('Upstream MCP timed out')
                    block = os.read(proc.stdout.fileno(), 4096)
                    if not block:
                        raise UpstreamDenied('Upstream MCP terminated without a response')
                    received_bytes += len(block)
                    if received_bytes > MAX_OUTPUT:
                        raise UpstreamDenied('Upstream MCP response size exceeded')
                    pending += block
            send({'jsonrpc': '2.0', 'id': 1, 'method': 'initialize', 'params': {
                'protocolVersion': '2025-06-18', 'capabilities': {},
                'clientInfo': {'name': 'AppleRAVEN-proven-adapter', 'version': '0.1.0'}}})
            first = read_reply(1)
            if 'error' in first or 'result' not in first:
                raise UpstreamDenied('Upstream MCP initialization failed')
            send({'jsonrpc': '2.0', 'method': 'notifications/initialized'})
            send({'jsonrpc': '2.0', 'id': 2, 'method': method, 'params': params})
            second = read_reply(2)
            if 'error' in second:
                raise UpstreamDenied('Approved upstream tool returned an MCP error')
            return second.get('result')
        finally:
            selector.close()
            proc.terminate() if proc.poll() is None else None
            try:
                proc.wait(timeout=1)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait(timeout=1)
            for handle in (proc.stdin, proc.stdout):
                if handle:
                    handle.close()

    def list(self, alias: str):
        entry, read, effects = self._entry(alias)
        result = self._exchange(entry, 'tools/list', {})
        tools = result.get('tools', []) if isinstance(result, dict) else []
        return {'server': alias, 'tools': [
            {'name': x['name'], 'description': x.get('description', ''),
             'effectful': x['name'] in effects}
            for x in tools if isinstance(x, dict) and x.get('name') in set(read + effects)
        ]}

    def call(self, alias: str, tool: str, arguments_json: str = '{}', approval: str = ''):
        entry, _, _ = self._entry(alias, tool, approved=approval == 'APPROVE')
        if not isinstance(arguments_json, str) or len(arguments_json.encode()) > MAX_ARGUMENTS:
            raise UpstreamDenied('MCP tool arguments exceed limit')
        try:
            arguments = json.loads(arguments_json)
        except ValueError as exc:
            raise UpstreamDenied('Tool arguments must be JSON') from exc
        if not isinstance(arguments, dict):
            raise UpstreamDenied('Tool arguments must be an object')
        return self._exchange(entry, 'tools/call', {'name': tool, 'arguments': arguments})
