"""Bounded, read-only Apple CoreDevice discovery for BIFROST's existing MCP.

A CoreDevice observation is NEVER an EDEN trust grant, a device pairing action,
proof of reachability, an iPhone system-control permission, or an agent connection.
Only Xcode's fixed devicectl list command is invoked. No user arguments, IDs,
account names, addresses, serials, or hostnames leave this adapter.
"""
from __future__ import annotations

import json
from pathlib import Path
import platform
import re
import subprocess
import tempfile

SCHEMA = "bifrost.apple.coredevice-observation.v1"
XCRUN = Path("/usr/bin/xcrun")
MAX_RESULT_BYTES = 262144
MAX_DEVICES = 64


def _public_token(value):
    """Return only bounded harmless class labels, never raw device metadata."""
    if isinstance(value, str) and re.fullmatch(r"[A-Za-z0-9.,_-]{1,64}", value):
        return value
    return "unknown"


def _view(raw):
    if not isinstance(raw, dict):
        raise ValueError("Invalid CoreDevice envelope")
    devices = raw.get("result", {}).get("devices") if isinstance(raw.get("result"), dict) else None
    if not isinstance(devices, list) or len(devices) > MAX_DEVICES:
        raise ValueError("Invalid or excessive CoreDevice list")
    observed = []
    for row in devices:
        if not isinstance(row, dict):
            raise ValueError("Invalid CoreDevice item")
        props = row.get("properties", {})
        props = props if isinstance(props, dict) else {}
        hardware = props.get("hardware", row.get("hardwareProperties", {}))
        connection = props.get("connection", row.get("connectionProperties", {}))
        hardware = hardware if isinstance(hardware, dict) else {}
        connection = connection if isinstance(connection, dict) else {}
        # Xcode 27 may use newer properties instead of deprecated *Properties.
        kind = _public_token(hardware.get("productType", hardware.get("model", "unknown")))
        transport = _public_token(connection.get("transportType", "unknown"))
        observed.append({"kind": kind, "transport": transport,
                         "developerPairing": "unverified", "edenTrust": "not-established"})
    return {"deviceCount": len(observed), "devices": observed}


def inspect(*, system=None, run=None, xcrun=None):
    """Observe a locally accessible Xcode device inventory, with no pairing.

    Injecting xcrun/run is exclusively for isolated tests; production dispatch
    always invokes the fixed /usr/bin/xcrun and discards stdout/stderr.
    """
    system = platform.system() if system is None else system
    base = {"schema": SCHEMA, "readOnly": True,
            "observed": False, "connected": "unknown",
            "edenPairing": "not-attempted", "deviceCount": 0, "devices": []}
    if system != "Darwin":
        return dict(base, status="unsupported-host")
    cli = XCRUN if xcrun is None else Path(xcrun)
    if not cli.is_file() or cli.is_symlink():
        return dict(base, status="xcode-command-line-tools-unavailable")
    runner = subprocess.run if run is None else run
    try:
        with tempfile.TemporaryDirectory(prefix="bifrost-coredevice-") as dirname:
            destination = Path(dirname) / "devices.json"
            response = runner([str(cli), "devicectl", "list", "devices", "--json-output", str(destination)],
                              stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                              stderr=subprocess.DEVNULL, timeout=10, check=False)
            if response.returncode != 0:
                return dict(base, status="devicectl-failed")
            if not destination.is_file() or destination.is_symlink():
                return dict(base, status="no-coredevice-result")
            size = destination.stat().st_size
            if not 2 <= size <= MAX_RESULT_BYTES:
                return dict(base, status="invalid-result-size")
            parsed = json.loads(destination.read_text(encoding="utf-8"))
            result = _view(parsed)
            return dict(base, **result, observed=True, status="local-developer-device-observation")
    except (OSError, UnicodeError, ValueError, subprocess.TimeoutExpired):
        return dict(base, status="discovery-unavailable")
