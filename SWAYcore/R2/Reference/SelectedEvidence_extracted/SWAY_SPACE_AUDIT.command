#!/bin/bash
set -euo pipefail

echo "SWAY SPACE AUDIT — read-only"
echo "Free space: $(df -h / | awk 'NR==2 {print $4}')"
echo
printf '%-10s %s\n' 'SIZE' 'PATH'
for p in \
 "$HOME/Library/Developer/Xcode/DerivedData" \
 "$HOME/Library/Developer/Xcode/Archives" \
 "$HOME/Library/Developer/Xcode/iOS DeviceSupport" \
 "$HOME/Library/Developer/CoreSimulator" \
 "$HOME/Library/Caches/com.apple.dt.Xcode" \
 "$HOME/Library/Caches/org.swift.swiftpm" \
 "$HOME/Downloads" \
 "$HOME/Desktop"; do
  [[ -e "$p" ]] && du -sh "$p" 2>/dev/null || true
done | sort -hr

echo
echo "Largest top-level items in ~/Library (read-only):"
du -sh "$HOME/Library"/* 2>/dev/null | sort -hr | head -20 || true

echo
echo "No files were changed."
