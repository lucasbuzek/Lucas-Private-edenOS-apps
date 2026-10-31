#!/bin/bash
# AppleRAVEN native MCP federation installer; run locally on macOS after package download.
set -euo pipefail
if [[ "$(uname -s)" != "Darwin" ]]; then echo "AppleRAVEN requires macOS." >&2; exit 1; fi
HERE="$(cd "$(dirname "$0")" && pwd -P)"
NODE_BIN="$(command -v node || true)"
if [[ -z "$NODE_BIN" ]] || [[ "$("$NODE_BIN" -p 'Number(process.versions.node.split(".")[0])')" -lt 22 ]]; then
 echo "Install Node.js 22+ and rerun." >&2; exit 1
fi
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
PYAPPLE="$BASE/python/bin/pyapple-mcp"
if [[ ! -x "$PYAPPLE" ]] && python3 -m venv "$BASE/python"; then
 "$BASE/python/bin/python" -m pip install --disable-pip-version-check pyapple-mcp || echo "pyapple-mcp installation unavailable; skipped." >&2
fi
if [[ ! -e "$CONFIG/providers.json" ]]; then
 APPLE_RAVEN_CONFIG="$CONFIG/providers.json" APPLE_RAVEN_BASE="$BASE" APPLE_RAVEN_PYAPPLE="$PYAPPLE" "$NODE_BIN" -e '
 const fs=require("node:fs"),path=require("node:path");
 const base=process.env.APPLE_RAVEN_BASE,p=[];
 p.push({key:"macui",command:"npx",args:["-y","mac-use-mcp@1.1.1"]});
 if(fs.existsSync(process.env.APPLE_RAVEN_PYAPPLE))p.push({key:"pyapple",command:process.env.APPLE_RAVEN_PYAPPLE,args:[]});
 const dev=path.join(base,"sources/mac-developer-bridge/bridge.mjs");
 if(fs.existsSync(dev))p.push({key:"macdev",command:process.execPath,args:[dev]});
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
if /bin/launchctl bootstrap "gui/$(id -u)" "$PLIST"; then
 echo "AppleRAVEN unified Mac agent installed and launched."
else
 echo "Review existing LaunchAgent or start manually: $NODE_BIN $BASE/appleraven_unified_agent.mjs"
fi
echo "Provider configuration: $CONFIG/providers.json"
echo "Operation logs: $LOGS"
