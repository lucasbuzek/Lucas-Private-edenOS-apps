"""Official SDK MCP adapter. No HTTP listener and no enrollment tools."""
from __future__ import annotations
import argparse
from contextlib import asynccontextmanager
from functools import wraps
from pathlib import Path
from typing import Any
from .native_host import NativeHost, NativeError, AppleSecrets, Session


def build_server(host: NativeHost, session: Session):
    from mcp.server.fastmcp import FastMCP
    from mcp.server.fastmcp.exceptions import ToolError

    @asynccontextmanager
    async def lifespan(_):
        try:
            yield host
        finally:
            host.close()

    mcp = FastMCP("BIFROST Native Host", instructions="Use only owner-approved folder and command IDs. Enrollment is handled by the native owner interface.", lifespan=lifespan)

    def guard(fn):
        @wraps(fn)
        def checked(*args, **kwargs):
            try:
                return fn(*args, **kwargs)
            except NativeError as exc:
                raise ToolError(f"{exc.code}: {exc}") from None
            except (OSError, ValueError, TypeError):
                raise ToolError("operation_failed: Check scope, input and macOS permission state") from None
        return checked

    @mcp.tool()
    @guard
    def host_status() -> dict[str, Any]:
        """Get this authenticated device's host identity, scopes and approved command IDs."""
        return host.status(session)

    @mcp.tool()
    @guard
    def capability_discovery() -> dict[str, Any]:
        """Detect installed system tools. Availability does not authorize execution."""
        return host.discovery(session)

    @mcp.tool()
    @guard
    def filesystem_list(grant_id: str, path: str = ".", offset: int = 0, limit: int = 200) -> dict[str, Any]:
        """List a paginated authorized folder. Paths are relative to the grant root."""
        return host.list(session, grant_id, path, offset, limit)

    @mcp.tool()
    @guard
    def filesystem_read(grant_id: str, path: str, offset: int = 0, length: int = 262144) -> dict[str, Any]:
        """Read a bounded base64 binary chunk, file digest and next offset."""
        return host.read(session, grant_id, path, offset, length)

    @mcp.tool()
    @guard
    def filesystem_metadata(grant_id: str, path: str) -> dict[str, Any]:
        """Get regular file size, modification time, mode and SHA-256."""
        return host.metadata(session, grant_id, path)

    @mcp.tool()
    @guard
    def filesystem_write(grant_id: str, path: str, data: str, expected_sha256: str | None = None) -> dict[str, Any]:
        """Atomically publish a base64 file chunk. Existing files require the current digest."""
        return host.write(session, grant_id, path, data, expected_sha256)

    @mcp.tool()
    @guard
    def filesystem_mkdir(grant_id: str, path: str) -> dict[str, Any]:
        """Create an approved folder. Does not recursively create missing parents."""
        return host.mkdir(session, grant_id, path)

    @mcp.tool()
    @guard
    def filesystem_move(grant_id: str, source: str, destination: str) -> dict[str, Any]:
        """Move a regular file without overwriting. Requires separate write and delete scopes."""
        return host.move(session, grant_id, source, destination)

    @mcp.tool()
    @guard
    def filesystem_remove(grant_id: str, path: str, expected_sha256: str) -> dict[str, Any]:
        """Delete a regular file with its current digest and an owner-approved delete scope."""
        return host.remove(session, grant_id, path, expected_sha256)

    @mcp.tool()
    @guard
    def filesystem_search(grant_id: str, query: str, content: bool = False, limit: int = 200) -> dict[str, Any]:
        """Search filenames or text deterministically. Reports skipped files and truncation."""
        return host.search(session, grant_id, query, content, limit)

    @mcp.tool()
    @guard
    def transfer_begin(grant_id: str, path: str, size: int, expected_sha256: str | None = None) -> dict[str, Any]:
        """Begin an atomic binary upload up to 1 GiB; destination is unchanged until finish."""
        return host.begin_upload(session, grant_id, path, size, expected_sha256)

    @mcp.tool()
    @guard
    def transfer_chunk(upload_id: str, offset: int, data: str) -> dict[str, Any]:
        """Append a bounded base64 upload chunk at the exact next offset."""
        return host.upload_chunk(session, upload_id, offset, data)

    @mcp.tool()
    @guard
    def transfer_finish(upload_id: str, sha256: str) -> dict[str, Any]:
        """Verify full upload size and digest before atomic publication."""
        return host.finish_upload(session, upload_id, sha256)

    @mcp.tool()
    @guard
    def transfer_abort(upload_id: str) -> dict[str, Any]:
        """Discard this device's staged transfer."""
        return host.abort_upload(session, upload_id)

    @mcp.tool()
    @guard
    def process_start(command_id: str) -> dict[str, Any]:
        """Start an exact owner-approved argv/cwd/environment command. Returns a managed job ID."""
        return host.start(session, command_id)

    @mcp.tool()
    @guard
    def process_output(job_id: str, stdout_offset: int = 0, stderr_offset: int = 0, length: int = 262144) -> dict[str, Any]:
        """Read separate bounded stdout/stderr with truthful exit state and output offsets."""
        return host.process(session, job_id, stdout_offset, stderr_offset, length)

    @mcp.tool()
    @guard
    def process_list() -> dict[str, Any]:
        """List only managed jobs owned by this device."""
        return {"jobs": host.jobs(session)}

    @mcp.tool()
    @guard
    def process_terminate(job_id: str) -> dict[str, Any]:
        """Terminate only this device's live managed child group."""
        return host.terminate(session, job_id)

    @mcp.tool()
    @guard
    def process_release(job_id: str) -> dict[str, Any]:
        """Release a finished job's retained output. Running jobs cannot be released."""
        return host.release(session, job_id)

    return mcp


def default_state():
    return Path.home() / "Library/Application Support/BIFROST/NativeHost"


def main():
    parser = argparse.ArgumentParser(description="BIFROST Native Host; owner pairing required")
    parser.add_argument("--device", required=True, help="Approved device ID, never a bearer token")
    parser.add_argument("--state-dir", type=Path, default=default_state())
    args = parser.parse_args()
    try:
        host = NativeHost(args.state_dir)
        token = host.vault.get(args.device)
        session = host.authenticate(args.device, token)
        build_server(host, session).run(transport="stdio")
    except NativeError as exc:
        import sys
        print(f"{exc.code}: {exc}", file=sys.stderr)
        raise SystemExit(1)


if __name__ == "__main__":
    main()
