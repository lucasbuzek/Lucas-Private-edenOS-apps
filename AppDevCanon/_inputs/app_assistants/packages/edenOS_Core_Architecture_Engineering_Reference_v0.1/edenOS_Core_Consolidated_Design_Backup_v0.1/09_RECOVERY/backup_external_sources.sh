#!/usr/bin/env bash
set -euo pipefail
STAMP=$(date +%Y%m%d_%H%M%S)
ROOT="${1:-EDEN_external_source_backup_$STAMP}"
mkdir -p "$ROOT"
clone() { name="$1"; url="$2"; echo "== $name =="; git clone --depth 1 "$url" "$ROOT/$name"; git -C "$ROOT/$name" rev-parse HEAD >> "$ROOT/COMMITS.txt"; }
clone OpenMower https://github.com/Gigabyte00/openmower.git
clone Acorn https://github.com/Twisted-Fields/acorn-precision-farming-rover.git
clone AgOpenGPS https://github.com/AgOpenGPS-Official/AgOpenGPS.git
clone BlueOS https://github.com/bluerobotics/BlueOS.git
clone Open_RMF https://github.com/open-rmf/rmf.git
printf '
NOTE: Large ecosystems such as PX4, ArduPilot, ROS 2/Nav2/Gazebo are intentionally referenced by URL rather than automatically cloned. Add them only when actively implementing that adapter to avoid a bloated backup.
' >> "$ROOT/COMMITS.txt"
tar -czf "${ROOT}.tar.gz" "$ROOT"
echo "Created ${ROOT}.tar.gz"
