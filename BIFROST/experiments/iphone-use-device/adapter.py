"""Read-only iphone-use GET /agent/status or MCP phone_status adapter."""

STATES = frozenset(("ready", "locked", "released", "releasing", "reconnecting",
                    "blocked", "offline", "degraded", "booting", "shutdown"))


def summarize_phone_status(response):
    if not isinstance(response, dict):
        raise ValueError("phone status must be an object")
    state = response.get("device_state")
    if state not in STATES:
        raise ValueError("unknown phone state")
    drivable = response.get("drivable", False)
    handoff = response.get("human_handoff", False)
    if type(drivable) is not bool or type(handoff) is not bool:
        raise ValueError("boolean fields required")
    if handoff and drivable:
        raise ValueError("human handoff cannot be drivable")
    lock = response.get("lock_readiness")
    verdict = "unknown"
    if lock is not None:
        if not isinstance(lock, dict):
            raise ValueError("invalid lock readiness")
        verdict = lock.get("verdict", "unknown")
        if verdict not in ("ready", "will_lock_needs_person", "will_lock_auto_unlocks", "unknown"):
            raise ValueError("unknown lock readiness")
    # Status does not authorize device input or reconnect, even when ready.
    return {"schema": "bifrost.candidate.iphone-use.v1", "enabled": False,
            "device_state": state, "ready_observed": state == "ready" and drivable and not handoff,
            "human_handoff": handoff, "lock_verdict": verdict}
