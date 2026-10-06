# Regression report

Protected capability list: `App/PROTECTED_CAPABILITIES.md`, `App/REGRESSION_CONTRACT.md` (as received).

## Executed in the authoring sandbox (Linux; Python/shell only)
| Suite | Result | Meaning |
|---|---|---|
| Protected-contract tests (identity, tabs, calibration order/titles, timing, scoring, content, assets, hazards) | **26/26 pass** | STATIC evidence on source text |
| Same suite against the AS-RECEIVED candidate (earlier version of the tests) | 22 ran, **3 failed** (calibration logic in view; JUMP title; empty entitlements) | the baseline that drove repairs D-004/D-006/D-007 |
| As-received defect reproduction (faithful matcher port) | 2/2 reproduce D-001, D-002 | defects were real in the received logic |
| Engine mirror scenarios (Python mirror of calibration/match/timeline) | **24/24 pass** | corroborates the algorithms; NOT the Swift code |
| Asset-factory suite (retarget FK round trip, coach-pose port sync + periodicity, provenance gate, bone aliases, runtime validator, clip manifest) | **23/23 pass** | Python tooling |
| DeviceSupport guard behaviour (fake tree) | **12/12 pass** | shell logic |
| `Tools/verify_all.py` | 16 STATIC PASS, 0 FAIL, 4 UNKNOWN | UNKNOWN = zsh scripts unchecked, no INVENTORY (working tree), assets not generated, visual quality |

## Written but NOT executed (need macOS/Xcode)
Engine XCTest: 31 test functions. App `SWAYSmokeTests`: 6. **State: IMPLEMENTED, not BUILT, not TESTED.**

## Not executed anywhere
Simulator run, physical device, Blender, performance, thermal. **UNKNOWN.**

## Regression risk notes
Protected Build 147 tracking path (`CameraPoseService`) is untouched. Scoring changed (D-001/2/3); calibration rewired (D-004); tempo floor (D-005); entitlements (D-007). These are the areas to watch first on the Mac.
