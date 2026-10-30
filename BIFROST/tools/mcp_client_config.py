#!/usr/bin/env python3
"""Print local MCP client configuration; never mutate any client settings.

Default keeps the original Claude Desktop JSON format. --codex prints one
shell-quoted Codex CLI command for its shared local host (Codex CLI and
ChatGPT desktop on supported installations). Neither path performs setup.
"""
import argparse
import json
from pathlib import Path
import shlex
import sys


def main(argv=None):
    parser = argparse.ArgumentParser(description="BIFROSTbridge local MCP client setup")
    parser.add_argument("--codex", action="store_true", help="Print a safe Codex MCP registration command instead of JSON")
    args = parser.parse_args(argv)
    root = Path(__file__).resolve().parents[1]
    command = sys.executable
    parameters = ["-B", str(root / "headless/mcp_bridge.py")]
    if args.codex:
        print(shlex.join(["codex", "mcp", "add", "BIFROSTbridge-local", "--", command, *parameters]))
    else:
        print(json.dumps({"mcpServers": {
            "BIFROSTbridge-local": {"command": command, "args": parameters}
        }}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
