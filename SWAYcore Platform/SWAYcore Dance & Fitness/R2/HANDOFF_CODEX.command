#!/bin/zsh
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
HANDOFF="$ROOT/CODEX_HANDOFF_SWAYCORE_DANCE_FITNESS_R2.md"
[[ -s "$HANDOFF" ]] || { echo "Missing handoff: $HANDOFF"; exit 1; }
command -v codex >/dev/null || { echo "Codex CLI not found."; exit 1; }
PROMPT="$(cat "$HANDOFF")"
exec codex "$PROMPT"
