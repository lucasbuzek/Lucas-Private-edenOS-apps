# YOUR DANCER modular asset provenance

- **Geometry source:** `girush-human-yw-cc0` in `ledger.json` (CC0-1.0, acquired and checksummed).
- **Authoring:** `blender/sway_author_yourdancer.py` creates named, skinned mesh derivatives locally. No downloaded geometry, image layer, cutout, or unknown-licence input is used.
- **Rig:** every module preserves the acquired character's native armature modifier and weights; export maps that articulated skin to the 23-joint `SWAYHumanoid-v1` contract.
- **Runtime contract:** `data/your_dancer_modules.json` is the authoritative mesh/material slot map.
- **Profile-photo boundary:** `portraitData` is private profile/UI input only. It is intentionally not projected onto the character or used as a texture; doing so would reintroduce the prohibited image/cutout path. Every other production appearance field resolves to a mesh, material parameter, or named transform root.
- **Acceptance state:** generated output and contact sheets remain **UNKNOWN** until the script runs in Blender 5.2.x and a human reviews every option and clip. The script stamps `visualQuality=UNREVIEWED`; generation must never promote an asset to accepted or release-ready.

The deterministic authoring command (from `SWAYcore/R2`) is:

```sh
blender --background Build/resume/20261006/eye_verified/candidate.blend \
  --python AssetFactory/blender/sway_author_yourdancer.py -- \
  --contract AssetFactory/data/your_dancer_modules.json \
  --out Build/resume/20261006/your_dancer/your_dancer.blend
```

Export that authored file with `sway_export_runtime.py --modules AssetFactory/data/your_dancer_modules.json`; the exporter fails if any contract mesh is absent.

## 2.5D Alpha component library (2026-10-07)

- **Source/ownership:** all `YD2D_*` transparent PNG component layers are deterministic, project-generated artwork produced by `python/generate_your_dancer_2_5d.py`. No third-party or unknown-license imagery is included.
- **Lineage:** silhouettes and anchors are derived only from the user-owned Build 143 `UserPoseNN` separated runtime layers, then procedurally redrawn as independently composable body, face, feature, hair-back, hair-front, clothing, shoe, and accessory masks.
- **Colour:** skin, hair, outfit and accessory variants are runtime mask/tint roles; colours are not baked into duplicate artwork.
- **Review:** `Docs/avatar_contact_sheets/` is deterministic review evidence. Its status is `visualQuality=UNREVIEWED`; generated does not mean implemented, built, tested, verified, or released.
