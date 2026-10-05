"""Provider-neutral adapter. Selection remains explicit and evidence-gated."""
from .native_host import NativeError

CAPABILITIES = {
    "host.status": "status", "capability.discover": "discovery",
    "filesystem.list": "list", "filesystem.read": "read", "filesystem.write": "write",
    "filesystem.metadata": "metadata", "filesystem.search": "search",
    "filesystem.mkdir": "mkdir", "filesystem.move": "move", "filesystem.remove": "remove",
    "transfer.begin": "begin_upload", "transfer.chunk": "upload_chunk",
    "transfer.finish": "finish_upload", "transfer.abort": "abort_upload",
    "process.start": "start", "process.output": "process", "process.list": "jobs",
    "process.terminate": "terminate", "process.release": "release",
}


class NativeProvider:
    provider_id = "bifrost.native"
    automatic_replacement = False
    def __init__(self, host, session):
        self.host, self.session = host, session
    def capabilities(self):
        self.host._check(self.session)
        return {"provider": self.provider_id, "capabilities": sorted(CAPABILITIES),
                "available": True, "regression_pass": False, "automatic_replacement": False}
    def execute(self, capability, arguments=None):
        if capability not in CAPABILITIES:
            raise NativeError("unsupported_capability", "Use an advertised native capability")
        return getattr(self.host, CAPABILITIES[capability])(self.session, **(arguments or {}))
