"""Public OpenSSH stdio transport; does not enable Remote Login or install keys."""
import ipaddress
import re
import shlex
from pathlib import Path
from .native_host import NativeError


def ssh_stdio_command(host, user, port, known_hosts, launcher, device_id, *, approved=False):
    """Generate an exact command for an explicitly approved, pre-enrolled SSH peer.

    Requires pre-existing OS-approved SSH login and a pinned known_hosts file.
    No automatic accept-new, password argument, tunnel, agent forwarding, or listener.
    """
    if approved is not True:
        raise NativeError("confirmation_required", "Confirm this enrolled peer before remote access")
    if not isinstance(host, str) or len(host)>253:
        raise NativeError("invalid_peer", "Invalid peer host")
    try:
        ipaddress.ip_address(host)
    except ValueError:
        if not re.fullmatch(r"[A-Za-z0-9](?:[A-Za-z0-9.-]*[A-Za-z0-9])?", host):
            raise NativeError("invalid_peer", "Use a verified hostname or IP address") from None
    if not re.fullmatch(r"[A-Za-z0-9_][A-Za-z0-9_.-]{0,63}", user):
        raise NativeError("invalid_peer", "Invalid SSH username")
    if not isinstance(port, int) or not 1 <= port <= 65535:
        raise NativeError("invalid_peer", "Invalid SSH port")
    known_hosts = Path(known_hosts)
    if not known_hosts.is_absolute() or not known_hosts.is_file() or known_hosts.is_symlink():
        raise NativeError("host_key_required", "Select the owner's verified known_hosts file")
    launcher = Path(launcher)
    if not launcher.is_absolute() or any(c in str(launcher) for c in ("\n", "\r", "\x00")):
        raise NativeError("invalid_peer", "Use the installed remote Native Host launcher path")
    if not re.fullmatch(r"[a-f0-9-]{36}", device_id):
        raise NativeError("invalid_peer", "Use an enrolled device UUID")
    return ["/usr/bin/ssh", "-F", "/dev/null", "-T", "-p", str(port),
            "-o", "BatchMode=yes", "-o", "StrictHostKeyChecking=yes",
            "-o", "UserKnownHostsFile=" + str(known_hosts), "-o", "GlobalKnownHostsFile=/dev/null",
            "-o", "ForwardAgent=no", "-o", "ClearAllForwardings=yes",
            "-o", "ConnectTimeout=10", "-o", "ServerAliveInterval=15",
            "-l", user, "--", host, shlex.join([str(launcher), "--device", device_id])]
