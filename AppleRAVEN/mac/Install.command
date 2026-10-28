#!/bin/bash
# AppleRAVEN owner-only native app installation and pairing.
# This script runs locally when AppleRAVEN.app is opened. No sudo, RDC or BIFROST.
set -euo pipefail

fail() { printf 'AppleRAVEN: %s\n' "$*" >&2; exit 1; }

if [[ "${1:-}" == "--dry-run" ]]; then
  echo "AppleRAVEN: read-only packaging check succeeded"
  exit 0
fi
[[ "$(uname -s)" == Darwin ]] || fail "Requires macOS."
[[ "$(uname -m)" == arm64 ]] || fail "Initial owner release requires an Apple Silicon Mac."
[[ "$(id -u)" != 0 ]] || fail "Run as the signed-in user, never with sudo."

HERE="$(cd "$(dirname "$0")" && pwd -P)"
SOURCE="$HERE/appleraven_agent.py"
[[ -f "$SOURCE" ]] || fail "Packaged agent is missing. Nothing modified."
PYTHON="$(command -v python3 || true)"
[[ -n "$PYTHON" ]] && "$PYTHON" -c 'import sys; assert sys.version_info >= (3,9)' 2>/dev/null ||
  fail "Python 3.9+ is required on this Mac. No files modified."

DEST="$HOME/Library/Application Support/AppleRAVEN"
AGENT="$DEST/agent.py"
LABEL="com.lucasbuzek.appleraven.agent"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
SOURCE_SHA="$(/usr/bin/shasum -a 256 "$SOURCE" | /usr/bin/awk '{print $1}')"
if [[ -e "$AGENT" ]]; then
  OLD_SHA="$(/usr/bin/shasum -a 256 "$AGENT" | /usr/bin/awk '{print $1}')"
  [[ "$OLD_SHA" == "$SOURCE_SHA" ]] ||
    fail "Another AppleRAVEN agent already exists. Preserving it; installer stopped."
  echo "Existing identical AppleRAVEN agent preserved."
elif [[ -e "$PLIST" ]]; then
  fail "Existing launch agent detected. Preserving installation without changes."
else
  /bin/mkdir -p "$DEST" "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
  /bin/chmod 700 "$DEST"
  /bin/cp "$SOURCE" "$AGENT"
  /bin/chmod 600 "$AGENT"
  [[ "$(/usr/bin/shasum -a 256 "$AGENT" | /usr/bin/awk '{print $1}')" == "$SOURCE_SHA" ]] ||
    fail "Copied file checksum mismatch; abort."
fi


echo "AppleRAVEN local files verified. No changes to RDC, BIFROST, Tailscale or macOS security."
"$PYTHON" "$AGENT" --status

PRESENT="$("$PYTHON" - "$AGENT" <<'PY'
import json, subprocess, sys
p=subprocess.run([sys.executable,sys.argv[1],"--status"],capture_output=True,text=True)
print("yes" if p.returncode==0 and json.loads(p.stdout)["device_credential_present"] else "no")
PY
)"
if [[ "$PRESENT" != yes ]]; then
  printf "\nAppleRAVEN pairing requires your approval in the browser.\n"
  read -r -p "Start secure owner pairing? [y/N] " ANSWER
  [[ "$ANSWER" == y || "$ANSWER" == Y ]] || {
    echo "Not paired. Installed local files remain; service not started."
    exit 0
  }
  "$PYTHON" "$AGENT" --pair || fail "Pairing was not approved; no service started."
else
  echo "Existing credential retained; no duplicate enrollment."
fi

# Register at login only after pairing has succeeded.
if [[ ! -e "$PLIST" ]]; then
  "$PYTHON" - "$PLIST" "$PYTHON" "$AGENT" <<'PY'
import pathlib, plistlib, sys
target, python, agent = map(str, sys.argv[1:])
p = {"Label": "com.lucasbuzek.appleraven.agent",
     "ProgramArguments": [python, agent],
     "RunAtLoad": True,
     "KeepAlive": True,
     "StandardOutPath": str(pathlib.Path.home()/"Library/Logs/AppleRAVEN.log"),
     "StandardErrorPath": str(pathlib.Path.home()/"Library/Logs/AppleRAVEN.error.log")}
pathlib.Path(target).write_bytes(plistlib.dumps(p))
PY
  /bin/chmod 600 "$PLIST"
fi


SERVICE="gui/$(id -u)/$LABEL"
if ! /bin/launchctl print "$SERVICE" >/dev/null 2>&1; then
  /bin/launchctl bootstrap "gui/$(id -u)" "$PLIST" ||
    fail "launchd registration unsuccessful; source and credentials preserved."
fi
/bin/launchctl kickstart -k "$SERVICE" ||
  fail "Agent start unsuccessful; no claim of an online device."
/bin/launchctl print "$SERVICE" >/dev/null 2>&1 ||
  fail "Agent not visible in launchd."

echo "AppleRAVEN agent loaded for signed-in user."
echo "Cloud acceptance is complete ONLY after the owner MCP lists this device online"
echo "and an authenticated Shortcuts tool call returns a real native result."
echo "Logs: ~/Library/Logs/AppleRAVEN.log"

