"""Scoped, passive connector discovery for the existing BIFROSTbridge.

This is a manifest reader, not an MCP/A2A proxy, credential broker, node pairer,
or an execution authority. Invalid configurations fail closed.
"""
import json
import os
import stat
from pathlib import Path
from urllib.parse import urlsplit

SCHEMA = "bifrost.bridge.connections.v1"
KINDS = frozenset({"mcp", "a2a", "cloud", "device", "user", "endpoint"})
ALLOWED_KEYS = frozenset({"id", "kind", "endpoint", "protocol", "owner", "tenant", "allowedSubjects", "capabilities"})
MAX_BYTES = 65536


class RegistryError(ValueError):
    pass


def _label(value):
    return (isinstance(value, str) and 1 <= len(value) <= 256
            and value == value.strip() and value != "*"
            and all(32 <= ord(c) < 127 for c in value))


def _normalize(entry):
    if not isinstance(entry, dict) or set(entry) - ALLOWED_KEYS:
        raise RegistryError("Invalid connection fields")
    if any(not _label(entry.get(k)) for k in ("id", "kind", "protocol", "owner", "tenant")):
        raise RegistryError("Invalid connection identity")
    if entry["kind"] not in KINDS:
        raise RegistryError("Unknown connection kind")
    subjects = entry.get("allowedSubjects")
    if (not isinstance(subjects, list) or not subjects or len(subjects) > 100
            or any(not _label(s) for s in subjects) or len(set(subjects)) != len(subjects)):
        raise RegistryError("Explicit, non-wildcard subject allowlist required")
    capabilities = entry.get("capabilities", [])
    if (not isinstance(capabilities, list) or len(capabilities) > 100
            or any(not _label(x) for x in capabilities) or len(set(capabilities)) != len(capabilities)):
        raise RegistryError("Invalid capability list")
    endpoint = entry.get("endpoint")
    if endpoint is not None:
        if not isinstance(endpoint, str) or len(endpoint) > 2048:
            raise RegistryError("Invalid endpoint")
        parsed = urlsplit(endpoint)
        if (parsed.scheme != "https" or not parsed.hostname or parsed.username
                or parsed.password or parsed.fragment or any(ord(c) < 33 for c in endpoint)):
            raise RegistryError("Only explicit HTTPS endpoints are allowed")
    elif entry["kind"] in {"mcp", "a2a", "cloud", "endpoint"}:
        raise RegistryError("Network connector requires an HTTPS endpoint")
    return {
        "id": entry["id"], "kind": entry["kind"], "protocol": entry["protocol"],
        "owner": entry["owner"], "tenant": entry["tenant"],
        "allowedSubjects": tuple(subjects), "capabilities": list(capabilities),
        "endpoint": endpoint,
    }


def visible_connections(subject, registry):
    """Return configured metadata for an authorized subject; no network activity."""
    if not _label(subject) or not isinstance(registry, dict) or registry.get("schema") != SCHEMA:
        raise RegistryError("Invalid subject or registry schema")
    if set(registry) != {"schema", "connections"} or not isinstance(registry["connections"], list):
        raise RegistryError("Invalid registry")
    connections = [_normalize(x) for x in registry["connections"]]
    identifiers = [x["id"] for x in connections]
    if len(set(identifiers)) != len(identifiers):
        raise RegistryError("Duplicate connection identity")
    return [{
        "id": x["id"], "kind": x["kind"], "protocol": x["protocol"],
        "owner": x["owner"], "tenant": x["tenant"], "endpoint": x["endpoint"],
        "capabilities": x["capabilities"], "state": "configured-unverified",
    } for x in connections if subject in x["allowedSubjects"]]


def connections_for_subject(subject, path=None):
    """Read an owner-provisioned private registry; absence means zero connections."""
    path = os.environ.get("BIFROST_BRIDGE_REGISTRY_FILE") if path is None else path
    if not path:
        return []
    path = Path(path)
    if not path.is_file() or path.is_symlink():
        raise RegistryError("Registry must be an existing regular file")
    if os.name == "posix" and stat.S_IMODE(path.stat().st_mode) & 0o077:
        raise RegistryError("Registry permissions must be owner-only")
    if path.stat().st_size > MAX_BYTES:
        raise RegistryError("Registry too large")
    try:
        with path.open("rb") as handle:
            data = handle.read(MAX_BYTES + 1)
        if len(data) > MAX_BYTES:
            raise RegistryError("Registry too large")
        return visible_connections(subject, json.loads(data))
    except (ValueError, UnicodeError, OSError, TypeError, RecursionError) as exc:
        raise RegistryError("Invalid or unreadable registry") from exc
