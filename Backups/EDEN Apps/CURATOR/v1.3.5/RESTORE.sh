#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="${1:-CURATOR_v1.3.5_FULL_BACKUP.tar.xz}"
cat \
 "$HERE/full-backup.part00.b64" \
 "$HERE/full-backup.part01.b64" \
 "$HERE/full-backup.part02.b64" \
 "$HERE/full-backup.part03-04.b64" \
 "$HERE/full-backup.part05-06.b64" \
 "$HERE/full-backup.part07-08.b64" \
 "$HERE/full-backup.part09.b64" \
 | tr -d '\r\n\t ' | base64 --decode > "$OUT"
EXPECTED="496dc92e30087c56cf652c2c67a829aae8149b7c317290cb09c56d3188859edd"
ACTUAL="$(shasum -a 256 "$OUT" | awk '{print $1}')"
[[ "$ACTUAL" == "$EXPECTED" ]] || { echo "SHA-256 mismatch: $ACTUAL"; exit 1; }
xz -t "$OUT"
echo "Backup restored and verified: $OUT"
echo "Extract with: tar -xJf '$OUT'"
