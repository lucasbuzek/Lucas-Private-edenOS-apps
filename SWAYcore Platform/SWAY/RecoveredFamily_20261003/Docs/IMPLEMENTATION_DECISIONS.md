# New implementation decisions (not recovered canon; all replaceable)

ND-001 Joint contract `SWAYHumanoid-v2`: 23 joints (root,hips,spine,chest,neck,head,headEnd + L/R shoulder,elbow,wrist,hand,hip,knee,ankle,toes). Count-compatible with recovered v1 (23); names are new.
ND-002 Coordinates: +x subject-left, +y up, +z forward; unit = torso length (hips→neck); origin hips. Blender: +X left, +Z up, forward −Y; USD export Y-up. **Axis agreement after USD export is UNVERIFIED** (needs first Blender run + visual check).
ND-003 Movement content is authored as FK angle presets (`Stance`) → poses; Blender clips and runtime retargeting derive from the same poses via `sway-fixtures` JSON (single movement truth).
ND-004 `.swaypack` v2 = JSON, FNV-1a-64 integrity checksum (not security), music **referenced not embedded**, v1 migration (`moves`→`movements`).
ND-005 Runtime budget: ≤60k triangles/character, ≤4 skin influences, height 1.4–2.0 m.
ND-006 26 bundled moves (10 are the recovered proof clip names); their poses are newly authored.
ND-007 Studio Management is a separate domain package; no dependency on the movement engine (references SWAYZ content by opaque id only).
ND-008 Retargeting: per-bone rotation aligns rest bone direction to posed direction; leaves inherit parent.
ND-009 Character appearance parameters (`Blender/characters.json`) are new; only the six identities are canon. Visual quality is never self-certified (`visualQuality: UNREVIEWED`).
ND-010 SWAY Beats are synthesized 16-step patterns for the 10 recovered style names.
ND-011 Kid Dancers: only safe necessary settings (camera off by default, recording off, speed cap). No parental accounts, curriculum, games or rewards invented.
ND-012 Display mirroring: coach and YOU are both drawn mirror-style (pose side-swap) so "left" is the viewer's left; matching compares subject-left to expected-left.
ND-013 Front-camera Vision orientation `.leftMirrored` with x flipped back to Core convention. **UNVERIFIED until calibration is run on a device** (left/right wave steps will reveal an error).
ND-014 Windows/Linux Studio outputs: **not built.** Recommended future approach: port `SWAYStudioKit` JSON schema (v2, documented in `StudioData`) to a cross-platform shell (e.g. Tauri/Qt) reading the same file format. No target-native verification is claimed.
ND-015 Project generation: XcodeGen (declared dependency, installed idempotently). Deployment target iOS/macOS 26.0 (recovered evidence).
ND-016 Calibration thresholds (wave oscillation, foot lift 0.2 torso, jump 0.12 torso rise then landing) are initial values to be tuned on device.
ND-017 Procedural body/outfit skinning uses inverse squared distance to the closest rest-bone segment and its parent/children, normalized to at most four influences. Root is a motion control; head/headEnd are excluded from body skinning because the head meshes bind separately. This replaces automatic heat weights, which discarded short extremity segments, and uses Blender's data API so hidden customization meshes can be bound. This is a replaceable implementation decision, not recovered canon or visual acceptance.
