# SWAY cut-out puppet asset bible

* **Authority:** board 136 turnaround art, without repainting faces, clothing, colour, or silhouette.
* **Runtime:** `SWAYRigPuppet` 2.5D cut-out; front, back, and one mirrorable side view.
* **Anatomy:** 20 shared SWAY joints and 15 overlapping rigid parts per view.
* **Occlusion:** torso at z40, pelvis z50, near terminal limbs above the body; profile far limbs
  are source-preserving 85% luminance duplicates below the torso.
* **Identity locks:** Nandi's braids and Zuri's curls remain on the head layer. YOUR DANCER is
  an explicitly neutral, replaceable board-kit base and is not Lucas's likeness.
* **Brand lock:** no board-125 wordmark or shoe logo is used. The neutral base uses board 136's
  unbranded blue outfit.
* **Technical limits:** RGBA PNG, long edge at most 1024 px; rig JSON names use character rawValue.
* **QA ladder:** source-preserving matte → cut parts → six-pose family sheet → rig validator →
  bundled-app build → physical iPhone/iPad review. A later rung never implies an earlier one.
