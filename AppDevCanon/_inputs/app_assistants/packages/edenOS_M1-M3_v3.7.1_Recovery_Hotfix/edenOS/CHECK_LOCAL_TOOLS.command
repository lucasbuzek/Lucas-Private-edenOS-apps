#!/bin/zsh
set -u
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"
export HOMEBREW_NO_AUTO_UPDATE=1
echo "EDEN local dependency check — no network refresh requested"
for x in qemu-system-aarch64 curl jq xz zstd hdiutil shasum; do
 printf "%-24s " "$x"
 if command -v "$x" >/dev/null 2>&1; then echo "PASS  $(command -v "$x")"; else echo "MISSING"; fi
done
command -v qemu-system-aarch64 >/dev/null 2>&1 && qemu-system-aarch64 --version | head -1
