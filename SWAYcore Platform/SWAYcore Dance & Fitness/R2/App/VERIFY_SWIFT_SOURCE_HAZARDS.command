#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
BUILD="$(awk '/CURRENT_PROJECT_VERSION:/ {print $2; exit}' project.yml)"
echo "SWAY Swift source hazard gate — Build $BUILD"
if grep -RInE '=([-+!<>])' --include='*.swift' SWAY; then
  echo "FAIL: ambiguous assignment/operator sequence found" >&2
  exit 1
fi
if grep -n 'StickFigureView(' SWAY/Views/StickFigureView.swift | awk -F: '$1>=424 && $1<=490 {bad=1} END{exit bad?0:1}'; then
  echo "FAIL: legacy StickFigureView selected inside SwayHumanFigureView" >&2
  exit 1
fi
grep -q 'SWAY-DURER-2.5D-v1.json in Resources' SWAY.xcodeproj/project.pbxproj
grep -q "CURRENT_PROJECT_VERSION = $BUILD" SWAY.xcodeproj/project.pbxproj
grep -q "INFOPLIST_KEY_CFBundleVersion = $BUILD" SWAY.xcodeproj/project.pbxproj
grep -q "INFOPLIST_KEY_CFBundleVersion: $BUILD" project.yml
echo "PASS: hazard/routing/resource/build-identity checks"
