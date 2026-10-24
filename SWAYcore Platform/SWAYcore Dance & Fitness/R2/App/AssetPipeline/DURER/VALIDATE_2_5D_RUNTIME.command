#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
echo "DÜRER protected 2.5D fallback validation"
test -f "$ROOT/SWAY/Avatar/SWAYSkeletal2DAvatarView.swift"
test -f "$ROOT/AssetPipeline/DURER/DURER_2_5D_ASSET_CONTRACT.json"
python3 - "$ROOT" <<'PY'
from pathlib import Path
import sys
r=Path(sys.argv[1]); s=(r/'SWAY/Views/StickFigureView.swift').read_text()
block=s[s.index('struct SwayHumanFigureView: View {'):]
block=block[:block.index('\n}')+2]
assert 'SWAYSkeletal2DAvatarView' in block
assert 'StickFigureView(' not in block
print('PASS shared runtime wrapper -> protected 2.5D fallback')
PY
echo "PASS DÜRER fallback contract present"
