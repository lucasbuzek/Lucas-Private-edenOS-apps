# CODEX Lucia Puppet Pilot receipt — 2026-10-07

## Evidence rules

This receipt follows CONDUCTOR evidence semantics: GENERATED is not IMPLEMENTED,
BUILT, TESTED, VERIFIED, or RELEASED; UNKNOWN is not PASS. Nothing in this work
promotes an LKG. Linux checks are not simulator or physical-iPhone evidence.

## Implemented candidate

* A native SwiftUI cut-out puppet renderer attaches separated Lucia parts to the
  SWAYHumanoid-v1 hierarchy. Coach poses come from `SwayCoachPoseEngine`; tracked
  YOU poses map Vision joints, retain last-good dropped joints, and report lost
  tracking as UNKNOWN.
* An eight-direction yaw selector uses a 10-degree hysteresis band. Angle and
  customisation asset names are resolved per part without a third-party runtime.
* The workout coach, NEXT preview (through the shared coach view), and YOU panel
  consume the puppet path.
* The source-only asset pipeline emits 1024 px PNG fallbacks, SVG preservation
  containers, manifest pivots/draw order, provenance, and review contact sheets.
  It does not claim that raster-preserving SVG containers are traced vectors.
* The SDK typecheck now compiles the complete app source set rather than an
  obsolete extracted renderer fragment. An OSI provenance regression gate is
  part of `RUN_R2_REGRESSION.command`.

## Acceptance-gate ledger

| Gate | State | Evidence / reason |
|---|---|---|
| 1. Pivot alignment for every Step Touch, Squat, spin frame | **UNKNOWN** | Manifest pivot arithmetic is tested, but app XCTest and rendered-frame measurement require macOS/Xcode. No claim of a 0.5 px rendered result is made. |
| 2. 0–360 angle order and ±10° hysteresis | **TESTED (parse/static); app XCTest UNKNOWN** | XCTest cases cover order and dead-band behavior; Swift parses on Linux. Execution under XCTest is pending macOS. |
| 3. Hair/top/bottom/shoe option swap at every angle | **MISSING / UNKNOWN** | Resolver naming exists, but alternate authored art is unavailable. Manifest entries explicitly use base fallback. |
| 4. Recorded Vision fixture drive and dropped joints | **PARTIALLY IMPLEMENTED; UNKNOWN** | Vision mapping and last-good retention exist with unit coverage, but no approved recorded Vision fixture set or app XCTest execution was available. |
| 5. OSI licence/provenance gate | **TESTED — PASS on Linux** | `check_oss_dependencies.py` passed and is wired into the regression command. |
| 6. Contact sheets | **GENERATED; visualQuality UNREVIEWED** | Lucia angle/option sheet is committed. Missing views are visibly labelled. Motion strips remain missing because rendered runtime capture requires the Apple runtime. |
| 7. Regression | **PARTIAL** | SWAYcoreEngine: 31/31 PASS. Puppet asset tests: 5/5 PASS. Full R2 result was 4 FAIL / 2 UNKNOWN: three Apple/Xcode commands are unavailable on Linux, while the pre-existing build-identity contract cannot find the ungenerated `SWAY.xcodeproj`. These are not reported as passes. |
| 8. Receipt | **IMPLEMENTED** | This document records the evidence without promotion or release claims. |

## Explicit UNKNOWN / MISSING list

* SIDE, BACK, 3/4 FRONT, and 3/4 BACK authored Lucia parts: **MISSING**; the
  manifest falls back to FRONT. Mirrored art is not claimed as newly authored.
* Second hairstyle, top, bottom, and shoe option: **MISSING**; base fallback only.
* True vector tracing: **MISSING**. Current SVGs are honest preservation wrappers.
* Step Touch, Squat, and spin rendered motion strips: **MISSING**.
* Simulator build and app XCTest execution: **UNKNOWN** (Linux has no Xcode or
  iPhoneOS SDK).
* Physical iPhone behavior, camera tracking, performance, and joint alignment:
  **UNKNOWN**.
* Lucas visual acceptance of character quality/contact sheets:
  **UNREVIEWED / UNKNOWN**.
* Release, LKG promotion, and all non-pilot characters: **NOT PERFORMED**.

## Required next evidence

On the Mac, run the full regression command and app XCTest target, capture the
three runtime motion strips, and measure rendered pivot-to-joint deltas. Lucas
must review the committed contact sheet before any visual-quality status changes.
Only authored, source-approved angle and option art may replace the declared
fallbacks.
