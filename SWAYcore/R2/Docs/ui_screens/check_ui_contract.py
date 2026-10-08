#!/usr/bin/env python3
"""Static release-UI ownership and navigation checks for non-Xcode hosts."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
VIEWS = ROOT / "App" / "SWAY" / "Views"
root = (VIEWS / "RootView.swift").read_text()
screens = "\n".join(path.read_text() for path in (VIEWS / "Screens").glob("*.swift"))

required_tabs = ['Label("Home"', 'Label("Moves"', 'Label("Beats"', 'Label("Profile"']
required_views = [
    "SWAYHomeScreen", "SWAYWorkoutSetupScreen", "SWAYWorkoutScreen",
    "SWAYWorkoutEndedScreen", "SWAYMovesScreen", "SWAYLearnMoveScreen",
    "SWAYCreateMoveScreen", "SWAYBeatsScreen", "SWAYProgressScreen",
    "SWAYCalibrationScreen", "SWAYProfileScreen", "SWAYAvatarCreatorScreen",
    "SWAYRecordPreviewScreen", "SWAYPermissionDeniedView", "SWAYOnboardingScreen",
]

for marker in required_tabs:
    assert marker in root, f"missing navigation tab: {marker}"
for view in required_views:
    assert f"struct {view}" in screens, f"missing screen: {view}"
assert "SWAYCharacterStage(" in screens, "release screens do not use frozen stage"
assert "SWAYAvatarCatalog.options" in screens and "SWAYAvatarCatalog.apply" in screens
for debug_view in ("CameraLabView()", "NativeLabView()", "StickFigureView("):
    assert debug_view not in root, f"debug view leaked into root navigation: {debug_view}"
assert "diagnosticsUnlocked" in screens and "taps >= 7" in screens

print(f"PASS: {len(required_views)} release screens, four canonical tabs, frozen avatar APIs, hidden diagnostics")
