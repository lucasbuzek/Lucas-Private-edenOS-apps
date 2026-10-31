#!/bin/bash
# AppleRAVEN bootstrap from Cloudflare Pages. Only downloads the owner's PRIVATE GitHub source.
set -euo pipefail
umask 077
if [[ "$(uname -s)" != "Darwin" ]]; then echo "Run on a Mac, using Terminal." >&2; exit 1; fi
if ! command -v gh >/dev/null 2>&1; then
 if command -v brew >/dev/null 2>&1; then
  echo "Installing the official GitHub CLI once (browser sign-in follows)."
  brew install gh
 else
  echo "GitHub CLI required: https://cli.github.com/manual/installation" >&2; exit 2
 fi
fi
if ! gh auth status -h github.com >/dev/null 2>&1; then
 echo "Opening GitHub browser sign-in for your existing PRIVATE AppleRAVEN repository."
 gh auth login -h github.com --web
fi
STAGE="$(mktemp -d -t appleravenmcp)"
if [[ -z "$STAGE" || ! -d "$STAGE" ]]; then exit 3; fi
cleanup(){
 case "$STAGE" in /var/folders/*|/tmp/*|/private/tmp/*) rm -rf -- "$STAGE";; *) echo "Temporary folder retained for safety: $STAGE" >&2;; esac
}
trap cleanup EXIT
REPO="lucasbuzek/Lucas-Private-edenOS-apps"
BRANCH="candidate/appleraven-unified-source-federation-oracle-20261031"
echo "Downloading the original AppleRAVEN source package from your private GitHub repository."
gh repo clone "$REPO" "$STAGE/repo" -- --branch "$BRANCH" --filter=blob:none --sparse --depth 1
git -C "$STAGE/repo" sparse-checkout set AppleRAVEN
COMMIT="$(git -C "$STAGE/repo" rev-parse HEAD)"
echo "Source commit: $COMMIT"
test -f "$STAGE/repo/AppleRAVEN/deploy/one-step.command"
test -f "$STAGE/repo/AppleRAVEN/cloud/oracle/docker-compose.yml"
test -f "$STAGE/repo/AppleRAVEN/mac/appleraven_unified_agent.mjs"
bash "$STAGE/repo/AppleRAVEN/deploy/one-step.command"
