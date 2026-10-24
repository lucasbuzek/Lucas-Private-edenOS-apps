# Lucia 2D puppet provenance

Evidence state: **GENERATED (derivatives), not visually VERIFIED**. `visualQuality` is **UNREVIEWED**.

## Inputs

| Input | Rights / authority | Use |
|---|---|---|
| `Reference/ArtDirection/136-SWAY_BUILD110_CHARACTER_ASSET_DIRECTION.png` | SWAY project-supplied art; no third-party dependency | Visual design authority only |
| `Reference/ArtDirection/125-IRIS_BUILD113_ARTICULATED_ASSET_DIRECTION.png` | SWAY project-supplied art; no third-party dependency | Parts-library reference only |
| `Reference/ArtDirection/LUCIA_RIG_REFERENCE_TURNAROUND.jpeg` | SWAY project-supplied art; no third-party dependency | Turnaround reference only |
| `App/ProductionAssets/Lucia/*.png` and `lucia.manifest.json` | SWAY project-supplied, already-separated Lucia source | Sole pixel source for generated puppet files |

No third-party logos or band art are introduced. The build downloads nothing.

## Reproducible transform

Run `python3 AssetFactory/python/build_lucia_puppet_assets.py` from any directory. The script uses Python (PSF-2.0) and Pillow (HPND license) to make 1024-pixel PNG fallbacks, lossless SVG preservation containers, the manifest, and contact sheet. Pillow is a build-time tool only; there is no shipped third-party runtime.

The SVG files preserve the reviewed raster pixels in an SVG container; they are deliberately named `svgPreservationCopy` in the manifest and are **not represented as traced vector artwork**. vtracer/potrace and SAM were not used. No primitive or inferred body geometry is fabricated.

## Outputs and limitations

* `AssetFactory/data/puppet/lucia_puppet_manifest.json` — SWAYHumanoid-v1 joint list, normalized pivots, draw order, angle/option availability.
* `AssetFactory/vector/lucia/front/*.svg` — source-preserving SVG containers.
* `App/SWAY/Resources/Puppets/Lucia/front/base/*.png` — 1024-pixel raster fallbacks.
* `Docs/puppet_contact_sheets/lucia_angles_options.png` — review evidence only.

Only the already separated **FRONT/base** source is implemented. SIDE, BACK, both 3/4 views, mirrored directions, and alternate hair/top/bottom/shoes are marked **MISSING** and explicitly fall back to FRONT/base. This is honest missing-art behavior, not acceptance-gate evidence. Motion contact strips are also MISSING until a runtime renderer exists.

## Tool licences

| Tool | Version requirement | OSI licence | URL |
|---|---|---|---|
| Python | 3.x | Python Software Foundation License 2.0 | https://docs.python.org/3/license.html |
| Pillow | 9+ | HPND | https://github.com/python-pillow/Pillow/blob/main/LICENSE |
