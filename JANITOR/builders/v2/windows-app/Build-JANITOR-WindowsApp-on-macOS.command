#!/bin/bash
# JANITOR Windows app - ONE-CLICK BUILDER for macOS (or Linux). Produces JANITOR.exe (.NET Framework 4.5, AnyCPU: Windows 7 SP1 to 11).
# Needs the .NET SDK. If it is missing this script offers a per-user install into ~/.dotnet (no sudo) and asks first.
# Tweak: SDK_CHANNEL below, or the project in ./src (JANITOR.csproj, Program.cs; janitor.ps1 is embedded and does the real work).
set -u

# ---- TWEAKABLE ----
SDK_CHANNEL="8.0"
# -------------------

HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/src"
OUT="${JANITOR_OUT:-$HERE/output}"
say()   { printf '%s\n' "$*"; }
pause() { if [ -t 0 ] && [ -z "${JANITOR_NOPAUSE:-}" ]; then read -r -p "Press Return to close..." _; fi; }
fail()  { say ""; say "FAILED: $*"; pause; exit 1; }

[ -f "$SRC/JANITOR.csproj" ] || fail "src/JANITOR.csproj not found next to this script."
DOTNET=""
if command -v dotnet >/dev/null 2>&1; then DOTNET="$(command -v dotnet)"
elif [ -x "$HOME/.dotnet/dotnet" ]; then DOTNET="$HOME/.dotnet/dotnet"; fi

if [ -z "$DOTNET" ]; then
  say "The .NET SDK was not found."
  say "I can install it for your user only (about 200 MB, into ~/.dotnet, no admin rights, nothing system-wide)."
  say "It is downloaded from https://dot.net/v1/dotnet-install.sh (Microsoft)."
  if [ -t 0 ]; then read -r -p "Install it now? [y/N] " A; else A="n"; fi
  case "$A" in y|Y) ;; *) fail "Cancelled. Nothing was changed. Install the .NET SDK yourself, then run this again." ;; esac
  T="$(mktemp -d "${TMPDIR:-/tmp}/janitor-dotnet.XXXXXX")" || fail "no temp folder"
  curl -fsSL -o "$T/dotnet-install.sh" https://dot.net/v1/dotnet-install.sh || fail "download failed (no network?)"
  bash "$T/dotnet-install.sh" --channel "$SDK_CHANNEL" --install-dir "$HOME/.dotnet" --no-path || fail "SDK install failed"
  rm -rf "$T"
  DOTNET="$HOME/.dotnet/dotnet"
fi

VER=$(sed -n 's:.*<Version>\(.*\)</Version>.*:\1:p' "$SRC/JANITOR.csproj" | head -1)
say "Building JANITOR Windows app $VER with $("$DOTNET" --version)"
rm -rf "$OUT"; mkdir -p "$OUT/app"
"$DOTNET" build "$SRC/JANITOR.csproj" -c Release -o "$OUT/app" -p:EnableWindowsTargeting=true > "$OUT/build.log" 2>&1 || { tail -n 25 "$OUT/build.log"; fail "build failed - full log: $OUT/build.log"; }
[ -f "$OUT/app/JANITOR.exe" ] || fail "JANITOR.exe was not produced - see $OUT/build.log"
cat > "$OUT/app/README.txt" <<EOF
JANITOR Windows app $VER (English)
Runs on Windows 7 SP1 to Windows 11. Needs .NET Framework 4.5 or newer (built into Windows 8.1+; Windows 7 may need it installed)
and Windows PowerShell 3.0+ (Windows 7 SP1: install the free WMF 5.1). Double-click JANITOR.exe. Nothing is installed.
STATUS: BUILT, NOT RUN ON WINDOWS.
EOF
( cd "$OUT" && rm -f "JANITOR-WindowsApp-$VER.zip" && (cd app && zip -qr "../JANITOR-WindowsApp-$VER.zip" JANITOR.exe README.txt) && shasum -a 256 "JANITOR-WindowsApp-$VER.zip" app/JANITOR.exe > SHA256SUMS.txt )
cat > "$OUT/BUILD_RECORD.txt" <<EOF
JANITOR Windows app $VER - net45, AnyCPU. Built on $(uname -s) $(uname -m), $(date '+%Y-%m-%d %H:%M'), SDK $("$DOTNET" --version).
STATE: BUILT, UNTESTED. Never run on Windows. Not signed (Windows SmartScreen will warn on first run).
EOF
say ""; say "DONE."; say "  $OUT/JANITOR-WindowsApp-$VER.zip"
pause
