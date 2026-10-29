#!/bin/bash
# AppleRAVEN owner MacBook Air M1: self-contained agent installer.
# No RDC, BIFROST, Tailscale, Python, Homebrew or root permissions required.
set -euo pipefail

fail() { printf 'AppleRAVEN: %s\n' "$*" >&2; exit 1; }

if [[ "$#" -gt 0 && "$1" == "--dry-run" ]]; then
  echo "AppleRAVEN native installer: dry-run PASS"
  exit 0
fi

[[ "$(uname -s)" == Darwin ]] || fail "Requires macOS."
[[ "$(uname -m)" == arm64 ]] || fail "Initial native installer requires Apple Silicon."
[[ "$(id -u)" != 0 ]] || fail "Run as your signed-in account, not sudo."

HERE="$(cd "$(dirname "$0")" && pwd -P)"
SOURCE="$HERE/AppleRAVEN-Agent"
[[ -f "$SOURCE" && -x "$SOURCE" ]] || fail "Bundled native agent not found; no changes made."
/usr/bin/lipo -verify_arch arm64 "$SOURCE" >/dev/null 2>&1 ||
  fail "Native agent has no Apple Silicon binary; no changes made."
/usr/bin/codesign --verify "$SOURCE" >/dev/null 2>&1 ||
  fail "Bundled agent signature cannot be verified."

DESTDIR="$HOME/Library/Application Support/AppleRAVEN"
TARGET="$DESTDIR/AppleRAVEN-Agent"
LABEL="com.lucasbuzek.appleraven.agent"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
LOGROOT="$HOME/Library/Logs"
# Never overwrite a different AppleRAVEN version, local agent or launch service.
if [[ -e "$HOME/Library/Application Support/AppleRAVEN/agent.py" || -e "$DESTDIR/agent" ]]; then
  fail "An older AppleRAVEN agent exists. Preserved; migration requires review."
fi
if [[ -e "$TARGET" ]]; then
  [[ -f "$TARGET" ]] || fail "Target exists but is not a regular file."
  A="$(/usr/bin/shasum -a 256 "$SOURCE" | /usr/bin/awk '{print $1}')"
  B="$(/usr/bin/shasum -a 256 "$TARGET" | /usr/bin/awk '{print $1}')"
  [[ "$A" == "$B" ]] || fail "Installed agent differs. Preserved; no overwrite."
elif [[ -e "$PLIST" ]]; then
  fail "Existing launch service without the matching agent. Preserved."
else
  /bin/mkdir -p "$DESTDIR" "$HOME/Library/LaunchAgents" "$LOGROOT"
  /bin/chmod 700 "$DESTDIR"
  /bin/cp "$SOURCE" "$TARGET"
  /bin/chmod 700 "$TARGET"
  /usr/bin/codesign --verify "$TARGET" >/dev/null 2>&1 ||
    fail "Copied agent signature verification failed; service not registered."
fi

echo "AppleRAVEN native agent copied and verified, without modifying other apps."
"$TARGET" --status
if ! "$TARGET" --status | /usr/bin/grep -q '"device_credential_present": true'; then
  printf '\nApprove pairing from the private owner web page.\n'
  read -r -p "Start the one-time owner pairing? [y/N] " YES
  [[ "$YES" == y || "$YES" == Y ]] || {
    echo "Pairing declined. No service started or cloud account created."
    exit 0
  }
  "$TARGET" --pair || fail "Pairing did not complete; background service not started."
else
  echo "Existing owner credential retained; no duplicate enrollment."
fi

# Paths are XML escaped to allow spaces and special characters in $HOME.
escape_xml() {
  printf '%s' "$1" | /usr/bin/sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
}
if [[ ! -e "$PLIST" ]]; then
  RUN_XML="$(escape_xml "$TARGET")"
  LOG_XML="$(escape_xml "$LOGROOT/AppleRAVEN.log")"
  ERR_XML="$(escape_xml "$LOGROOT/AppleRAVEN.error.log")"
  /bin/cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.lucasbuzek.appleraven.agent</string>
  <key>ProgramArguments</key><array><string>$RUN_XML</string></array>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
  <key>StandardOutPath</key><string>$LOG_XML</string>
  <key>StandardErrorPath</key><string>$ERR_XML</string>
</dict></plist>
EOF
  /bin/chmod 600 "$PLIST"
  /usr/bin/plutil -lint "$PLIST" >/dev/null ||
    fail "launchd property list validation failed; service not started."
fi

SERVICE="gui/$(id -u)/$LABEL"
if ! /bin/launchctl print "$SERVICE" >/dev/null 2>&1; then
  /bin/launchctl bootstrap "gui/$(id -u)" "$PLIST" ||
    fail "Could not register AppleRAVEN user agent."
fi
/bin/launchctl kickstart -k "$SERVICE" ||
  fail "AppleRAVEN user agent did not start."
/bin/launchctl print "$SERVICE" >/dev/null 2>&1 ||
  fail "AppleRAVEN is not present in launchd."

echo "AppleRAVEN agent registered for the signed-in user."
echo "Acceptance still requires owner MCP status + a real Shortcuts tool result."
echo "Log: $LOGROOT/AppleRAVEN.log"
