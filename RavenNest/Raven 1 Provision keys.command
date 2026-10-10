#!/bin/sh
cd "$(dirname "$0")" || exit 1
./bifrostctl raven-provision
echo
echo "Done. You can close this window."
