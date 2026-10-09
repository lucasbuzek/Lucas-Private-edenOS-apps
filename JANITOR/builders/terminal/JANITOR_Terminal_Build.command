#!/bin/bash
# JANITOR — version identity comes directly from the packaged core.
set -u
ROOT="$(cd "$(dirname "$0")" && pwd -P)"
CORE="$ROOT/core/janitor-macos.sh"
if [ ! -f "$CORE" ]; then
  printf 'JANITOR core is missing:\n%s\n' "$CORE"
  read -r -p 'Press Return to close…' _
  exit 2
fi
case "${1:-}" in --version|-v|version|--help|-h) exec /bin/bash "$CORE" "$@";; esac
# Present this Terminal window as JANITOR rather than a generic shell session.
if [ -t 1 ]; then
printf '\033]0;JANITOR — Maintenance & Recovery\007'
printf '\033[?1049h\033[?25h'
cleanup(){ printf '\033[?25h\033[?1049l'; }
trap cleanup EXIT HUP INT TERM
fi
/bin/bash "$CORE" "$@"
exit $?
