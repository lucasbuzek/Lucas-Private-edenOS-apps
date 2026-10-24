"""BIFROST ZERO fixed-target, opt-in terminal and Web connectivity checks.

Reuse the current Headless process and existing connection_observer interface.
Reports independent OS-route, loopback service, gateway ICMP, public ICMP,
DNS and HTTPS evidence; never claims pairing, provider auth or online task rights.
No user-provided hosts, shell invocation, credential stores or background jobs.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timezone
import ipaddress
import json
import subprocess
import sys
from urllib.request import urlopen

import connection_observer as existing_connections

SCHEMA = "bifrost.connections.diagnostics.v1"
ALLOWED = ("local", "internet", "all")
PUBLIC_PING_TARGET = "1.1.1.1"
DNS_TARGET = "example.com"
HTTPS_TARGET = "https://www.example.com/"


def _item(name, state, note, *, evidence):
    return {"id": name, "state": state, "detail": note, "evidence": evidence,
            "authorizedService": False}


def _fixed_command(args, *, timeout):
    """Fixed argv only, never shell, never pass client-supplied destinations."""
    try:
        return subprocess.run(args, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                              stderr=subprocess.DEVNULL, text=True,
                              check=False, timeout=timeout)
    except (OSError, subprocess.TimeoutExpired):
        return None


def route_status():
    """Read current adapter metadata without probing any network peer."""
    adapter = existing_connections._interface()
    return {
        "schema": SCHEMA,
        "at": datetime.now(timezone.utc).isoformat(),
        "device": {"kind": "this-mac",
                   "interface": adapter["name"] if adapter else None,
                   "address": adapter["address"] if adapter else None,
                   "subnet": adapter["subnet"] if adapter else None,
                   "state": "local-adapter-observed" if adapter else "unknown"},
        "remoteTestsRun": False,
        "internetReachability": "NOT_TESTED",
        "disclaimer": "An interface or route does not prove internet access",
    }


def _gateway(adapter):
    if not adapter:
        return None
    route = _fixed_command(["/usr/sbin/netstat", "-rn", "-f", "inet"], timeout=3)
    if route is None or route.returncode != 0:
        return None
    for line in route.stdout.splitlines():
        tokens = line.split()
        if len(tokens) < 4 or tokens[0] != "default" or tokens[-1] != adapter["name"]:
            continue
        try:
            address = ipaddress.IPv4Address(tokens[1])
            subnet = ipaddress.IPv4Network(adapter["subnet"], strict=False)
            if address in subnet and str(address) != adapter["address"]:
                return str(address)
        except (ValueError, ipaddress.AddressValueError):
            pass
    return None


def _ping(name, address):
    response = _fixed_command(["/sbin/ping", "-n", "-c", "1", "-W", "1000",
                               "-t", "2", address], timeout=3)
    if response is None:
        return _item(name, "UNKNOWN", "ICMP utility unavailable or timed out",
                     evidence="bounded single ICMP packet")
    if response.returncode == 0:
        return _item(name, "RESPONDING", "ICMP echo reply received; no service login verified",
                     evidence="bounded single ICMP packet")
    return _item(name, "NO_REPLY", "No ICMP reply; filtering does not prove offline",
                 evidence="bounded single ICMP packet")


def _headless():
    try:
        with urlopen("http://127.0.0.1:8798/api/health", timeout=2) as page:
            data = json.loads(page.read(4096))
        identity = data.get("identity", {}) if isinstance(data, dict) else {}
        if (data.get("ok") is True
                and isinstance(identity, dict)
                and identity.get("schema") == "bifrost.headless.identity.v1"
                and identity.get("productId") == "eden.bifrost.headless"):
            return _item("bifrost-headless", "VERIFIED",
                         "Installed local Headless identity responded; authentication separate",
                         evidence="fixed localhost HTTP GET /api/health")
        return _item("bifrost-headless", "UNVERIFIED",
                     "Loopback replied with unrecognized service identity",
                     evidence="fixed localhost HTTP GET /api/health")
    except (OSError, ValueError, TypeError, KeyError, TimeoutError):
        return _item("bifrost-headless", "UNAVAILABLE",
                     "Installed local Headless did not return verified health",
                     evidence="fixed localhost HTTP GET /api/health")


def _dns():
    result = _fixed_command(["/usr/bin/dig", "+time=2", "+tries=1", "+short",
                             DNS_TARGET, "A"], timeout=3)
    if result is None or result.returncode != 0:
        return _item("dns", "UNKNOWN", "DNS check unavailable or timed out",
                     evidence="fixed public domain resolution")
    addresses = []
    for row in result.stdout.splitlines():
        try:
            ip = ipaddress.IPv4Address(row.strip())
            if not (ip.is_loopback or ip.is_unspecified):
                addresses.append(str(ip))
        except ipaddress.AddressValueError:
            pass
    return _item("dns", "RESOLVED" if addresses else "NO_ANSWER",
                 ("Public DNS resolved " + str(len(addresses)) + " IPv4 addresses"
                  if addresses else "No public IPv4 answer; resolver may be restricted"),
                 evidence="fixed public domain resolution")


def _https():
    result = _fixed_command(["/usr/bin/curl", "--silent", "--show-error",
                             "--head", "--location", "--max-time", "6",
                             "--connect-timeout", "3", "--output", "/dev/null",
                             "--write-out", "%{http_code}", HTTPS_TARGET], timeout=7)
    if result is None or result.returncode != 0:
        return _item("https", "NO_RESPONSE", "Fixed HTTPS test did not complete",
                     evidence="fixed public HTTPS HEAD with valid system TLS")
    code = result.stdout.strip()
    if code.isdigit() and len(code) == 3 and code[0] in "2345":
        return _item("https", "RESPONDING",
                     "HTTPS replied with HTTP " + code +
                     " (website access does not verify other providers)",
                     evidence="fixed public HTTPS HEAD with valid system TLS")
    return _item("https", "UNKNOWN", "HTTPS test did not return an HTTP response",
                 evidence="fixed public HTTPS HEAD with valid system TLS")


def check(scope, *, confirmed=False):
    if scope not in ALLOWED or type(scope) is not str:
        raise ValueError("Check scope must be local, internet, or all")
    if confirmed is not True:
        raise PermissionError("External/gateway connectivity checks require explicit consent")
    adapter = existing_connections._interface()
    results = []
    if scope in ("local", "all"):
        results.append(_headless())
        gateway = _gateway(adapter)
        results.append(_ping("gateway", gateway) if gateway else
                       _item("gateway", "UNKNOWN",
                             "No verified on-subnet default gateway to check",
                             evidence="passive local route inspection"))
    if scope in ("internet", "all"):
        results.extend((_dns(), _ping("public-icmp", PUBLIC_PING_TARGET), _https()))
    return {
        "schema": SCHEMA, "scope": scope,
        "at": datetime.now(timezone.utc).isoformat(),
        "explicitConsent": True, "checkCount": len(results), "checks": results,
        "network": {
            "interface": adapter["name"] if adapter else None,
            "subnet": adapter["subnet"] if adapter else None,
        },
        "identityAndProviderAuthorization": "NOT_INFERRED_FROM_NETWORK_REACHABILITY",
        "credentialsAccessed": False,
        "arbitraryTargetsAllowed": False,
        "durationPolicy": "single bounded probe per target, no background monitoring",
    }


def main(argv=None):
    parser = argparse.ArgumentParser(description="BIFROST local-first connectivity diagnostics")
    parser.add_argument("action", choices=("status", "check"), nargs="?", default="status")
    parser.add_argument("--scope", choices=ALLOWED, default="all")
    parser.add_argument("--confirm", action="store_true",
                        help="explicitly authorize one bounded check against fixed local/public hosts")
    args = parser.parse_args(argv)
    try:
        result = route_status() if args.action == "status" else check(
            args.scope, confirmed=args.confirm)
        print(json.dumps(result, indent=2))
        return 0
    except (PermissionError, ValueError) as error:
        print("BIFROST: " + str(error), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
