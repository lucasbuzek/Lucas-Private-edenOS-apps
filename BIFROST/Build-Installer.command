#!/bin/bash
set -eu
cd -- "$(dirname -- "$0")"
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
trap 'read -r -p "Press Return to close."' EXIT
PYTHON=""
for candidate in /opt/homebrew/bin/python3 /usr/local/bin/python3 /usr/bin/python3; do
  if [ -x "$candidate" ] && "$candidate" -c 'import sys; sys.exit(sys.version_info < (3,10))' 2>/dev/null; then
    PYTHON="$candidate"
    break
  fi
done
if [ -z "$PYTHON" ]; then
  echo 'Builder requires Python 3.10 or newer.'
  exit 1
fi
if ! command -v node >/dev/null; then
  echo 'Builder requires Node.js to verify the Web UI.'
  exit 1
fi
"$PYTHON" -B tools/build_installer.py
