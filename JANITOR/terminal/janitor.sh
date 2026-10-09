#!/bin/bash
# JANITOR terminal 0.1.1 — safe, bounded, macOS-version-agnostic (bash 3.2 + BSD userland; also runs on GNU for testing)
# Contract: UNKNOWN != JUNK.  inspect -> classify -> review -> confirm -> act -> verify -> record.
# No daemon, telemetry, network, or installs. Cloud/File Provider and Photos libraries are never traversed or touched.
set -u
VERSION="0.1.1"
HOME_DIR="${HOME:?HOME is not set}"
STATE="${JANITOR_HOME:-$HOME_DIR/Library/Application Support/JANITOR}"
QROOT="${JANITOR_QUARANTINE:-$HOME_DIR/Downloads/#Review&Delete/JANITOR}"
LOGS="${JANITOR_LOGS:-$HOME_DIR/Library/Logs/JANITOR}"
BUDGET="${JANITOR_BUDGET:-6}"            # seconds per root
LAST="$STATE/last-scan.tsv"
TAB=$'\t'
YES=0
mkdir -p "$STATE" "$LOGS" 2>/dev/null
LOGFILE="$LOGS/$(date +%Y%m%d)-janitor.log"
TMP=$(mktemp -d "${TMPDIR:-/tmp}/janitor.XXXXXX") || exit 1
trap 'rm -rf "$TMP"' EXIT

if [ -t 1 ]; then B=$'\033[1m'; G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; D=$'\033[2m'; N=$'\033[0m'; else B=; G=; Y=; R=; D=; N=; fi
say()  { printf '%s\n' "$*"; }
log()  { printf '%s %s\n' "$(date '+%Y-%m-%dT%H:%M:%S')" "$*" >> "$LOGFILE" 2>/dev/null; }
die()  { printf '%s%s%s\n' "$R" "$*" "$N" >&2; exit 1; }

if [ "$(uname -s)" = "Darwin" ]; then
  fsize()  { stat -f %z "$1" 2>/dev/null || echo 0; }
  fmtime() { stat -f %m "$1" 2>/dev/null || echo 0; }
  fdev()   { stat -f %d "$1" 2>/dev/null; }
else
  fsize()  { stat -c %s "$1" 2>/dev/null || echo 0; }
  fmtime() { stat -c %Y "$1" 2>/dev/null || echo 0; }
  fdev()   { stat -c %d "$1" 2>/dev/null; }
fi
sha() { if command -v shasum >/dev/null 2>&1; then shasum -a 256; else sha256sum; fi | cut -d' ' -f1; }
hk()  { LC_ALL=C awk -v k="${1:-0}" 'BEGIN{ if(k>=1048576) printf "%.1f GB",k/1048576; else if(k>=1024) printf "%.1f MB",k/1024; else printf "%d KB",k }'; }
abbr(){ case "$1" in "$HOME_DIR"/*) printf '~/%s' "${1#$HOME_DIR/}";; *) printf '%s' "$1";; esac; }
exists(){ [ -e "$1" ] || [ -L "$1" ]; }
rp()  { ( cd -P "$1" 2>/dev/null && pwd -P ); }

# ---------- safety primitives ----------
icloud_active() { [ -d "$HOME_DIR/Library/Mobile Documents/com~apple~CloudDocs" ]; }

storage_class() {
  local p="$1"
  case "$p" in
    *.photoslibrary|*.photoslibrary/*) echo PHOTOS_LIBRARY; return;;
    */Library/Mobile\ Documents|*/Library/Mobile\ Documents/*|*/Library/CloudStorage|*/Library/CloudStorage/*) echo FILE_PROVIDER-CLOUD; return;;
    /System|/System/*|/usr|/usr/*|/bin|/bin/*|/sbin|/sbin/*|/private/var/db|/private/var/db/*) echo PROTECTED; return;;
    /Volumes/*) echo EXTERNAL_OR_NETWORK; return;;
  esac
  if icloud_active; then
    case "$p" in "$HOME_DIR/Desktop"|"$HOME_DIR/Desktop/"*|"$HOME_DIR/Documents"|"$HOME_DIR/Documents/"*) echo FILE_PROVIDER-CLOUD; return;; esac
  fi
  echo LOCAL
}

is_broad() {  # home folder or anything that contains it
  local r h; r=$(rp "$1"); h=$(rp "$HOME_DIR")
  [ -z "$r" ] && return 1
  [ "$r" = "/" ] && return 0
  [ "$r" = "$h" ] && return 0
  case "$h" in "$r"/*) return 0;; esac
  return 1
}

bounded() {   # bounded SECS cmd args...   (output redirected by caller) ; 124 = timed out
  local secs=$1; shift
  "$@" & local pid=$!
  ( sleep "$secs"; kill "$pid" 2>/dev/null ) >/dev/null 2>&1 & local w=$!
  wait "$pid" 2>/dev/null; local rc=$?
  kill "$w" 2>/dev/null; wait "$w" 2>/dev/null
  [ "$rc" -ge 128 ] && return 124
  return "$rc"
}

DEADLINE=0; PARTIAL=0
dir_kb() {
  local rem=$(( DEADLINE - SECONDS )); [ "$rem" -lt 1 ] && rem=1
  : > "$TMP/du.out"
  bounded "$rem" du -sk "$1" > "$TMP/du.out" 2>/dev/null
  if [ $? -eq 124 ]; then PARTIAL=1; echo 0; return; fi
  awk 'NR==1{print $1+0; found=1} END{if(!found) print 0}' "$TMP/du.out"
}

# managed trees: VCS/projects, backups, LKG snapshots, content-addressed stores, hidden, review folders, our quarantine
managed_dirs() {
  find "$1" -maxdepth 8 -type d \( -name '.*' -o -name Library -o -name '#[Rr]eview*' -o -iname '*backup*' -o -iname '*lkg*' \
       -o -name objects -o -name blobs -o -name node_modules -o -name vendor -o -name Pods -o -name DerivedData -o -name snapshots \) -print 2>/dev/null
  find "$1" -maxdepth 8 \( -name .git -o -name Package.swift -o -name package.json -o -name Cargo.toml -o -name pyproject.toml \
       -o -name build.gradle -o -name build.gradle.kts -o -name pom.xml -o -name go.mod -o -name Podfile \) -print 2>/dev/null \
    | while IFS= read -r f; do dirname "$f"; done
  printf '%s\n' "$QROOT"
}
filter_managed() {   # $1 = file of managed dirs ; stdin paths -> stdout paths that are NOT inside one
  awk -v mf="$1" 'BEGIN{ while((getline l < mf)>0) if(l!="") m[++n]=l } { p=$0; ok=1; for(i=1;i<=n;i++){ d=m[i]; if(p==d || index(p, d "/")==1){ok=0;break} } if(ok) print p }'
}

confirm() {   # confirm "question"
  [ "$YES" = 1 ] && return 0
  printf '%s [y/N] ' "$1"; local a; read -r a </dev/tty 2>/dev/null || read -r a; [ "$a" = "y" ] || [ "$a" = "Y" ]
}

# ---------- candidate table ----------
print_table() {   # prints $LAST
  [ -s "$LAST" ] || { say "  (nothing to review)"; return; }
  printf '%s%4s  %-7s %10s  %-18s %s%s\n' "$D" ID SAFETY SIZE CATEGORY PATH "$N"
  while IFS="$TAB" read -r id safe kb cat path keeper; do
    printf '%4s  %-7s %10s  %-18s %s\n' "$id" "$safe" "$(hk "$kb")" "$cat" "$(abbr "$path")"
    [ -n "${keeper:-}" ] && printf '%s%35s keeps: %s%s\n' "$D" "" "$(abbr "$keeper")" "$N"
  done < "$LAST"
}

finish_scan() {   # sorts $TMP/cands.tsv -> $LAST, prints
  local limit=${1:-60}
  if [ -s "$TMP/cands.tsv" ]; then
    sort -t "$TAB" -k2,2nr "$TMP/cands.tsv" | head -n "$limit" | awk -F'\t' 'BEGIN{OFS="\t"} {print NR,$1,$2,$3,$4,$5}' > "$LAST"
  else : > "$LAST"; fi
  say; print_table
  local tot; tot=$(awk -F'\t' '$2=="SAFE"{s+=$3} END{print s+0}' "$LAST")
  say; say "${B}SAFE items: $(hk "$tot")${N}  — review, then: janitor quarantine --all-safe   |   janitor quarantine ID...   |   janitor delete ID..."
  log "scan: $(wc -l < "$LAST" | tr -d ' ') candidates, safe $(hk "$tot")"
}

# ---------- scan ----------
collect() {   # collect DIR CATEGORY SAFETY "skip|names"
  local dir=$1 cat=$2 safe=$3 skip=$4 cls p name kb s status
  [ -d "$dir" ] || return 0
  cls=$(storage_class "$dir")
  if [ "$cls" != LOCAL ]; then printf '  %-11s %s (%s) — not traversed\n' "[DEFERRED]" "$(abbr "$dir")" "$cls"; return 0; fi
  if ! ls -A "$dir" >/dev/null 2>&1; then printf '  %-11s %s — not readable (grant your terminal Full Disk Access)\n' "[SKIPPED]" "$(abbr "$dir")"; return 0; fi
  DEADLINE=$((SECONDS+BUDGET)); PARTIAL=0
  for p in "$dir"/* "$dir"/.[!.]*; do
    exists "$p" || continue
    [ -L "$p" ] && continue
    name=${p##*/}
    case "|$skip|" in *"|$name|"*) continue;; esac
    case "$p" in *"$TAB"*) continue;; esac
    if [ "$SECONDS" -ge "$DEADLINE" ]; then PARTIAL=1; break; fi
    kb=$(dir_kb "$p")
    [ "${kb:-0}" -ge 100 ] || continue
    s=$safe
    case "$cat:$name" in CACHE:com.apple.*) s=REVIEW;; esac
    printf '%s\t%s\t%s\t%s\t\n' "$s" "$kb" "$cat" "$p" >> "$TMP/cands.tsv"
  done
  [ "$PARTIAL" = 1 ] && status=PARTIAL || status=COMPLETE
  printf '  %-11s %s\n' "[$status]" "$(abbr "$dir")"
}

collect_stale_tmp() {
  local t="${TMPDIR:-/tmp}" p kb
  [ -d "$t" ] || return 0
  DEADLINE=$((SECONDS+BUDGET)); PARTIAL=0
  find "$t" -maxdepth 1 -mindepth 1 -mtime +14 -print 2>/dev/null | while IFS= read -r p; do
    case "$p" in "$TMP"|"$TMP"/*) continue;; esac
    [ -L "$p" ] && continue
    kb=$(dir_kb "$p"); [ "${kb:-0}" -ge 100 ] || continue
    printf 'SAFE\t%s\tSTALE TEMP\t%s\t\n' "$kb" "$p" >> "$TMP/cands.tsv"
  done
  printf '  %-11s %s (older than 14 days)\n' "[COMPLETE]" "$(abbr "$t")"
}

cmd_scan() {
  local mode="${1:-quick}"
  : > "$TMP/cands.tsv"
  say "${B}JANITOR $VERSION — $mode scan${N}  (bounded: ${BUDGET}s per root, home folder is never crawled)"
  collect "$HOME_DIR/Library/Caches" CACHE SAFE "Homebrew|com.janitor.native"
  collect "$HOME_DIR/Library/Logs"   LOG   SAFE "JANITOR"
  collect "$HOME_DIR/.Trash"         TRASH SAFE ""
  collect_stale_tmp
  if [ "$mode" = full ]; then
    local c
    for c in "$HOME_DIR"/Library/Containers/*/Data/Library/Caches; do
      [ -d "$c" ] && collect "$c" "CONTAINER CACHE" SAFE ""
    done
  fi
  [ -d "$HOME_DIR/Library/Caches/Homebrew" ] && say "  ${D}Homebrew cache present — not junk. Use: brew cleanup${N}"
  finish_scan 60
}

# ---------- duplicates ----------
cmd_dupes() {
  : > "$TMP/roots"; : > "$TMP/cands.tsv"
  local r
  for r in "$@"; do
    if [ ! -d "$r" ]; then say "SKIPPED: $r is not a folder"; continue; fi
    if is_broad "$r"; then say "${R}REFUSED${N}: $(abbr "$r") is your home folder (or above it). Duplicate scans never run there."; continue; fi
    echo "$(rp "$r")" >> "$TMP/roots"
  done
  if [ ! -s "$TMP/roots" ]; then
    for r in Movies Music Pictures Downloads; do [ -d "$HOME_DIR/$r" ] && echo "$HOME_DIR/$r" >> "$TMP/roots"; done
  fi
  say "${B}JANITOR $VERSION — exact duplicates${N}  (files ≥ 1 MB; managed trees, hidden, backup/LKG, projects, quarantine, cloud and Photos excluded)"
  : > "$TMP/files"
  while IFS= read -r r; do
    local cls; cls=$(storage_class "$r")
    if [ "$cls" != LOCAL ]; then printf '  %-11s %s (%s)\n' "[DEFERRED]" "$(abbr "$r")" "$cls"; continue; fi
    managed_dirs "$r" > "$TMP/managed"
    if awk -v r="$r" '$0==r{f=1} END{exit !f}' "$TMP/managed"; then printf '  %-11s %s looks like a managed tree\n' "[EXCLUDED]" "$(abbr "$r")"; continue; fi
    bounded $((BUDGET*2)) find "$r" -maxdepth 6 \( -name '*.photoslibrary' -o -path '*/Library/CloudStorage' -o -path '*/Library/Mobile Documents' \) -prune -o -type f -size +1024k -print > "$TMP/found" 2>/dev/null
    local rc=$?; local st=COMPLETE; [ $rc -eq 124 ] && st=PARTIAL
    filter_managed "$TMP/managed" < "$TMP/found" >> "$TMP/files"
    printf '  %-11s %s\n' "[$st]" "$(abbr "$r")"
  done < "$TMP/roots"
  # size groups
  : > "$TMP/sz"
  while IFS= read -r p; do
    case "$p" in *"$TAB"*) continue;; esac
    printf '%s\t%s\n' "$(fsize "$p")" "$p" >> "$TMP/sz"
  done < "$TMP/files"
  awk -F'\t' 'NR==FNR{c[$1]++;next} c[$1]>1' "$TMP/sz" "$TMP/sz" > "$TMP/sz2"
  local HDEAD=$((SECONDS+BUDGET*5)) partial=0
  : > "$TMP/ph"
  while IFS="$TAB" read -r size p; do
    if [ "$SECONDS" -ge "$HDEAD" ]; then partial=1; break; fi
    printf '%s|%s\t%s\n' "$size" "$(head -c 65536 "$p" 2>/dev/null | sha)" "$p" >> "$TMP/ph"
  done < "$TMP/sz2"
  awk -F'\t' 'NR==FNR{c[$1]++;next} c[$1]>1' "$TMP/ph" "$TMP/ph" > "$TMP/ph2"
  : > "$TMP/full"
  while IFS="$TAB" read -r key p; do
    if [ "$SECONDS" -ge "$HDEAD" ]; then partial=1; break; fi
    printf '%s\t%s\t%s\t%s\n' "$(sha < "$p" 2>/dev/null)" "$(fsize "$p")" "$(fmtime "$p")" "$p" >> "$TMP/full"
  done < "$TMP/ph2"
  awk -F'\t' 'NR==FNR{c[$1]++;next} c[$1]>1' "$TMP/full" "$TMP/full" | sort -t "$TAB" -k1,1 -k3,3n \
    | awk -F'\t' '{ if($1!=last){keeper=$4; last=$1} else printf "REVIEW\t%d\tEXACT DUPLICATE\t%s\t%s\n", $2/1024, $4, keeper }' > "$TMP/cands.tsv"
  [ "$partial" = 1 ] && say "  ${Y}PARTIAL — time budget reached; run again or narrow the folder${N}"
  finish_scan 300
  say "${D}Oldest copy is kept. Items are never auto-deleted; the kept copy is verified before any removal.${N}"
}

# ---------- quarantine ----------
select_rows() {   # args: ids or --all-safe ; writes $TMP/sel.tsv
  [ -s "$LAST" ] || die "No scan results. Run: janitor scan | janitor dupes"
  : > "$TMP/sel.tsv"
  if [ "${1:-}" = "--all-safe" ]; then awk -F'\t' '$2=="SAFE"' "$LAST" > "$TMP/sel.tsv"
  else
    local id; for id in "$@"; do awk -F'\t' -v i="$id" '$1==i' "$LAST" >> "$TMP/sel.tsv"; done
  fi
  [ -s "$TMP/sel.tsv" ] || die "Nothing selected."
}

keeper_ok() {   # keeper_ok path keeper -> 0 ok
  local p=$1 k=$2
  [ -z "$k" ] && return 0
  exists "$k" || return 1
  awk -F'\t' -v k="$k" '$5==k{f=1} END{exit f?0:1}' "$TMP/sel.tsv" && return 1
  [ -f "$p" ] && [ "$(fsize "$k")" != "$(fsize "$p")" ] && return 1
  return 0
}

cmd_quarantine() {
  select_rows "$@"
  local n tot; n=$(wc -l < "$TMP/sel.tsv" | tr -d ' '); tot=$(awk -F'\t' '{s+=$3} END{print s+0}' "$TMP/sel.tsv")
  say "About to move $n item(s) ($(hk "$tot")) to quarantine at $(abbr "$QROOT")"
  confirm "Proceed?" || { say "Cancelled."; return 1; }
  mkdir -p "$QROOT" 2>/dev/null || die "Cannot create quarantine root"
  [ "$(storage_class "$QROOT")" = LOCAL ] || die "Quarantine root is not LOCAL storage ($(storage_class "$QROOT")); provider-safe quarantine is not supported in the terminal edition."
  local op; op="$(date +%Y%m%d-%H%M%S)-janitor"; local dir="$QROOT/$op"; mkdir -p "$dir/items" || die "Cannot create $dir"
  local man="$dir/manifest.tsv"; printf '# JANITOR %s quarantine %s\n# state\toriginal\tdestination\tkb\treason\ttimestamp\n' "$VERSION" "$op" > "$man"
  local i=0 moved=0 failed=0 skipped=0 missing=0 id safe kb cat path keeper dest ts
  while IFS="$TAB" read -r id safe kb cat path keeper; do
    i=$((i+1))
    if ! exists "$path"; then printf '  %sMISSING %s %s\n' "$Y" "$N" "$(abbr "$path")"; missing=$((missing+1)); continue; fi
    case "$path" in "$QROOT"/*) printf '  SKIPPED  %s (already in quarantine)\n' "$(abbr "$path")"; skipped=$((skipped+1)); continue;; esac
    local pc; pc=$(storage_class "$(dirname "$path")")
    if [ "$pc" != LOCAL ]; then printf '  SKIPPED  %s (%s)\n' "$(abbr "$path")" "$pc"; skipped=$((skipped+1)); continue; fi
    if [ "$(fdev "$(dirname "$path")")" != "$(fdev "$dir/items")" ]; then printf '  SKIPPED  %s (different volume — a move would copy)\n' "$(abbr "$path")"; skipped=$((skipped+1)); continue; fi
    if ! keeper_ok "$path" "${keeper:-}"; then printf '  SKIPPED  %s (kept copy missing, changed or also selected)\n' "$(abbr "$path")"; skipped=$((skipped+1)); continue; fi
    dest="$dir/items/$(printf '%03d' "$i")-${path##*/}"
    if mv -n "$path" "$dest" 2>/dev/null && ! exists "$path" && exists "$dest"; then
      ts=$(date '+%Y-%m-%dT%H:%M:%S'); printf 'MOVED\t%s\t%s\t%s\t%s\t%s\n' "$path" "$dest" "$kb" "$cat" "$ts" >> "$man"
      printf '  %sMOVED   %s %s\n' "$G" "$N" "$(abbr "$path")"; moved=$((moved+1))
    else printf '  %sFAILED  %s %s\n' "$R" "$N" "$(abbr "$path")"; failed=$((failed+1)); fi
  done < "$TMP/sel.tsv"
  say; say "${B}$moved MOVED · $failed FAILED · $skipped SKIPPED · $missing MISSING${N}  → $op"
  say "Space is freed when the quarantine is purged. Restore with: janitor restore $op"
  log "quarantine $op moved=$moved failed=$failed skipped=$skipped missing=$missing"
}

cmd_delete() {
  select_rows "$@"
  local n tot; n=$(wc -l < "$TMP/sel.tsv" | tr -d ' '); tot=$(awk -F'\t' '{s+=$3} END{print s+0}' "$TMP/sel.tsv")
  say "${R}PERMANENTLY delete $n item(s) ($(hk "$tot"))? This cannot be undone. Prefer 'quarantine'.${N}"
  if [ "$YES" != 1 ]; then printf 'Type DELETE to confirm: '; local a; read -r a </dev/tty 2>/dev/null || read -r a; [ "$a" = "DELETE" ] || { say "Cancelled."; return 1; }; fi
  local gone=0 failed=0 skipped=0 freed=0 id safe kb cat path keeper
  while IFS="$TAB" read -r id safe kb cat path keeper; do
    if ! exists "$path"; then printf '  MISSING  %s\n' "$(abbr "$path")"; continue; fi
    local comps; comps=$(printf '%s' "$path" | awk -F/ '{print NF-1}')
    if [ "$comps" -lt 3 ] || [ "$(storage_class "$(dirname "$path")")" != LOCAL ] || ! keeper_ok "$path" "${keeper:-}"; then
      printf '  SKIPPED  %s\n' "$(abbr "$path")"; skipped=$((skipped+1)); continue; fi
    rm -rf -- "$path" 2>/dev/null
    if exists "$path"; then printf '  %sFAILED  %s %s\n' "$R" "$N" "$(abbr "$path")"; failed=$((failed+1))
    else printf '  %sDELETED %s %s\n' "$G" "$N" "$(abbr "$path")"; gone=$((gone+1)); freed=$((freed+kb)); fi
  done < "$TMP/sel.tsv"
  say; say "${B}$gone DELETED · $failed FAILED · $skipped SKIPPED${N} — removed $(hk "$freed") (size from scan; removal verified per item)"
  log "delete deleted=$gone failed=$failed skipped=$skipped freed_kb=$freed"
}

refresh_manifest() {   # mark MOVED rows whose destination vanished as MISSING
  local man="$1" out="$TMP/man.new" line state rest dest
  : > "$out"
  while IFS= read -r line; do
    case "$line" in "#"*|"") printf '%s\n' "$line" >> "$out"; continue;; esac
    state=${line%%$TAB*}; rest=${line#*$TAB}
    if [ "$state" = MOVED ]; then dest=$(printf '%s' "$rest" | awk -F'\t' '{print $2}'); exists "$dest" || line="MISSING${TAB}${rest}"; fi
    printf '%s\n' "$line" >> "$out"
  done < "$man"
  cmp -s "$out" "$man" || cp "$out" "$man"
}

cmd_list() {
  [ -d "$QROOT" ] || { say "No quarantine yet ($(abbr "$QROOT"))."; return; }
  local d any=0
  for d in "$QROOT"/*/; do
    [ -f "${d}manifest.tsv" ] || continue; any=1
    refresh_manifest "${d}manifest.tsv"
    printf '%s  %s\n' "$(basename "$d")" "$(awk -F'\t' '!/^#/ && NF>0 {c[$1]++} END{for(s in c) printf "%d %s  ", c[s], s}' "${d}manifest.tsv")"
  done
  [ "$any" = 0 ] && say "No quarantine operations."
}

cmd_show() {
  local op="${1:-}"; [ -n "$op" ] && [ -f "$QROOT/$op/manifest.tsv" ] || die "Usage: janitor show OP   (see: janitor list)"
  refresh_manifest "$QROOT/$op/manifest.tsv"
  awk -F'\t' '!/^#/ && NF>0 {n++; printf "%3d  %-8s %s\n", n, $1, $2}' "$QROOT/$op/manifest.tsv"
}

uniq_target() {
  local t="$1" base ext dir n=1 cand
  dir=$(dirname "$t"); base=$(basename "$t")
  case "$base" in *.*) ext=".${base##*.}"; base="${base%.*}";; *) ext="";; esac
  while :; do cand="$dir/$base (restored $n)$ext"; exists "$cand" || { printf '%s' "$cand"; return; }; n=$((n+1)); done
}

cmd_restore() {
  local op="${1:-}"; shift 2>/dev/null
  [ -n "$op" ] && [ -f "$QROOT/$op/manifest.tsv" ] || die "Usage: janitor restore OP [N ...]"
  local man="$QROOT/$op/manifest.tsv"; refresh_manifest "$man"
  local out="$TMP/man.rs"; : > "$out"; local n=0 line state rest orig dest pick want ok=0 miss=0 fail=0
  while IFS= read -r line; do
    case "$line" in "#"*|"") printf '%s\n' "$line" >> "$out"; continue;; esac
    n=$((n+1)); state=${line%%$TAB*}; rest=${line#*$TAB}
    orig=$(printf '%s' "$rest" | awk -F'\t' '{print $1}'); dest=$(printf '%s' "$rest" | awk -F'\t' '{print $2}')
    want=1; if [ $# -gt 0 ]; then want=0; for pick in "$@"; do [ "$pick" = "$n" ] && want=1; done; fi
    if [ "$want" = 1 ] && [ "$state" = MISSING ]; then printf '  MISSING  %s (removed from quarantine)\n' "$(abbr "$orig")"; miss=$((miss+1)); fi
    if [ "$want" = 1 ] && [ "$state" = MOVED ]; then
      if ! exists "$dest"; then printf '  MISSING  %s (removed from quarantine)\n' "$(abbr "$orig")"; line="MISSING${TAB}${rest}"; miss=$((miss+1))
      else
        local target="$orig"; mkdir -p "$(dirname "$orig")" 2>/dev/null
        exists "$target" && target=$(uniq_target "$orig")
        if mv -n "$dest" "$target" 2>/dev/null && exists "$target" && ! exists "$dest"; then
          printf '  %sRESTORED%s %s%s\n' "$G" "$N" "$(abbr "$target")" "$([ "$target" != "$orig" ] && printf ' (original path was occupied)')"
          line="RESTORED${TAB}${rest}"; ok=$((ok+1))
        else printf '  %sFAILED  %s %s\n' "$R" "$N" "$(abbr "$orig")"; fail=$((fail+1)); fi
      fi
    fi
    printf '%s\n' "$line" >> "$out"
  done < "$man"
  cp "$out" "$man"; say; say "${B}$ok RESTORED · $miss MISSING · $fail FAILED${N}"; log "restore $op ok=$ok missing=$miss failed=$fail"
}

cmd_purge() {
  local op="${1:-}"; [ -n "$op" ] && [ -d "$QROOT/$op" ] || die "Usage: janitor purge OP"
  confirm "Permanently delete quarantine operation $op? Items inside can no longer be restored." || { say Cancelled.; return 1; }
  rm -rf -- "${QROOT:?}/$op"; exists "$QROOT/$op" && die "FAILED: still present" || say "DELETED $op"; log "purge $op"
}

cmd_diag() {
  say "${B}JANITOR $VERSION diagnostics${N}"
  say "macOS: $(sw_vers -productVersion 2>/dev/null || uname -sr) · $(uname -m) · shell bash ${BASH_VERSION}"
  local t; for t in find du stat shasum head awk sort mv rm brew tmutil diskutil; do printf '  %-9s %s\n' "$t" "$(command -v "$t" || echo 'not found')"; done
  say "iCloud Drive present: $(icloud_active && echo 'yes — Desktop/Documents treated as cloud-managed' || echo no)"
  say "Trash readable: $(ls -A "$HOME_DIR/.Trash" >/dev/null 2>&1 && echo yes || echo 'no (grant Full Disk Access to your terminal)')"
  say "Quarantine root: $(abbr "$QROOT") — class $(storage_class "$QROOT") — $( [ -d "$QROOT" ] && echo exists || echo 'not created yet')"
  say "Logs: $(abbr "$LOGS")   State: $(abbr "$STATE")"
}

cmd_help() {
cat <<EOF
JANITOR $VERSION — safe cleanup, quarantine and recovery (terminal edition)
  janitor scan [quick|full]      bounded scan of caches, logs, Trash, stale temp → numbered candidates
  janitor dupes [FOLDER...]      exact duplicates (default: Movies Music Pictures Downloads; never your home folder)
  janitor quarantine ID...|--all-safe   move selected candidates into the reviewable quarantine (verified)
  janitor delete ID...           permanent delete (type DELETE to confirm)
  janitor list | show OP         quarantine operations / items
  janitor restore OP [N...]      restore all or selected items (collision-safe; missing items tolerated)
  janitor purge OP               permanently delete one quarantine operation
  janitor diag                   environment and permission check
Options: -y/--yes skip confirmation prompts (for scripts)   env: JANITOR_BUDGET, JANITOR_QUARANTINE, JANITOR_HOME
Unknown != junk. Cloud/File Provider storage and Photos libraries are never traversed or modified here.
EOF
}

# ---------- main ----------
args=(); for a in "$@"; do case "$a" in -y|--yes) YES=1;; *) args[${#args[@]}]="$a";; esac; done
cmd="${args[0]:-help}"
rest=(); i=1; while [ $i -lt ${#args[@]} ]; do rest[${#rest[@]}]="${args[$i]}"; i=$((i+1)); done
set -- ${rest[@]+"${rest[@]}"}
case "$cmd" in
  scan) cmd_scan "$@";;  dupes) cmd_dupes "$@";;  quarantine|q) cmd_quarantine "$@";;  delete) cmd_delete "$@";;
  list|ls) cmd_list;;  show) cmd_show "$@";;  restore) cmd_restore "$@";;  purge) cmd_purge "$@";;
  diag) cmd_diag;;  help|-h|--help) cmd_help;;  version|--version) say "$VERSION";;
  *) cmd_help; exit 2;;
esac
