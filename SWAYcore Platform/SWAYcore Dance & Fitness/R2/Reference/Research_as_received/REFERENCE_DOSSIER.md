# SWAYcore implementation/reference dossier — 2026-10-04

Use references to solve specific contracts; do not copy incompatible/proprietary code or assets. Verify exact license before incorporating any third-party code/model.

## Apple-native implementation references
- Vision 3D body pose sample: https://developer.apple.com/documentation/Vision/detecting-human-body-poses-in-3d-with-vision — reference for on-device 3D pose extraction and camera-relative joints. Vision's 3D detector exposes 17 detected joints; SWAYHumanoid-v1 remains SWAY's own 23-joint avatar/runtime contract, so build an explicit mapping layer rather than redefining the canonical rig.
- Vision 2D body pose: https://developer.apple.com/documentation/vision/detecting-human-body-poses-in-images — fallback/2D tracking and calibration reference.
- Create ML live action recognition: https://developer.apple.com/documentation/createml/detecting-human-actions-in-a-live-video-feed — reference for temporal action classification from pose sequences; do not replace deterministic SWAY movement/scoring truth without evidence.
- RealityKit character/skeleton/IK APIs: https://developer.apple.com/documentation/realitykit/game-development-character-skeletons — investigate current-platform SkeletalPose/IK/retargeting APIs before inventing runtime skeletal machinery.
- RealityKit USD guidance: https://developer.apple.com/documentation/RealityKit/bringing-your-scenekit-projects-to-realitykit — USD is Apple's preferred 3D interchange/runtime direction; preserve editable Blender masters and deterministic USD/USDZ export.
- ShazamKit: https://developer.apple.com/documentation/shazamkit — useful for recognition/alignment, not a substitute for SWAY beat/downbeat/bar/phrase/count timeline.
- HealthKit: https://developer.apple.com/documentation/healthkit/ and https://developer.apple.com/documentation/healthkit/setting-up-healthkit — permissions/capabilities must be explicit and denial-safe.
- MusicKit: https://developer.apple.com/documentation/musickit — Apple Music catalog/playback integration; permission and entitlement behavior must be tested on device.
- AVFoundation: https://developer.apple.com/av-foundation/ — recording/capture/audio boundary.

## Open-source/reference implementation candidates
- `rushil1510/Form` (GitHub): offline-first iPhone gym-form coaching using Vision body pose. Inspect architecture/tests/license before reuse. Treat as pattern evidence, not canonical SWAY code.
- Search for maintained Swift/Vision pose projects only to answer a concrete implementation question. Record repository, commit/tag, license, platform status, dependency cost and adopt/adapt/reject decision in `THIRD_PARTY_LEDGER.md`.

## Product interaction references — inspiration only
Study Apple Fitness+, Just Dance, STEEZY, Dance Reality, Nike Training Club and Peloton-like workout flows for onboarding, class/move discovery, progress, workout pacing, camera feedback, instructor prominence and results. Do not clone trade dress, proprietary content, choreography, characters, art or source.

## Character/model sourcing gate
Before modeling from scratch, evaluate existing stylized rigged humanoid bases. Required acceptance columns: source; exact asset/version; exact license; commercial app redistribution rights; modification rights; whether source attribution is required; topology; rig; skinning/deformation quality; expression support; mobile polygon/material/texture budget; Blender 5.2.2 import health; effort to map/retarget to SWAYHumanoid-v1; silhouette/visual fit; instructor/custom-avatar fit; ACCEPT/ADAPT/REJECT. Unknown rights = REJECT until resolved.

Do not use Mixamo/Ready Player Me/VRoid/MakeHuman/etc merely because they are convenient: verify their current license/terms and whether their visual/technical result meets SWAY's only-slightly-Memoji-inspired stylized direction and strong-silhouette requirement. Prefer a legally distributable base that can be transformed into a distinctive SWAY-owned visual system.
