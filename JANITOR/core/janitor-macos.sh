#!/bin/bash
set -u
VERSION="0.11.1-terminal-safety-candidate"
ACTION_STARTED=$SECONDS
ACTION_COUNT=0
QROOT="${JANITOR_QUARANTINE:-$HOME/Downloads/#Review&Delete/JANITOR}"
REPORT_DIR="${JANITOR_REPORT_DIR:-$HOME/Library/Logs/JANITOR}"
CACHE_DIR="${JANITOR_CACHE_DIR:-$HOME/Library/Caches/JANITOR}"
# Initialization happens after the path guards are defined, immediately before dispatch.
# LCAS colors: disabled automatically when output is not a terminal.
if [ -t 1 ]; then
  RESET=$'\033[0m'; BOLD=$'\033[1m'; DIM=$'\033[2m'
  CYAN=$'\033[36m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; BLUE=$'\033[34m'
else RESET=''; BOLD=''; DIM=''; CYAN=''; GREEN=''; YELLOW=''; RED=''; BLUE=''; fi
now(){ date '+%Y-%m-%d_%H-%M-%S'; }
human_kb(){ awk -v k="$1" 'BEGIN{if(k>=1048576)printf "%.1f GB",k/1048576;else if(k>=1024)printf "%.1f MB",k/1024;else printf "%d KB",k}'; }
size_kb(){
 local v timeout="${2:-${JANITOR_SIZE_TIMEOUT:-12}}"
 v=$(bounded_size_kb "$1" "$timeout")
 case "$v" in
  TIMEOUT|PROVIDER) echo "PARTIAL / REVIEW — size unavailable: $1" >&2; printf '0\n'; return 1;;
  *[!0-9]*|'') printf '0\n'; return 1;;
  *) printf '%s\n' "$v";;
 esac
}
file_bytes(){ if [ "$(uname -s)" = Darwin ]; then stat -f '%z' "$1" 2>/dev/null; else stat -c '%s' "$1" 2>/dev/null; fi; }
line(){ printf '%*s\n' 68 '' | tr ' ' '─'; }
pause(){ printf '\nPress Return to continue...'; read -r _ || true; }
header(){ [ ! -t 1 ] || printf '\033[H\033[2J'; printf '%s%sJANITOR%s — Justified Analysis, Navigation, Inspection,\n' "$BOLD" "$CYAN" "$RESET"; echo "Tidying, Optimization & Recovery"; printf '%sv%s • standalone • deterministic • zero resident services%s\n' "$DIM" "$VERSION" "$RESET"; line; }
report_path(){ mktemp "$REPORT_DIR/JANITOR_$(now)_$1.XXXXXX"; }
scan_path(){ local label="$1" path="$2" kb; if ! local_scan_guard "$path" >/dev/null 2>&1; then kb='PROTECTED / skipped'; elif [ ! -e "$path" ]; then kb='not found'; else kb=$(bounded_size_kb "$path" "${JANITOR_SIZE_TIMEOUT:-12}"); case "$kb" in TIMEOUT|PROVIDER) kb='PARTIAL / REVIEW';; *) kb=$(human_kb "$kb");; esac; fi; printf '%-34s %12s  %s\n' "$label" "$kb" "$path"; }
roots(){
 # Terminal developer discovery uses Downloads only by default.
 # Documents/Desktop may be File Provider known folders even when their POSIX
 # presentation is not obviously inside CloudDocs; native JANITOR will resolve
 # NSFileProvider known-folder ownership. Custom local paths remain available
 # through explicit bounded scans.
 local p="$HOME/Downloads"
 [ -d "$p" ] && local_scan_guard "$p" >/dev/null 2>&1 && printf '%s\n' "$p"
}

project_kind(){
 local p="$1"
 case "$p" in
  */node_modules/*|*/Pods/*|*/vendor/*|*/.venv/*|*/venv/*) echo dependency; return;;
  */examples/*|*/example/*|*/Examples/*|*/samples/*|*/sample/*) echo example; return;;
  */libraries/*|*/GardenOSLib/*) echo library; return;;
 esac
 echo project
}
# Normalize common version/build/copy suffixes for family grouping. Conservative: report only.
family_name(){
 local n="$1"
 echo "$n" | sed -E \
  -e 's/[._ -]?[vV]?[0-9]+([._-][0-9]+){1,3}([._-]?(alpha|beta|rc|build)[._-]?[0-9]*)?$//' \
  -e 's/[._ -]+(build|BUILD|Build)[._ -]*[0-9._-]+$//' \
  -e 's/[._ -]+(final|FINAL|Final)([._ -]*(fixed|FIXED|Fixed))?$//' \
  -e 's/[._ -]+(copy|COPY|Copy)([._ -]*[0-9]+)?$//' \
  -e 's/[._ -]+$//'
}
marker_root(){
 local f="$1"
 case "$f" in
   */.git) dirname "$f";;
   *.xcodeproj) dirname "$f";;
   *) dirname "$f";;
 esac
}

developer_analyze(){
 header; echo "DEVELOPER ANALYZE — read-only"; line
 local r; r=$(report_path developer-analysis)
 {
  echo "JANITOR Developer Analysis — $(date)"; echo "Host: $(hostname)"; echo
  scan_path "Xcode DerivedData" "$HOME/Library/Developer/Xcode/DerivedData"
  scan_path "Xcode Archives" "$HOME/Library/Developer/Xcode/Archives"
  scan_path "Xcode iOS DeviceSupport" "$HOME/Library/Developer/Xcode/iOS DeviceSupport"
  scan_path "CoreSimulator devices" "$HOME/Library/Developer/CoreSimulator/Devices"
  scan_path "SwiftPM cache" "$HOME/Library/Caches/org.swift.swiftpm"
  scan_path "Homebrew cache — REVIEW" "$HOME/Library/Caches/Homebrew"
  scan_path "npm cache" "$HOME/.npm"
  scan_path "pnpm store" "$HOME/Library/pnpm/store"
  scan_path "Yarn cache" "$HOME/Library/Caches/Yarn"
  scan_path "pip cache" "$HOME/Library/Caches/pip"
  scan_path "Gradle cache" "$HOME/.gradle/caches"
  scan_path "Arduino cache" "$HOME/Library/Arduino15/cache"
  scan_path "Docker data" "$HOME/Library/Containers/com.docker.docker/Data"
 } | tee "$r"
 echo; echo "Report: $r"; pause
}

safe_clean_preview(){
 header; echo "SAFE DEVELOPER CLEAN — PREVIEW"; line
 echo "Only regenerable caches are eligible. Nothing is removed yet."; echo
 scan_path "Xcode DerivedData" "$HOME/Library/Developer/Xcode/DerivedData"
 scan_path "SwiftPM cache" "$HOME/Library/Caches/org.swift.swiftpm"
 scan_path "Homebrew cache — REVIEW" "$HOME/Library/Caches/Homebrew"
 scan_path "npm cache" "$HOME/.npm/_cacache"
 scan_path "pip cache" "$HOME/Library/Caches/pip"
 echo; echo "REVIEW ONLY: Homebrew cache (never included in automatic SAFE clean)."; echo "Excluded: Archives, simulators, DeviceSupport, source projects, Git repos,"; echo "EDEN LKG/state, user documents and ambiguous material."
 echo; read -r -p "Move eligible cache CONTENTS to JANITOR quarantine? [y/N] " ans
 case "$ans" in y|Y) safe_clean_execute;; *) echo "Cancelled."; pause;; esac
}
quarantine_item_verified(){
 local src="$1" session="$2" category="${3:-SAFE}" id dest
 action_budget || return 124
 mutation_guard "$src" || return 90
 local_scan_guard "$session" >/dev/null 2>&1 || return 90
 mkdir -p "$session/items" || return 3
 id=$(printf '%s' "$src" | shasum -a 256 | awk '{print substr($1,1,12)}')
 dest="$session/items/${id}--$(basename "$src")"
 [ ! -e "$dest" ] && [ ! -L "$dest" ] || return 4
 # Write the intended transfer before action. If interrupted, it is still reviewable.
 printf 'INTENT\t%s\t0\t%s\t%s\n' "$category" "$src" "$dest" >> "$session/MANIFEST.txt" || return 4
 if local_rename_verified "$src" "$dest"; then LOCAL_LAST_DEST="$dest"; return 0; fi
 echo "PARTIAL / REVIEW — transfer not verified: $src -> $dest" >&2
 return 6
}

new_quarantine_session(){
 local_scan_guard "$QROOT" >/dev/null 2>&1 || return 90
 (umask 077; mkdir -p "$QROOT" && mktemp -d "$QROOT/$(now)-$1.XXXXXX")
}

action_budget(){
 ACTION_COUNT=$((ACTION_COUNT+1))
 if [ "$ACTION_COUNT" -gt 1000 ] || [ $((SECONDS-ACTION_STARTED)) -ge "${JANITOR_ACTION_TOTAL_TIMEOUT:-30}" ]; then
  echo 'PARTIAL / REVIEW — action budget reached; remaining items are unchanged.' >&2; return 124
 fi
}

mutation_guard(){
 local src="$1" out err rc
 local_scan_guard "$src" >/dev/null 2>&1 || { echo "REFUSED: unknown/provider/protected source: $src" >&2; return 90; }
 if [ "${2:-}" != quarantine-session ]; then protected_path "$src" && { echo "PROTECTED: $src" >&2; return 3; }; fi
 [ ! -L "$src" ] || { echo 'REFUSED: symlink mutation requires native review.' >&2; return 90; }
 [ -e "$src" ] || return 2
 [ ! -d "$src" ] && return 0
 out=$(mktemp); err=$(mktemp)
 # Preflight only metadata; dataless and provider roots are pruned before descent.
 run_deadline "${JANITOR_MUTATION_PREFLIGHT_TIMEOUT:-5}" "$out" "$err" /usr/bin/find -P "$src" -xdev \
  \( -flags +dataless -o -name .git -o -name '*.photoslibrary' -o -name CloudStorage -o -name 'Mobile Documents' -o -name Dropbox -o -name 'Google Drive' -o -name GDrivA -o -name 'My Drive' -o -name 'OneDrive*' -o -name 'Creative Cloud Files*' \) -prune -print; rc=$?
 [ "$rc" -eq 0 ] && [ ! -s "$out" ]; rc=$?
 rm -f "$out" "$err"
 [ "$rc" -eq 0 ] || echo "REFUSED: boundary/Git/Photos or incomplete preflight: $src" >&2
 return "$rc"
}

local_rename_verified(){
 local src="$1" dest="$2" srcdev destdev before after out err rc
 [ -e "$src" ] && [ ! -L "$src" ] && [ ! -e "$dest" ] && [ ! -L "$dest" ] || return 2
 srcdev=$(/usr/bin/stat -f '%d' "$src") || return 2
 destdev=$(/usr/bin/stat -f '%d' "$(dirname "$dest")") || return 2
 [ "$srcdev" = "$destdev" ] || { echo 'DEFERRED: cross-filesystem transfer; no copy/remove fallback.' >&2; return 90; }
 before=$(/usr/bin/stat -f '%d:%i' "$src") || return 2
 out=$(mktemp); err=$(mktemp)
 run_deadline "${JANITOR_LOCAL_MOVE_TIMEOUT:-10}" "$out" "$err" /bin/mv -n "$src" "$dest"; rc=$?
 after=$(/usr/bin/stat -f '%d:%i' "$dest" 2>/dev/null || true)
 rm -f "$out" "$err"
 [ "$rc" -eq 0 ] && [ ! -e "$src" ] && [ "$before" = "$after" ]
}

delete_local_verified(){
 local src="$1" out err rc
 action_budget || return 124
 mutation_guard "$src" || return 90
 out=$(mktemp); err=$(mktemp)
 printf 'DELETE_INTENT\t%s\n' "$src" >> "$REPORT_DIR/actions.tsv" || return 2
 run_deadline "${JANITOR_DELETE_TIMEOUT:-10}" "$out" "$err" /bin/rm -rf -- "$src"; rc=$?
 [ "$rc" -eq 0 ] && [ ! -e "$src" ] && [ ! -L "$src" ]; rc=$?
 printf 'DELETE_RESULT\t%s\t%s\n' "$rc" "$src" >> "$REPORT_DIR/actions.tsv"
 rm -f "$out" "$err"; return "$rc"
}

delete_quarantine_session(){
 local q="$1" qr canonical out err rc
 [ ! -L "$q" ] || return 90
 qr=$(/bin/realpath -q "$QROOT") || return 90
 canonical=$(/bin/realpath -q "$q") || return 90
 [ "$(dirname "$canonical")" = "$qr" ] || { echo 'REFUSED: select one direct quarantine session.'; return 90; }
 mutation_guard "$q" quarantine-session || return 90
 out=$(mktemp); err=$(mktemp)
 printf 'SESSION_DELETE_INTENT\t%s\n' "$q" >> "$REPORT_DIR/actions.tsv" || return 2
 run_deadline "${JANITOR_DELETE_TIMEOUT:-10}" "$out" "$err" /bin/rm -rf -- "$q"; rc=$?
 [ "$rc" -eq 0 ] && [ ! -e "$q" ]; rc=$?
 printf 'SESSION_DELETE_RESULT\t%s\t%s\n' "$rc" "$q" >> "$REPORT_DIR/actions.tsv"
 rm -f "$out" "$err"; return "$rc"
}
safe_clean_execute(){
 ACTION_STARTED=$SECONDS; ACTION_COUNT=0
 local session moved=0 failed=0 src item
 if ! local_scan_guard "$QROOT" >/dev/null 2>&1; then echo 'Quarantine root is provider-managed; Terminal Safe Clean is deferred.'; pause; return; fi
 session=$(new_quarantine_session developer-safe-clean) || { echo 'Cannot create quarantine.'; pause; return; }
 mkdir -p "$session/items" || { echo 'Cannot create quarantine.'; pause; return; }
 cat > "$session/MANIFEST.txt" <<EOF
JANITOR quarantine session
Created: $(date)
Operation: developer-safe-clean
Nothing here is automatically purged.
EOF
 for src in "$HOME/Library/Developer/Xcode/DerivedData" "$HOME/Library/Caches/org.swift.swiftpm" "$HOME/.npm/_cacache" "$HOME/Library/Caches/pip"; do
  [ -d "$src" ] || continue
  local_scan_guard "$src" >/dev/null 2>&1 || { echo "Provider-managed cache skipped: $src"; continue; }
  for item in "$src"/* "$src"/.[!.]* "$src"/..?*; do
   [ $((SECONDS-ACTION_STARTED)) -lt "${JANITOR_ACTION_TOTAL_TIMEOUT:-30}" ] || { echo "PARTIAL — action budget reached."; break; }; [ -e "$item" ] || continue
   if quarantine_item_verified "$item" "$session" developer-safe; then
    printf 'MOVED\tSAFE\t0\t%s\t%s\n' "$item" "$LOCAL_LAST_DEST" >> "$session/MANIFEST.txt"; moved=$((moved+1))
   else
    printf 'FAILED\t%s\n' "$item" >> "$session/MANIFEST.txt"; failed=$((failed+1))
   fi
  done
 done
 echo; printf 'Verified quarantined: %d   Failed/review: %d\n' "$moved" "$failed"; echo "Quarantine: $session"; pause
}


project_walk(){
 local dir="$1" depth="$2" out="$3"
 safe_find "$dir" -maxdepth "$((depth+1))"   \( -type d \( -name node_modules -o -name Pods -o -name vendor -o -name .venv -o -name venv -o -name .build -o -name DerivedData -o -name JANITOR_Quarantine -o -name JANITOR_Consolidated \) -prune \) -o   \( -name .git -o -name '*.xcodeproj' -o -name Package.swift -o -name package.json -o -name pyproject.toml -o -name Cargo.toml -o -name platformio.ini -o -name '*.ino' \) -print >> "$out"
}
project_discovery(){
 header; echo "DEVELOPER — PROJECT IDENTITY / VERSION DISCOVERY"; line
 echo "Read-only • true shell-bounded depth 6 • provider-managed roots skipped."; echo
 local tmp="$CACHE_DIR/projects.$$.tsv" markers="$CACHE_DIR/project-markers.$$.txt" total=0 root
 : > "$tmp"; : > "$markers"
 while IFS= read -r root; do
  echo "→ Scanning $root (depth <= 6)…"
  : > "$markers"; _po="$CACHE_DIR/project-walk.$$.out"; _pe="$CACHE_DIR/project-walk.$$.err"; if run_deadline "${JANITOR_PROJECT_TIMEOUT:-45}" "$_po" "$_pe" project_walk "$root" 6 "$markers"; then :; else _prc=$?; [ "$_prc" -eq 124 ] && echo "  PARTIAL — project scan time budget reached."; fi; rm -f "$_po" "$_pe"
  while IFS= read -r f; do
   [ -n "$f" ] || continue
   pr=$(marker_root "$f"); kind=$(project_kind "$pr"); base=$(basename "$pr"); fam=$(family_name "$base"); marker=$(basename "$f")
   printf '%s	%s	%s	%s	%s
' "$kind" "$fam" "$base" "$pr" "$marker" >> "$tmp"; total=$((total+1))
  done < <(head -5000 "$markers")
  echo "  $total project markers classified."
 done < <(roots)
 local r projects libs examples deps; r=$(report_path project-discovery)
 awk -F '	' '!seen[$1 FS $4]++' "$tmp" > "$tmp.u"; mv "$tmp.u" "$tmp"
 projects=$(awk -F '	' '$1=="project"{n++} END{print n+0}' "$tmp"); libs=$(awk -F '	' '$1=="library"{n++} END{print n+0}' "$tmp"); examples=$(awk -F '	' '$1=="example"{n++} END{print n+0}' "$tmp"); deps=$(awk -F '	' '$1=="dependency"{n++} END{print n+0}' "$tmp")
 echo; line; echo SUMMARY; printf 'Project candidates: %d
Libraries: %d
Examples: %d
Dependencies: %d
' "$projects" "$libs" "$examples" "$deps"
 echo; echo 'PROJECT CANDIDATES'; awk -F '\t' '$1=="project"{print "  " $3 "  " $4}' "$tmp" | head -80
 { echo "JANITOR Project Discovery — $(date)"; echo 'kind|family|name|path|marker'; awk -F '\t' '{print $1 "|" $2 "|" $3 "|" $4 "|" $5}' "$tmp"; } > "$r"
 cp "$tmp" "$CACHE_DIR/last-project-discovery.tsv" 2>/dev/null || true; rm -f "$tmp" "$markers"
 echo; echo "Report: $r"; echo 'No consolidation performed.'; pause
}
large_dev(){
 header; echo "DEVELOPER — BUILD / DEPENDENCY DISCOVERY"; line
 echo "Read-only. Locating known heavy developer containers first, then measuring them."; echo
 local tmp="$CACHE_DIR/large.$$.txt" list="$CACHE_DIR/large.$$.paths" err="$CACHE_DIR/large.$$.err" measured="$CACHE_DIR/large.$$.measured" root n=0 root_index=0 started=$SECONDS total_limit="${JANITOR_LARGE_DEV_TOTAL_TIMEOUT:-60}" remain root_limit p kb partial=0
 : > "$tmp"; : > "$measured"
 while IFS= read -r root; do
   remain=$((total_limit-(SECONDS-started))); [ "$remain" -gt 0 ] || { partial=1; break; }
   root_index=$((root_index+1)); root_limit="${JANITOR_LARGE_DEV_ROOT_TIMEOUT:-20}"; [ "$remain" -lt "$root_limit" ] && root_limit="$remain"
   echo "→ Locating build/dependency roots in ${root}…"
   if ! run_deadline "$root_limit" "$list" "$err" safe_find "$root" -xdev -maxdepth 6 \( -type d -name '*.photoslibrary' -prune \) -o \( -type d \( -name node_modules -o -name DerivedData -o -name .build -o -name build -o -name dist -o -name Pods -o -name .gradle -o -name .venv -o -name venv \) -prune -print \); then partial=1; fi
   while IFS= read -r p; do [ -n "$p" ] && { printf '%s\n' "$p" >> "$tmp"; n=$((n+1)); }; done < "$list"
   printf '\r  %d candidates found.             \n' "$n"
   [ $((SECONDS-started)) -lt "$total_limit" ] || { partial=1; break; }
 done < <(roots)
 sort -u "$tmp" -o "$tmp"
 local total; total=$(wc -l < "$tmp" | tr -d ' '); echo; echo "Measuring $total candidate directories…"
 local i=0
 while IFS= read -r p; do
   [ -n "$p" ] || continue; remain=$((total_limit-(SECONDS-started))); [ "$remain" -gt 0 ] || { partial=1; break; }
   i=$((i+1)); printf '\r  [%d/%d] %s' "$i" "$total" "$(basename "$p")"
   root_limit="${JANITOR_LARGE_DEV_SIZE_TIMEOUT:-3}"; [ "$remain" -lt "$root_limit" ] && root_limit="$remain"
   kb=$(size_kb "$p" "$root_limit"); printf '%012d\t%s\n' "$kb" "$p" >> "$measured"
 done < "$tmp"
 printf '\r  [%d/%d] measurement complete.                              \n' "$i" "$total"; [ "$partial" -eq 0 ] || echo 'PARTIAL — Developer discovery time budget reached; completed results retained.'
 local r; r=$(report_path build-dependency-discovery)
 echo; line; echo "LARGEST BUILD / DEPENDENCY ROOTS"; line
 sort -rn "$measured" | head -100 | while IFS=$'\t' read -r kb p; do kb=$(printf "%s" "$kb" | sed "s/^0*//"); kb=${kb:-0}; printf '%12s  %s\n' "$(human_kb "$kb")" "$p"; done | tee "$r"
 cp "$measured" "$CACHE_DIR/last-large-dev.tsv" 2>/dev/null || true; rm -f "$tmp" "$list" "$err" "$measured"
 echo; echo "Report: $r"; echo "No files changed."; pause
}

compare_readiness(){
 header; echo "DEVELOPER — CONSOLIDATION READINESS"; line
 local idx="$CACHE_DIR/last-project-discovery.tsv"
 if [ ! -f "$idx" ]; then echo "No classified project index yet."; echo "Run option 3 first."; pause; return; fi
 echo "JANITOR will NOT consolidate yet. This gate identifies candidate families"; echo "and the evidence still required before a safe consolidation."; echo
 awk -F '\t' '$1=="project" && $2!=""{c[$2]++; paths[$2]=paths[$2] "\n      " $4} END{for(f in c) if(c[f]>1) print "FAMILY: " f " (" c[f] " candidates)" paths[f] "\n"}' "$idx" | head -160
 echo "Required before consolidation:"; echo "  • file/tree comparison"; echo "  • unique-material inventory"; echo "  • Git/manifest/version provenance"; echo "  • authority/LKG determination"; echo "  • conflict report"; echo "  • previewed consolidation plan"; echo "  • quarantine/rollback plan"; echo "  • post-action verification"
 echo; echo "Status: CONSOLIDATION DISABLED BY SAFETY GATE"; pause
}

quarantine_manifests(){
 local maxdepth="${1:-4}" limit="${2:-8}" out="$CACHE_DIR/manifests.$$.out" err="$CACHE_DIR/manifests.$$.err" rc
 [ -d "$QROOT" ] || return 0
 if ! local_scan_guard "$QROOT" >/dev/null 2>&1; then echo 'Quarantine root is provider-managed; Terminal listing skipped.'; return 90; fi
 if run_deadline "$limit" "$out" "$err" safe_find "$QROOT" -xdev -maxdepth "$maxdepth" -name MANIFEST.txt -print; then rc=0; else rc=$?; fi
 head -50 "$out"; [ "$rc" -eq 0 ] || echo 'PARTIAL — quarantine listing timed out.'
 rm -f "$out" "$err"; return 0
}
quarantine_review(){
 header; echo "QUARANTINE"; line
 if [ ! -d "$QROOT" ]; then echo "No JANITOR quarantine exists yet."; pause; return; fi
 if ! local_scan_guard "$QROOT" >/dev/null 2>&1; then echo 'Provider-managed quarantine is not traversed by Terminal JANITOR.'; pause; return; fi
 local entry kb start=$SECONDS limit="${JANITOR_QUARANTINE_REVIEW_TIMEOUT:-15}"
 for entry in "$QROOT"/*; do
  [ -e "$entry" ] || continue
  [ $((SECONDS-start)) -lt "$limit" ] || { echo 'PARTIAL — quarantine review time budget reached.'; break; }
  if ! local_scan_guard "$entry" >/dev/null 2>&1; then printf 'PROVIDER SKIP  %s\n' "$entry"; continue; fi
  kb=$(size_kb "$entry" 3); printf '%12s  %s\n' "$(human_kb "$kb")" "$entry"
 done
 echo; echo "Location: $QROOT"; echo "JANITOR never automatically purges quarantine."; pause
}
system_info(){ header; echo "JANITOR STATUS"; line; sw_vers 2>/dev/null || uname -a; echo; df -h "$HOME" | tail -1; echo; echo "AI: OFF / optional integration only"; echo "Resident JANITOR services: none by design"; echo "Persistent scan indexes: $CACHE_DIR (data only, no process)"; pause; }

normalize_name(){ printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[._ -]*(copy|final|old|new|backup|bak|v?[0-9]+([._-][0-9]+)*|build[._ -]*[0-9]+)[._ -]*/ /g; s/[^a-z0-9]+/ /g; s/^ +| +$//g'; }
scan_summary(){
 local p="$1" kb out err files='PARTIAL' folders='PARTIAL'
 [ -d "$p" ] || { echo "Folder not found: $p"; return 1; }
 local_scan_guard "$p" || { printf '%-12s %s\n' State 'PROTECTED / scan skipped'; return 0; }
 printf '%-12s %s\n' Path "$p"
 if ! local_scan_guard "$p" >/dev/null 2>&1; then printf '%-12s %s\n' State 'PROTECTED / recursive scan skipped'; return 0; fi
 kb=$(bounded_size_kb "$p" "${JANITOR_SUMMARY_TIMEOUT:-15}"); [ "$kb" = TIMEOUT ] && printf '%-12s %s\n' Size 'PARTIAL / timed out' || printf '%-12s %s\n' Size "$(human_kb "$kb")"
 out="$CACHE_DIR/summary-files.$$.out"; err="$CACHE_DIR/summary-files.$$.err"
 if run_deadline "${JANITOR_SUMMARY_TIMEOUT:-15}" "$out" "$err" safe_find "$p" -xdev \( -type d -name '*.photoslibrary' -prune \) -o \( -type f -print \); then files=$(wc -l < "$out" | tr -d ' '); fi
 rm -f "$out" "$err"; out="$CACHE_DIR/summary-dirs.$$.out"; err="$CACHE_DIR/summary-dirs.$$.err"
 if run_deadline "${JANITOR_SUMMARY_TIMEOUT:-15}" "$out" "$err" safe_find "$p" -xdev \( -type d -name '*.photoslibrary' -prune \) -o \( -type d -print \); then folders=$(wc -l < "$out" | tr -d ' '); fi
 rm -f "$out" "$err"; printf '%-12s %s\n' Files "$files"; printf '%-12s %s\n' Folders "$folders"
}
choose_scope(){ printf 'Folder to scan: ' >&2; IFS= read -r p || return 1; p="${p#\'}"; p="${p%\'}"; p="${p#\"}"; p="${p%\"}"; local_scan_guard "$p" || return 1; [ -d "$p" ] || { echo "Folder not found: $p" >&2; return 1; }; printf '%s\n' "$p"; }
quick_safe_candidates(){
  # Only known regenerable/disposable material. Never Downloads/media/documents.
  local p
  for p in \
    "$HOME/Library/Developer/Xcode/DerivedData" \
    "$HOME/Library/Caches/org.swift.swiftpm" \
    "$HOME/.npm/_cacache" \
    "$HOME/Library/Caches/pip" \
    "$HOME/.gradle/caches"; do
    [ -d "$p" ] && printf '%s\n' "$p"
  done
}
quick_safe_inventory(){
  local out="$1" timeout="${2:-${JANITOR_SIZE_TIMEOUT:-12}}" total=0 p kb started=$SECONDS remain budget limit="${JANITOR_SAFE_TOTAL_TIMEOUT:-12}"
  : > "$out"
  while IFS= read -r p; do
    remain=$((limit-(SECONDS-started))); [ "$remain" -gt 0 ] || { echo "PARTIAL — cache inventory time budget reached." >&2; break; }
    [ -d "$p" ] || continue
    local_scan_guard "$p" >/dev/null 2>&1 || continue
    budget="$timeout"; [ "$budget" -le "$remain" ] || budget="$remain"; kb=$(size_kb "$p" "$budget") || continue; total=$((total+kb)); printf '%s\t%s\n' "$kb" "$p" >> "$out"
  done < <(quick_safe_candidates)
  printf '%s\n' "$total"
}
quick_delete_safe(){
 ACTION_STARTED=$SECONDS; ACTION_COUNT=0
  local inv="$1" before="$2" deleted=0 failed=0 p kb item after reclaimed
  printf '\n%s%sDELETE SAFE ITEMS%s\n' "$BOLD" "$GREEN" "$RESET"; line
  printf 'Known regenerable cache material: %s\n\n' "$(human_kb "$before")"
  while IFS=$'\t' read -r kb p; do [ -n "$p" ] && printf '  %-12s %s\n' "$(human_kb "$kb")" "$p"; done < "$inv"
  printf '\n%sDownloads, movies, documents, projects and UNKNOWN items are excluded.%s\n' "$YELLOW" "$RESET"
  read -r -p "Permanently delete these SAFE cache contents? [y/N] " ans
  case "$ans" in y|Y) ACTION_STARTED=$SECONDS; ACTION_COUNT=0;; *) printf '%sCancelled.%s\n' "$YELLOW" "$RESET"; return 0;; esac
 while IFS=$'\t' read -r kb p; do
    [ -d "$p" ] || continue
    local_scan_guard "$p" >/dev/null 2>&1 || { failed=$((failed+1)); continue; }
    # Delete contents, never the known cache container itself. Hidden items included.
    while IFS= read -r -d '' item; do
      [ $((SECONDS-ACTION_STARTED)) -lt "${JANITOR_ACTION_TOTAL_TIMEOUT:-30}" ] || { echo "PARTIAL — action budget reached."; break; }
      if delete_local_verified "$item"; then deleted=$((deleted+1)); else failed=$((failed+1)); fi
    done < <(safe_find "$p" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)
  done < "$inv"
  after=$(quick_safe_inventory "$inv.after")
  reclaimed=$((before-after)); [ "$reclaimed" -lt 0 ] && reclaimed=0
  echo; echo 'Deletion results verified per entry; allocated-size estimates are not guaranteed reclaimed bytes.'
  printf 'Top-level entries deleted: %d\nFailed: %d\nAllocated-size difference (estimate): %s\nRemaining eligible caches: %s\n' "$deleted" "$failed" "$(human_kb "$reclaimed")" "$(human_kb "$after")"
  rm -f "$inv.after"
}
quick_scan(){
 header; printf '%s%sLCAS • QUICK SCAN%s\n' "$BOLD" "$CYAN" "$RESET"; echo "Fast bounded scan • classify → review → act"; line
 local start=$SECONDS r inv safe_kb large_count=0 dlout="$CACHE_DIR/quick-downloads.$$.out" dlerr="$CACHE_DIR/quick-downloads.$$.err" dlrc=0; r=$(report_path quick-scan); inv="$CACHE_DIR/quick-safe.$$.tsv"; : > "$dlout"; : > "$dlerr"
 printf '%s[1/4]%s Scanning common locations…\n' "$CYAN" "$RESET"
 local label p kb remain budget quick_limit="${JANITOR_QUICK_TOTAL_TIMEOUT:-20}" partial=0
 while IFS='|' read -r label p; do
  [ -n "$p" ] || continue
  remain=$((quick_limit-(SECONDS-start))); [ "$remain" -gt 0 ] || { partial=1; echo "PARTIAL — Quick Scan time budget reached."; break; }
  budget="${JANITOR_QUICK_SIZE_TIMEOUT:-2}"; [ "$budget" -le "$remain" ] || budget="$remain"
  if [ ! -e "$p" ]; then printf '%s·%s %-24s %12s\n' "$DIM" "$RESET" "$label" 'not found'
  elif ! local_scan_guard "$p" >/dev/null 2>&1; then printf '%s·%s %-24s %12s\n' "$YELLOW" "$RESET" "$label" 'protected/provider skipped'
  else kb=$(bounded_size_kb "$p" "$budget"); case "$kb" in TIMEOUT) partial=1; printf '%s!%s %-24s %12s\n' "$YELLOW" "$RESET" "$label" 'partial / timeout';; PROVIDER) printf '%s·%s %-24s %12s\n' "$YELLOW" "$RESET" "$label" 'provider skipped';; *) printf '%s✓%s %-24s %12s\n' "$GREEN" "$RESET" "$label" "$(human_kb "$kb")";; esac; fi
 done <<EOF
Downloads|$HOME/Downloads
Trash|$HOME/.Trash
User caches|$HOME/Library/Caches
User logs|$HOME/Library/Logs
Xcode DerivedData|$HOME/Library/Developer/Xcode/DerivedData
SwiftPM cache|$HOME/Library/Caches/org.swift.swiftpm
Homebrew cache|$HOME/Library/Caches/Homebrew
npm cache|$HOME/.npm/_cacache
Gradle cache|$HOME/.gradle/caches
EOF
 printf '\n%s[2/4]%s Classifying known safe cache material…\n' "$CYAN" "$RESET"
 remain=$((quick_limit-(SECONDS-start))); [ "$remain" -ge 0 ] || remain=0
 safe_kb=$(JANITOR_SAFE_TOTAL_TIMEOUT="$remain" quick_safe_inventory "$inv" "${JANITOR_QUICK_SIZE_TIMEOUT:-2}")
 printf '%s[3/4]%s Checking large Downloads as REVIEW only…\n' "$CYAN" "$RESET"
 remain=$((quick_limit-(SECONDS-start))); budget="${JANITOR_QUICK_DOWNLOADS_TIMEOUT:-3}"; [ "$budget" -le "$remain" ] || budget="$remain"
 if [ "$remain" -le 0 ]; then dlrc=124; partial=1
 elif [ -d "$HOME/Downloads" ] && local_scan_guard "$HOME/Downloads" >/dev/null 2>&1; then
  if run_deadline "$budget" "$dlout" "$dlerr" safe_find "$HOME/Downloads" -xdev -maxdepth 3 \( -type d -name '*.photoslibrary' -prune \) -o \( -type f -size +500M -print \); then dlrc=0; else dlrc=$?; fi
  large_count=$(wc -l < "$dlout" | tr -d ' ')
 else dlrc=90; fi
 printf '%s[4/4]%s Building result…\n\n' "$CYAN" "$RESET"
 line
 printf '%s%sSAFE TO DELETE%s %30s\n' "$BOLD" "$GREEN" "$RESET" "$(human_kb "$safe_kb")"
 while IFS=$'\t' read -r kb p; do [ -n "$p" ] && printf '  %-12s %s\n' "$(human_kb "$kb")" "$(basename "$p")"; done < "$inv"
 printf '\n%s%sREVIEW%s %38s\n' "$BOLD" "$YELLOW" "$RESET" "$large_count large Downloads"
 printf '  %sLarge media/files are findings only; never SAFE junk.%s\n' "$DIM" "$RESET"
 printf '\nCompleted in %ss\n' "$((SECONDS-start))"
 {
   echo "JANITOR Quick Scan — $(date)"; echo "SAFE_KB=$safe_kb"; echo "PARTIAL=$partial"; echo "REVIEW_LARGE_DOWNLOADS=$large_count"; [ "$dlrc" -eq 124 ] && echo 'DOWNLOADS_SCAN=PARTIAL_TIMEOUT'; [ "$dlrc" -eq 90 ] && echo 'DOWNLOADS_SCAN=PROVIDER_SKIPPED'; echo; echo "SAFE CANDIDATES"; cat "$inv"; echo; echo "LARGE DOWNLOADS — REVIEW ONLY"; cat "$dlout"
 } > "$r"
 [ "$partial" -eq 0 ] && [ "$dlrc" -eq 0 ] || echo "PARTIAL / REVIEW — skipped or timed-out work is not an empty scan."
 echo "Report: $r"
 while true; do
   echo; printf '%s[D]%s Delete Safe Items   %s[V]%s View Details   %s[F]%s Full Scan   %s[Q]%s Main Menu\n' "$GREEN" "$RESET" "$CYAN" "$RESET" "$CYAN" "$RESET" "$DIM" "$RESET"
   read -r -p "Choose: " action || return 0
   case "$action" in
     d|D) if [ "$safe_kb" -gt 0 ]; then quick_delete_safe "$inv" "$safe_kb"; else echo "No SAFE cache material found."; fi; pause; rm -f "$inv" "$dlout" "$dlerr"; return;;
     v|V) echo; line; echo "SAFE CANDIDATES"; cat "$inv"; echo; echo "LARGE DOWNLOADS — REVIEW ONLY"; cat "$dlout"; [ "$dlrc" -eq 90 ] && echo 'Downloads provider-managed — scan skipped.'; [ "$dlrc" -eq 124 ] && echo 'PARTIAL — Downloads time budget reached.';;
     f|F) rm -f "$inv" "$dlout" "$dlerr"; full_scan; return;;
     q|Q|'') rm -f "$inv" "$dlout" "$dlerr"; return;;
   esac
 done
}

# Fast development-workspace hygiene. Filename/build-number evidence selects only
# intermediate iterations for recoverable quarantine; first + latest are preserved.
dev_build_inventory(){
 local out="$1" root item base stem build family kb gitflag root_index=0 started=$SECONDS total_limit="${JANITOR_DEV_BUILD_TOTAL_TIMEOUT:-35}" remain root_limit list err marker
 : > "$out"
 while IFS= read -r root; do
  [ -d "$root" ] || continue
  root_index=$((root_index+1)); remain=$((total_limit-(SECONDS-started))); [ "$remain" -gt 0 ] || { echo 'PARTIAL — Developer Quick time budget reached.' >&2; break; }
  root_limit="${JANITOR_DEV_INVENTORY_TIMEOUT:-12}"; [ "$remain" -lt "$root_limit" ] && root_limit="$remain"
  list="$CACHE_DIR/dev-inventory.$$.${root_index}.nul"; err="$CACHE_DIR/dev-inventory.$$.${root_index}.err"
  if ! run_deadline "$root_limit" "$list" "$err" safe_find "$root" -xdev -maxdepth 2 -mindepth 1 \( -type d -name '*.photoslibrary' -prune \) -o \( \( -type f -name '*.zip' -o -type d \) -print0 \) 2>/dev/null; then echo 'PARTIAL — Developer build inventory time budget reached.' >&2; fi
  while IFS= read -r -d '' item; do
   remain=$((total_limit-(SECONDS-started))); [ "$remain" -gt 0 ] || { echo 'PARTIAL — Developer Quick time budget reached.' >&2; break; }
   base=$(basename "$item"); stem=${base%.zip}
   build=$(printf '%s' "$stem" | sed -nE 's/.*[Bb][Uu][Ii][Ll][Dd][ _.-]*([0-9]+).*/\1/p')
   [ -n "$build" ] || continue
   family=$(printf '%s' "$stem" | sed -E 's/[ _.-]*[Bb][Uu][Ii][Ll][Dd][ _.-]*[0-9]+.*$//; s/[ _.-]+$//')
   [ -n "$family" ] || continue
   gitflag=0
   if [ -d "$item" ]; then
    marker="$CACHE_DIR/dev-git.$$.${root_index}.txt"
    root_limit=2; [ "$remain" -lt "$root_limit" ] && root_limit="$remain"
    if run_deadline "$root_limit" "$marker" "$err" safe_find "$item" -xdev -name .git -print -quit; then [ -s "$marker" ] && gitflag=1; else gitflag=1; echo 'PARTIAL — Git marker check unavailable; candidate protected.' >&2; fi
    rm -f "$marker"
   fi
   root_limit="${JANITOR_DEV_SIZE_TIMEOUT:-3}"; [ "$remain" -lt "$root_limit" ] && root_limit="$remain"
   kb=$(size_kb "$item" "$root_limit")
   printf '%s\t%09d\t%s\t%s\t%s\t%s\n' "$family" "$build" "$kb" "$gitflag" "$base" "$item" >> "$out"
  done < "$list"
  rm -f "$list" "$err"
  [ $((SECONDS-started)) -lt "$total_limit" ] || break
 done < <(roots)
 sort -t $'\t' -k1,1 -k2,2n -k6,6 -u "$out" -o "$out"
}
dev_quarantine_intermediate(){
 ACTION_STARTED=$SECONDS; ACTION_COUNT=0
 local inv="$1" plan="$2" session moved=0 failed=0 family build kb gitflag base src
 session=$(new_quarantine_session developer-build-family) || return 90
 mkdir -p "$session/items" || return 2
 printf 'JANITOR developer build-family quarantine\nCreated: %s\nRule: keep first/latest; recheck boundaries and Git; same-filesystem rename only.\n' "$(date)" > "$session/MANIFEST.txt"
 while IFS=$'\t' read -r family build kb gitflag base src; do
  [ -n "$src" ] || continue
  [ $((SECONDS-ACTION_STARTED)) -lt "${JANITOR_ACTION_TOTAL_TIMEOUT:-30}" ] || { echo "PARTIAL — action budget reached."; failed=$((failed+1)); break; }
  if [ "$gitflag" != 0 ]; then failed=$((failed+1)); continue; fi
  if quarantine_item_verified "$src" "$session" "$family"; then
   printf 'MOVED\t%s\t%s\t%s\t%s\n' "$family" "$build" "$src" "$LOCAL_LAST_DEST" >> "$session/MANIFEST.txt"
   moved=$((moved+1)); echo "Verified quarantined: $src"
  else
   printf 'FAILED\t%s\n' "$src" >> "$session/MANIFEST.txt"; failed=$((failed+1))
  fi
 done < "$plan"
 printf 'Verified quarantined: %d  Failed/review: %d\nManifest: %s\n' "$moved" "$failed" "$session/MANIFEST.txt"
 [ "$failed" -eq 0 ]
}
developer_quick_scan(){
 header; printf '%s%sLCAS • DEVELOPER QUICK SCAN%s\n' "$BOLD" "$CYAN" "$RESET"; echo 'Xcode/cache waste + build-family hygiene'; line
 local inv="$CACHE_DIR/dev-quick.$$.tsv" plan="$CACHE_DIR/dev-plan.$$.tsv" families="$CACHE_DIR/dev-families.$$.txt"
 local cacheinv="$CACHE_DIR/dev-safe.$$.tsv" safe_kb family min max count qcount=0 qkb=0
 dev_build_inventory "$inv"; : > "$plan"; : > "$families"
 safe_kb=$(quick_safe_inventory "$cacheinv")
 # One row per family/build artifact. Keep every artifact belonging to min/max build.
 cut -f1 "$inv" | sort -u | while IFS= read -r family; do
  [ -n "$family" ] || continue
  min=$(awk -F '\t' -v f="$family" '$1==f{print $2}' "$inv" | sort -n | head -1)
  max=$(awk -F '\t' -v f="$family" '$1==f{print $2}' "$inv" | sort -n | tail -1)
  count=$(awk -F '\t' -v f="$family" '{if($1==f) seen[$2]=1} END{for(x in seen)n++;print n+0}' "$inv")
  printf '%s\t%s\t%s\t%s\n' "$family" "$min" "$max" "$count" >> "$families"
  awk -F '\t' -v f="$family" -v lo="$min" -v hi="$max" '$1==f && ($2+0)>(lo+0) && ($2+0)<(hi+0) && $4==0' "$inv" >> "$plan"
 done
 qcount=$(wc -l < "$plan" | tr -d ' '); qkb=$(awk -F '\t' '{s+=$3}END{print s+0}' "$plan")
 # Never act on a build artifact whose BUILD number appears in an active xcodebuild/swift command.
 local active_builds="$CACHE_DIR/active-builds.$$.txt"
 ps -axo command= 2>/dev/null | grep -Ei 'xcodebuild|swift(build|c)?|SourceKit' | sed -nE 's/.*[Bb][Uu][Ii][Ll][Dd][ _.-]*([0-9]+).*/\1/p' | sort -u > "$active_builds" || true
 if [ -s "$active_builds" ]; then
  awk -F '\t' 'NR==FNR{a[$1]=1;next}!a[$2+0]' "$active_builds" "$plan" > "$plan.safe" && mv "$plan.safe" "$plan"
  qcount=$(wc -l < "$plan" | tr -d ' '); qkb=$(awk -F '\t' '{s+=$3}END{print s+0}' "$plan")
 fi
 printf '%sSAFE DEVELOPMENT CACHE%s       %s\n' "$GREEN" "$RESET" "$(human_kb "$safe_kb")"
 while IFS=$'\t' read -r kb p; do [ -n "$p" ] && printf '  %-12s %s\n' "$(human_kb "$kb")" "$(basename "$p")"; done < "$cacheinv"
 printf '  %sHomebrew cache: REVIEW ONLY%s\n\n' "$YELLOW" "$RESET"
 printf '%sBUILD FAMILIES%s\n' "$CYAN" "$RESET"
 while IFS=$'\t' read -r family min max count; do
  [ -n "$family" ] || continue
  printf '  %-28s keep BUILD%d + BUILD%d  (%d builds)\n' "$family" "$((10#$min))" "$((10#$max))" "$count" 2>/dev/null || printf '  %-28s keep %s + %s\n' "$family" "$min" "$max"
 done < "$families"
 printf '\n%sQUARANTINE CANDIDATES%s          %d items / %s\n' "$YELLOW" "$RESET" "$qcount" "$(human_kb "$qkb")"
 echo 'Build numbers are filename evidence only: REVIEW these candidates before action.'; echo 'First + latest stay in place. Git working copies are excluded.'
 while true; do
  echo; printf '%s[V]%s Review list   %s[Q]%s Quarantine   %s[D]%s Delete intermediates   %s[C]%s Clean SAFE dev cache   %s[B]%s Back\n' "$CYAN" "$RESET" "$YELLOW" "$RESET" "$RED" "$RESET" "$GREEN" "$RESET" "$DIM" "$RESET"
  read -r -p 'Choose: ' a || return 0
  case "$a" in
   v|V) echo; line; echo 'KEEP — FIRST + LATEST'; while IFS=$'\t' read -r family min max count; do printf '  %s: BUILD%d and BUILD%d\n' "$family" "$((10#$min))" "$((10#$max))" 2>/dev/null || true; done < "$families"; echo; echo 'QUARANTINE — INTERMEDIATE ITEMS'; while IFS=$'\t' read -r family build kb gitflag base src; do printf '  %-10s %-10s %s\n' "BUILD$((10#$build))" "$(human_kb "$kb")" "$src" 2>/dev/null || printf '  %s\n' "$src"; done < "$plan";;
   q|Q) if [ "$qcount" -eq 0 ]; then echo 'No confident intermediate builds found.'; else echo; echo 'The exact items shown by [V] will be MOVED to recoverable quarantine.'; read -r -p 'Proceed? [y/N] ' ok; case "$ok" in y|Y) dev_quarantine_intermediate "$inv" "$plan";; *) echo Cancelled.;; esac; fi; pause; break;;
   d|D) if [ "$qcount" -eq 0 ]; then echo 'No confident intermediate builds found.'; else dev_delete_intermediate "$plan" "$qcount"; fi; pause; break;;
   c|C) if [ "$safe_kb" -gt 0 ]; then echo 'SAFE developer cache excludes Homebrew.'; quick_delete_safe "$cacheinv" "$safe_kb"; else echo 'No SAFE developer cache found.'; fi; pause; break;;
   b|B|'') break;;
  esac
 done
 rm -f "$inv" "$plan" "$families" "$cacheinv" "${active_builds:-}"
}

custom_scan(){
 header; echo 'CHOOSE WHAT TO SCAN — bounded / read-only'; line
 local p out err rc f bytes; p=$(choose_scope)||{ pause; return; }
 local_scan_guard "$p" || { pause; return; }
 scan_summary "$p"; echo; echo 'Largest files >100 MB:'
 out="$CACHE_DIR/custom.$$.out"; err="$CACHE_DIR/custom.$$.err"
 run_deadline "${JANITOR_TARGET_SCAN_TIMEOUT:-45}" "$out" "$err" safe_find "$p" -xdev \( -type d -name '*.photoslibrary' -prune \) -o \( -type f -size +100M -print \); rc=$?
 [ "$rc" -eq 0 ] || echo 'PARTIAL / REVIEW — time budget or filesystem error.'
 while IFS= read -r f; do [ -f "$f" ] || continue; bytes=$(file_bytes "$f" || echo 0); printf '%020d\t%s\n' "$bytes" "$f"; done < <(head -1000 "$out") | sort -rn | head -50 | awk -F '\t' '{printf "%.1f GB  %s\n",$1/1073741824,$2}'
 rm -f "$out" "$err"; pause
}
large_files(){
 header; echo 'LARGE FILES — bounded / read-only'; line
 local p mb out err rc f bytes
 p=$(choose_scope)||{ pause; return; }; printf 'Minimum MB [500]: '; read -r mb; mb=${mb:-500}; case "$mb" in *[!0-9]*) echo 'Invalid number.'; pause; return;; esac
 if ! local_scan_guard "$p"; then echo 'Protected/provider path: JANITOR will not recursively walk it.'; pause; return; fi
 out="$CACHE_DIR/large-files.$$.out"; err="$CACHE_DIR/large-files.$$.err"
 run_deadline "${JANITOR_TARGET_SCAN_TIMEOUT:-45}" "$out" "$err" safe_find "$p" -xdev \( -type d -name '*.photoslibrary' -prune \) -o \( -type f -size +"${mb}"M -print \); rc=$?
 [ "$rc" -eq 0 ] || echo 'PARTIAL — scan reached its time budget; completed findings follow.'
 while IFS= read -r f; do [ -f "$f" ] || continue; bytes=$(file_bytes "$f" || echo 0); awk -v b="$bytes" -v f="$f" 'BEGIN{printf "%.1f GB  %s\n",b/1073741824,f}'; done < <(head -1000 "$out") | sort -rn | head -200
 rm -f "$out" "$err"; pause
}
exact_duplicates_path(){ ( local p="$1" tmp f sz h hk; local_scan_guard "$p" >/dev/null 2>&1 || return 90; [ -d "$p" ]||return 2; tmp=$(mktemp -d "${TMPDIR:-/tmp}/janitor.XXXXXX")||return 3; trap 'rm -rf -- "$tmp"' EXIT; trap 'exit 124' TERM HUP INT; safe_find "$p" -xdev \( -type d -name '*.photoslibrary' -prune \) -o \( -type f -size +0 -print0 \) >"$tmp/list"; rc=$?; [ "$rc" -eq 0 ] || { echo "PARTIAL / REVIEW — duplicate inventory incomplete." >&2; return "$rc"; }; while IFS= read -r -d '' f; do sz=$(stat -f '%z' "$f" 2>/dev/null)||continue; printf '%s\n' "$sz" >>"$tmp/all-sizes"; sk="$sz"; printf '%s\0' "$f" >>"$tmp/size-$sk"; done <"$tmp/list"; [ -f "$tmp/all-sizes" ]||{ rm -r "$tmp"; return 0; }; sort "$tmp/all-sizes"|uniq -d >"$tmp/duplicate-sizes"; while IFS= read -r sz; do sk="$sz"; while IFS= read -r -d '' f; do local_scan_guard "$f" >/dev/null 2>&1 || continue; before=$(/usr/bin/stat -f "%d:%i:%z:%m:%c" "$f") || continue; h=$(shasum -a 256 "$f" 2>/dev/null) || continue; after=$(/usr/bin/stat -f "%d:%i:%z:%m:%c" "$f") || continue; [ "$before" = "$after" ] || { echo "PARTIAL / REVIEW — changing file skipped: $f" >&2; continue; }; h=${h%% *}; [ -n "$h" ]||continue; printf '%s\n' "$h" >>"$tmp/all-hashes"; hk="$h"; printf '%s\0' "$f" >>"$tmp/hash-$hk"; done <"$tmp/size-$sk"; done <"$tmp/duplicate-sizes"; [ -f "$tmp/all-hashes" ]||{ rm -r "$tmp"; return 0; }; sort "$tmp/all-hashes"|uniq -d|while IFS= read -r h; do hk="$h"; echo "SHA-256 $h"; while IFS= read -r -d '' f; do printf '    %s\n' "$f"; done <"$tmp/hash-$hk"; echo; done; rm -r "$tmp";) }
exact_duplicates(){
 header; echo 'EXACT DUPLICATES — LOCAL FILES ONLY'; line
 local p out err rc; p=$(choose_scope)||{ pause; return; }; local_scan_guard "$p" || { pause; return; }
 case "$p" in *.photoslibrary|*.photoslibrary/*) echo 'Photos libraries are protected.'; pause; return;; esac
 out=$(mktemp); err=$(mktemp)
 echo "Bounded hash scan: ${JANITOR_DUPLICATE_TIMEOUT:-60}s. Provider-managed paths are rejected."
 if run_deadline "${JANITOR_DUPLICATE_TIMEOUT:-60}" "$out" "$err" exact_duplicates_path "$p"; then rc=0; else rc=$?; fi
 cat "$out"; [ "$rc" -eq 0 ] || echo 'PARTIAL — time budget reached; no files changed.'; [ -s "$err" ] && cat "$err"
 rm -f "$out" "$err"; pause
}
similar_names(){
 header; echo 'SIMILAR NAMES — LOCAL / BOUNDED'; echo 'Similarity never authorizes deletion'; line
 local p tmp out err rc; p=$(choose_scope)||{ pause; return; }; local_scan_guard "$p" || { pause; return; }
 tmp=$(mktemp); out=$(mktemp); err=$(mktemp)
 if run_deadline "${JANITOR_SIMILAR_TIMEOUT:-45}" "$out" "$err" safe_find "$p" -xdev \( -type d -name '*.photoslibrary' -prune \) -o \( -type f -print \); then rc=0; else rc=$?; fi
 while IFS= read -r f; do n=$(normalize_name "$(basename "$f")"); [ ${#n} -ge 4 ] && printf '%s|%s
' "$n" "$f"; done < <(head -1000 "$out") | sort > "$tmp"
 awk -F'|' '{c[$1]++;p[$1]=p[$1]"\n    "$2}END{for(n in c)if(c[n]>1)print "POSSIBLE FAMILY: " n " (" c[n] ")" p[n] "\n"}' "$tmp" | head -400
 [ "$rc" -eq 0 ] || echo 'PARTIAL / REVIEW — time budget or filesystem error.'; rm -f "$tmp" "$out" "$err"; pause
}
media_inventory(){
 header; echo 'PHOTOS & VIDEOS — bounded filesystem inventory'; echo 'Photos libraries are protected and pruned from filesystem recursion.'; line
 local p out err rc f bytes
 p=$(choose_scope)||{ pause; return; }
 if ! local_scan_guard "$p"; then echo 'Protected/provider path: use Cloud Media Storage instead of recursive inventory.'; pause; return; fi
 out="$CACHE_DIR/media.$$.out"; err="$CACHE_DIR/media.$$.err"
 run_deadline "${JANITOR_TARGET_SCAN_TIMEOUT:-45}" "$out" "$err" safe_find "$p" -xdev \( -type d -name '*.photoslibrary' -prune \) -o \( -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.heic' -o -iname '*.tif' -o -iname '*.tiff' -o -iname '*.raw' -o -iname '*.dng' -o -iname '*.mov' -o -iname '*.mp4' -o -iname '*.m4v' -o -iname '*.avi' -o -iname '*.mkv' \) -print \); rc=$?
 [ "$rc" -eq 0 ] || echo 'PARTIAL — inventory reached its time budget; completed findings follow.'
 while IFS= read -r f; do [ -f "$f" ] || continue; bytes=$(file_bytes "$f" || echo 0); printf '%020d\t%s\n' "$bytes" "$f"; done < <(head -1000 "$out") | sort -rn | head -100 | while IFS=$'\t' read -r bytes f; do awk -v b="$bytes" -v f="$f" 'BEGIN{printf "%.1f MB  %s\n",b/1048576,f}'; done
 rm -f "$out" "$err"; pause
}
apps_inventory(){
 header; echo 'APPLICATIONS — read-only, bounded inventory'; line
 local root out="$CACHE_DIR/apps.$$.out" err="$CACHE_DIR/apps.$$.err" rc
 for root in /Applications "$HOME/Applications"; do
  [ -d "$root" ] || continue
  if [ "$root" != /Applications ]; then local_scan_guard "$root" || { echo "Skipped protected/provider path: $root"; continue; }; fi
  if run_deadline "${JANITOR_APP_SCAN_TIMEOUT:-10}" "$out" "$err" safe_find "$root" -xdev -maxdepth 5 \( -type d -name '*.photoslibrary' -prune \) -o \( -type d -name '*.app' -prune -print \); then rc=0; else rc=$?; fi
  cat "$out" | head -200
  [ "$rc" -eq 0 ] || echo "PARTIAL — application scan time budget reached: $root"
 done
 rm -f "$out" "$err"; pause
}
protected_path(){ local p="$1"; case "$p" in /|/System|/System/*|/Library|/Library/*|/Applications|/Applications/*|"$HOME"|"$HOME/Downloads"|"$HOME/Documents"|"$HOME/Desktop"|"$HOME/Pictures"|"$HOME/Movies"|"$QROOT"|"$QROOT"/*|"$REPORT_DIR"|"$REPORT_DIR"/*|"$CACHE_DIR"|"$CACHE_DIR"/*|*.photoslibrary|*.photoslibrary/*) return 0;; esac; return 1; }
quarantine_path(){
 ACTION_STARTED=$SECONDS; ACTION_COUNT=0
 local src="$1" session parent base
 mutation_guard "$src" || return $?
 parent=$(/bin/realpath -q "$(dirname "$src")") || return 2
 src="$parent/$(basename "$src")"
 session=$(new_quarantine_session manual) || return 90
 mkdir -p "$session/items" || return 4
 printf 'JANITOR quarantine manifest\nCreated: %s\n' "$(date)" > "$session/MANIFEST.txt" || return 4
 if quarantine_item_verified "$src" "$session" MANUAL; then
  printf 'MOVED\tMANUAL\t0\t%s\t%s\n' "$src" "$LOCAL_LAST_DEST" >> "$session/MANIFEST.txt" || return 5
  echo "Verified recoverable move: $LOCAL_LAST_DEST"
 else
  printf 'FAILED\t%s\n' "$src" >> "$session/MANIFEST.txt"
  echo 'QUARANTINE NOT VERIFIED — inspect INTENT record and both locations.' >&2; return 5
 fi
}
quarantine_manual(){ header; echo 'QUARANTINE ONE EXPLICIT PATH'; line; printf 'Exact path: '; read -r src; [ -n "$src" ]||{ pause; return; }; protected_path "$src"&&{ echo 'PROTECTED'; pause; return; }; read -r -p "Move '$src' to JANITOR quarantine? [y/N] " a || return 0; case "$a" in y|Y) quarantine_path "$src";;*) echo Cancelled;;esac; pause; }
restore_entry(){
 local m="$1" orig="$2" q="$3" session qc
 session=$(/bin/realpath -q "$(dirname "$m")") || return 3
 case "$orig$q" in *$'\n'*|*$'\r'*|*$'\t'*|*'/../'*|*/..) echo 'REFUSED: unsafe manifest path.'; return 3;; esac
 case "$q" in "$session"/items/*) ;; *) echo 'REFUSED: item outside manifest session.'; return 3;; esac
 if [ ! -e "$q" ] && [ ! -L "$q" ]; then echo "Missing/already removed: $q"; return 10; fi
 [ ! -L "$q" ] || { echo 'REFUSED: symlink quarantine item.'; return 3; }
 qc=$(/bin/realpath -q "$q") || return 3
 case "$qc" in "$session"/items/*) ;; *) echo 'REFUSED: redirected quarantine item.'; return 3;; esac
 local_scan_guard "$q" >/dev/null 2>&1 && local_scan_guard "$orig" >/dev/null 2>&1 || { echo 'REFUSED: unknown/provider/protected restore path.'; return 90; }
 protected_path "$orig" && { echo 'REFUSED: protected restore destination.'; return 3; }
 if [ -e "$orig" ] || [ -L "$orig" ]; then echo "Restore blocked; destination exists: $orig"; return 10; fi
 [ -d "$(dirname "$orig")" ] || { echo 'REVIEW: original parent missing; recreate it before restoring.'; return 3; }
 if local_rename_verified "$q" "$orig"; then
  printf 'RESTORED\t%s\t%s\n' "$orig" "$q" >> "$m"
  echo "Restored: $orig"; return 0
 fi
 echo 'PARTIAL / REVIEW — restore not verified.'; return 6
}
recover_manifest(){
 ACTION_STARTED=$SECONDS; ACTION_COUNT=0
 local m="$1" orig q restored=0 skipped=0 failed=0 rc state family build extra canonical qr
 case "$m" in *'/../'*|*/..|*$'\n'*|*$'\t'*) echo 'REFUSED: unsafe manifest.'; return 3;; esac
 [ -f "$m" ] && [ ! -L "$m" ] || return 2
 canonical=$(/bin/realpath -q "$m") || return 3
 qr=$(/bin/realpath -q "$QROOT") || return 3
 case "$canonical" in "$qr"/*/MANIFEST.txt) ;; *) echo 'REFUSED: manifest outside JANITOR quarantine.'; return 3;; esac
 local_scan_guard "$m" >/dev/null 2>&1 || return 90
 # Copy records first; RESTORED audit append must not extend the input stream.
 local records; records=$(mktemp) || return 3
 if grep -q $'^MOVED\t\|^INTENT\t' "$m"; then
  awk -F '\t' '($1=="MOVED" || $1=="INTENT") && !seen[$4 FS $5]++ {print}' "$m" > "$records"
 else
  orig=$(sed -n 's/^Original: //p' "$m" | head -1)
  q=$(sed -n 's/^Quarantined: //p' "$m" | head -1)
  [ -n "$orig" ] && [ -n "$q" ] || { rm -f "$records"; return 3; }
  printf 'MOVED\tMANUAL\t0\t%s\t%s\n' "$orig" "$q" > "$records"
 fi
 while IFS=$'\t' read -r state family build orig q extra; do
  action_budget || { failed=$((failed+1)); break; }; restore_entry "$m" "$orig" "$q"; rc=$?
  case "$rc" in 0) restored=$((restored+1));; 10) skipped=$((skipped+1));; *) failed=$((failed+1));; esac
 done < "$records"
 rm -f "$records"
 printf 'Restore complete. Restored: %d  Skipped: %d  Failed/review: %d\n' "$restored" "$skipped" "$failed"
 [ "$failed" -eq 0 ]
}
recover_menu(){
 header; echo 'QUARANTINE / RECOVER'; line
 if [ ! -d "$QROOT" ]; then echo 'No local JANITOR quarantine manifests found.'; pause; return; fi
 if ! local_scan_guard "$QROOT" >/dev/null 2>&1; then echo 'Provider-managed quarantine is never traversed or mutated by Terminal JANITOR.'; pause; return; fi
 echo 'LOCAL JANITOR QUARANTINE'; quarantine_manifests 4 8
 echo; echo '[R] Restore manifest   [D] Delete quarantine session   [B] Back'
 read -r -p 'Choose: ' a || return 0
 case "$a" in
  r|R) printf 'Manifest path: '; read -r m; [ -n "$m" ] || return; echo "Restore uses this manifest and refuses existing/protected destinations: $m"; read -r -p 'Restore these recorded items? [y/N] ' ok; case "$ok" in y|Y) recover_manifest "$m";; *) echo Cancelled.;; esac;;
  d|D) printf 'Quarantine session folder: '; read -r q; case "$q" in "$QROOT"/*) [ -d "$q" ] || { echo 'Not found.'; pause; return; }; if ! local_scan_guard "$q"; then echo 'REFUSED: provider/protected path.'; else read -r -p 'Type DELETE to permanently delete this quarantine session: ' ok; [ "$ok" = DELETE ] && delete_quarantine_session "$q" && echo 'Deleted quarantine session.' || echo 'Cancelled / failed.'; fi;; *) echo 'REFUSED: outside JANITOR quarantine.';; esac;;
 esac
 pause
}

storage_overview(){
 header; echo 'STORAGE OVERVIEW — bounded / read-only'; line; df -h "$HOME"; echo
 local p kb
 echo 'Common local roots (each size has a time budget):'
 for p in "$HOME/Downloads" "$HOME/Documents" "$HOME/Desktop" "$HOME/Pictures" "$HOME/Movies"; do
  [ -d "$p" ] || continue
  if ! local_scan_guard "$p" >/dev/null 2>&1; then printf '%-14s %s\n' "$(basename "$p")" 'PROTECTED / provider skipped'; continue; fi
  kb=$(bounded_size_kb "$p" "${JANITOR_SUMMARY_TIMEOUT:-15}"); [ "$kb" = TIMEOUT ] && printf '%-14s %s\n' "$(basename "$p")" 'PARTIAL / timed out' || printf '%-14s %s\n' "$(basename "$p")" "$(human_kb "$kb")"
 done
 echo; echo 'Use Cloud Storage for provider-managed roots and Media → Photos for Photos libraries.'; pause
}
downloads_analyze(){
 header; echo "DOWNLOADS — bounded / read-only"; line
 local p="$HOME/Downloads" out err rc; [ -d "$p" ] || { echo "Downloads unavailable."; pause; return; }
 local_scan_guard "$p" || { pause; return; }
 out="$CACHE_DIR/downloads.$$.out"; err="$CACHE_DIR/downloads.$$.err"
 run_deadline "${JANITOR_TARGET_SCAN_TIMEOUT:-45}" "$out" "$err" safe_find "$p" -xdev -maxdepth 6 \( -type d -name '*.photoslibrary' -prune \) -o \( -type f \( -iname '*.dmg' -o -iname '*.pkg' -o -iname '*.zip' -o -iname '*.tar' -o -iname '*.gz' -o -iname '*.7z' -o -iname '*.download' -o -iname '*.part' -o -iname '*.crdownload' -o -size +500M \) -print \); rc=$?
 [ "$rc" -eq 0 ] || echo 'PARTIAL / REVIEW — time budget or filesystem error.'
 echo 'Installers / archives:'; grep -Ei '\.(dmg|pkg|zip|tar|gz|7z)$' "$out" | head -200 || true
 echo; echo 'Partial / failed downloads:'; grep -Ei '\.(download|part|crdownload)$' "$out" | head -200 || true
 echo; echo 'Large Downloads (>500 MB):'; while IFS= read -r f; do [ -f "$f" ] && [ "$(file_bytes "$f" || echo 0)" -gt 524288000 ] && echo "$f"; done < <(head -1000 "$out") | head -100
 rm -f "$out" "$err"; pause
}
privacy_analyze(){ header; echo "PRIVACY RESIDUE — read-only"; echo "Nothing is preselected or deleted."; line; for p in "$HOME/Library/Safari/History.db" "$HOME/Library/Safari/Downloads.plist" "$HOME/Library/Caches/com.apple.Safari" "$HOME/Library/Application Support/Google/Chrome/Default/History" "$HOME/Library/Application Support/Firefox/Profiles"; do [ -e "$p" ] && printf '%12s  %s\n' "$(human_kb "$(size_kb "$p")")" "$p"; done; echo "Browser/recent history is personal data: review only."; pause; }
broken_items(){
 header; echo 'BROKEN ITEMS — bounded / read-only'; line
 local root out err rc
 echo 'Broken symbolic links in common local roots:'
 for root in "$HOME/Downloads" "$HOME/Documents" "$HOME/Desktop"; do
  [ -d "$root" ] || continue; local_scan_guard "$root" >/dev/null 2>&1 || { echo "  SKIP protected/provider root: $root"; continue; }
  out="$CACHE_DIR/broken.$$.out"; err="$CACHE_DIR/broken.$$.err"
  run_deadline "${JANITOR_TARGET_SCAN_TIMEOUT:-30}" "$out" "$err" safe_find "$root" -xdev \( -type d -name '*.photoslibrary' -prune \) -o \( -type l ! -exec test -e {} \; -print \); rc=$?
  [ "$rc" -eq 0 ] || echo "  PARTIAL: $root reached time budget"
  head -100 "$out"; rm -f "$out" "$err"
 done
 echo; echo 'Invalid user LaunchAgent plists:'
 if [ -d "$HOME/Library/LaunchAgents" ]; then for f in "$HOME"/Library/LaunchAgents/*.plist; do [ -f "$f" ] || continue; plutil -lint "$f" >/dev/null 2>&1 || echo "$f"; done; fi
 pause
}
backups_status(){
 header; echo "BACKUPS / SNAPSHOTS / iOS BACKUPS — read-only"; line
 tmutil status 2>/dev/null || echo "Time Machine status unavailable / permission required."; echo
 tmutil listlocalsnapshots / 2>/dev/null || echo "Local snapshots unavailable / permission required."; echo
 local mob="$HOME/Library/Application Support/MobileSync/Backup" _b _kb
 if [ -d "$mob" ]; then
  if ! local_scan_guard "$mob" >/dev/null 2>&1; then echo 'MobileSync backup folder is provider-managed; traversal skipped.'
  else
   echo "Local iPhone/iPad backups:"
   for _b in "$mob"/*; do [ -e "$_b" ] || continue; _kb=$(bounded_size_kb "$_b" "${JANITOR_SUMMARY_TIMEOUT:-15}"); case "$_kb" in TIMEOUT) echo "  PARTIAL  $_b";; PROVIDER) echo "  PROVIDER SKIP  $_b";; *) printf "  %12s  %s\n" "$(human_kb "$_kb")" "$_b";; esac; done
  fi
 else echo "No local MobileSync backup folder detected."; fi
 pause
}
cloud_status(){ header; echo 'CLOUD / LOCAL STATE — read-only'; line; local label root count=0; while IFS=$'\t' read -r label root; do count=$((count+1)); printf '%-24s %s\n' "$label" "$root"; done < <(cloud_roots); [ "$count" -gt 0 ] || echo 'No supported cloud roots detected.'; echo 'Provider-managed content is not recursively sized and cloud-only items are never classified as junk.'; pause; }
app_leftovers(){
 header; echo "APP SUPPORT / USER LOGIN AGENTS — review only"; line
 local root item out="$CACHE_DIR/launchagents.$$.out" err="$CACHE_DIR/launchagents.$$.err" rc
 echo 'User LaunchAgents:'
 root="$HOME/Library/LaunchAgents"
 if [ -d "$root" ]; then
  if local_scan_guard "$root" && run_deadline "${JANITOR_LAUNCHAGENT_TIMEOUT:-5}" "$out" "$err" safe_find "$root" -xdev -maxdepth 1 -type f -name '*.plist' -print; then cat "$out"; else rc=$?; [ "${rc:-1}" -eq 124 ] && echo 'PARTIAL — LaunchAgent listing timed out.'; fi
 fi
 echo; echo 'Top-level Application Support folders (ownership not inferred):'
 for root in "$HOME/Library/Application Support" /Library/Application\ Support; do
  [ -d "$root" ] || continue
  if [ "$root" != /Library/Application\ Support ]; then local_scan_guard "$root" || { echo "Skipped protected/provider path: $root"; continue; }; fi
  for item in "$root"/*; do [ -d "$item" ] && printf '  %s\n' "$item"; done | head -100
 done
 echo; echo 'No support folder is labeled an orphan/remnant without ownership proof; removal is deferred.'
 rm -f "$out" "$err"; pause
}
safe_clean_general(){
 ACTION_STARTED=$SECONDS; ACTION_COUNT=0
 header; printf '%s%sSAFE CLEAN — PREVIEW / RECOVERABLE CLEAN%s\n' "$BOLD" "$GREEN" "$RESET"; line
 echo 'Known regenerable caches and user-discarded Trash are reviewed before action.'
 echo 'Homebrew is REVIEW ONLY and is never included automatically.'; echo
 local inv="$CACHE_DIR/safe-general.$$.tsv" total=0 kb p
 : > "$inv"
 for p in "$HOME/.Trash"; do
  [ -d "$p" ] || continue; local_scan_guard "$p" >/dev/null 2>&1 || continue; kb=$(size_kb "$p"); [ "$kb" -gt 0 ] || continue
  printf '%s\t%s\n' "$kb" "$p" >> "$inv"; total=$((total+kb))
 done
 # Application cache root is not blanket-safe. Only JANITOR-known regenerable developer caches are automatic.
 for p in "$HOME/Library/Developer/Xcode/DerivedData" "$HOME/Library/Caches/org.swift.swiftpm" "$HOME/.npm/_cacache" "$HOME/Library/Caches/pip"; do
  [ -d "$p" ] || continue; local_scan_guard "$p" >/dev/null 2>&1 || continue; kb=$(size_kb "$p"); [ "$kb" -gt 0 ] || continue
  printf '%s\t%s\n' "$kb" "$p" >> "$inv"; total=$((total+kb))
 done
 printf '%sSAFE / RECOVERABLE CANDIDATES%s  %s\n' "$GREEN" "$RESET" "$(human_kb "$total")"
 while IFS=$'\t' read -r kb p; do printf '  %12s  %s\n' "$(human_kb "$kb")" "$p"; done < "$inv"
 echo; printf '%sREVIEW ONLY%s\n' "$YELLOW" "$RESET"
 [ -d "$HOME/Library/Caches/Homebrew" ] && { if ! local_scan_guard "$HOME/Library/Caches/Homebrew" >/dev/null 2>&1; then echo '  Homebrew cache — provider-managed, skipped'; else printf '  %12s  %s\n' "$(human_kb "$(size_kb "$HOME/Library/Caches/Homebrew")")" "$HOME/Library/Caches/Homebrew"; fi; }
 echo '  ~/Library/Caches as a whole and user logs (not blanket-safe; use Maintenance review)'
 [ "$total" -gt 0 ] || { echo; echo 'Nothing eligible found.'; rm -f "$inv"; pause; return; }
 echo; read -r -p '[Q] Quarantine candidates (recoverable)  [B] Back: ' a || return 0
 case "$a" in q|Q)
  read -r -p 'Move ONLY the listed SAFE candidates to JANITOR quarantine? [y/N] ' ok
  case "$ok" in y|Y) ACTION_STARTED=$SECONDS; ACTION_COUNT=0;; *) echo Cancelled.; rm -f "$inv"; pause; return;; esac
  local session moved=0 failed=0 before after item slot dest
  if ! local_scan_guard "$QROOT" >/dev/null 2>&1; then echo 'Quarantine root is provider-managed; no cleanup was performed.'; rm -f "$inv"; pause; return; fi
  session=$(new_quarantine_session safe-clean) || { echo "Cannot create quarantine."; return; }; mkdir -p "$session/items"; printf 'JANITOR SAFE CLEAN\nCreated: %s\n' "$(date)" > "$session/MANIFEST.txt"
  while IFS=$'\t' read -r kb p; do
   [ -d "$p" ] || continue
   local_scan_guard "$p" >/dev/null 2>&1 || { failed=$((failed+1)); continue; }
   for item in "$p"/* "$p"/.[!.]* "$p"/..?*; do
    [ $((SECONDS-ACTION_STARTED)) -lt "${JANITOR_ACTION_TOTAL_TIMEOUT:-30}" ] || { echo "PARTIAL — action budget reached."; break; }; [ -e "$item" ] || continue
    case "$item" in "$HOME/Library/Logs/JANITOR"|"$QROOT"|"$QROOT"/*) continue;; esac
    before=$(size_kb "$item")
    if quarantine_item_verified "$item" "$session" safe-clean; then
      printf 'MOVED\tSAFE\t0\t%s\t%s\n' "$item" "$LOCAL_LAST_DEST" >> "$session/MANIFEST.txt"; moved=$((moved+1))
    else failed=$((failed+1)); printf 'FAILED\t%s\n' "$item" >> "$session/MANIFEST.txt"; fi
   done
  done < "$inv"
  echo; printf 'Quarantined: %d   Failed: %d\nLocation: %s\n' "$moved" "$failed" "$session";;
 *) echo 'No changes made.';; esac
 rm -f "$inv"; pause
}

maintenance_logs(){
 ACTION_STARTED=$SECONDS; ACTION_COUNT=0
 header; echo 'MAINTENANCE • OLD USER LOGS'; line
 local root="$HOME/Library/Logs" list="$CACHE_DIR/maintenance-logs.$$.txt" count=0 kb=0 f
 [ -d "$root" ] || { echo 'No user Logs folder.'; pause; return; }
 local err="$CACHE_DIR/maintenance-logs.$$.err" rc=0 files_seen=0 bytes=0 file_size cap="$CACHE_DIR/maintenance-logs.$$.cap"
 if ! local_scan_guard "$root" >/dev/null 2>&1; then echo 'User Logs are provider-managed; scan skipped.'; pause; return; fi
 if run_deadline "${JANITOR_LOG_SCAN_TIMEOUT:-15}" "$list" "$err" safe_find "$root" -xdev -maxdepth 6 -type f -mtime +30 ! -path "$HOME/Library/Logs/JANITOR/*" -print; then rc=0; else rc=$?; fi
 count=$(wc -l < "$list" | tr -d ' ')
 if [ "$count" -gt 1000 ]; then head -1000 "$list" > "$cap"; mv "$cap" "$list"; count=1000; rc=124; fi
 while IFS= read -r f; do
  [ -f "$f" ] || continue
  file_size=$(file_bytes "$f" 2>/dev/null || echo 0); case "$file_size" in *[!0-9]*|'') file_size=0;; esac; bytes=$((bytes+file_size)); files_seen=$((files_seen+1))
 done < "$list"
 kb=$((bytes/1024)); count="$files_seen"; [ "$rc" -eq 0 ] || echo 'PARTIAL — old log scan time budget reached.'
 printf 'Files older than 30 days: %d / %s\n' "$count" "$(human_kb "$kb")"
 [ "$count" -gt 0 ] || { rm -f "$list"; pause; return; }
 read -r -p '[V] View  [D] Delete these old logs  [B] Back: ' a || return 0
 case "$a" in v|V) cat "$list";; d|D) read -r -p 'Permanently delete ONLY these listed old log files? [y/N] ' ok; case "$ok" in y|Y) local deleted=0 failed=0; while IFS= read -r f; do if [ -f "$f" ] && delete_local_verified "$f"; then deleted=$((deleted+1)); else failed=$((failed+1)); fi; done < "$list"; printf 'Deleted: %d  Failed: %d\n' "$deleted" "$failed";; esac;; esac
 rm -f "$list" "$err" "$cap"; pause
}
maintenance_trash(){
 ACTION_STARTED=$SECONDS; ACTION_COUNT=0
 header; echo 'MAINTENANCE • TRASH'; line; local t="$HOME/.Trash"; [ -d "$t" ] || { echo 'Trash unavailable.'; pause; return; }
 local_scan_guard "$t" >/dev/null 2>&1 || { echo 'Trash is provider-managed; Terminal cleanup is skipped.'; pause; return; }
 echo "Current Trash: $(human_kb "$(size_kb "$t")")"; read -r -p 'Permanently empty your Trash? [y/N] ' ok
 case "$ok" in y|Y) local failed=0 item; for item in "$t"/* "$t"/.[!.]* "$t"/..?*; do [ -e "$item" ] || continue; delete_local_verified "$item" || failed=$((failed+1)); done; echo "Trash after: $(human_kb "$(size_kb "$t")")  Failures: $failed";; *) echo Cancelled.;; esac; pause
}
maintenance_menu(){
 while true; do header; printf '%s%sLCAS • MAINTENANCE%s\n' "$BOLD" "$GREEN" "$RESET"; echo 'Actions that maintain the machine'; line
  echo '1 Safe Clean — recoverable cleanup'; echo '2 Old User Logs — review/delete >30 days'; echo '3 Trash — review/empty'; echo '4 Developer Maintenance — Xcode/Swift/npm/pip safe cache'; echo '5 Broken Items Check — symlinks / invalid LaunchAgents'; echo '6 Diagnostics / JANITOR Status'; echo '0 Back'; line
  read -r -p 'Choose: ' c || return 0; case "$c" in 1) safe_clean_general;;2) maintenance_logs;;3) maintenance_trash;;4) safe_clean_preview;;5) broken_items;;6) system_info;;0) return 0;;*) sleep 1;;esac
 done
}
running_processes(){
 header; echo 'FULL CREW • RUNNING PROCESSES'; echo 'Origin-classified read-only inspection'; line
 local tmp="$CACHE_DIR/processes.$$.txt" pid cpu mem elapsed cmd exe kind
 local err="$CACHE_DIR/processes.$$.err"
 if ! run_deadline 5 "$tmp" "$err" ps -axo pid=,%cpu=,%mem=,etime=,command= -r; then echo 'PARTIAL / REVIEW — process inspection unavailable.'; fi
 echo 'Grouping uses executable-path hints; signing/origin verification is DEFERRED TO NATIVE.'
 for kind in 'INSTALLED APPS' 'USER / DEVELOPMENT' 'macOS / APPLE SYSTEM' 'UNKNOWN / REVIEW'; do
  echo; printf '%s%s%s\n' "$BOLD" "$kind" "$RESET"; line; local shown=0
  if [ "$kind" = 'macOS / APPLE SYSTEM' ]; then echo '  COLLAPSED / PROTECTED / READ-ONLY'; continue; fi
  while read -r pid cpu mem elapsed cmd; do
   [ -n "$pid" ] || continue; exe="$cmd"
   k=$(origin_group "$cmd")
   [ "$k" = "$kind" ] || continue
   printf '%-7s %-6s %-6s %-9s %s
' "$pid" "$cpu" "$mem" "$elapsed" "$cmd"; shown=$((shown+1)); [ "$shown" -ge 25 ] && break
  done < "$tmp"
  [ "$shown" -eq 0 ] && echo '  none in top process sample'
 done
 rm -f "$tmp" "$err"; echo; echo 'System processes are protected/read-only here. Process termination is deferred to Activity Monitor/native JANITOR.'; pause
}
origin_group(){
 case "$1" in
  /System/*|/usr/libexec/*|/usr/sbin/*|/sbin/*|/usr/bin/*|/bin/*) echo 'macOS / APPLE SYSTEM';;
  /Applications/Xcode.app/*|/Library/Developer/*|/opt/homebrew/*|/usr/local/*) echo 'USER / DEVELOPMENT';;
  /Applications/*.app/*|"$HOME"/Applications/*.app/*) echo 'INSTALLED APPS';;
  "$HOME"/*) echo 'USER / DEVELOPMENT';;
  *) echo 'UNKNOWN / REVIEW';;
 esac
}
startup_inventory(){
 local root f program kind
 for root in "$HOME/Library/LaunchAgents" /Library/LaunchAgents /Library/LaunchDaemons; do
  [ -d "$root" ] || continue
  case "$root" in "$HOME"/*) local_scan_guard "$root" >/dev/null 2>&1 || continue;; esac
  /usr/bin/find -P "$root" -xdev -maxdepth 1 \( -flags +dataless -prune \) -o \( -type f -name '*.plist' -print0 \) |
  while IFS= read -r -d '' f; do
   program=$(/usr/libexec/PlistBuddy -c 'Print :Program' "$f" 2>/dev/null) || program=$(/usr/libexec/PlistBuddy -c 'Print :ProgramArguments:0' "$f" 2>/dev/null) || program='UNKNOWN'
   kind=$(origin_group "$program")
   printf '%s\t%s\t%s\n' "$kind" "$f" "$program"
  done
 done
}
background_items(){
 header; echo 'FULL CREW • BACKGROUND / STARTUP ITEMS'; line
 local tmp="$CACHE_DIR/startup.$$.tsv" err="$CACHE_DIR/startup.$$.err" kind
 if ! run_deadline 5 "$tmp" "$err" startup_inventory; then echo 'PARTIAL / REVIEW — startup inventory incomplete.'; fi
 echo 'Groups use declared executable paths; signing/ownership and management are DEFERRED TO NATIVE.'
 for kind in 'macOS / APPLE SYSTEM' 'INSTALLED APPS' 'USER / DEVELOPMENT' 'UNKNOWN / REVIEW'; do
  echo; echo "$kind"
  if [ "$kind" = 'macOS / APPLE SYSTEM' ]; then echo '  COLLAPSED / PROTECTED / READ-ONLY'; continue; fi
  awk -F '\t' -v group="$kind" '$1==group {print "  "$2" -> "$3}' "$tmp" | head -50
 done
 rm -f "$tmp" "$err"; pause
}
remnants_review(){
 header; echo 'FULL CREW • INSTALLED APPS & SUPPORT INVENTORY'; echo 'Read-only — NOT remnant detection'; line
 echo 'Installed applications:'; for root in /Applications "$HOME/Applications"; do [ -d "$root" ] || continue; for app in "$root"/*.app; do [ -d "$app" ] && echo "  $app"; done; done
 echo; echo 'Top-level Application Support folders (ownership not inferred):'
 local root item
 for root in "$HOME/Library/Application Support" /Library/Application\ Support; do
  [ -d "$root" ] || continue
  if [ "$root" != /Library/Application\ Support ]; then local_scan_guard "$root" || { echo "  Skipped protected/provider path: $root"; continue; }; fi
  for item in "$root"/*; do [ -d "$item" ] && printf '  %s\n' "$item"; done | head -100
 done
 echo; echo 'Terminal JANITOR does not label support data as orphaned/remnant without reliable bundle ownership and package receipts.'
 echo 'True software-remnant correlation/removal is DEFERRED TO NATIVE macOS JANITOR.'; pause
}
dev_delete_intermediate(){
 ACTION_STARTED=$SECONDS; ACTION_COUNT=0
 local plan="$1" count="$2"; [ "$count" -gt 0 ] || return 0
 echo; printf '%sPERMANENT DELETE — INTERMEDIATE BUILDS%s\n' "$RED" "$RESET"; line
 while IFS=$'\t' read -r family build kb gitflag base src; do printf '  %-12s %12s  %s\n' "BUILD$((10#$build))" "$(human_kb "$kb")" "$src" 2>/dev/null || echo "  $src"; done < "$plan"
 echo; echo 'First + latest builds remain. Git working copies are excluded.'
 read -r -p 'Type DELETE to permanently remove ONLY the items above: ' ok; [ "$ok" = DELETE ] || { echo Cancelled.; return 1; }; ACTION_STARTED=$SECONDS; ACTION_COUNT=0
 local deleted=0 failed=0 src
 while IFS=$'\t' read -r family build kb gitflag base src; do
  if [ "$gitflag" = 0 ] && delete_local_verified "$src"; then printf '✓ %s\n' "$src"; deleted=$((deleted+1)); else printf '! FAILED %s\n' "$src"; failed=$((failed+1)); fi
 done < "$plan"
 printf 'Deleted: %d  Failed: %d\n' "$deleted" "$failed"; [ "$failed" -eq 0 ]
}



run_deadline(){ (
 local seconds="$1" out="$2" err="$3"; shift 3
 local pid start rc
 case "$seconds" in ''|*[!0-9]*) echo 'Invalid time budget.' >&2; return 2;; esac
 [ "$seconds" -gt 0 ] && [ "$seconds" -le 300 ] || return 2
 : > "$out"; : > "$err"
 # Native Bash job control gives the worker a separate process group. Kill
 # that group, including find/stat/hash subprocesses, rather than only its shell.
 set -m
 "$@" >"$out" 2>"$err" & pid=$!; start=$SECONDS
 set +m
 trap 'kill -TERM -- "-$pid" 2>/dev/null; kill -KILL -- "-$pid" 2>/dev/null' INT TERM HUP
 while kill -0 "$pid" 2>/dev/null; do
  if [ $((SECONDS-start)) -ge "$seconds" ]; then
   kill -TERM -- "-$pid" 2>/dev/null || true; sleep 0.2
   kill -KILL -- "-$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true
   return 124
  fi
  sleep 0.1
 done
 wait "$pid" 2>/dev/null; rc=$?; return "$rc"
) }

bounded_size_kb(){
 local path="$1" seconds="${2:-12}" include_photos="${3:-0}" out err rc value
 if [ "$include_photos" != 1 ] && ! local_scan_guard "$path" >/dev/null 2>&1; then printf 'PROVIDER\n'; return 0; fi
 out=$(mktemp "${TMPDIR:-/tmp}/janitor-size.XXXXXX") || { printf 'TIMEOUT\n'; return 0; }
 err=$(mktemp "${TMPDIR:-/tmp}/janitor-size.XXXXXX") || { rm -f "$out"; printf 'TIMEOUT\n'; return 0; }
 if [ "$include_photos" = 1 ]; then
  if run_deadline "$seconds" "$out" "$err" photos_size_metadata "$path"; then rc=0; else rc=$?; fi
 else
  if run_deadline "$seconds" "$out" "$err" bounded_size_excluding_photos "$path"; then rc=0; else rc=$?; fi
 fi
 value=$(awk 'NR==1 && $1 ~ /^[0-9]+$/ {print $1}' "$out")
 rm -f "$out" "$err"
 if [ "$rc" -ne 0 ] || [ -z "$value" ]; then printf 'TIMEOUT\n'; else printf '%s\n' "$value"; fi
}
photos_size_metadata(){
 local JANITOR_PHOTOS_FOOTPRINT=1
 bounded_size_excluding_photos "$1"
}
bounded_size_excluding_photos(){
 # Reuse native find/stat in batches. st_blocks measures allocated storage,
 # not sparse apparent length. Never open file contents for size estimation.
 set -o pipefail
 safe_find "$1" -xdev -type f -exec /usr/bin/stat -f '%d %i %b' {} + |
  awk '!seen[$1 FS $2]++ {blocks+=$3} END {printf "%.0f\n",blocks/2}'
}

cloud_roots(){
 local ic="$HOME/Library/Mobile Documents/com~apple~CloudDocs" d
 [ -d "$ic" ] && printf 'iCloud Drive\t%s\n' "$ic"
 if [ -d "$HOME/Library/CloudStorage" ]; then
  for d in "$HOME/Library/CloudStorage"/*; do [ -d "$d" ] || continue; printf '%s\t%s\n' "$(basename "$d")" "$d"; done
 fi
}
cloud_root_for_path(){
 local input="$1" parent canonical label root rootcanon ic
 # Known-folder ownership cannot be established in Bash. Visible iCloud
 # aliases are not a prerequisite for deferral. Legacy/custom provider names
 # are conservative boundaries as well as modern CloudStorage roots.
 case "$input" in
  "$HOME/Documents"|"$HOME/Documents"/*|"$HOME/Desktop"|"$HOME/Desktop"/*|*/CloudStorage|*/CloudStorage/*|*/Mobile\ Documents|*/Mobile\ Documents/*|*/Dropbox|*/Dropbox/*|*/Google\ Drive|*/Google\ Drive/*|*/GDrivA|*/GDrivA/*|*/My\ Drive|*/My\ Drive/*|*/OneDrive*|*/Creative\ Cloud\ Files*) printf '%s\n' "$input"; return 0;;
 esac
 if [ -d "$input" ]; then
  canonical=$(cd "$input" 2>/dev/null && pwd -P) || canonical="$input"
  input="$canonical"
 else
  parent=$(dirname "$input")
  canonical=$(cd "$parent" 2>/dev/null && pwd -P) || canonical="$parent"
  input="$canonical/$(basename "$input")"
 fi
 while IFS=$'	' read -r label root; do
  rootcanon=$(cd "$root" 2>/dev/null && pwd -P) || rootcanon="$root"
  case "$input" in "$rootcanon"|"$rootcanon"/*) printf '%s
' "$root"; return 0;; esac
 done < <(cloud_roots)
 # Bash cannot query NSFileProviderKnownFolders. Be conservative when iCloud
 # exposes Desktop/Documents: do not recursively treat the user-visible known
 # folder as ordinary local storage.
 ic="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
 if [ -d "$ic" ]; then
  case "$1" in
   "$HOME/Documents"|"$HOME/Documents"/*) [ -e "$ic/Documents" ] && { printf '%s
' "$ic"; return 0; };;
   "$HOME/Desktop"|"$HOME/Desktop"/*) [ -e "$ic/Desktop" ] && { printf '%s
' "$ic"; return 0; };;
  esac
 fi
 return 1
}
path_contains_provider_root(){
 local out err rc
 out=$(mktemp); err=$(mktemp)
 run_deadline "${JANITOR_GUARD_TIMEOUT:-2}" "$out" "$err" path_contains_provider_root_impl "$1"; rc=$?
 rm -f "$out" "$err"
 # Failure to complete ownership checks is a conservative exclusion.
 [ "$rc" -ne 1 ]
}
path_contains_provider_root_impl(){
 local input="$1" canonical label root rootcanon candidate candidatecanon
 [ -d "$input" ] || return 1
 canonical=$(cd "$input" 2>/dev/null && pwd -P) || canonical="$input"
 while IFS=$'\t' read -r label root; do
  rootcanon=$(cd "$root" 2>/dev/null && pwd -P) || rootcanon="$root"
  case "$rootcanon/" in "$canonical/"*) return 0;; esac
 done < <(cloud_roots)
 for candidate in "$HOME/Documents" "$HOME/Desktop"; do
  if cloud_root_for_path "$candidate" >/dev/null 2>&1; then
   candidatecanon=$(cd "$candidate" 2>/dev/null && pwd -P) || candidatecanon="$candidate"
   case "$candidatecanon/" in "$canonical/"*) return 0;; esac
  fi
 done
 return 1
}
path_owner(){
 local out err rc
 out=$(mktemp); err=$(mktemp)
 run_deadline "${JANITOR_GUARD_TIMEOUT:-2}" "$out" "$err" path_owner_impl "$1"; rc=$?
 if [ "$rc" -eq 0 ] && [ -s "$out" ]; then cat "$out"; else echo UNKNOWN; fi
 rm -f "$out" "$err"
}
path_owner_impl(){
 local p="$1" cr resolved
 case "$p" in *$'\n'*|*$'\r'*|*$'\t'*|*'/../'*|*/..|../*|..|*'/./'*|*/.) echo UNKNOWN; return;; esac
 case "$p" in /*) ;; *) p="$PWD/$p";; esac
 cr=$(cloud_root_for_path "$p" 2>/dev/null || true); [ -n "$cr" ] && { echo FILE_PROVIDER; return; }
 if [ -e "$p" ] || [ -L "$p" ]; then
  resolved=$(/bin/realpath -q "$p") || { echo UNKNOWN; return; }
 else
  local ancestor="$p" suffix='' levels=0
  while [ ! -e "$ancestor" ] && [ ! -L "$ancestor" ]; do
   levels=$((levels+1)); [ "$levels" -le 32 ] || { echo UNKNOWN; return; }
   suffix="/$(basename "$ancestor")$suffix"; ancestor=$(dirname "$ancestor")
  done
  resolved=$(/bin/realpath -q "$ancestor") || { echo UNKNOWN; return; }
  resolved="$resolved$suffix"
 fi
 p="$resolved"
 case "$p" in *.photoslibrary|*.photoslibrary/*) echo PHOTOS_LIBRARY; return 0;; /System|/System/*|/usr|/usr/*|/bin|/bin/*|/sbin|/sbin/*) echo PROTECTED_SYSTEM; return 0;; esac
 cr=$(cloud_root_for_path "$p" 2>/dev/null || true); [ -n "$cr" ] && { echo FILE_PROVIDER; return 0; }
 case "$p" in /Volumes/*) echo EXTERNAL_OR_NETWORK; return 0;; esac
 # This Terminal candidate accepts bounded work in established local scopes.
 # Arbitrary home folders may be custom sync roots: UNKNOWN remains deferred.
 case "$p" in
  /private/tmp|/private/tmp/*|"${TMPDIR:-/private/tmp}"|"${TMPDIR:-/private/tmp}"/*|"$HOME/Downloads"|"$HOME/Downloads"/*|"$HOME/Pictures"|"$HOME/Pictures"/*|"$HOME/Movies"|"$HOME/Movies"/*|"$HOME/.Trash"|"$HOME/.Trash"/*|"$HOME/.npm"|"$HOME/.npm"/*|"$HOME/.gradle"|"$HOME/.gradle"/*|"$HOME/Library/Caches"|"$HOME/Library/Caches"/*|"$HOME/Library/Logs"|"$HOME/Library/Logs"/*|"$HOME/Library/Developer"|"$HOME/Library/Developer"/*|"$HOME/Library/Application Support"|"$HOME/Library/Application Support"/*|"$HOME/Library/LaunchAgents"|"$HOME/Library/LaunchAgents"/*|"$HOME/Library/pnpm"|"$HOME/Library/pnpm"/*|"$HOME/Library/Arduino15"|"$HOME/Library/Arduino15"/*|"$HOME/Library/Containers/com.docker.docker/Data"|"$HOME/Library/Containers/com.docker.docker/Data"/*|"$HOME/Applications"|"$HOME/Applications"/*) ;;
  *) echo UNKNOWN; return;;
 esac
 if [ -e "$p" ]; then
  cr=$(/usr/bin/stat -f '%Sf' "$p" 2>/dev/null) || { echo UNKNOWN; return; }
  case "$cr" in *dataless*) echo FILE_PROVIDER; return;; esac
 fi
 echo LOCAL
}
local_scan_guard(){
 local p="$1" owner; owner=$(path_owner "$p")
 case "$owner" in
  LOCAL) if path_contains_provider_root "$p"; then echo "SKIP: selected root contains a provider-managed location: $p" >&2; return 2; fi; return 0;;
  FILE_PROVIDER) echo "SKIP: provider-managed path — Bash cannot safely determine dataless/materialized state: $p" >&2; return 2;;
  PHOTOS_LIBRARY) echo "SKIP: Photos library internals are protected: $p" >&2; return 3;;
  *) echo "SKIP: $owner path: $p" >&2; return 4;;
 esac
}

safe_find(){
 local root="$1"; shift
 local options=(-xdev)
 # Options precede the prune expression. Keep the existing native find queries.
 while [ "$#" -gt 0 ]; do
  case "$1" in
   -xdev) shift;;
   -maxdepth|-mindepth) options+=("$1" "$2"); shift 2;;
   *) break;;
  esac
 done
 if [ "${JANITOR_PHOTOS_FOOTPRINT:-0}" = 1 ]; then
  cloud_root_for_path "$root" >/dev/null 2>&1 && return 90
 else
  local_scan_guard "$root" >/dev/null 2>&1 || return 90
 fi
 local photos_mask='*.photoslibrary'
 [ "${JANITOR_PHOTOS_FOOTPRINT:-0}" = 1 ] && photos_mask='__JANITOR_NO_PHOTOS_PRUNE__'
 /usr/bin/find -P "$root" "${options[@]}" \
  \( -flags +dataless -o -name $'*\n*' -o -name $'*\t*' -o -name $'*\r*' -o \( -type d \( -name "$photos_mask" -o -name CloudStorage -o -name 'Mobile Documents' -o -name Dropbox -o -name 'Google Drive' -o -name GDrivA -o -name 'My Drive' -o -name 'OneDrive*' -o -name 'Creative Cloud Files*' \) \) \) -prune -o \( "$@" \)
}
cloud_provider_label(){
 local target="$1" label root
 while IFS=$'\t' read -r label root; do [ "$root" = "$target" ] && { printf '%s\n' "$label"; return; }; done < <(cloud_roots)
 printf 'Cloud Provider\n'
}
cloud_move_same_provider(){ echo "DEFERRED TO NATIVE APP — File Provider mutation is not executed by JANITOR Terminal." >&2; return 90; }
cloud_delete_path(){ echo "DEFERRED TO NATIVE APP — File Provider mutation is not executed by JANITOR Terminal." >&2; return 90; }
cloud_choose_path(){ echo "DEFERRED TO NATIVE APP — File Provider mutation is not executed by JANITOR Terminal." >&2; return 90; }
cloud_storage_review(){
 header; echo 'CLOUD STORAGE — TERMINAL BOUNDARY'; line
 local label root count=0
 while IFS=$'\t' read -r label root; do count=$((count+1)); printf '  %-24s %s\n' "$label" "$root"; done < <(cloud_roots)
 [ "$count" -gt 0 ] || echo 'No supported provider roots detected.'
 echo; echo 'Terminal JANITOR does NOT recursively scan, hash, move, consolidate, delete or restore provider-managed content.'
 echo 'Reason: Bash cannot reliably determine File Provider known-folder ownership or dataless/materialized state.'
 echo 'Cloud Scan / Review / Quarantine / Consolidate / Delete are DEFERRED TO NATIVE JANITOR.'
 pause
}

photos_analyze_library(){
 local lib="$1" total part kb
 echo; printf '%sPHOTOS LIBRARY%s\n%s\n' "$CYAN" "$RESET" "$lib"
 if cloud_root_for_path "$lib" >/dev/null 2>&1 || path_contains_provider_root "$lib"; then echo '  Provider-managed library: filesystem traversal skipped; PhotoKit analysis is deferred.'; return; fi
 total=$(bounded_size_kb "$lib" "${JANITOR_PHOTOS_SIZE_TIMEOUT:-8}" 1)
 if [ "$total" = TIMEOUT ]; then echo '  Total footprint: PARTIAL — size walk exceeded time budget'; else printf '  %-22s %s\n' 'Filesystem footprint:' "$(human_kb "$total")"; fi
 echo '  Protected: YES — JANITOR will not delete Photos database/originals directly.'
 for part in originals resources database private external scopes; do
  [ -d "$lib/$part" ] || continue
  kb=$(bounded_size_kb "$lib/$part" "${JANITOR_PHOTOS_COMPONENT_TIMEOUT:-3}" 1)
  if [ "$kb" = TIMEOUT ]; then printf '  %-22s %s\n' "$part:" 'PARTIAL / timed out'; else printf '  %-22s %s\n' "$part:" "$(human_kb "$kb")"; fi
 done
}
photos_storage_analysis(){
 header; echo 'MEDIA • PHOTOS LIBRARY FOOTPRINT'; echo 'Read-only local filesystem view'; line
 local found=0 lib
 if [ -d "$HOME/Pictures" ] && local_scan_guard "$HOME/Pictures" >/dev/null 2>&1; then for lib in "$HOME/Pictures"/*.photoslibrary; do [ -d "$lib" ] || continue; found=$((found+1)); photos_analyze_library "$lib"; done
 elif [ -d "$HOME/Pictures" ]; then echo 'Pictures is provider-managed; no library traversal performed.'; fi
 [ "$found" -gt 0 ] || echo 'No .photoslibrary found directly in ~/Pictures.'
 echo; echo 'Terminal limitation: this does NOT determine PHAsset iCloud/local-resident state and performs no reclaim.'
 echo 'Photos/iCloud resident-state analysis and safe reclaim are DEFERRED TO NATIVE JANITOR using PhotoKit with network access disabled.'
 echo 'Photos library internals remain PROTECTED.'; pause
}
bounded_large_scan_root(){
 local root="$1" out="$2" limit="${JANITOR_FULLSCAN_ROOT_TIMEOUT:-25}" err="$CACHE_DIR/fullscan.$$.err" tmp="$CACHE_DIR/fullscan.$$.paths" rc=0 f bytes
 : > "$out"; : > "$tmp"
 if run_deadline "$limit" "$tmp" "$err" safe_find "$root" -xdev \( -type d -name '*.photoslibrary' -prune \) -o \( -type f -size +500M -print \); then rc=0; else rc=$?; fi
 while IFS= read -r f; do [ -f "$f" ] || continue; bytes=$(file_bytes "$f" || echo 0); printf '%020d\t%s\n' "$bytes" "$f" >> "$out"; done < <(head -1000 "$tmp")
 rm -f "$tmp" "$err"; return "$rc"
}
full_scan(){
 header; echo 'LCAS • FULL SCAN'; echo 'Bounded local scan • provider-aware • read-only until you choose an action'; line
 local r start=$SECONDS root label idx=0 partial=0 findings="$CACHE_DIR/full-findings.$$.tsv" part="$CACHE_DIR/full-part.$$.tsv" inv="$CACHE_DIR/full-safe.$$.tsv" safe_kb
 : > "$findings"; r=$(report_path full-scan)
 echo 'Cloud provider roots and Photos library internals are excluded from automatic recursion.'
 echo "Per-root time budget: ${JANITOR_FULLSCAN_ROOT_TIMEOUT:-25}s"; echo
 for root in "$HOME/Downloads" "$HOME/Documents" "$HOME/Desktop" "$HOME/Pictures" "$HOME/Movies"; do
  [ -d "$root" ] || continue; idx=$((idx+1)); label=$(basename "$root")
  if ! local_scan_guard "$root" >/dev/null 2>&1; then printf '[%d] %-12s %sSKIP protected/provider root%s\n' "$idx" "$label" "$YELLOW" "$RESET"; continue; fi
  printf '[%d] %-12s scanning… ' "$idx" "$label"; : > "$part"
  if bounded_large_scan_root "$root" "$part"; then printf '%sDONE%s\n' "$GREEN" "$RESET"; else rc=$?; if [ "$rc" -eq 124 ]; then printf '%sPARTIAL — time budget reached%s\n' "$YELLOW" "$RESET"; partial=$((partial+1)); else printf '%sPARTIAL — scan error%s\n' "$YELLOW" "$RESET"; partial=$((partial+1)); fi; fi
  cat "$part" >> "$findings"
 done
 safe_kb=$(quick_safe_inventory "$inv")
 {
  echo "JANITOR Full Scan — $(date)"; echo 'Mode: bounded local roots'; echo "Partial roots: $partial"; echo "Safe cache KB: $safe_kb"; echo; echo 'LARGE FILES — REVIEW'; sort -rn "$findings" | head -100 | while IFS=$'\t' read -r bytes f; do [ -n "$f" ] || continue; awk -v b="$bytes" -v f="$f" 'BEGIN{printf "%.1f GB\t%s\n",b/1073741824,f}'; done
 } > "$r"
 echo; line; printf '%sSAFE TO DELETE%s %s\n' "$GREEN" "$RESET" "$(human_kb "$safe_kb")"; echo 'Known regenerable cache material only.'
 printf '%sREVIEW%s %s large-file findings\n' "$YELLOW" "$RESET" "$(wc -l < "$findings" | tr -d ' ')"
 [ "$partial" -gt 0 ] && printf '%sPARTIAL%s %d root(s) hit their time budget; completed findings were retained.\n' "$YELLOW" "$RESET" "$partial"
 echo "Completed in $((SECONDS-start))s"; echo "Report: $r"
 while true; do
  echo; echo '[D] Delete SAFE cache items   [V] View findings   [C] Cloud Storage   [B] Back'
  read -r -p 'Choose: ' a || return 0
  case "$a" in d|D) [ "$safe_kb" -gt 0 ] && quick_delete_safe "$inv" "$safe_kb" || echo 'No SAFE items.'; pause; break;; v|V) cat "$r"; pause;; c|C) cloud_storage_review;; b|B|'') break;; esac
 done
 rm -f "$findings" "$part" "$inv"
}

standard_menu(){
 while true; do header; echo 'STANDARD'; echo 'Everyday maintenance — technical/developer/media detail kept out of the way'; line
  echo '1 Quick Scan'; echo '2 Full Scan — bounded'; echo '3 Safe Clean'; echo '4 Maintenance'; echo '5 Cloud Storage — provider status / native deferral'; echo '6 Quarantine / Recovery'; echo '7 Diagnostics'; echo '0 Back'; line
  read -r -p 'Choose: ' c || return 0; case "$c" in 1) quick_scan;;2) full_scan;;3) safe_clean_general;;4) maintenance_menu;;5) cloud_storage_review;;6) recover_menu;;7) system_info;;0) return 0;;*) sleep 1;;esac
 done
}
developer_mode_menu(){
 while true; do header; echo 'DEVELOPER'; echo 'Projects, builds, toolchains and development storage'; line
  echo '1 Developer Quick Scan'; echo '2 Developer Storage Analysis'; echo '3 Safe Developer Clean'; echo '4 Project Discovery'; echo '5 Build / Dependency Discovery'; echo '6 Consolidation Readiness'; echo '7 Cloud Project Storage — provider status / native deferral'; echo '0 Back'; line
  read -r -p 'Choose: ' c || return 0; case "$c" in 1) developer_quick_scan;;2) developer_analyze;;3) safe_clean_preview;;4) project_discovery;;5) large_dev;;6) compare_readiness;;7) cloud_storage_review;;0) return 0;;*) sleep 1;;esac
 done
}
media_mode_menu(){
 while true; do header; echo 'MEDIA'; echo 'Photos, video and media storage — originals are protected'; line
  echo '1 Photos Library Footprint — native PhotoKit analysis deferred'; echo '2 Photos / Video Inventory'; echo '3 Large Media Files'; echo '4 Exact Duplicate Files'; echo '5 Cloud Media Storage — provider status / native deferral'; echo '0 Back'; line
  read -r -p 'Choose: ' c || return 0; case "$c" in 1) photos_storage_analysis;;2) media_inventory;;3) large_files;;4) exact_duplicates;;5) cloud_storage_review;;0) return 0;;*) sleep 1;;esac
 done
}



native_deferrals(){
 header; echo 'NATIVE APP CAPABILITIES — DEFERRED FROM TERMINAL'; line
 echo '• File Provider item/domain identity, dataless/materialized state, eviction and safe provider mutation'
 echo '• Photos PhotoKit asset/local-vs-iCloud analysis and supported reclaim'
 echo '• Reliable app-remnant ownership correlation and authorized removal'
 echo '• Rich process/app signing attribution and managed termination controls'
 echo '• Login-item/background-task management requiring native frameworks/authorization'
 echo; echo 'Terminal JANITOR remains the deterministic reference for local filesystem maintenance, developer cleanup, bounded discovery, quarantine/recovery and reports.'; pause
}

deep_scans_menu(){ while true; do header; echo "LCAS • DEEP SCANS"; echo "Targeted investigations"; line; echo "1 Exact Duplicates"; echo "2 Large Files"; echo "3 Storage Overview"; echo "4 Applications"; echo "5 Media Inventory"; echo "6 Downloads"; echo "7 Developer Storage"; echo "8 More Diagnostics"; echo "0 Back"; line; read -r -p "Choose: " c || return 0; case "$c" in 1) exact_duplicates;;2) large_files;;3) storage_overview;;4) apps_inventory;;5) media_inventory;;6) downloads_analyze;;7) developer_analyze;;8) more_menu;;0) return 0;;*) sleep 1;;esac; done; }

full_crew_menu(){
 while true; do header; echo 'LCAS • JANITOR FULL CREW'; echo 'Advanced terminal-safe inspection'; line
  echo '1 Running Processes — origin classified / read-only'; echo '2 Background / Startup Items — origin separated'; echo '3 Installed Apps & Support Inventory'; echo '4 Project / Version Families — bounded local'; echo '5 Build / Dependency Archaeology — local'; echo '6 Similar-name Families — bounded local'; echo '7 Exact Content Comparison — bounded local'; echo '8 Consolidation Readiness — report only'; echo '9 Advanced Quarantine / Recover — local'; echo 'A Backups / Snapshots / iOS Backups'; echo 'B Privacy Residue'; echo 'C Broken Items'; echo 'D Downloads Analysis'; echo 'N Native-only capabilities / deferrals'; echo '0 Back'; line
  read -r -p 'Choose: ' c || return 0; case "$c" in 1) running_processes;;2) background_items;;3) remnants_review;;4) project_discovery;;5) large_dev;;6) similar_names;;7) exact_duplicates;;8) compare_readiness;;9) recover_menu;;a|A) backups_status;;b|B) privacy_analyze;;c|C) broken_items;;d|D) downloads_analyze;;n|N) native_deferrals;;0) return 0;;*) sleep 1;;esac
 done
}
developer_menu(){ while true; do header; echo "DEVELOPER — SIMPLE"; line; echo "1 Analyze developer storage"; echo "2 Safe Developer Clean — preview/quarantine"; echo "3 Project Discovery — read-only"; echo "0 Back"; line; echo "Advanced project-family analysis and consolidation belong to JANITOR FULL CREW."; read -r -p "Choose: " c || return 0; case "$c" in 1) developer_analyze;;2) safe_clean_preview;;3) project_discovery;;0) return 0;;*) sleep 1;;esac; done; }
more_menu(){ while true; do header; echo "MORE — READ-ONLY / REVIEW"; line; echo "1 Choose What to Scan"; echo "2 Similar Names"; echo "3 Photos & Videos inventory"; echo "4 Applications inventory"; echo "5 Privacy residue"; echo "6 Broken Items"; echo "7 Backups / Snapshots"; echo "8 Cloud / Local State"; echo "9 App Support / Login Agents"; echo "0 Back"; line; read -r -p "Choose: " c || return 0; case "$c" in 1) custom_scan;;2) similar_names;;3) media_inventory;;4) apps_inventory;;5) privacy_analyze;;6) broken_items;;7) backups_status;;8) cloud_status;;9) app_leftovers;;0) return 0;;*) sleep 1;;esac; done; }
menu(){
 while true; do
  header; echo 'LCAS • JANITOR'; echo 'Choose the kind of work first'; line
  echo '1  STANDARD       Everyday maintenance';
  echo '2  DEVELOPER      Projects, builds & development cleanup';
  echo '3  MEDIA          Photos, video & media storage';
  echo '4  FULL CREW      Advanced inspection & recovery';
  echo '5  QUARANTINE / RECOVERY';
  echo '6  SETTINGS / DIAGNOSTICS';
  echo 'X  Exit'; line
  read -r -p 'Choose: ' c || return 0
  case "$c" in 1|s|S) standard_menu;;2|d|D) developer_mode_menu;;3|m|M) media_mode_menu;;4|c|C) full_crew_menu;;5|r|R) recover_menu;;6) system_info;;x|X|0) exit 0;;*) sleep 1;;esac
 done
}

init_runtime(){
 local p
 for p in "$REPORT_DIR" "$CACHE_DIR"; do
  local_scan_guard "$p" >/dev/null 2>&1 || { echo "REFUSED: unknown/provider runtime directory: $p" >&2; return 90; }
 done
 (umask 077; mkdir -p "$REPORT_DIR" "$CACHE_DIR") || { echo 'Cannot create local reports/cache directories.' >&2; return 2; }
}

case "${1:-}" in --version|-v|version|--help|-h) ;; *) init_runtime || exit $?;; esac

case "${1:-}" in
 quick) quick_scan;; dev-quick|developer-quick) developer_quick_scan;; full) full_scan;; standard) standard_menu;; developer) developer_mode_menu;; media) media_mode_menu;; photos) photos_storage_analysis;; cloud) cloud_storage_review;; deep) storage_overview;; crew|full-crew) full_crew_menu;; recover) echo "Quarantine: $QROOT"; quarantine_manifests 3 8;; safe|safe-clean) safe_clean_general;; storage) storage_overview;; downloads) downloads_analyze;; privacy) privacy_analyze;; broken) broken_items;; backups) backups_status;; analyze) developer_analyze;; clean) safe_clean_preview;; projects) project_discovery;; large-dev) large_dev;; readiness) compare_readiness;; status) system_info;;
 scan) [ -d "${2:-}" ]&&scan_summary "$2"||{ echo 'Usage: JANITOR.command scan FOLDER'; exit 2; };;
 duplicates) [ -d "${2:-}" ] || { echo 'Usage: JANITOR.command duplicates FOLDER'; exit 2; }; local_scan_guard "$2" || exit 3; case "$2" in *.photoslibrary|*.photoslibrary/*) echo 'Photos libraries are protected.'; exit 3;; esac; out=$(mktemp); err=$(mktemp); run_deadline "${JANITOR_DUPLICATE_TIMEOUT:-60}" "$out" "$err" exact_duplicates_path "$2"; rc=$?; cat "$out"; [ "$rc" -eq 0 ] || echo 'PARTIAL / REVIEW — time budget or filesystem error.'; rm -f "$out" "$err";;
 quarantine) [ -n "${2:-}" ]||{ echo 'Usage: JANITOR.command quarantine PATH'; exit 2; }; quarantine_path "$2";;
 cloud-quarantine) [ -n "${2:-}" ]||{ echo 'Usage: JANITOR.command cloud-quarantine PATH'; exit 2; }; cloud_move_same_provider "$2" quarantine cli;;
 cloud-consolidate) [ -n "${2:-}" ]||{ echo 'Usage: JANITOR.command cloud-consolidate PATH'; exit 2; }; cloud_move_same_provider "$2" consolidate cli;;
 restore) [ -n "${2:-}" ]||{ echo 'Usage: JANITOR.command restore MANIFEST'; exit 2; }; recover_manifest "$2";;
 --version|-v|version) echo "$VERSION";; --help|-h) echo 'standard | developer | media | quick | dev-quick | full | photos | cloud | crew | recover | safe | storage | downloads | scan FOLDER | duplicates FOLDER | quarantine PATH | cloud-quarantine PATH | cloud-consolidate PATH | restore MANIFEST | status | --version';;
 *) menu;; esac
