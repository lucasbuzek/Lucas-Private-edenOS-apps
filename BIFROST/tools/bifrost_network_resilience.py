#!/usr/bin/env python3
"""BIFROSTcore ZERO: opt-in Mac network resilience, no extra daemon.

Separate BIFROST network-path health from the already implemented, optional
LAN host scanner. Never switch an interface, inspect Wi-Fi passwords, change
auto-join settings, scan nearby WLANs, retain identifiers or silently contact
an external endpoint. An owner explicitly selects each destination/interval.
Native macOS Auto-Join Hotspot is preferred for automatic fallback.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import json
import re
import socket
import subprocess
import sys
import time

SCHEMA = "bifrost.network.resilience.v1"
CHECKS = {
    "rdc": ("mcp.desktopcommander.app", 443),
    "apple": ("www.apple.com", 443),
}
ALLOWED_INTERVALS = (15, 30, 60, 120, 300, 600, 900)
FAILURE_THRESHOLD = 3
COOLDOWN_SECONDS = 300


class ResilienceError(RuntimeError):
    pass


def route_interface(run=None):
    """Read only the system-selected default route, never private credentials."""
    run = subprocess.run if run is None else run
    try:
        result = run(["/sbin/route", "-n", "get", "default"],
                     capture_output=True, text=True, timeout=4, check=False)
    except (OSError, subprocess.TimeoutExpired):
        return None
    if result.returncode:
        return None
    match = re.search(r"^\s*interface:\s*([a-zA-Z0-9]+)\s*$",
                      result.stdout, re.MULTILINE)
    if not match:
        return None
    device = match.group(1)
    return device if re.fullmatch(r"(?:en|bridge|pdp_ip)[0-9]+", device) else None


def sample(target=None, *, approved=False, connect=socket.create_connection,
           interface=route_interface):
    """No network traffic without explicit selected target + owner approval.

    TCP success is evidence of *one endpoint path*, not internet quality,
    website login, provider availability, or a verified remote agent.
    """
    device = interface()
    answer = {
        "schema": SCHEMA, "observedAt": datetime.now(timezone.utc).isoformat(),
        "routeInterface": device, "interfaceObserved": bool(device),
        "target": target, "endpointTCP": "NOT_CHECKED",
        "networkChangeExecuted": False, "providerAuthenticated": False,
        "wifiSSIDRead": False, "privacy": "read-only-owner-controlled",
    }
    if target is None:
        return answer
    if target not in CHECKS or not approved:
        raise ResilienceError("Explicit approved fixed-endpoint probe required")
    if not device:
        answer["endpointTCP"] = "NO_DEFAULT_ROUTE"
        return answer
    address = CHECKS[target]
    try:
        sock = connect(address, timeout=3)
        try:
            answer["endpointTCP"] = "REACHABLE_ON_THIS_PROBE"
        finally:
            sock.close()
    except (OSError, TimeoutError):
        answer["endpointTCP"] = "UNREACHABLE_ON_THIS_PROBE"
    return answer


class FailurePolicy:
    """Debounced recommendation only; never mutate macOS network settings."""

    def __init__(self, *, threshold=FAILURE_THRESHOLD,
                 cooldown=COOLDOWN_SECONDS):
        if threshold < 2 or cooldown < 1:
            raise ValueError("Unsafe resilience policy")
        self.threshold = threshold
        self.cooldown = cooldown
        self.failed = 0
        self.previous_interface = None
        self.last_notice = None

    def update(self, observation, now):
        device = observation.get("routeInterface")
        if self.previous_interface is not None and device != self.previous_interface:
            self.failed = 0
            self.last_notice = None
        self.previous_interface = device
        state = observation.get("endpointTCP")
        if state == "REACHABLE_ON_THIS_PROBE":
            self.failed = 0
            return "OBSERVED_REACHABLE"
        if state not in ("UNREACHABLE_ON_THIS_PROBE", "NO_DEFAULT_ROUTE"):
            return "UNKNOWN_NO_PROBE"
        self.failed += 1
        if self.failed < self.threshold:
            return "RETRY_OBSERVATION"
        if self.last_notice is not None and now - self.last_notice < self.cooldown:
            return "DEGRADED_COOLDOWN"
        self.last_notice = now
        return "OWNER_FALLBACK_RECOMMENDED"


def open_wifi_settings(*, approved=False, run=None):
    run = subprocess.run if run is None else run
    if not approved:
        raise ResilienceError("Opening macOS Wi-Fi settings requires explicit choice")
    result = run(["/usr/bin/open", "-a", "System Settings"],
                 capture_output=True, text=True, check=False, timeout=15)
    if result.returncode:
        raise ResilienceError("System Settings could not be opened")
    return "SYSTEM_SETTINGS_OPEN_REQUESTED_NOT_NETWORK_SWITCHED"


def guidance():
    return (
        "Preferred Mac fallback: System Settings > Wi-Fi > Ask to join hotspots "
        "> Automatic, where available and explicitly configured by the owner. "
        "macOS controls Instant Hotspot. This ZERO observer never changes "
        "the network carrying RDC and never accesses a Wi-Fi password."
    )


def watch(*, interval, target, approved, output=print,
          read=sample, wait=time.sleep, clock=time.monotonic,
          ask=input, max_checks=None):
    if interval not in ALLOWED_INTERVALS:
        raise ResilienceError("Select a supported interval in seconds")
    if target not in CHECKS or not approved:
        raise ResilienceError("Select and explicitly approve one fixed target")
    if max_checks is not None and (type(max_checks) is not int or max_checks < 1):
        raise ResilienceError("Invalid bounded check count")
    policy = FailurePolicy()
    count = 0
    while True:
        observation = read(target, approved=True)
        decision = policy.update(observation, clock())
        output(json.dumps({"observation": observation, "decision": decision},
                          sort_keys=True))
        count += 1
        if decision == "OWNER_FALLBACK_RECOMMENDED":
            output("Repeated endpoint failures. " + guidance())
            # Never touch the current Wi-Fi/RDC connection; the only local
            # action available is user-requested native Settings handoff.
            if ask("Type SETTINGS to open macOS network choices, or Enter to continue: ") == "SETTINGS":
                output(open_wifi_settings(approved=True))
        if max_checks is not None and count >= max_checks:
            return count
        wait(interval)


def main(argv=None):
    parser = argparse.ArgumentParser(
        description="BIFROSTcore ZERO network resilience (read-only)")
    parser.add_argument("action", choices=("status", "check", "watch", "settings", "guide"))
    parser.add_argument("--target", choices=tuple(CHECKS))
    parser.add_argument("--interval", type=int, default=60,
                        choices=ALLOWED_INTERVALS)
    parser.add_argument("--approve-probe", action="store_true")
    parser.add_argument("--approve-settings", action="store_true")
    args = parser.parse_args(argv)
    try:
        if args.action == "guide":
            print(guidance())
        elif args.action == "status":
            print(json.dumps(sample(), indent=2))
        elif args.action == "check":
            print(json.dumps(sample(args.target, approved=args.approve_probe),
                             indent=2))
        elif args.action == "settings":
            print(open_wifi_settings(approved=args.approve_settings))
        elif args.action == "watch":
            if not sys.stdin.isatty():
                raise ResilienceError("Monitoring requires an interactive Mac Terminal")
            if not args.approve_probe:
                raise ResilienceError("Owner must approve a network endpoint probe")
            if input("Monitor " + str(args.target) + " every " + str(args.interval) +
                     " seconds? Type MONITOR: ") != "MONITOR":
                raise ResilienceError("Owner declined network monitoring")
            try:
                watch(interval=args.interval, target=args.target, approved=True)
            except KeyboardInterrupt:
                print("Monitoring stopped; network unchanged.")
        return 0
    except (ResilienceError, OSError, ValueError, subprocess.TimeoutExpired) as exc:
        print("BIFROST network resilience: " + str(exc), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
