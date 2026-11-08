#!/bin/sh
# Owner-initiated THEMBIcouncil connector installation (macOS/Linux).
# No sudo, automatic run, or embedded credentials.
set -eu
base="$HOME/THEMBIcouncil"
file="$base/thembicouncil_agent.py"
url="https://raw.githubusercontent.com/lucasbuzek/Lucas-Private-edenOS-apps/5cc421746f8f5e6a258a840c3eee1d79aaaf1ebe/THEMBIcouncil/device-agent/thembicouncil_agent.py"
command -v python3 >/dev/null 2>&1 || { echo 'Install Python 3.10+.' >&2; exit 1; }
mkdir -p "$base"
chmod 700 "$base"
test ! -e "$file" || { echo 'Connector already exists; refusing to overwrite.' >&2; exit 1; }
curl --fail --show-error --location --max-time 30 "$url" -o "$file"
chmod 600 "$file"
python3 -m py_compile "$file"
echo "THEMBIcouncil connector saved to: $file"
echo 'Pair after obtaining an individual one-time Council pairing code:'
echo 'python3 "$HOME/THEMBIcouncil/thembicouncil_agent.py" pair --label "Thembi Mac" --root "$HOME/Documents"'
echo 'Then run: python3 "$HOME/THEMBIcouncil/thembicouncil_agent.py" run'
echo "No elevated privileges or unattended service were installed."
