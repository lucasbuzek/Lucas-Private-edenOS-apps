#!/bin/bash
# AppleRAVEN native MCP federation installer; run locally on macOS after package download.
set -euo pipefail
if [[ "$(uname -s)" != "Darwin" ]]; then echo "AppleRAVEN requires macOS." >&2; exit 1; fi
HERE="$(cd "$(dirname "$0")" && pwd -P)"
NODE_BIN="$(command -v node || true)"
if [[ -z "$NODE_BIN" ]] || [[ "$("$NODE_BIN" -p 'Number(process.versions.node.split(".")[0])' 2>/dev/null || echo 0)" -lt 22 ]]; then
 if command -v brew >/dev/null 2>&1; then
  echo "Installing free Node.js 22 for the local AppleRAVEN runtime."
  brew install node@22 || { echo "Node.js install failed. See https://nodejs.org/en/download" >&2; exit 1; }
  NODE_BIN="$(brew --prefix node@22)/bin/node"
 else
  echo "Node.js 22+ required: https://nodejs.org/en/download (or install Homebrew)." >&2; exit 1
 fi
fi
if [[ ! -x "$NODE_BIN" ]]; then echo "Node.js 22 installation not usable." >&2; exit 1; fi
# npx and native providers inherit a matching Node.js runtime instead of a stale
# older npm installation from the user's shell.
export PATH="$(dirname "$NODE_BIN"):$PATH"
if ! command -v python3 >/dev/null; then echo "Python 3 required for Keychain pairing." >&2; exit 1; fi
if [[ ! -f "$HERE/appleraven_unified_agent.mjs" || ! -f "$HERE/appleraven_agent.py" ]]; then
 echo "Use the complete AppleRAVEN Mac distribution, not this script alone." >&2; exit 1
fi
BASE="$HOME/Library/Application Support/AppleRAVEN/Unified"
CONFIG="$HOME/.config/appleraven"
LOGS="$HOME/Library/Logs/AppleRAVEN"
PLIST="$HOME/Library/LaunchAgents/com.lucasbuzek.appleraven.unified.plist"
mkdir -p "$BASE" "$CONFIG" "$LOGS" "$HOME/Library/LaunchAgents"
chmod 700 "$CONFIG"
install -m 0755 "$HERE/appleraven_unified_agent.mjs" "$BASE/appleraven_unified_agent.mjs"
install -m 0700 "$HERE/appleraven_agent.py" "$BASE/appleraven_agent.py"
"$NODE_BIN" --check "$BASE/appleraven_unified_agent.mjs"
if ! /usr/bin/security find-generic-password -s com.lucasbuzek.appleraven.device -a "$(id -un)" >/dev/null 2>&1; then
 echo "Pair using your existing AppleRAVEN owner sign-in. Device secret stays in Keychain."
 python3 "$BASE/appleraven_agent.py" --pair
fi
SOURCE_DIR="$BASE/sources"
mkdir -p "$SOURCE_DIR"
if [[ ! -e "$SOURCE_DIR/mac-developer-bridge" ]]; then
 git clone --depth 1 https://github.com/alexanderradahl/mac-developer-bridge.git "$SOURCE_DIR/mac-developer-bridge" || echo "Developer bridge unavailable; skipped." >&2
fi
# Mac Developer Bridge exposes broad local authority. Ask the owner explicitly before
# activating it; every federated call also receives an AppleRAVEN GUI approval.
DEVELOPER_BRIDGE="$SOURCE_DIR/mac-developer-bridge/bridge.mjs"
BRIDGE_DATA="$HOME/Library/Application Support/MacDeveloperBridge"
BRIDGE_UNLOCK="$BRIDGE_DATA/FULL_ACCESS_ENABLED"
if [[ -f "$DEVELOPER_BRIDGE" && ! -f "$BRIDGE_UNLOCK" ]]; then
 echo
 echo "Optional: Mac Developer Bridge adds PTY sessions, Codex history, advanced file"
 echo "operations and complete developer jobs. It can access data as your Mac user."
 echo "AppleRAVEN asks for confirmation before each forwarded call. You may revoke"
 echo "the bridge independently by removing its FULL_ACCESS_ENABLED file."
 read -r -p "Enable this powerful local MCP provider? Type ENABLE to confirm [skip]: " BRIDGE_CHOICE
 if [[ "$BRIDGE_CHOICE" == "ENABLE" ]]; then
  mkdir -p "$BRIDGE_DATA"
  chmod 700 "$BRIDGE_DATA"
  ( umask 077; printf '%s\n' 'I_UNDERSTAND_THIS_GRANTS_FULL_ACCESS' > "$BRIDGE_UNLOCK" )
  chmod 600 "$BRIDGE_UNLOCK"
  echo "Mac Developer Bridge enabled for this macOS user."
 else
  echo "Mac Developer Bridge disabled. Other AppleRAVEN tools remain available."
 fi
fi
PYAPPLE="$BASE/python/bin/pyapple-mcp"
if [[ ! -x "$PYAPPLE" && "${APPLERAVEN_DEFER_PYAPPLE:-0}" != "1" ]] && python3 -m venv "$BASE/python"; then
 "$BASE/python/bin/python" -m pip install --disable-pip-version-check pyapple-mcp || echo "pyapple-mcp installation unavailable; skipped." >&2
fi
# Apple-Tools-MCP is an optional unified native provider; uvx manages its
# Python environment. No paid service or separate cloud connection is involved.
UVX_BIN="$(command -v uvx || true)"
if [[ -z "$UVX_BIN" ]] && command -v brew >/dev/null 2>&1; then
 echo "Installing the free uv runner for Apple-Tools-MCP."
 brew install uv || echo "uv unavailable; Apple-Tools-MCP will be skipped." >&2
 UVX_BIN="$(command -v uvx || true)"
fi
if [[ ! -e "$CONFIG/providers.json" ]]; then
 APPLE_RAVEN_CONFIG="$CONFIG/providers.json" APPLE_RAVEN_BASE="$BASE" APPLE_RAVEN_PYAPPLE="$PYAPPLE" APPLE_RAVEN_UVX="$UVX_BIN" "$NODE_BIN" -e '
 const fs=require("node:fs"),path=require("node:path");
 const base=process.env.APPLE_RAVEN_BASE,p=[];
 p.push({key:"macui",command:"npx",args:["-y","mac-use-mcp@1.1.1"]});
 // JoshuaRileyDev's MIT launcher provides installed-app enumeration and open-with.
 p.push({key:"applaunch",command:"npx",args:["-y","@joshuarileydev/mac-apps-launcher-mcp-server@0.0.1"]});
 // Reuse the actual upstream Apple MCP implementations instead of recreating them.
 p.push({key:"imcp",command:"npx",args:["-y","@heznpc/imcp@1.3.0","--full"]});
 p.push({key:"photos",command:"npx",args:["-y","apple-photos-mcp"]});
 if(process.env.APPLE_RAVEN_UVX)p.push({key:"appletools",command:process.env.APPLE_RAVEN_UVX,args:["apple-tools-mcp"]});
 if(fs.existsSync(process.env.APPLE_RAVEN_PYAPPLE))p.push({key:"pyapple",command:process.env.APPLE_RAVEN_PYAPPLE,args:[]});
 const dev=path.join(base,"sources/mac-developer-bridge/bridge.mjs");
 if(fs.existsSync(dev)&&fs.existsSync(path.join(require("node:os").homedir(),"Library/Application Support/MacDeveloperBridge/FULL_ACCESS_ENABLED")))p.push({key:"macdev",command:process.execPath,args:[dev]});
 fs.writeFileSync(process.env.APPLE_RAVEN_CONFIG,JSON.stringify({providers:p},null,2)+"\n",{flag:"wx",mode:0o600});
 '
fi
if [[ ! -e "$PLIST" ]]; then
 APPLE_RAVEN_PLIST="$PLIST" APPLE_RAVEN_AGENT="$BASE/appleraven_unified_agent.mjs" APPLE_RAVEN_LOGS="$LOGS" APPLE_RAVEN_NODE="$NODE_BIN" "$NODE_BIN" -e '
 const fs=require("node:fs");
 const xml=s=>String(s).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;");
 const plist=[
 "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
 "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">",
 "<plist version=\"1.0\"><dict><key>Label</key><string>com.lucasbuzek.appleraven.unified</string>",
 "<key>ProgramArguments</key><array><string>"+xml(process.env.APPLE_RAVEN_NODE)+"</string><string>"+xml(process.env.APPLE_RAVEN_AGENT)+"</string></array>",
 "<key>RunAtLoad</key><true/><key>KeepAlive</key><true/>",
 "<key>EnvironmentVariables</key><dict><key>PATH</key><string>"+xml(process.env.PATH)+"</string></dict>",
 "<key>StandardOutPath</key><string>"+xml(process.env.APPLE_RAVEN_LOGS+"/unified.out.log")+"</string>",
 "<key>StandardErrorPath</key><string>"+xml(process.env.APPLE_RAVEN_LOGS+"/unified.err.log")+"</string></dict></plist>"
 ].join("\n")+"\n";
 fs.writeFileSync(process.env.APPLE_RAVEN_PLIST,plist,{flag:"wx",mode:0o600});
 '
fi
LABEL="com.lucasbuzek.appleraven.unified"
DOMAIN="gui/$(id -u)"
# Re-running the installer updates the existing executable and restarts the live agent.
# Without this, launchctl bootstrap returns "already loaded" and keeps the old code.
if /bin/launchctl print "$DOMAIN/$LABEL" >/dev/null 2>&1; then
  echo "Restarting existing AppleRAVEN user agent with current source."
  /bin/launchctl bootout "$DOMAIN/$LABEL" || {
    echo "Could not stop existing AppleRAVEN agent; no forced termination." >&2
    exit 1
  }
fi
if /bin/launchctl bootstrap "$DOMAIN" "$PLIST"; then
 /bin/launchctl kickstart "$DOMAIN/$LABEL" >/dev/null 2>&1 || true
 echo "AppleRAVEN unified Mac agent installed and launched."
else
 echo "Could not load agent. Review $LOGS/unified.err.log or start manually: $NODE_BIN $BASE/appleraven_unified_agent.mjs" >&2
 exit 1
fi
echo "Provider configuration: $CONFIG/providers.json"
echo "Operation logs: $LOGS"
echo
echo "AppleRAVEN local connection summary:"
python3 "$BASE/appleraven_agent.py" --status
if /bin/launchctl print "$DOMAIN/$LABEL" >/dev/null 2>&1; then
 echo "Background execution service: loaded"
else
 echo "Background execution service: NOT LOADED (check logs above)" >&2
 exit 1
fi
echo "Cloud owner MCP: https://appleraven-private.lucasravensnest.workers.dev/mcp"
echo "Use appleraven.devices.list from your existing ChatGPT AppleRAVEN connector after pairing."
