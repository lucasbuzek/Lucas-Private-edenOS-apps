"""Test-only child server. Production has no test-vault or bypass flag."""
import sys
from pathlib import Path
from bifrost.native_host import NativeHost
from bifrost.native_mcp import build_server
from test_native_host import MemorySecrets

root = Path(sys.argv[1])
share = root / "share"
share.mkdir(exist_ok=True)
host = NativeHost(root / "state", MemorySecrets())
device = host.enroll("Protocol fixture", approved=True)
session = host.authenticate(device["id"], host.vault.get(device["id"]))
grant = host.grant(device["id"], share, ["read", "write", "search"], approved=True)
host.approve_command(device["id"], [str(Path(sys.executable).resolve()), "-c",
    "import sys; print('protocol-out'); print('protocol-err',file=sys.stderr); sys.exit(3)"], grant["id"], approved=True)
build_server(host, session).run(transport="stdio")
