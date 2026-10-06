# SWAYcore Full Feature Alpha Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Deliver one local-first one-click Mac package that coordinates Blender and Xcode, preserves SWAY's protected capabilities, builds the full-feature Alpha candidate, and captures evidence for iPhone/iPad testing.

**Architecture:** Build 152 is preserved as the source baseline. A macOS launcher performs deterministic preflight, validates the repository contracts, runs Blender's character pipeline when available, opens Blender and Xcode together, builds with Xcode, detects connected iOS/iPadOS devices instead of hard-coding one device, and writes a local evidence bundle. Internet-dependent providers are reported separately and never block offline core testing.

**Tech Stack:** Swift/SwiftUI, RealityKit, Vision, MusicKit/ShazamKit, HealthKit, ReplayKit, Blender Python, zsh/bash, xcodebuild/devicectl.

**Spec:** `PRODUCT_SPECIFICATION.md` plus `*_CONTRACT.md` and `PHYSICAL_TEST_MATRIX.md`.

## Global Constraints
- Preserve Build 143 graphical reference, Build 147 tracking path, Build 149 recovered working baseline.
- Build 148 remains rejected.
- Consumer navigation remains HOME · MOVES · BEATS · PROFILE.
- Blender/DÜRER is production character authoring; RealityKit is runtime.
- One movement truth and one musical timeline.
- Core Alpha remains offline/local-first.
- iPhone, iPad portrait and iPad landscape are physical acceptance targets.
- No physical-pass claims from compilation.

## Review Focus
- Missing Internet must not block local Alpha build/test.
- Missing Blender/Xcode must produce an actionable blocker, not destructive fallback.
- No hard-coded device UDID.
- Existing signing/profile state should be reused; otherwise open Xcode for the one required signing action.
- Evidence must distinguish static/build/device/provider states.

---

### Task 1: One-click Mac Alpha launcher
Create `FULL_FEATURE_ALPHA.command` and tests validating dynamic tool/device discovery, build identity, offline behavior and evidence output.

### Task 2: Blender/Xcode convergence
Use the existing SWAYHumanoid contract and Blender generator without replacing protected 2.5D fallback. Run Blender automation locally when available and open generated source plus Xcode together.

### Task 3: Device build/install harness
Build with Xcode, enumerate connected devices with `devicectl`, install to a selected connected iPhone/iPad when possible, otherwise leave Xcode open for device selection/signing.

### Task 4: Full-feature physical test harness
Create a local checklist/evidence directory for the authoritative journey and device/layout gates.

### Task 5: Package verification
Synchronize Build 153 identity, executable bits, static verifiers and ZIP integrity. Do not promote physical gates.
