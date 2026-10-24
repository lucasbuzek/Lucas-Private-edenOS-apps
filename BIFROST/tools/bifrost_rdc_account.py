#!/usr/bin/env python3
"""BIFROSTcore ZERO · Apple Hide My Email → RDC guided account enrollment.

This is a THIN, opt-in front end for the established RDC5 identity manager and
Apple's official Safari/iCloud+ UI, not an alternate authentication engine.
No Apple relay enumeration, email/password/token storage, vendor signup bots,
Keychain scraping, remote service activation, or global browser modification.
"""
from __future__ import annotations

import argparse
import pathlib
import re
import subprocess
import sys

LABEL = "bifrostLucasTest1"
APPLE_URL = "https://www.icloud.com/icloudplus/"
RDC_URL = "https://mcp.desktopcommander.app/"
SAFARI_ID = "com.apple.Safari"
RDC5 = (pathlib.Path(__file__).resolve().parents[2] /
        "Online Plugins & Connectors" / "RDC5" / "rdc5")
SWIFT_DEFAULT_BROWSER = (
    "import AppKit; import Foundation; "
    'let target = URL(string: "https://mcp.desktopcommander.app/")!; '
    "if let browser = NSWorkspace.shared.urlForApplication(toOpen: target) { "
    'print(Bundle(url: browser)?.bundleIdentifier ?? "UNKNOWN") '
    '} else { print("UNKNOWN") }'
)


class EnrollmentError(RuntimeError):
    """Refuse action when account, identity or Safari preconditions are unknown."""


def rdc_command(arguments: list[str], *, capture: bool = True):
    """Run the existing approved RDC5 command, with no injected user paths."""
    if not RDC5.is_file() or RDC5.is_symlink():
        raise EnrollmentError("Existing RDC5 launcher is unavailable or unsafe")
    return subprocess.run(
        [str(RDC5), *arguments], cwd=str(RDC5.parent),
        capture_output=capture, text=capture, check=False,
        timeout=20 if capture else None,
    )


def profiles() -> tuple[str, str]:
    result = rdc_command(["list"])
    if result.returncode:
        raise EnrollmentError("Cannot establish current RDC identity list")
    lines = result.stdout.splitlines()
    matching = [line for line in lines if re.match(
        r"^\s*\*?\s*" + re.escape(LABEL) + r"\s+", line)]
    if len(matching) != 1:
        raise EnrollmentError(
            "Target RDC profile was not uniquely found; do not create duplicates")
    selected = [m.group(1) for line in lines
                if (m := re.match(r"^\*\s+([A-Za-z][A-Za-z0-9_-]*)\s+", line))]
    if len(selected) != 1:
        raise EnrollmentError("Cannot verify selected RDC identity")
    return selected[0], matching[0].strip()


def https_browser() -> str:
    """Ask macOS what application would receive the vendor's HTTPS OAuth page."""
    p = subprocess.run(
        ["/usr/bin/swift", "-e", SWIFT_DEFAULT_BROWSER],
        capture_output=True, text=True, timeout=30, check=False)
    if p.returncode or not p.stdout.strip():
        return "UNKNOWN"
    return p.stdout.strip()


def open_safari(url: str) -> None:
    if url not in (APPLE_URL, RDC_URL):
        raise EnrollmentError("Destination not in audited Apple/RDC allowlist")
    result = subprocess.run(
        ["/usr/bin/open", "-a", "Safari", url],
        capture_output=True, text=True, timeout=15, check=False)
    if result.returncode:
        raise EnrollmentError("Safari failed to open the approved destination")


def status() -> None:
    selected, record = profiles()
    print("BIFROSTcore · RDC account enrollment")
    print("Target Apple Hide My Email label: " + LABEL)
    print("Target RDC profile: " + record)
    print("Previous selected RDC profile: " + selected)
    print("HTTPS browser: " + https_browser())
    print("Apple relay: USER-VERIFICATION REQUIRED (not read from Apple)")
    print("Apple Passwords: USER-VERIFICATION REQUIRED (never read credentials)")
    print("RDC provider account / pairing: NOT VERIFIED by local profile metadata")
    print("ChatGPT RDC connector OAuth: independent step, NOT automatically paired")


def guidance() -> None:
    print("BIFROSTcore ZERO — three approved user confirmation gates")
    print("1. Apple Hide My Email: in Safari iCloud+ → Hide My Email. "
          "Find an existing suitable address or create one with label " + LABEL + ".")
    print("   Confirm 'Forward to' and Apple's Create/Save action. "
          "Do not paste your Apple Account password into Terminal.")
    print("2. RDC provider: use the official site in Safari. "
          "Create a distinct vendor login using the Apple relay.")
    print("   Complete your own email verification, passkey/password, terms and MFA.")
    print("   Let Safari offer to save the website login in Apple Passwords.")
    print("3. Run 'login' ONLY after those user actions; match the official "
          "device code in Terminal with the browser, approve device pairing, "
          "then authorize the same RDC account in ChatGPT separately.")
    print("No existing RDC account is logged out or reauthorized automatically.")


def login(*, relay_confirmed: bool, vendor_confirmed: bool) -> int:
    if not (relay_confirmed and vendor_confirmed):
        raise EnrollmentError(
            "Official Apple relay and RDC account creation must both be user-confirmed")
    browser = https_browser()
    if browser != SAFARI_ID:
        raise EnrollmentError(
            "RDC vendor CLI may open the default browser; "
            "default HTTPS handler is not verified Apple Safari")
    prior, record = profiles()
    if "not paired locally" not in record:
        raise EnrollmentError(
            "Existing target session detected; inspect status instead of reauthenticating")
    print("Delegating to EXISTING RDC5 login for " + LABEL)
    print("Use the official browser/device code, and keep this Terminal open "
          "while the authorized RDC test device is needed.")
    try:
        # The established launcher owns all credential/OAuth and local HOME logic.
        # No captured output, no password or token is read by this wrapper.
        result = rdc_command(["login", LABEL], capture=False)
        return result.returncode
    finally:
        # RDC5 login selects the target; restore the pre-existing chosen profile
        # after the official foreground vendor process actually exits.
        if prior != LABEL:
            restored = rdc_command(["switch", prior])
            if restored.returncode:
                print("WARNING: could not restore prior local RDC selection; "
                      "no credential changes were attempted", file=sys.stderr)
            else:
                print("Restored prior RDC selection: " + prior)


def menu(input_fn=input) -> int:
    """One compact guided macOS Terminal interface; all actions are opt-in."""
    guidance()
    while True:
        print("\\nBIFROSTcore · " + LABEL)
        print("[1] Apple Hide My Email in Safari")
        print("[2] RDC signup in Safari")
        print("[3] Official RDC device authorization (after signup)")
        print("[4] Account status")
        print("[q] Quit; no credentials changed")
        try:
            choice = input_fn("Select: ").strip().lower()
            if choice == "q":
                return 0
            if choice == "1":
                profiles()
                open_safari(APPLE_URL)
                print("Set/confirm Apple Hide My Email label: " + LABEL)
            elif choice == "2":
                profiles()
                open_safari(RDC_URL)
                print("Sign in/up with Apple's actual relay; save offered "
                      "website credential in Apple Passwords.")
            elif choice == "3":
                apple_ok = input_fn(
                    "Apple relay exists and forwards correctly? Type YES: ") == "YES"
                vendor_ok = input_fn(
                    "New RDC account created and verified? Type YES: ") == "YES"
                login(relay_confirmed=apple_ok, vendor_confirmed=vendor_ok)
            elif choice == "4":
                status()
            else:
                print("No action selected.")
        except (EnrollmentError, OSError, subprocess.TimeoutExpired) as error:
            print("BIFROST account setup: " + str(error), file=sys.stderr)
        except (EOFError, KeyboardInterrupt):
            print("\\nAccount setup menu closed without reauthorization.")
            return 130


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(
        prog="bifrost-rdc-account",
        description="Guided Apple Hide My Email and official RDC5 account enrollment")
    action = parser.add_subparsers(dest="action", required=True)
    action.add_parser("status", help="Inspect local RDC identity; no secrets")
    action.add_parser("guide", help="Show official Apple and RDC account steps")
    action.add_parser("apple", help="Open Apple's own Hide My Email setup in Safari")
    action.add_parser("provider", help="Open the official RDC site in Safari")
    signin = action.add_parser("login", help="Hand off to the existing RDC5 official OAuth CLI")
    signin.add_argument("--apple-relay-created", action="store_true",
                        help="I personally confirmed the Apple relay exists")
    signin.add_argument("--rdc-account-created", action="store_true",
                        help="I personally registered and verified the RDC account")
    args = parser.parse_args(argv)
    try:
        if args.action == "status":
            status()
        elif args.action == "guide":
            guidance()
        elif args.action == "apple":
            profiles()
            open_safari(APPLE_URL)
            print("Apple iCloud+ page opened in Safari; label: " + LABEL)
            print("The Apple relay and forwarding remain user-confirmation gates.")
        elif args.action == "provider":
            profiles()
            open_safari(RDC_URL)
            print("Official RDC account portal opened in Safari.")
            print("Sign up and save the site credential using Apple Passwords.")
        elif args.action == "login":
            return login(relay_confirmed=args.apple_relay_created,
                         vendor_confirmed=args.rdc_account_created)
        return 0
    except (EnrollmentError, OSError, subprocess.TimeoutExpired) as error:
        print("BIFROST account setup: " + str(error), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
