#!/usr/bin/env python3
"""Existing BIFROST CLI; preserves original no-argument remote status."""
import json
import sys

from bifrost.remote_provider import RemoteProvider
from bifrost.apple_capabilities import discover_apple_capabilities


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    if argv in (["apple", "status"], ["apple", "discover"]):
        print(json.dumps(discover_apple_capabilities(), indent=2))
        return 0
    if argv:
        print("Usage: bifrostctl.py [apple status|apple discover]", file=sys.stderr)
        return 2
    print(json.dumps(RemoteProvider().status(), indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
