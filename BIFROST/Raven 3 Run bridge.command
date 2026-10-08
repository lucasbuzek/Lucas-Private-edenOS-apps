#!/bin/sh
cd "$(dirname "$0")" || exit 1
RAVEN_URL=https://lucas-raven.pages.dev ./bifrostctl raven-bridge
echo
echo "Done. You can close this window."
