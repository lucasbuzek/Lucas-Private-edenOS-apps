#!/bin/bash
# Xcode DeviceSupport / dyld-shared-cache safety guard. SOURCE this file. bash 3.2 compatible.
#
# Background (root cause UNKNOWN, per handoff): physical-device preparation once consumed large disk via dyld shared-cache copying/extraction.
# This guard NEVER deletes anything. It detects low free disk, incomplete/locked DeviceSupport entries and runaway growth, then STOPS with diagnostics.
# Cleanup is a human decision: the guard only names the single folder that appears incomplete.

DS_ROOTS_DEFAULT="$HOME/Library/Developer/Xcode/iOS DeviceSupport"
free_gb() { local kb; kb="$(df -Pk "$1" 2>/dev/null | awk 'NR==2{print $4}')"; echo $(( ${kb:-0} / 1024 / 1024 )); }
dir_mb()  { du -sk "$1" 2>/dev/null | awk '{printf "%d", $1/1024}'; }

# require_free_gb <path> <minGB> <label> -> 0 ok, 1 too low
require_free_gb() {
  local f; f="$(free_gb "$1")"
  if [ "$f" -lt "$2" ]; then echo "DISK: only ${f} GB free on the volume of $1; $3 needs >= $2 GB. Stopping safely (nothing deleted). Free space manually, then re-run."; return 1; fi
  echo "DISK: ${f} GB free (>= $2 GB required for $3)"; return 0
}

# devicesupport_audit [root] -> 0 healthy, 1 suspicious
devicesupport_audit() {
  local root="${1:-${SWAY_DEVICESUPPORT_ROOT:-$DS_ROOTS_DEFAULT}}" rc=0 d mb
  [ -d "$root" ] || { echo "DeviceSupport: no folder at '$root' (nothing prepared yet) - OK"; return 0; }
  local total; total="$(dir_mb "$root")"; echo "DeviceSupport: '$root' = ${total} MB"
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    if [ -e "$d/.copying_lock" ] || [ -e "$d/.copying_lock.lock" ]; then
      echo "DeviceSupport: LOCK present in '$d' (copy/extract in progress or interrupted)"; rc=1
    elif [ ! -d "$d/Symbols" ] && [ ! -e "$d/.finalized" ]; then
      mb="$(dir_mb "$d")"
      if [ "${mb:-0}" -gt 0 ]; then echo "DeviceSupport: INCOMPLETE entry ('$d', ${mb} MB, no Symbols folder)"; rc=1; fi
    fi
  done <<EOF2
$(find "$root" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
EOF2
  local limit="${SWAY_DEVICESUPPORT_MAX_MB:-60000}"
  if [ "${total:-0}" -gt "$limit" ]; then echo "DeviceSupport: total ${total} MB exceeds sanity limit ${limit} MB (many OS versions or runaway extraction)"; rc=1; fi
  return $rc
}

# devicesupport_growth_watch [root] [seconds] [maxGrowthMB] -> 1 if growing faster than the threshold
devicesupport_growth_watch() {
  local root="${1:-${SWAY_DEVICESUPPORT_ROOT:-$DS_ROOTS_DEFAULT}}" secs="${2:-5}" max="${3:-${SWAY_DEVICESUPPORT_MAX_GROWTH_MB:-400}}" a b g
  [ -d "$root" ] || return 0
  a="$(dir_mb "$root")"; sleep "$secs"; b="$(dir_mb "$root")"; g=$(( b - a ))
  echo "DeviceSupport growth over ${secs}s: ${g} MB"
  if [ "$g" -gt "$max" ]; then echo "DeviceSupport: GROWING ${g} MB in ${secs}s (> ${max} MB). Likely repeated dyld shared-cache extraction. Quit Xcode, disconnect the device, inspect '$root'."; return 1; fi
  return 0
}

# Full pre-device gate: disk -> audit -> growth. Prints a recovery hint but performs NO deletion.
devicesupport_gate() {
  local min="${SWAY_MIN_FREE_GB_DEVICE:-25}" rc=0
  require_free_gb "${SWAY_ROOT:-.}" "$min" "physical-device preparation" || rc=1
  require_free_gb "$HOME" "$min" "Xcode DeviceSupport (home volume)" || rc=1
  devicesupport_audit "$@" || rc=1
  devicesupport_growth_watch "$@" || rc=1
  if [ $rc -ne 0 ]; then
    echo "----- SAFE NEXT STEPS (no automatic deletion) -----"
    echo "1) Quit Xcode and unplug the device.  2) Identify the single incomplete/locked entry from the lines above."
    echo "3) Only that one '<device> <OS> (<build>)' folder is a removal candidate (Xcode regenerates it). Do NOT recursively delete ~/Library/Developer or other Xcode data."
    echo "4) Reconnect and let Xcode finish 'Preparing device' once, with at least ${min} GB free."
  fi
  return $rc
}
