# Claude Rebuild Handoff — SWAYcore Engine/Core

## Identity
SWAYcore is a reusable temporal human-movement instruction engine. Canon: **ONE CORE. MULTIPLE EXPERIENCES.** Dance & Fitness is its first major consumer, not the definition of the engine. Intended family/domain consumers include Dance & Fitness, Kid Dancers, SWAYZ, Studio integrations, Yoga, Tai Chi, Martial Arts and other fitness/movement apps.

## Engine responsibilities
Own normalized body geometry/pose; movement definitions; transitions; direction/side/symmetry; counts, cadence, holds, repetitions; choreography/sequences; reference and learner streams; camera/body-pose adapters; calibration/registration; matching/comparison/confidence; scoring primitives; articulated COACH animation; YOU representation hooks; sessions/countdown/pause/resume/end; cue semantics; progression/mastery primitives; accessibility/adaptation hooks; serialization/import/export; local persistence; offline operation; provider adapters.

One movement truth: Movement Definition -> choreography/counts/holds/transitions -> normalized pose/movement -> instructor rig -> COACH target -> expected YOU target -> Learn/Practice -> session/workout -> tracking/comparison/scoring. Never fork choreography per screen, instructor or tracking mode.

Reusable hierarchy where appropriate: Move -> Variation -> Combination -> Routine -> Workout/Session -> Challenge -> Program. Complexity is separate from intensity and accessibility.

## Time
Rhythmic products: audio/music -> metadata/recognition if available -> tempo/onset -> beat grid/phase -> downbeat -> bar -> phrase -> normalized SWAY timeline -> count -> movement -> repetition -> COACH phase -> cue -> expected YOU pose -> scoring. BPM alone is insufficient; Shazam is supportive, not clock authority. Support half-time mappings without losing phase.

Non-dance disciplines use the same temporal primitives for holds, breathing/cadence and continuous transitions.

Domain extensions: Dance=rhythm/choreography/expression; Yoga=alignment/holds/transitions/breath; Tai Chi=continuous flow/balance/cadence; Martial Arts=stances/techniques/trajectories/sides/timing; Fitness=reps/sets/intervals/form/intensity/adaptation.

## Tracking
Vision observations are data, not consumer graphics. MATCH / NOT MATCHED / UNKNOWN remain distinct. Out-of-frame, stale, low-confidence or missing-reference observations never earn false credit. Calibration and session lifecycle are separate states. Tracking loss is representable without corrupting the session.

## Characters
Expose a common articulated humanoid contract. Dance & Fitness established coaches: Lucia, Nandi, Thabo, Zuri, Kyle. YOUR DANCER uses the compatible movement contract. Identity/presentation is product data over common motion truth.

## Portability/privacy
Preserve versioned/validated `.swaypack` local-first content portability. Never embed protected music where redistribution is forbidden. Camera analysis is on-device where practical; frames are discarded unless explicit recording is requested. Core use does not require permanent account/server. No-camera follow-along cannot claim camera-derived matching/scoring.

## Builder/toolchain
Deliver a macOS `.command` one-click builder. Resolve project root; preflight identity/source; check Homebrew; provide ensure_formula/ensure_cask helpers; fetch only declared missing formulae/casks; check Xcode via xcode-select/xcodebuild/xcrun; do not silently install Xcode; check compatible Blender (Build 153 recovery evidence used Blender 5.2.2 LTS); build/validate engine and fixtures; package exact outputs. Idempotent reruns.

## Tests
Deterministic tests for movement parsing, timeline, pose normalization, confidence, matching, calibration state, pause/resume, serialization/version migration and malformed packages. At least one real family app must consume the core without duplicated timing/tracking/choreography logic before calling the extraction verified.
