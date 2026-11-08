#!/usr/bin/env bash
# THEMBIcouncil isolated FreeLLMAPI installation from its original source.
set -Eeuo pipefail
umask 077
ROOT="${HOME}/thembicouncil-freellmapi"
PROJECT="thembicouncil-freellmapi"
PORT="3103"
cd "$ROOT"
test -f docker-compose.yml || { echo "Missing original FreeLLMAPI source"; exit 10; }
test "$(git remote get-url origin)" = "https://github.com/tashfeenahmed/freellmapi.git" || { echo "Unexpected source"; exit 11; }
docker compose version >/dev/null
openssl version >/dev/null
if [ ! -f .env ]; then
  key="$(openssl rand -hex 32)"
  printf 'ENCRYPTION_KEY=%s\nHOST_BIND=127.0.0.1\nPORT=%s\n' "$key" "$PORT" > .env
  unset key
  chmod 0600 .env
fi
if ! grep -qx 'HOST_BIND=127.0.0.1' .env || ! grep -qx 'PORT=3103' .env; then
  echo "Existing config differs. Refusing to overwrite." >&2
  exit 12
fi
if [ ! -f council-bootstrap.json ]; then
  python3 - <<'PY'
import json, os, pathlib, secrets
p=pathlib.Path("council-bootstrap.json")
with p.open("x", encoding="utf8") as f:
    json.dump({"admin":{"email":"lucasbuzek@gmail.com","password":secrets.token_urlsafe(36)},
               "routing":{"strategy":"balanced"}},f)
os.chmod(p,0o600)
PY
fi
cat > council.override.yml <<'YAML'
services:
  freellmapi:
    image: ghcr.io/tashfeenahmed/freellmapi:v0.16.20
    build: !reset null
    mem_limit: 240m
    cpus: 0.55
    pids_limit: 160
    security_opt:
      - no-new-privileges:true
    environment:
      FREEAPI_CONFIG_PATH: /etc/thembicouncil/freellmapi-bootstrap.json
    volumes:
      - thembicouncil-data:/app/server/data
      - ./council-bootstrap.json:/etc/thembicouncil/freellmapi-bootstrap.json:ro
volumes:
  thembicouncil-data: {}
YAML
chmod 0600 council.override.yml
docker compose -p "$PROJECT" -f docker-compose.yml -f council.override.yml config -q
docker compose -p "$PROJECT" -f docker-compose.yml -f council.override.yml pull freellmapi
docker compose -p "$PROJECT" -f docker-compose.yml -f council.override.yml up -d --no-build --no-deps freellmapi
for i in $(seq 1 20); do
  if curl --noproxy '*' -fsS --max-time 4 "http://127.0.0.1:${PORT}/api/ping" >/dev/null; then
    echo "THEMBIcouncil router responds on localhost:${PORT}"
    docker compose -p "$PROJECT" -f docker-compose.yml -f council.override.yml ps
    exit 0
  fi
  sleep 2
done
echo "Router health failed; inspect isolated Compose logs" >&2
exit 20
