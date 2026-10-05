"""Owner-side native control channel, never exposed through MCP or a listener."""
import json
import sys
from .native_host import NativeHost, NativeError
from .native_mcp import default_state


def control(host, request):
    action = request.get("action")
    if action == "devices":
        return {"host_id": host.identity, "devices": host.devices()}
    approved = request.get("approved") is True
    if action == "enable":
        host._approval(approved)
        with host._lock:
            row = host.db.execute("SELECT value FROM meta WHERE key='local_device'").fetchone()
        device = next((d for d in host.devices() if row and d["id"] == row[0] and not d["revoked"]), None)
        if device is None:
            import socket
            device = host.enroll(socket.gethostname(), approved=True)
            with host._lock, host.db:
                host.db.execute("INSERT OR REPLACE INTO meta VALUES ('local_device',?)", (device["id"],))
        permissions = request.get("permissions", ["read", "search"])
        if set(permissions) - {"read", "search", "write", "delete"}:
            raise NativeError("invalid_scope", "Unknown folder permissions")
        grant = host.grant(device["id"], request["folder"], permissions, approved=True)
        session = host.authenticate(device["id"], host.vault.get(device["id"]))
        result = host.status(session)
        # A real scoped list probe; READY is never inferred from registration.
        host.list(session, grant["id"])
        result.update({"state": "local-ready", "grant_id": grant["id"], "remote_enabled": False})
        return result
    if action == "enroll":
        return host.enroll(request["name"], approved=approved)
    if action == "grant":
        return host.grant(request["device_id"], request["folder"], request["permissions"], approved=approved)
    if action == "revoke":
        return host.revoke(request["device_id"], approved=approved)
    if action == "revoke_grant":
        return host.revoke_grant(request["grant_id"], approved=approved)
    if action == "approve_command":
        return host.approve_command(request["device_id"], request["argv"], request["grant_id"],
                                    request.get("cwd", "."), request.get("environment"), request.get("timeout", 300),
                                    approved=approved)
    if action == "status":
        device = request["device_id"]
        session = host.authenticate(device, host.vault.get(device))
        return host.status(session)
    raise NativeError("unsupported_action", "Use a supported owner control operation")


def main():
    host = None
    try:
        data = sys.stdin.buffer.read(65537)
        if len(data) > 65536:
            raise NativeError("invalid_request", "Owner request exceeds 64 KiB")
        request = json.loads(data)
        if not isinstance(request, dict):
            raise NativeError("invalid_request", "Owner request must be an object")
        host = NativeHost(default_state())
        result = control(host, request)
        print(json.dumps({"ok": True, "result": result}))
    except NativeError as exc:
        print(json.dumps({"ok": False, "error": {"code": exc.code, "message": str(exc)}}))
        raise SystemExit(1)
    except (OSError, ValueError, KeyError, TypeError):
        print(json.dumps({"ok": False, "error": {"code": "operation_failed", "message": "Check owner input, folder permission and Keychain availability"}}))
        raise SystemExit(1)
    finally:
        if host:
            host.close()


if __name__ == "__main__":
    main()
