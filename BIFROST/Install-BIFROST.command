#!/bin/bash
set -eu
cd -- "$(dirname -- "$0")"
PYTHON=""
for candidate in /opt/homebrew/bin/python3 /usr/local/bin/python3 /usr/bin/python3; do
  if [ -x "$candidate" ] && "$candidate" -c 'import sys; sys.exit(sys.version_info < (3,10))' 2>/dev/null; then
    PYTHON="$candidate"
    break
  fi
done
if [ -z "$PYTHON" ]; then
  echo 'Python 3.10 or newer is required. Install Python for macOS, then run this again.'
else
  "$PYTHON" -B tools/install_headless.py || true
fi
read -r -p 'Press Return to close.'
