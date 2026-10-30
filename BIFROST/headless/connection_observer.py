"""BIFROST ZERO local connection observations.

Extends existing Headless only with scoped, truthful OS observations.
No secrets, provider login, arbitrary URL input, launch or blanket network
scan. Native BIFROST LANProbe remains the authoritative native-scanner design;
this headless adapter uses the same bounded on-device ICMP semantics.
"""
from __future__ import annotations

from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
import http.client
import json
import ipaddress
from pathlib import Path
import re
import socket
import subprocess
import threading
import time

SCHEMA = "bifrost.connections.observation.v1"
NETWORK_STALE_SECONDS = 300
BASE = Path("/Users/lucas/edenOS/Software Development")
PROJECT = BASE / "BIFROST"
CONNECTORS = BASE / "Online Plugins & Connectors"
CATALOG = (
    ("rdc", "RDC · Desktop Commander", "RDC5", "Remote connector manager"),
    ("workincodex", "WORKinCODEX", "WORKinCODEX", "Development bridge"),
    ("files-storage", "BIFROST Files & Storage", None, "Storage capability"),
    ("ai-toolkit", "AI TOOLKIT", None, "AI/tools catalog"),
    ("adobe", "Adobe / Photoshop actions", None, "External creative adapter"),
)
# Last observed ChatGPT personal Plugin Creator inventory on 2026-10-20.
# Registration is not runtime reachability, provider authentication or a
# locally installed native app. Keep these explicitly distinct in the UI.
VERIFIED_PLUGIN_NAMES = {"janitor": "JANITOR", "penelope": "PENELOPE",
                         "heimdall": "HEIMDALL", "files-storage": "BIFROST Files & Storage"}
APP_NAMES = ("BIFROST", "JANITOR", "PENELOPE", "HEIMDALL", "CURATOR")

# ZERO: Recover EXACT local Web representations from each specialist's own
# current source/manifest. Health + actual HTML identity must agree before a
# launch URL is exposed. Neither source presence nor plugin registration grants
# a live Web identity. No generic URL input, remote host, login or OS launch.
WEB_REPRESENTATIONS = {
    "HEIMDALL": {"port": 8787, "htmlTitle": "<title>HEIMDALL", "identity": "heimdall"},
    "PENELOPE": {"port": 8765, "htmlTitle": "<title>PENELOPE", "identity": "penelope"},
}


def _web_get(port, route, *, mime, limit):
    """Bounded, no-redirect GET to an explicit loopback-only known service."""
    conn = http.client.HTTPConnection("127.0.0.1", port, timeout=0.55)
    try:
        conn.request("GET", route, headers={"Accept": mime, "Connection": "close"})
        response = conn.getresponse()
        if response.status != 200 or not response.getheader("Content-Type", "").lower().startswith(mime):
            return None
        size = response.getheader("Content-Length")
        if size is not None and (not size.isdecimal() or int(size) > limit):
            return None
        value = response.read(limit + 1)
        return value if len(value) <= limit else None
    except (OSError, TimeoutError, ValueError, http.client.HTTPException):
        return None
    finally:
        conn.close()


def _verified_web(name):
    """Return a pinned Web URL only after the owning service proves its identity."""
    spec = WEB_REPRESENTATIONS.get(name)
    if not spec:
        return None
    port = spec["port"]
    health = _web_get(port, "/api/health", mime="application/json", limit=2048)
    if health is None:
        return None
    try:
        parsed = json.loads(health)
    except (ValueError, UnicodeDecodeError):
        return None
    if not isinstance(parsed, dict):
        return None
    if spec["identity"] == "heimdall":
        identity_ok = (parsed.get("ok") is True
                       and parsed.get("app") == "HEIMDALL"
                       and parsed.get("identity") == "ORGANIZE & UNDERSTAND"
                       and parsed.get("schema_version") == 2
                       and parsed.get("build_id") == "heimdall-private-exp-20260925.4")
    elif spec["identity"] == "penelope":
        identity_ok = (parsed.get("status") == "ready"
                       and parsed.get("custody") == "read-only"
                       and parsed.get("legacy_reconcile") is True
                       and parsed.get("version") == "0.2.0")
    else:
        return None
    if not identity_ok:
        return None
    html = _web_get(port, "/", mime="text/html", limit=32768)
    if html is None or spec["htmlTitle"].encode("utf-8") not in html:
        return None
    return "http://127.0.0.1:{}/".format(port)


def _fixed_read(args, timeout=3):
    try:
        result = subprocess.run(args, capture_output=True, text=True,
                                check=False, timeout=timeout)
        return result.stdout[:30000] if result.returncode == 0 else ""
    except (OSError, subprocess.TimeoutExpired):
        return ""


def _interface():
    # Mac default device is established from the current route, not guessed
    # from a hard-coded Wi-Fi name. Exclude VPN and public networks.
    table = _fixed_read(["/usr/sbin/netstat", "-rn", "-f", "inet"])
    iface = None
    for row in table.splitlines():
        columns = row.split()
        if columns and columns[0] == "default" and len(columns) >= 4:
            candidate = columns[-1]
            if re.fullmatch(r"en[0-9]+", candidate):
                iface = candidate
                break
    if not iface:
        return None
    info = _fixed_read(["/sbin/ifconfig", iface])
    match = re.search(r"^\s*inet (\d{1,3}(?:\.\d{1,3}){3}) netmask (0x[0-9a-fA-F]+)", info, re.M)
    if not match:
        return None
    try:
        address = ipaddress.IPv4Address(match.group(1))
        mask = int(match.group(2), 16)
        network = ipaddress.IPv4Network((int(address), bin(mask).count("1")), strict=False)
        if int(network.netmask) != mask:
            return None
        if (not address.is_private or address.is_loopback or network.prefixlen < 24
                or network.prefixlen > 30):
            return None
        # The existing native LANProbe caps broad networks at one /24.
        if network.prefixlen > 24:
            subnet = network
        else:
            subnet = ipaddress.IPv4Network((int(address), 24), strict=False)
        return {"name": iface, "address": str(address), "subnet": str(subnet),
                "network": subnet}
    except (ValueError, ipaddress.AddressValueError, ipaddress.NetmaskValueError):
        return None


def _arp(subnet, own_address):
    raw = _fixed_read(["/usr/sbin/arp", "-an"])
    observed = set()
    for line in raw.splitlines():
        if " at " not in line or "(incomplete)" in line:
            continue
        found = re.search(r"\((\d{1,3}(?:\.\d{1,3}){3})\)", line)
        if not found:
            continue
        try:
            ip = ipaddress.IPv4Address(found.group(1))
            if ip in subnet and str(ip) != own_address:
                observed.add(str(ip))
        except ipaddress.AddressValueError:
            continue
    return sorted(observed, key=lambda x: int(ipaddress.IPv4Address(x)))


def _rdc():
    exe = CONNECTORS / "RDC5" / "rdc5"
    if not exe.is_file() or exe.is_symlink():
        return {"state": "not-found", "selected": None, "profiles": [],
                "authentication": "not-verified-from-local-profile",
                "liveChatGPTTransport": "independent-verification-required"}
    text = _fixed_read([str(exe), "list"], timeout=5)
    selected, profiles = None, []
    for line in text.splitlines():
        match = re.match(r"^\s*(\*?)\s*(RDC[1-9][0-9]*|bifrostLucasTest1)\s+", line)
        if match:
            profiles.append(match.group(2))
            if match.group(1):
                selected = match.group(2)
    return {"state": "catalogued" if profiles else "unverified",
            "selected": selected, "profiles": profiles,
            "authentication": "not-verified-from-local-profile",
            "liveChatGPTTransport": "independent-verification-required"}


def _apps(home):
    release = home / "edenOS/Releases"
    available = []
    if release.is_dir() and not release.is_symlink():
        try:
            available = [p.name for p in release.iterdir()
                         if p.name.lower().endswith(".app") and not p.is_symlink()][:400]
        except OSError:
            pass
    result = []
    for name in APP_NAMES:
        tests = [file for file in available if file.upper().startswith(name + "_")]
        plugin = name.lower() in VERIFIED_PLUGIN_NAMES
        web_url = _verified_web(name)
        result.append({
            "id": name.lower(), "name": name,
            "nativeTestCandidate": bool(tests),
            "nativeInstalled": "unverified",
            "chatgptPluginObserved": plugin,
            "pluginObservation": "2026-10-20 owner inventory, no live BIFROST dispatch" if plugin else None,
            "webURL": web_url, "webVerified": web_url is not None,
            "webEvidence": "exact-loopback-health-and-html" if web_url else "UNVERIFIED",
            "status": ("Mac test candidate observed" if tests else
                       "ChatGPT plugin catalogued" if plugin else "No local launch candidate observed")
        })
    return result


def _connectors(home, rdc):
    return [
        {"id": key, "name": title,
         "type": kind, "state": (
             "selected-local-profile" if key == "rdc" and rdc["selected"]
             else "adapter-source-observed" if (
                 (key == "workincodex" and (CONNECTORS / "WORKinCODEX").is_dir()) or
                 (key == "files-storage" and (PROJECT / "core/storage_capability.py").is_file()) or
                 (key == "ai-toolkit" and (BASE / "#common/Universal_AI_Toolkit_Final/catalog_metadata.json").is_file())
             ) else "external-tool-offered-not-device-authorized" if key == "adobe"
             else "unverified"),
         "detail": (("Selected " + rdc["selected"] + "; authentication checked independently") if
                    key == "rdc" and rdc["selected"] else
                    "Capability presence is not a connected app Web UI"),
         "webURL": None, "webVerified": False}
        for key,title,folder,kind in CATALOG
    ]


class LANMonitor:
    def __init__(self):
        self.lock = threading.Lock()
        self.status = "not-scanned"
        self.started = 0.0
        self.completed = 0.0
        self.scanned = 0
        self.total = 0
        self.responders = []
        self.range = None
        self.failure = None

    def snapshot(self):
        with self.lock:
            current = time.time()
            age = (current - self.completed) if self.completed else None
            return {
                "status": self.status if age is None or age <= NETWORK_STALE_SECONDS
                          else "stale",
                "range": self.range, "scanned": self.scanned, "total": self.total,
                "responders": list(self.responders) if age is None or age <= NETWORK_STALE_SECONDS else [],
                "ageSeconds": round(age, 1) if age is not None else None,
                "error": self.failure,
                "effectsVerified": False
            }

    def begin(self, start, end, *, confirmed=False):
        interface = _interface()
        if not confirmed:
            raise ValueError("Owner confirmation required for ICMP scan")
        if not interface:
            raise ValueError("No verified private local IPv4 interface")
        if type(start) is not int or type(end) is not int or not (1 <= start <= end <= 254):
            raise ValueError("Choose an IPv4 host range between 1 and 254")
        if end - start + 1 > 64:
            raise ValueError("One user-selected probe batch is limited to 64 LAN addresses")
        subnet = interface["network"]
        targets = [str(ipaddress.IPv4Address(int(subnet.network_address) + n))
                   for n in range(start, end + 1)]
        targets = [ip for ip in targets if ip != interface["address"]
                   and ipaddress.IPv4Address(ip) in subnet]
        if not targets:
            raise ValueError("No eligible peers in this subnet")
        with self.lock:
            if self.status == "scanning":
                raise ValueError("A bounded scan is already in progress")
            self.status = "scanning"
            self.started = time.time()
            self.completed = 0
            self.scanned = 0
            self.total = len(targets)
            self.range = "{} · {}–{}".format(interface["subnet"],start,end)
            self.responders = []
            self.failure = None
        threading.Thread(target=self._probe, args=(targets,), daemon=True,
                         name="BIFROST-Owner-LAN-Probe").start()
        return self.snapshot()

    def _probe(self, targets):
        def ping(ip):
            try:
                result = subprocess.run(
                    ["/sbin/ping", "-n", "-c", "1", "-W", "850", "-t", "2", ip],
                    stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL, timeout=3, check=False)
                return ip, result.returncode == 0
            except (OSError, subprocess.TimeoutExpired):
                return ip, False
        try:
            with ThreadPoolExecutor(max_workers=8) as worker:
                futures = [worker.submit(ping, ip) for ip in targets]
                for item in as_completed(futures):
                    ip, ok = item.result()
                    with self.lock:
                        self.scanned += 1
                        if ok:
                            self.responders.append(ip)
                            self.responders.sort(key=lambda n: int(ipaddress.IPv4Address(n)))
            with self.lock:
                self.status = "complete"
                self.completed = time.time()
        except (RuntimeError, ValueError) as exc:
            with self.lock:
                self.status = "error"
                self.failure = str(exc)
                self.completed = time.time()


MONITOR = LANMonitor()


def snapshot(home=None, runtime_id=None):
    home = BASE.parents[1] if home is None else Path(home)
    interface = _interface()
    neighbors = _arp(interface["network"], interface["address"]) if interface else []
    scan = MONITOR.snapshot()
    recent = set(scan["responders"])
    peers = [
        {"address": ip, "state": "icmp-responded" if ip in recent else "arp-cached",
         "connectedServiceVerified": False}
        for ip in sorted(set(neighbors) | recent, key=lambda x: int(ipaddress.IPv4Address(x)))
    ]
    rdc = _rdc()
    return {
        "schema": SCHEMA,
        "observedAt": datetime.now(timezone.utc).isoformat(),
        "thisDevice": {"name": socket.gethostname(), "type": "this-mac",
                       "state": "local-session-observed", "runtimeId": runtime_id},
        "lan": {"interface": interface["name"] if interface else None,
                "address": interface["address"] if interface else None,
                "subnet": interface["subnet"] if interface else None,
                "passiveARPCount": len(neighbors),
                "observedPeers": peers, "scan": scan,
                "monitoring": "read-only-refresh-by-owner-selected-interval",
                "nativeBonjour": "implemented-in-native-BIFROST-not-shared-to-this-API"},
        "rdc": rdc,
        "apps": _apps(home),
        "connectors": _connectors(home, rdc),
        "privacy": {"scope": "this-device-and-selected-private-LAN",
                    "credentialRead": False, "backgroundNetworkScan": False,
                    "serviceHealthNotInferredFromARP": True,
                    "launchAuthority": False}
    }
