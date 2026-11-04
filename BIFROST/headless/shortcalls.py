#!/usr/bin/env python3
"""BIFROST portable shortCALLnames: bounded local read-only executors.

Manifest semantics are provider-neutral; no arbitrary script or remote commands.
Future platform adapters must explicitly register and independently test support.
"""
import argparse
import json
import platform
import sys
from pathlib import Path

SCHEMA = "bifrost.shortcalls.v1"
MANIFEST = Path(__file__).resolve().parents[1] / "core" / "shortcalls.v1.json"
PLATFORMS = {"Darwin": "macos", "Linux": "linux", "Windows": "windows"}
READONLY_ADAPTERS = frozenset({"python.platform", "python.automation", "python.setup", "python.apple.native", "python.apple.coredevice", "python.connection.observation"})


class ShortCallError(ValueError):
    pass


def _key(name):
    import re
    if not isinstance(name, str) or not re.fullmatch(r"[A-Za-z][A-Za-z0-9_.-]{0,127}", name):
        raise ShortCallError("Invalid shortNameCall identifier")
    return name.casefold()


def _indexes(data):
    seen, actions, workflows = set(), {}, {}
    def register(index, entry):
        if not isinstance(entry, dict) or not isinstance(entry.get("aliases", []), list):
            raise ShortCallError("Malformed manifest entry")
        for name in [entry.get("id"), *entry.get("aliases", [])]:
            key = _key(name)
            if key in seen:
                raise ShortCallError("Duplicate action/workflow name or alias: " + name)
            seen.add(key)
            index[key] = entry
    for entry in data["actions"]:
        register(actions, entry)
    for entry in data.get("combinations", []):
        register(workflows, entry)
        for step in entry.get("steps", []):
            if _key(step) not in actions:
                raise ShortCallError("Unregistered workflow step: " + step)
    return actions, workflows


def catalog():
    data = json.loads(MANIFEST.read_text(encoding="utf-8"))
    if data.get("schema") != SCHEMA or not isinstance(data.get("actions"), list) or not isinstance(data.get("combinations", []), list):
        raise ShortCallError("Invalid shortCALL catalogue schema")
    _indexes(data)
    return data


def describe(action_id):
    entry = _indexes(catalog())[0].get(_key(action_id))
    if entry is None: raise ShortCallError("Unregistered action")
    return entry


def resolve(action_id, system=None):
    entry = describe(action_id)
    os_name = system or PLATFORMS.get(platform.system(), "unknown")
    impl = entry.get("executors", {}).get(os_name)
    available = (impl in READONLY_ADAPTERS
                 and entry["state"] == "implemented-readonly"
                 and entry["effect"] == "read"
                 and entry.get("requiresApproval") is False)
    return {"action": entry["id"], "platform": os_name,
            "available": available,
            "adapter": impl if available else None,
            "effect": entry["effect"], "state": entry["state"]}


def _execution_platform(system):
    actual = PLATFORMS.get(platform.system(), "unknown")
    if system is not None and system != actual:
        raise ShortCallError("Execution platform does not match this host; use resolve/workflow-plan for other platforms")
    return actual


def call(action_id, payload=None, system=None):
    if payload not in (None, {}):
        raise ShortCallError("This read-only action accepts no inputs")
    system = _execution_platform(system)
    action_id = describe(action_id)["id"]
    route = resolve(action_id, system=system)
    if not route["available"]:
        raise ShortCallError("No verified executor for this action/platform")
    # Exact allowlist: never execute commands from the manifest itself.
    match route["adapter"]:
        case "python.platform":
            return {"schema": SCHEMA, "action": action_id, "verified": True,
                    "result": {"system": platform.system(), "machine": platform.machine()},
                    "effectsVerified": True}
        case "python.automation":
            import orchestration
            return {"schema": SCHEMA, "action": action_id, "verified": True,
                    "result": orchestration.catalog(), "effectsVerified": True}
        case "python.setup":
            import setup_manager
            return {"schema": SCHEMA, "action": action_id, "verified": True,
                    "result": setup_manager.catalog(), "effectsVerified": True}
        case "python.apple.native":
            import apple_native_probe
            result = apple_native_probe.inspect()
            return {"schema": SCHEMA, "action": action_id, "verified": True,
                    "result": result, "effectsVerified": True}
        case "python.apple.coredevice":
            # Reuse the canonical BIFROST device action/dispatcher. This reads
            # Xcode's CoreDevice inventory; discovery is NOT EDEN pairing.
            import apple_device_discovery
            observed = apple_device_discovery.inspect()
            return {"schema": SCHEMA, "action": action_id, "verified": True,
                    "result": observed, "effectsVerified": False}
        case "python.connection.observation":
            # Reuse the existing headless observer. Never start the LAN scanner,
            # expose IP/hostnames, disclose account identifiers or assert online
            # health from cached ARP or a registered provider.
            import connection_observer
            state = connection_observer.snapshot()
            lan = state.get("lan", {})
            scan = lan.get("scan", {})
            result = {
                "schema": "bifrost.connection.mcp-observation.v1",
                "observedAt": state.get("observedAt"),
                "thisDevice": {"state": state.get("thisDevice", {}).get("state", "unknown")},
                "lan": {
                    "observedPeerCount": len(lan.get("observedPeers", [])),
                    "passiveARPCount": lan.get("passiveARPCount", 0),
                    "scanStatus": scan.get("status", "not-scanned"),
                    "peerServiceHealth": "unverified"
                },
                "rdc": {
                    "state": state.get("rdc", {}).get("state", "unverified"),
                    "authentication": "not-verified-from-local-profile"
                },
                "apps": [
                    {"id": app["id"], "webVerified": app.get("webVerified") is True}
                    for app in state.get("apps", []) if isinstance(app, dict) and "id" in app
                ],
                "connectors": [
                    {"id": conn["id"], "state": conn.get("state", "unverified")}
                    for conn in state.get("connectors", []) if isinstance(conn, dict) and "id" in conn
                ],
                "scope": "local-read-only-redacted",
                "liveConnectionVerified": False
            }
            return {"schema": SCHEMA, "action": action_id, "verified": True,
                    "result": result, "effectsVerified": False}
        case _:
            raise ShortCallError("Executor is not registered")


def describe_workflow(workflow_id):
    entry = _indexes(catalog())[1].get(_key(workflow_id))
    if entry is None: raise ShortCallError("Unregistered workflow")
    return entry


def plan_workflow(workflow_id, system=None):
    entry = describe_workflow(workflow_id)
    routes = [resolve(step, system=system) for step in entry.get("steps", [])]
    ready = (entry["state"] == "implemented-readonly" and bool(routes)
             and entry.get("requiresApproval") is False
             and all(x["available"] and x["effect"] == "read" for x in routes))
    return {"schema": SCHEMA, "workflow": entry["id"],
            "platform": system or PLATFORMS.get(platform.system(), "unknown"),
            "state": entry["state"], "executable": ready, "steps": routes,
            "requiresApproval": entry.get("requiresApproval", False)}


def run_workflow(workflow_id, system=None):
    system = _execution_platform(system)
    plan = plan_workflow(workflow_id, system=system)
    if not plan["executable"]:
        raise ShortCallError("Workflow has no verified read-only executor on this platform")
    results = [call(route["action"], system=system) for route in plan["steps"]]
    return {"schema": SCHEMA, "workflow": plan["workflow"],
            "state": "completed-readonly", "results": results,
            "effectsVerified": all(x.get("effectsVerified") is True for x in results)}


def main(argv=None):
    parser = argparse.ArgumentParser(description="BIFROST portable shortCALLnames")
    parser.add_argument("operation", choices=("list", "describe", "resolve", "call", "workflows", "workflow-describe", "workflow-plan", "workflow-run"))
    parser.add_argument("action", nargs="?")
    parser.add_argument("--platform", choices=("macos", "linux", "windows"))
    args = parser.parse_args(argv)
    try:
        if args.operation in ("list", "workflows"):
            if args.action: raise ShortCallError("Unexpected action argument")
            data = catalog()
            result = data if args.operation == "list" else {"schema": SCHEMA, "combinations": data.get("combinations", [])}
        else:
            if not args.action: raise ShortCallError("Action/workflow ID is required")
            if args.operation == "describe": result = describe(args.action)
            elif args.operation == "resolve": result = resolve(args.action, args.platform)
            elif args.operation == "call": result = call(args.action, system=args.platform)
            elif args.operation == "workflow-describe": result = describe_workflow(args.action)
            elif args.operation == "workflow-plan": result = plan_workflow(args.action, args.platform)
            else: result = run_workflow(args.action, system=args.platform)
        print(json.dumps(result, sort_keys=True, ensure_ascii=False))
        return 0
    except (ShortCallError, OSError, ValueError) as e:
        print(json.dumps({"error": str(e), "status": "refused"}), file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())

