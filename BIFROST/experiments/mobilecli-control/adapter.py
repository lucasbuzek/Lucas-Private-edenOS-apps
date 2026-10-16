"""Read-only MobileCLI devices response adapter. No CLI subprocess or fleet token."""

PLATFORMS = frozenset(("ios", "android"))
STATES = frozenset(("online", "offline"))


def summarize_devices(response):
    """Summarize the upstream DevicesCommand response without device identifiers."""
    if not isinstance(response, dict) or response.get("status") != "ok":
        raise ValueError("MobileCLI response must have status ok")
    data = response.get("data")
    if not isinstance(data, dict) or not isinstance(data.get("devices"), list):
        raise ValueError("MobileCLI devices response missing")
    items = data["devices"]
    if len(items) > 100:
        raise ValueError("too many devices")
    counts = {"ios": 0, "android": 0, "online": 0, "offline": 0}
    for item in items:
        if not isinstance(item, dict):
            raise ValueError("invalid device")
        platform, state = item.get("platform"), item.get("state")
        if platform not in PLATFORMS or state not in STATES:
            raise ValueError("unsupported device platform or state")
        counts[platform] += 1
        counts[state] += 1
    return {"schema": "bifrost.candidate.mobilecli.v1", "observed": True,
            "enabled": False, "device_count": len(items), "counts": counts}
