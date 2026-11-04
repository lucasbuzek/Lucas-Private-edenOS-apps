"""Read-only Apple tool preflight for BIFROST's existing shortNameCall dispatcher.

Detecting a binary is not proof of an enabled extension, configured MCP client,
permission grant, account session, available device or functioning action.
No shortcuts, scripts, MCP sessions or providers are invoked.
"""
from __future__ import annotations

import platform
import shutil
import subprocess


SCHEMA = "bifrost.apple.native-preflight.v1"


def inspect(*, system=None, which=None, run=None):
    """Return bounded non-sensitive diagnostics without changing host state."""
    system_name = platform.system() if system is None else system
    if system_name != "Darwin":
        return {"schema": SCHEMA, "platform": system_name, "status": "unsupported-host",
                "readOnly": True, "capabilities": []}

    which = shutil.which if which is None else which
    run = subprocess.run if run is None else run

    def cli(executable):
        return "binary-found" if which(executable) else "not-detected"

    shortcuts = cli("shortcuts")
    osascript = cli("osascript")
    xcodebuild = cli("xcodebuild")
    if not which("xcrun"):
        bridge = "not-detected"
    else:
        try:
            check = run(["xcrun", "--find", "mcpbridge"],
                        stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                        stderr=subprocess.DEVNULL, timeout=3, check=False)
            bridge = "binary-found" if check.returncode == 0 else "not-detected"
        except (OSError, subprocess.TimeoutExpired):
            bridge = "probe-failed"

    def item(identifier, status, permission, note):
        return {"id": identifier, "status": status, "permission": permission,
                "connected": "unknown", "note": note}

    return {"schema": SCHEMA, "platform": "macos", "status": "inventory-only",
            "readOnly": True, "capabilities": [
                item("apple.shortcuts.cli", shortcuts, "not-checked",
                     "No installed Shortcut names or executions were inspected."),
                item("apple.applescript.cli", osascript, "tcc-unknown",
                     "Apple Events consent not checked; no automation ran."),
                item("apple.xcodebuild.cli", xcodebuild, "not-checked",
                     "Xcode project and build capability not tested."),
                item("apple.xcode.mcpbridge", bridge, "xcode-setting-unknown",
                     "Binary detection does not mean Xcode allows agents or MCP is connected."),
                item("apple.safari.extension", "requires-app-implementation", "site-grants-unknown",
                     "Existing Safari extension must be assessed per app and website."),
                item("apple.icloud.connectors", "requires-authorized-provider", "not-checked",
                     "No Apple Account, calendar, mail or iCloud data was accessed."),
            ]}
