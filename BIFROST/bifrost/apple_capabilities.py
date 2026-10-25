"""Read-only Apple capability discovery for BIFROST.

Detection is NOT authorization, pairing, availability of a specific user account,
or proof that an MCP client or Apple extension is configured.
"""
from __future__ import annotations

import argparse
import json
import platform
import shutil
import subprocess


def discover_apple_capabilities(os_name=None, which=None, xcode_probe=None):
    """Return stable, non-sensitive capability metadata; make no state changes."""
    os_name = platform.system() if os_name is None else os_name
    which = shutil.which if which is None else which
    mac = os_name == "Darwin"

    def command(name):
        return bool(mac and which(name))

    def record(identifier, kind, status, permission, offline, note):
        return {
            "id": identifier,
            "kind": kind,
            "status": status,
            "permission": permission,
            "offline_capable": offline,
            "note": note,
        }

    records = [
        record("apple.shortcuts.cli", "native_cli",
               "tool_detected" if command("shortcuts") else "not_detected",
               "not_checked", True,
               "Discovery only; executing shortcuts may prompt and requires separate authorization."),
        record("apple.applescript.cli", "native_cli",
               "tool_detected" if command("osascript") else "not_detected",
               "not_checked", True,
               "Apple Events/TCC automation consent is unknown; no AppleScript was run."),
        record("apple.xcode.cli", "developer_cli",
               "tool_detected" if command("xcodebuild") else "not_detected",
               "not_checked", True,
               "Xcode project, signing and simulator state were not inspected."),
    ]
    if not mac or not command("xcrun"):
        mcp_status = "not_detected"
    elif xcode_probe is not None:
        mcp_status = "tool_detected" if xcode_probe() else "not_detected"
    else:
        try:
            result = subprocess.run(
                ["xcrun", "--find", "mcpbridge"], capture_output=True,
                text=True, check=False, timeout=3,
            )
            mcp_status = "tool_detected" if result.returncode == 0 else "not_detected"
        except (OSError, subprocess.TimeoutExpired):
            mcp_status = "probe_failed"
    records.extend([
        record("apple.xcode.mcpbridge", "local_mcp", mcp_status,
               "xcode_setting_and_agent_consent_not_checked", True,
               "Finding mcpbridge does not prove Xcode's external-agent setting is enabled."),
        record("apple.safari.web_extension", "native_extension",
               "requires_app_extension", "extension_and_site_permissions_not_checked", True,
               "Supported through a signed app/extension; no installed extension is inferred."),
        record("apple.app_intents", "native_framework",
               "requires_app_implementation", "per_app_permissions_not_checked", True,
               "Siri, Shortcuts and App Intents require each app's own implementation."),
        record("apple.icloud.mail", "external_connector",
               "connection_not_checked", "apple_account_consent_required", False,
               "IMAP/SMTP or an authorized connector; no Apple Account data read."),
        record("apple.icloud.calendar_contacts", "external_connector",
               "connection_not_checked", "apple_account_consent_required", False,
               "Authorized CalDAV/CardDAV or connector; not a generic iCloud Drive API."),
    ])
    return {"schema": "eden.bifrost.apple.capabilities.v1", "host_os": os_name,
            "read_only": True, "capabilities": records}


def main(argv=None):
    parser = argparse.ArgumentParser(description="Read-only Apple capability inventory")
    parser.add_argument("--json", action="store_true", help="Machine-readable output")
    args = parser.parse_args(argv)
    result = discover_apple_capabilities()
    if args.json:
        print(json.dumps(result, sort_keys=True, indent=2))
    else:
        for item in result["capabilities"]:
            print(f"{item['id']}: {item['status']} (permission: {item['permission']})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
