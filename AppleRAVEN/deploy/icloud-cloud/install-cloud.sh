#!/usr/bin/env bash
# Usage: bash AppleRAVEN/deploy/icloud-cloud/install-cloud.sh
# Private cloud Docker installation; Cloudflare routing is configured separately.
set -euo pipefail
if [[ "$(uname -s)" != "Linux" ]]; then
  echo "Cloud iCloud engine requires a Linux cloud node (Mac native agent is separate)." >&2
  exit 1
fi
HERE="$(cd "$(dirname "$0")" && pwd -P)"
cd "$HERE"
if ! command -v docker >/dev/null 2>&1 || ! docker compose version >/dev/null 2>&1; then
  echo "Docker Engine with Compose plugin is required on the selected free VM." >&2
  exit 1
fi
if [[ ! -f ".env" ]]; then
  echo "Enter the Apple ACCOUNT ADDRESS only; password and 2FA are requested later by Apple inside the private container."
  read -r -p "Apple Account (email): " apple_id
  if [[ ! "$apple_id" =~ ^[^[:space:]@=]+@[^[:space:]@=]+$ ]]; then
    echo "Invalid Apple Account identifier." >&2
    exit 1
  fi
  ( umask 077; printf 'ICLOUD_APPLE_ID=%s\n' "$apple_id" > .env )
fi
chmod 600 .env
docker compose config --quiet
echo "Building two upstream MIT iCloud MCP sources (no Apple data accessed during build)."
docker compose build
echo "Apple sign-in begins ONLY inside private cloud terminal. Do not paste passwords into ChatGPT."
echo "Authenticate iCloud Drive:"
docker compose run --rm --entrypoint /opt/icloud-mcp/.venv/bin/icloud-mcp drive login
echo "Authenticate iCloud Photos:"
docker compose run --rm --entrypoint sh photos -c 'icloud auth login --username "$ICLOUD_USERNAME" --session-dir "$ICLOUD_SESSION_DIR"'
echo "Starting the private, localhost-only cloud services."
docker compose up -d
echo "Photos local service health (not a sign-in test):"
docker compose ps
echo
echo "Next: connect cloudflared outbound tunnel on THIS VM, create Cloudflare Workers VPC Services"
echo "for localhost ports 8301 (Photos), 8302 (Drive), then bind them to appleraven-private."
echo "Do NOT publish those ports on the public network, and keep Photo writes/deletes disabled."
