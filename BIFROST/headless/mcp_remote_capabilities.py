"""Safe remote MCP discovery view over BIFROST's existing shortCALL catalogue.

Discovery reports allowlisted mappings, NOT a verified live endpoint, remote
execution authorization, provider account, or permission to run a planned tool.
"""
import platform

import shortcalls

SCHEMA = "bifrost.mcp.capabilities.v1"


def snapshot(system=None):
    """List only currently mapped read-only actions, with honest evidence fields."""
    host_platform = system or shortcalls.PLATFORMS.get(platform.system(), "unknown")
    catalog = shortcalls.catalog()
    mapped = []
    for action in catalog["actions"]:
        resolution = shortcalls.resolve(action["id"], system=host_platform)
        if not resolution["available"]:
            continue
        # Resolve is the existing executor authority. Never infer implementation
        # from a manifest title, alias, contract-only state, or vendor name.
        if (resolution["effect"] != "read"
                or action.get("requiresApproval") is not False
                or action.get("state") != "implemented-readonly"):
            raise shortcalls.ShortCallError("Inconsistent read-only capability authority")
        mapped.append({
            "id": resolution["action"],
            "group": action.get("group", "Other"),
            "title": action.get("title", resolution["action"]),
            "effect": "read",
            "executorMapped": True,
            "runtimeVerified": False,
        })
    return {
        "schema": SCHEMA,
        "catalogVersion": catalog.get("catalogVersion"),
        "platform": host_platform,
        "mappedReadOnly": mapped,
        "mappedCount": len(mapped),
        "liveProviderCountVerified": 0,
        "runtimeVerified": False,
        "execution": "not-granted-by-discovery",
        "scope": "authenticated-readonly-discovery",
    }
