#!/usr/bin/env python3
"""Standalone terminal interface for BIFROSTcore Files & Storage.
No daemon, credentials, sync or network access is started by this CLI.
"""
import argparse
import json
import pathlib
import sys

CORE = pathlib.Path(__file__).resolve().parents[1] / "core"
sys.path.insert(0, str(CORE))
from storage_capability import (StorageDenied, accounts, configure_profile,
                                list_direct, profiles, providers, status)
from storage_preview import preview as preview_scope, rclone_metadata_reader


def main(argv=None):
    parser = argparse.ArgumentParser(prog="bifrost-storage",
                                     description="BIFROSTcore Files & Storage — local-first, read-only unless explicit profile --apply")
    sub = parser.add_subparsers(dest="command", required=True)
    for name in ("status", "providers", "accounts"):
        sub.add_parser(name)
    folder = sub.add_parser("list-local", help="list a user-selected folder without recursion")
    folder.add_argument("--path", required=True)
    cloud = sub.add_parser("list-icloud", help="inspect an explicitly selected iCloud Drive folder")
    cloud.add_argument("--path", required=True)
    preview_cmd = sub.add_parser("preview", help="read exactly one configured profile folder")
    preview_cmd.add_argument("--name", required=True)
    preview_cmd.add_argument("--folder", default="")
    preview_cmd.add_argument("--read-remote", action="store_true",
                             help="explicitly fetch remote metadata, never file contents")
    accounts_cmd = sub.add_parser("profiles")
    actions = accounts_cmd.add_subparsers(dest="action", required=True)
    actions.add_parser("list")
    add = actions.add_parser("add", help="preview a metadata-only provider profile")
    for field in ("name", "provider", "source", "local-root"):
        add.add_argument("--" + field, required=True)
    add.add_argument("--remote", default="")
    add.add_argument("--remote-root", default="",
                     help="exact approved cloud directory; blank disables cloud preview")
    add.add_argument("--apply", action="store_true",
                     help="write only private profile metadata; NEVER start sync")
    args = parser.parse_args(argv)
    try:
        if args.command == "status":
            result = status()
        elif args.command == "providers":
            result = providers()
        elif args.command == "accounts":
            result = accounts()
        elif args.command == "list-local":
            result = list_direct(args.path)
        elif args.command == "list-icloud":
            result = list_direct(args.path, icloud=True)
        elif args.command == "preview":
            result = preview_scope(args.name, folder=args.folder,
                                   read_remote=args.read_remote,
                                   remote_reader=rclone_metadata_reader if args.read_remote else None)
        elif args.action == "list":
            result = profiles()
        else:
            result = configure_profile(args.name, args.provider, args.source,
                                       args.remote, args.local_root, apply=args.apply,
                                       remote_root=args.remote_root or None)
        print(json.dumps(result, sort_keys=True, ensure_ascii=False, indent=2))
        return 0
    except (StorageDenied, OSError, UnicodeError, ValueError) as exc:
        # Fail closed; never display confidential file contents or OAuth credentials.
        print(json.dumps({"status": "DENIED_OR_UNAVAILABLE",
                          "reason": str(exc)}), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
