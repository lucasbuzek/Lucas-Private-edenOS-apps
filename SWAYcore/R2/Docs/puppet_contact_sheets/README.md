# Lucia puppet posed-review evidence

These files are deterministic pipeline evidence, **not visual approval**.

* `lucia_angles_options.png` poses separated runtime parts in all eight yaw slots. FRONT, SIDE RIGHT, BACK and SIDE LEFT are hand-segmented from the turnaround; four three-quarter slots are visibly labelled nearest-angle fallbacks because the source has no neutral three-quarter turnaround.
* `lucia_{step_touch,squat,spin}_8_frames.png` are posed strips made by the pure-Python reference compositor from the SwayCoachPoseEngine port and the same endpoint midpoint/rotation convention as `SWAYPuppetMath`.
* Matching `*_joint_track.json` files preserve the exact eight joint/yaw inputs used by each strip.
* Alternate hair/top/bottom/shoe items remain **MISSING**. Board 136 shows a parts kit, but overlapping presentation does not provide enough source pixels to refit those items without inventing occluded geometry.

`visualQuality` remains **UNREVIEWED** until Lucas reviews these sheets.
