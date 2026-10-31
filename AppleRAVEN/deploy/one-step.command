#!/bin/bash
# AppleRAVEN one-step deployment: existing Mac SSH key -> Oracle Docker; Pages; native Mac MCPs.
set -euo pipefail
umask 077
if [[ "$(uname -s)" != "Darwin" ]]; then echo "Run in Terminal on your Mac with the Oracle SSH key." >&2; exit 2; fi
ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
CLOUD="$ROOT/cloud/oracle"
WEB="$ROOT/web/installer"
MAC="$ROOT/mac"
KEY="$HOME/Library/CloudStorage/Dropbox/cloudInstall/ssh-key-2026-10-31.key"
REMOTE="ubuntu@145.241.191.137"
DEST="/opt/appleraven/oracle"
for f in "$CLOUD/docker-compose.yml" "$CLOUD/config/mcpServers.json" "$MAC/Install-unified.command" "$WEB/index.html"; do
 if [[ ! -f "$f" ]]; then echo "Incomplete AppleRAVEN package: $f" >&2; exit 3; fi
done
if [[ ! -f "$KEY" ]]; then echo "Oracle SSH key missing at established Mac-local path: $KEY" >&2; exit 4; fi
MODE="$(stat -f %Lp "$KEY")"
if [[ "$MODE" != "600" && "$MODE" != "400" ]]; then echo "SSH key permissions must be 600 or 400: $KEY" >&2; exit 5; fi
echo "AppleRAVEN: checking authenticated SSH to the existing Oracle VM."
SSH=(ssh -i "$KEY" -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=15)
"${SSH[@]}" "$REMOTE" 'test "$(uname -s)" = Linux && id -un && (command -v docker || true)'
echo "AppleRAVEN: configuring a separate Oracle coordinator; existing OracleCloudIn untouched."
"${SSH[@]}" "$REMOTE" "sudo install -d -m 0750 -o ubuntu -g ubuntu '$DEST' '$DEST/config'"
tar -C "$CLOUD" -cf - docker-compose.yml config | "${SSH[@]}" "$REMOTE" "tar -C '$DEST' -xf -"
"${SSH[@]}" "$REMOTE" 'if ! command -v docker >/dev/null; then sudo apt-get update && sudo apt-get install -y docker.io docker-compose-v2; fi'
"${SSH[@]}" "$REMOTE" 'if ! sudo docker compose version >/dev/null 2>&1; then echo "Docker Compose v2 is required." >&2; exit 12; fi'
"${SSH[@]}" "$REMOTE" "cd '$DEST' && sudo docker compose -p appleraven-oracle config --quiet && sudo docker compose -p appleraven-oracle pull && sudo docker compose -p appleraven-oracle up -d"
echo "AppleRAVEN: testing the loopback-only Oracle gateway."
"${SSH[@]}" "$REMOTE" 'set -e; n=0; until curl --fail --silent http://127.0.0.1:5567/health >/dev/null; do n=$((n+1)); if [ "$n" -ge 15 ]; then sudo docker logs --tail 60 appleraven-orchestrator; exit 13; fi; sleep 3; done; echo ORACLE_GATEWAY_HEALTHY'
echo "AppleRAVEN: Docker installed; no new public port opened."
if command -v npx >/dev/null 2>&1; then
 echo "AppleRAVEN: Cloudflare Pages browser login and safe preview deployment."
 if npx --yes wrangler whoami >/dev/null 2>&1 || npx --yes wrangler login; then
   npx --yes wrangler pages deploy "$WEB" --project-name appleraven-setup --branch appleravenMCP
 else
   echo "Cloudflare login incomplete; Pages source remains prepared." >&2
 fi
else
 echo "Node.js/npx not available; Pages source remains prepared." >&2
fi
echo "AppleRAVEN: installing the source-MCP Mac agent with existing owner pairing."
bash "$MAC/Install-unified.command"
echo "AppleRAVEN installer finished. Production OAuth promotion and cloud-provider consent remain gated."
