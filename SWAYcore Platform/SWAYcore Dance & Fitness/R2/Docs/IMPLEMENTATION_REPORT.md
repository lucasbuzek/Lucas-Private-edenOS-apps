# Implementation report

Strategy: **recover, don't rewrite.** The received candidate (Build 153 line, 18 Swift files, ~6k lines, single `SWAY` target) was kept. Changes are narrow, each tied to evidence.

## Inventory (what exists, by evidence state)
| Area | State |
|---|---|
| Candidate source (HOME/MOVES/BEATS/PROFILE/YOU tabs, Learn, Create, Workout, Beats, MusicKit, Shazam, HealthKit, recorder, .swaypack v2, 20 authored coach moves) | GENERATED/IMPLEMENTED; historical device evidence for Build 143/147/153 is described in the handoff, **not re-verified here** |
| Lexical balance of all 18 files | STATIC PASS (real lexer). My earlier "805/803 parens" was a false positive of a naive regex on nested string interpolation; withdrawn. |
| Candidate's own Python test | not re-run as authority; its hazard scripts are shell/zsh |
| `SWAY.xcodeproj` as received | stale-risk; moved to `Reference/`; project is regenerated from `project.yml` |
| Avatars | 2.5D / cutout / primitive-rig: authority-rejected as final; kept as fallback only |

## Findings and repairs
| ID | Finding | Evidence | Repair | State |
|---|---|---|---|---|
| D-001 | Zero overlapping joints still scored PARTIAL (mean error defaulted to 90 deg, timing+continuity gave 0.585) | `Reports/evidence/defect_repro_D001_D002.txt` (faithful port) | `SwayMatchTruth` requires coverage | IMPLEMENTED; Swift test written; mirror scenario PASS |
| D-002 | 1 of 4 reference joints produced GOOD | same | same | same |
| D-003 | Poorly matched but well observed pose was indistinguishable from UNKNOWN (TRACKING), so adaptation could never see poor performance | source reading | `.notMatched` outcome/state | IMPLEMENTED; **behaviour change needing owner confirmation (U-07)** |
| D-004 | Calibration decisions lived inside a SwiftUI view; wave counted any wrist motion cumulatively (jitter could eventually pass); jump baseline fixed at first sighting (stepping away could look like a jump); progress survived tracking loss; no timeout/cancel/orientation handling | baseline test failure + source reading | `SwayCalibrationMachine` in the engine package; view reduced to render + frame feed | IMPLEMENTED; 14 Swift tests written; 14 mirror scenarios PASS |
| D-005 | Tempo floor 40 BPM in 9 places vs the 20-180 BPM Learn contract | grep; mirror test documents old vs new | single shared floor `SwayTimelineMath.minimumBPM = 20` | IMPLEMENTED |
| D-006 | Jump step title was "AND... JUMP!" ; authority requires exactly `JUMP` | baseline test failure | canonical titles from the engine | IMPLEMENTED |
| D-007 | `SWAY.entitlements` was an empty dict although HealthKit is used | baseline test failure | added healthkit keys | IMPLEMENTED, **UNVERIFIED signing (U-04)** |

## Architecture (boundaries)
`SWAYcoreEngine` (new, Foundation-only, no UI/camera): calibration state machine, match truth, musical timeline mapping, SWAYHumanoid-v1 contract + Vision-to-contract mapper. `SwayTimelineEngine` and `SwayPoseMatcher` now delegate to it; the calibration view consumes it. Everything else (camera service, Vision ingestion, RealityKit/2.5D renderers, store, Music, Health, recording) remains in the app target and is **not** yet extracted. Extracting those without a compiler would have been reckless; the engine boundary is deliberately limited to logic with tests.
SWAYHumanoid-v1 names follow `AssetPipeline/contracts/SWAYHumanoid-v1.json` (a test pins the Swift list to the JSON).

## Asset factory (details in `AssetFactory/`)
convert acquired CC0 base to contract rig (fails loudly on unmapped joints; provenance gate) -> bake 21 clips from the app's own movement truth (pose engine port pinned by sha256) -> structural + deformation-sanity validation -> Build 153-convention USD export -> runtime-set validation. **No production character exists** (U-01).

## What was NOT done
See `UNRESOLVED_ITEMS.md`. Notably: no Swift compile, no Blender run, no production characters, no performance measurement, no UI redesign, no device evidence generated.
