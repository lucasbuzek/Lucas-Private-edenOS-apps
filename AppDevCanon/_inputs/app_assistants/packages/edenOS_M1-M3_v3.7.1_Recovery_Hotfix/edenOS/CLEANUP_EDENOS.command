#!/bin/zsh
set -euo pipefail

# edenOS development workspace consolidator / cleanup
# Safety: scans only ~/Downloads for recognized edenOS development artifacts.
# Default is review; destructive removal always requires explicit confirmation.

DOWNLOADS="$HOME/Downloads"
CANON="$DOWNLOADS/edenOS"
MODE="interactive"
[[ "${1:-}" == "--scan-only" ]] && MODE="scan"

print ""
print "edenOS Cleanup & Consolidation v3.7"
print "Canonical workspace: $CANON"
print "Scope: $DOWNLOADS only"
print ""

mkdir -p "$CANON"/{cache,build,builds,images,logs,data,config,releases,tools} 2>/dev/null || true

# Recognized legacy workspaces. Never scan arbitrary user folders.
typeset -a roots
for p in "$DOWNLOADS"/edenOS\ *(N) "$DOWNLOADS"/edenOS_*(N) "$DOWNLOADS"/edenosfix(N); do
  [[ -e "$p" ]] || continue
  [[ "$p" == "$CANON" ]] && continue
  [[ -d "$p" ]] && roots+=("$p")
done

# Recognized release archives/images only; excludes canonical runtime images directory.
typeset -a archives
for p in "$DOWNLOADS"/edenOS*.zip(N) "$DOWNLOADS"/edenOS*.iso(N) "$DOWNLOADS"/edenOS*.dmg(N) "$DOWNLOADS"/edenOS*.sha256(N); do
  [[ -e "$p" ]] || continue
  [[ -f "$p" ]] && archives+=("$p")
done

human_size() { du -sh "$1" 2>/dev/null | awk '{print $1}' || print "?"; }

print "Found legacy edenOS folders: ${#roots[@]}"
for p in "${roots[@]}"; do print "  [REVIEW] $(basename "$p")  ($(human_size "$p"))"; done
print "Found old edenOS release files: ${#archives[@]}"
for p in "${archives[@]}"; do print "  [REVIEW] $(basename "$p")  ($(human_size "$p"))"; done

[[ "$MODE" == "scan" ]] && { print "\nSCAN ONLY: no files changed."; exit 0; }
[[ ${#roots[@]} -eq 0 && ${#archives[@]} -eq 0 ]] && { print "\nNothing to consolidate or clean."; exit 0; }

print ""
print "Persistent material that can be consolidated before deletion:"
print "  cache/ images/ data/ config/ logs/ builds/ releases/"
print "Source/release files are NOT silently merged over the current release."
print ""
print "Choose:"
print "  [C] Consolidate persistent material only; delete nothing"
print "  [A] Consolidate, then offer recommended deletions"
print "  [R] Review each legacy item"
print "  [Q] Quit"
read "choice?> "
choice="${choice:u}"
[[ "$choice" == "Q" || -z "$choice" ]] && exit 0

copy_unique_tree() {
  local src="$1" dst="$2"
  [[ -d "$src" ]] || return 0
  mkdir -p "$dst"
  # ditto merges directories and preserves macOS metadata. Existing destination files win
  # unless source has a unique relative path; rsync --ignore-existing is preferred when available.
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --ignore-existing "$src/" "$dst/"
  else
    # Copy only absent files without overwriting canonical state.
    (cd "$src" && find . -type f -print0) | while IFS= read -r -d '' rel; do
      [[ -e "$dst/$rel" ]] && continue
      mkdir -p "$(dirname "$dst/$rel")"
      cp -p "$src/$rel" "$dst/$rel"
    done
  fi
}

consolidate_root() {
  local r="$1"
  print "Consolidating: $r"
  for d in cache images data config logs builds releases; do
    copy_unique_tree "$r/$d" "$CANON/$d"
  done
  # Historical packages used singular build/. Preserve unique evidence under builds/legacy-<folder>.
  if [[ -d "$r/build" ]]; then
    local legacy="$CANON/builds/legacy-$(basename "$r" | tr ' /' '__')"
    copy_unique_tree "$r/build" "$legacy"
  fi
}

for r in "${roots[@]}"; do consolidate_root "$r"; done
print "\nConsolidation complete. Canonical persistent data was not overwritten."

[[ "$choice" == "C" ]] && { print "No deletions performed."; exit 0; }

confirm_delete() {
  local p="$1" label="$2"
  print ""
  print "$label"
  print "  $p"
  print "  Size: $(human_size "$p")"
  read "ans?Delete this item? [y/N] "
  [[ "${ans:l}" == "y" || "${ans:l}" == "yes" ]] || return 0
  rm -rf -- "$p"
  print "  Deleted."
}

if [[ "$choice" == "A" ]]; then
  print "\nRecommended cleanup: legacy versioned workspaces and old release archives."
  print "Each deletion still requires confirmation."
fi

for r in "${roots[@]}"; do confirm_delete "$r" "Legacy edenOS workspace"; done
for p in "${archives[@]}"; do confirm_delete "$p" "Old edenOS release artifact"; done

print "\nedenOS cleanup complete."
print "Canonical workspace retained: $CANON"
