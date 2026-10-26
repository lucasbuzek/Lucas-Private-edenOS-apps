#!/bin/bash
set -eu
cd -- "$(dirname -- "$0")"
status=0
PYTHON=""
for candidate in /opt/homebrew/bin/python3 /usr/local/bin/python3 /usr/bin/python3; do
  if [ -x "$candidate" ] && "$candidate" -c 'import sys; sys.exit(sys.version_info < (3,10))' 2>/dev/null; then
    PYTHON="$candidate"
    break
  fi
done
if [ -z "$PYTHON" ]; then
  echo 'Python 3.10 or newer is required. Install Python for macOS, then run this again.'
  status=1
else
  "$PYTHON" -B tools/install_headless.py || status=$?
fi
if [ "$status" -ne 0 ]; then echo "Installation failed (exit $status)."; fi
if [ -t 0 ]; then read -r -p 'Press Return to close.' || :; fi
exit "$status"
