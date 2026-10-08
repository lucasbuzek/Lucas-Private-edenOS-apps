#!/usr/bin/env python3
"""BIFROST control CLI.

  bifrostctl.py                 remote/keep-awake provider status (original behaviour)
  bifrostctl.py state           full node capability state (JSON)
  bifrostctl.py raven-provision create Raven node/operator keys in the login Keychain (idempotent)
  bifrostctl.py raven-hash ROLE print SHA-256 of a Raven key (node|operator) for edge secrets
  bifrostctl.py raven-pair      copy the Raven pairing link (operator key in URL #fragment) to the clipboard
  bifrostctl.py raven-bridge    run the ZERO bridge (add --once for a single cycle)
"""
import hashlib
import json
import secrets
import subprocess
import sys

from bifrost.remote_provider import RemoteProvider

SERVICES = {"node": "eden.bifrost.raven.node", "operator": "eden.bifrost.raven.operator"}


def _get(service):
    p = subprocess.run(["/usr/bin/security", "find-generic-password", "-s", service, "-w"],
                       capture_output=True, text=True)
    return p.stdout.strip() if p.returncode == 0 else None


def provision():
    import getpass
    for role, service in SERVICES.items():
        if _get(service):
            print(f"{role}: present in Keychain ({service})")
            continue
        key = secrets.token_hex(32)
        subprocess.run(["/usr/bin/security", "add-generic-password", "-s", service, "-a", getpass.getuser(),
                        "-l", f"BIFROST Lucas Raven {role} key", "-w", key, "-T", "/usr/bin/security"],
                       check=True)
        print(f"{role}: created in Keychain ({service})")


def key_hash(role):
    key = _get(SERVICES[role])
    if not key:
        sys.exit(f"{role} key missing; run raven-provision")
    sys.stdout.write(hashlib.sha256(key.encode()).hexdigest())


def pair():
    from bifrost.raven_bridge import RAVEN_URL
    key = _get(SERVICES["operator"])
    if not key:
        sys.exit("operator key missing; run raven-provision")
    subprocess.run(["/usr/bin/pbcopy"], input=f"{RAVEN_URL}/#key={key}", text=True, check=True)
    print("Pairing link copied to the Mac clipboard (Universal Clipboard can paste it on iPhone).")


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "status"
    if cmd == "status":
        print(json.dumps(RemoteProvider().status(), indent=2))
    elif cmd == "state":
        from bifrost.node_state import StateCollector
        print(json.dumps(StateCollector().collect(force_slow=True), indent=2, default=str))
    elif cmd == "raven-provision":
        provision()
    elif cmd == "raven-hash" and len(sys.argv) > 2 and sys.argv[2] in SERVICES:
        key_hash(sys.argv[2])
    elif cmd == "raven-pair":
        pair()
    elif cmd == "raven-bridge":
        from bifrost.raven_bridge import run_forever
        run_forever(once="--once" in sys.argv)
    else:
        sys.exit(__doc__)
