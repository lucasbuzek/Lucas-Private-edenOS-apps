"""Isolated openhands candidate boundary; deliberately no upstream dependency.

BIFROST's existing headless server is loopback-only and RavenNest is separate.
This module is a deny-by-default normalization boundary, not an enabled adapter.
"""
from __future__ import annotations

KIND = "openhands"
UPSTREAM = "OpenHands/OpenHands"
ALLOWED = frozenset(("status", "capabilities"))

def normalize_observation(payload):
    """Return only bounded public observation fields, never credentials or commands."""
    if not isinstance(payload, dict):
        raise ValueError("observation must be an object")
    if payload.get("kind") != KIND:
        raise ValueError("wrong provider kind")
    operation = payload.get("operation")
    if operation not in ALLOWED:
        raise PermissionError("candidate cannot execute operations")
    status = payload.get("status")
    if not isinstance(status, str) or status not in ("available", "unavailable", "unknown"):
        raise ValueError("invalid observation status")
    return {"kind": KIND, "operation": operation, "status": status, "enabled": False}

def execute(*_args, **_kwargs):
    raise PermissionError("candidate not authorized for execution")
