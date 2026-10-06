#!/bin/bash
# SWAYcore development-factory library. SOURCE it. bash 3.2 compatible (macOS /bin/bash). Never executed directly.
# Evidence rules: PASS needs exit 0 + a log. A missing prerequisite is FAIL or UNKNOWN, never PASS. Nothing here deletes user data.

fx_init() { # $1 = directory of the calling .command
  local start; start="$(cd "$1" && pwd -P)"; FX_ROOT=""
  local d="$start"; while [ "$d" != "/" ]; do [ -f "$d/SWAYcore.root" ] && FX_ROOT="$d" && break; d="$(dirname "$d")"; done
  [ -n "$FX_ROOT" ] || { echo "FAIL: cannot locate SWAYcore root (no SWAYcore.root marker above $start)"; exit 2; }
  FX_VERSION="$(cat "$FX_ROOT/VERSION")"; FX_STAMP="$(date +%Y%m%d-%H%M%S)"; FX_BUILD="$FX_ROOT/Build"
  FX_LOGS="$FX_BUILD/logs/$FX_STAMP"; FX_REPORT="$FX_BUILD/report"; FX_OUT="$FX_BUILD/Output"; FX_RECOVERY="$FX_BUILD/RecoveryArchive"
  mkdir -p "$FX_LOGS" "$FX_REPORT" "$FX_OUT" "$FX_RECOVERY"
  FX_GATES="$FX_REPORT/gates-$FX_STAMP.tsv"; : > "$FX_GATES"; FX_FAILS=0; FX_UNKNOWNS=0
  export FX_ROOT FX_LOGS FX_REPORT FX_BUILD
  # shellcheck source=/dev/null
  . "$FX_ROOT/Scripts/devicesupport_guard.sh"
  echo "SWAYcore factory $FX_VERSION  root=$FX_ROOT  logs=$FX_LOGS"
}
have() { command -v "$1" >/dev/null 2>&1; }
is_mac() { [ "$(uname -s)" = Darwin ]; }

# ---- gates ----------------------------------------------------------------
fx_record() { printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$FX_GATES"; printf '  [%-7s] %s  (%s)\n' "$2" "$1" "$3"
  [ "$2" = FAIL ] && FX_FAILS=$((FX_FAILS+1)); [ "$2" = UNKNOWN ] && FX_UNKNOWNS=$((FX_UNKNOWNS+1)); return 0; }
fx_gate() { # name cmd...   evidence = exit code + log path. Failure is recorded and the run CONTINUES (caller decides).
  local name="$1"; shift; local log="$FX_LOGS/$(echo "$name" | tr -c 'A-Za-z0-9\n' '_').log"
  echo "> $name"; ( set -o pipefail; "$@" ) > "$log" 2>&1; local rc=$?
  if [ $rc -eq 0 ]; then fx_record "$name" PASS "exit 0; log=$log"; else fx_record "$name" FAIL "exit $rc; log=$log"; tail -n 20 "$log" | sed 's/^/      | /'; fi
  return $rc; }
fx_unknown() { fx_record "$1" UNKNOWN "$2"; }
fx_need() { fx_gate "$@" || { fx_finish "STOPPED: prerequisite gate failed: $1"; exit 1; }; }   # hard prerequisite only
fx_skip_nonmac() { is_mac || { fx_unknown "$1" "host is $(uname -s), not macOS; cannot execute here"; return 1; }; }

# ---- idempotent dependency helpers ----------------------------------------------------
need_brew() { have brew && return 0; for p in /opt/homebrew/bin/brew /usr/local/bin/brew; do [ -x "$p" ] && eval "$($p shellenv)" && return 0; done
  echo "Homebrew missing. Install from https://brew.sh then re-run."; return 1; }
ensure_formula() { need_brew || return 1; if brew list --formula "$1" >/dev/null 2>&1; then echo "formula $1: present (not touched)"; else echo "formula $1: installing"; brew install "$1"; fi; }
ensure_cask()    { need_brew || return 1; if brew list --cask "$1" >/dev/null 2>&1; then echo "cask $1: present (not touched)"; else echo "cask $1: installing"; brew install --cask "$1"; fi; }

# ---- preflight ----------------------------------------------------------------
pf_host() { is_mac || { echo "Not macOS ($(uname -s))"; return 1; }
  echo "macOS $(sw_vers -productVersion) build $(sw_vers -buildVersion), arch $(uname -m)"; have git && git --version || { echo "git missing"; return 1; }; }
pf_disk() { require_free_gb "$FX_ROOT" "${1:-10}" "${2:-build}"; }
pf_xcode() {
  local p; p="$(xcode-select -p 2>&1)" || { echo "xcode-select unset. Install full Xcode, open once, then: sudo xcode-select -s /Applications/Xcode.app"; return 1; }
  echo "xcode-select: $p"; case "$p" in */CommandLineTools) echo "Only Command Line Tools selected; full Xcode required."; return 1;; esac
  xcodebuild -version || { echo "xcodebuild unusable (license? sudo xcodebuild -license accept)"; return 1; }
  swift --version 2>&1 | head -2; for t in xcodebuild swift simctl; do xcrun --find "$t" >/dev/null 2>&1 || { echo "xcrun cannot find $t"; return 1; }; done
  echo "SDKs:"; xcodebuild -showsdks | grep -E 'iOS|iphone|macOS' | head -12
  xcodebuild -showsdks | grep -q -- '-sdk iphoneos' || { echo "No iphoneos SDK (Xcode > Settings > Components)."; return 1; }
  xcodebuild -showsdks | grep -q -- '-sdk iphonesimulator' || echo "NOTE: no iphonesimulator SDK; simulator gates will be UNKNOWN."
  return 0; }
pf_xcodegen() { have xcodegen || ensure_formula xcodegen; xcodegen --version; }
FX_BLENDER=""
find_blender() { if have blender; then FX_BLENDER="$(command -v blender)"; return 0; fi
  for p in /Applications/Blender.app/Contents/MacOS/Blender "$HOME/Applications/Blender.app/Contents/MacOS/Blender"; do [ -x "$p" ] && FX_BLENDER="$p" && return 0; done; return 1; }
pf_blender() { find_blender || { ensure_cask blender || return 1; find_blender || { echo "Blender not found after install"; return 1; }; }
  local v; v="$("$FX_BLENDER" --version 2>/dev/null | head -1)"; echo "Blender: $v ($FX_BLENDER)"
  case "$v" in *"Blender 5.2"*) echo "matches target 5.2.x LTS";; *"Blender 5."*|*"Blender 4."*) echo "NOTE: target is 5.2.2 LTS; this version is outside the tested line (scripts feature-detect API drift).";; *) echo "Unrecognised Blender version"; return 1;; esac; }

# ---- recovery archive ----------------------------------------------------------------------
fx_preserve_recovery() { # Preserve bytes only; never infer verification or LKG.
  local label="$1"; shift; local dst="$FX_RECOVERY/$label/$FX_STAMP"; local any=0 p
  for p in "$@"; do [ -e "$p" ] && { mkdir -p "$dst"; cp -R "$p" "$dst/" && any=1; }; done
  [ $any -eq 1 ] && echo "Recovery bytes preserved (UNVERIFIED): $dst" || echo "Recovery: nothing to preserve for $label"; return 0; }

# ---- project generation / build ----------------------------------------------------
app_dir() { echo "$FX_ROOT/App"; }
gen_project() { ( cd "$(app_dir)" && xcodegen generate --spec project.yml && shasum -a 256 project.yml SWAY.xcodeproj/project.pbxproj > "$FX_REPORT/project-generation.sha256" ); }
swift_test() { swift test --package-path "$FX_ROOT/Packages/$1"; }
sim_name() { xcrun simctl list devices available 2>/dev/null | grep -E 'iPhone' | head -1 | sed -E 's/^ *(.*) \([0-9A-F-]{36}\).*/\1/'; }
build_sim() { ( cd "$(app_dir)" && xcodebuild -project SWAY.xcodeproj -scheme SWAY -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath "$FX_BUILD/DerivedData/sim" CODE_SIGNING_ALLOWED=NO build ); }
test_sim() { ( cd "$(app_dir)" && xcodebuild -project SWAY.xcodeproj -scheme SWAY -configuration Debug -destination "platform=iOS Simulator,name=$1" -derivedDataPath "$FX_BUILD/DerivedData/sim-test" CODE_SIGNING_ALLOWED=NO test ); }
build_device() { # signing preserved from project.yml (team/automatic); NO overrides, no secrets
  ( cd "$(app_dir)" && xcodebuild -project SWAY.xcodeproj -scheme SWAY -configuration Debug -destination 'generic/platform=iOS' -derivedDataPath "$FX_BUILD/DerivedData/device" -allowProvisioningUpdates build ); }
package_zip() { # label app-path
  local d="$FX_OUT/$1"; mkdir -p "$d"; [ -d "$2" ] || { echo "app not found: $2"; return 1; }
  local z="$d/SWAY-$1-$FX_VERSION-$FX_STAMP.zip"; ditto -c -k --keepParent "$2" "$z" && echo "$z" > "$d/.latest"; }
verify_zip() { local z; z="$(cat "$FX_OUT/$1/.latest" 2>/dev/null)"; [ -f "$z" ] || { echo "no package"; return 1; }
  unzip -tq "$z" || return 1; unzip -l "$z" | grep -q 'Info.plist' || { echo "no Info.plist in package"; return 1; }
  unzip -l "$z" | grep -q 'Characters/' || echo "NOTE: no Characters/ resources in package"; shasum -a 256 "$z" | tee "$z.sha256"; }

# ---- python suites (portable) ----------------------------------------------------------
py_suite() { ( cd "$FX_ROOT" && python3 -W ignore -m unittest "$@" ); }

# ---- report ---------------------------------------------------------------------------
fx_finish() {
  local md="$FX_REPORT/BUILD_REPORT-$FX_STAMP.md"
  { echo "# SWAYcore factory report - $FX_STAMP"; echo; echo "Version $FX_VERSION. ${1:-done}"; echo; echo "Host: $(uname -s) $(uname -m)"; echo
    echo "| Gate | Status | Evidence |"; echo "|---|---|---|"
    while IFS="$(printf '\t')" read -r n s e; do echo "| $n | $s | $e |"; done < "$FX_GATES"
    echo; echo "PASS = exit 0 with a log. UNKNOWN != PASS. Built != tested != verified != released. Simulator != physical device."; } > "$md"
  cp "$md" "$FX_REPORT/LATEST_BUILD_REPORT.md"
  local f u; f="$(grep -c "	FAIL	" "$FX_GATES")"; u="$(grep -c "	UNKNOWN	" "$FX_GATES")"
  echo ""; echo "======== RESULT: $( [ "$f" -eq 0 ] && echo 'NO FAILED GATES' || echo "$f FAILED GATE(S)" ) | $u UNKNOWN ========"; echo "$1"; echo "Report: $md"; }
fx_exit() { [ -t 0 ] && [ -z "$FX_NONINTERACTIVE" ] && read -r -p "Press Return to close..." _; [ "$FX_FAILS" -eq 0 ]; }

# Alpha has two identities; Beta keeps the existing extensible six-character path.
asset_pairs() {
  case "${1:-alpha}" in
    alpha) printf '%s\n' 'lucia:Lucia' 'yourdancer:YourDancer';;
    all) printf '%s\n' 'lucia:Lucia' 'nandi:Nandi' 'thabo:Thabo' 'zuri:Zuri' 'kyle:Kyle' 'yourdancer:YourDancer';;
    *) echo 'Unknown asset release scope' >&2; return 2;;
  esac
}
