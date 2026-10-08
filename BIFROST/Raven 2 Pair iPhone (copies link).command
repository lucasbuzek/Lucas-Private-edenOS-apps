#!/bin/sh
cd "$(dirname "$0")" || exit 1
./bifrostctl raven-pair && echo "Pairing link copied. Paste it on your iPhone (Notes/Messages to yourself) and open it."
echo
echo "Done. You can close this window."
