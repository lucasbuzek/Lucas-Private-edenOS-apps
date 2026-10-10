#!/opt/homebrew/bin/python3
"""BIFROST control CLI.

  bifrostctl.py                 remote/keep-awake provider status (original behaviour)
  bifrostctl.py state           full node capability state (JSON)
  bifrostctl.py raven-provision create Raven node/operator keys in the login Keychain (idempotent)
  bifrostctl.py raven-hash ROLE print SHA-256 of a Raven key (node|operator) for edge secrets
  bifrostctl.py raven-pair      copy the Raven pairing link (operator key in URL #fragment) to the clipboard
  bifrostctl.py raven-enroll    read a one-time enrollment token from stdin and store the node credential
  bifrostctl.py raven-submit-clear  clear submit rate/failure state after Lucas reviews it
  bifrostctl.py raven-bridge    run the ZERO bridge (add --once; --force never bypasses a held lock)
"""
import os
import platform
import sys

# Never run under Intel/Rosetta: if started by a non-arm64 Python on Apple Silicon, re-exec natively.
if sys.platform == "darwin" and platform.machine() != "arm64" and os.environ.get("BIFROST_NO_REEXEC") != "1":
    _py = "/opt/homebrew/bin/python3"
    if os.path.exists(_py):
        os.environ["BIFROST_NO_REEXEC"] = "1"
        os.execv("/usr/bin/arch", ["/usr/bin/arch", "-arm64", _py] + sys.argv)
import hashlib
import json
import secrets
import subprocess
import urllib.request

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


def enroll(stdin=None, input_fn=input, opener=urllib.request.urlopen):
    """Exchange a stdin-only one-time token; never display either credential."""
    from bifrost.raven_bridge import NODE_ID, RAVEN_URL
    stream = stdin or sys.stdin
    if stream.isatty():
        print("Paste the one-time enrollment token, then press Return:", file=sys.stderr)
    token = stream.readline().strip()
    if not token:
        raise SystemExit("no enrollment token received on stdin")
    existing = _get(SERVICES["node"])
    if existing and input_fn("Replace the existing Raven node credential? [y/N] ").strip().lower() != "y":
        raise SystemExit("enrollment cancelled; existing credential unchanged")
    body = json.dumps({"enrollment_token": token, "node_id": NODE_ID}).encode()
    req = urllib.request.Request(RAVEN_URL + "/api/node/enroll", data=body, method="POST",
                                 headers={"Content-Type": "application/json", "User-Agent": "BIFROST-enroll/1"})
    with opener(req, timeout=20) as response:
        result = json.loads(response.read())
    credential = result.get("node_credential") or result.get("node_key") or result.get("credential")
    if not isinstance(credential, str) or not credential:
        raise SystemExit("enrollment response did not contain a node credential")
    import getpass
    subprocess.run(["/usr/bin/security", "add-generic-password", "-U", "-s", SERVICES["node"],
                    "-a", getpass.getuser(), "-l", "BIFROST Lucas Raven node key", "-w", credential,
                    "-T", "/usr/bin/security"], check=True)
    print("Raven node enrollment completed; credential stored in the login Keychain.")


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
    elif cmd == "raven-enroll":
        enroll()
    elif cmd == "raven-submit-clear":
        from bifrost.workincodex import Submitter
        Submitter().clear_block()
        print("WORKinCODEX submission limiter/failure state cleared after local review.")
    elif cmd == "raven-bridge":
        from bifrost.raven_bridge import run_forever
        try:
            run_forever(once="--once" in sys.argv, force="--force" in sys.argv)
        except RuntimeError as exc:
            sys.exit(str(exc))
    else:
        sys.exit(__doc__)
