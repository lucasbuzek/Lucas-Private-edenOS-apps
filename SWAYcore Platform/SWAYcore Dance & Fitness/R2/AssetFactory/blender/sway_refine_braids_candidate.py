"""Non-destructive R2 Blender native-skinned YOUR DANCER hair-option study.
Build only an unapproved candidate; preserve the source asset and untouched modules.
The long braided hairstyle is guided by the user's 2026-10-23 supplied reference
collages. This is not an exact likeness, final garment design or iOS approval.
Execute via Blender with an existing .blend open:
  blender -b INPUT.blend --python sway_refine_braids_candidate.py -- --output OUTPUT.blend
"""
from __future__ import annotations

import argparse
import math
from pathlib import Path
import sys

import bpy
import bmesh


def main():
    args_list = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args(args_list)
    out = args.output.resolve()
    if out.exists():
        raise RuntimeError(f"No-clobber: output already exists: {out}")
    hair = bpy.data.objects.get("YD_Hair_Braids")
    if hair is None or hair.type != "MESH" or not hair.get("sway_module"):
        raise RuntimeError("Existing authored braid option is absent or not a module")
    if bpy.data.objects.get("SWAYArmature") is None:
        raise RuntimeError("Required SWAYHumanoid-v1 armature absent")
    head_group = hair.vertex_groups.get("head")
    if head_group is None:
        raise RuntimeError("Existing head deformation group absent; refusing a new rig")
    original_vertices = len(hair.data.vertices)
    original_faces = len(hair.data.polygons)
    original_mesh = hair.data
    hair.data = original_mesh.copy()  # Do not mutate other options sharing datablocks.

    bm = bmesh.new()
    bm.from_mesh(hair.data)
    bm.verts.ensure_lookup_table()
    bm.faces.ensure_lookup_table()
    # Hair silhouette: many individual braided strands from scalp toward
    # mid-torso, matching the owner's long-braid appearance direction.
    # Keep the existing scalp cap, skins/modifiers, UVs, material, and rig.
    roots = []
    for row, y in enumerate((-11.0, -7.5, 3.0, 9.0)):
        for j in range(7):
            x = (j - 3) * 3.1 + (1.3 if row % 2 else 0.0)
            if abs(x) > 11.0 or (y < 0 and abs(x) < 5.4):
                continue
            roots.append((x, y, 185.0 - (abs(x) / 11) * 3.5 - row * 0.6))
    if len(roots) < 20:
        raise RuntimeError("Insufficient roots for intended hairstyle")
    rings = 17
    sections = 7
    length = 78.0
    for strand_index, (rx, ry, rz) in enumerate(roots):
        previous = None
        for step in range(rings + 1):
            t = step / rings
            # Controlled low-amplitude sweep makes hair hang naturally without
            # creating a second skeleton/animation clock.
            lateral = 0.65 * math.sin(2 * math.pi * (t + strand_index / 9))
            lateral += 0.28 * math.sin(t * math.pi * 4)
            centre_x = rx + lateral + 0.17 * strand_index / len(roots)
            centre_y = ry + (-5.0 if ry < 0 else 2.5) * t + 0.35 * math.cos(2 * math.pi * t)
            centre_z = rz - length * t
            ring = []
            # Braided outer surface: small periodic three-lobe raised plaits.
            for side in range(sections):
                a = math.tau * side / sections
                plait = 0.16 * math.cos(6 * math.tau * t - 3 * a + strand_index * 0.7)
                radius = max(0.14, (0.74 + plait) * (1.0 - 0.78 * t**6))
                v = bm.verts.new((centre_x + radius * math.cos(a),
                                  centre_y + radius * math.sin(a),
                                  centre_z))
                ring.append(v)
            if previous is not None:
                for j in range(sections):
                    # Manifold quad strand surface; face winding is consistent.
                    bm.faces.new((previous[j], previous[(j + 1) % sections],
                                  ring[(j + 1) % sections], ring[j]))
            previous = ring

    bm.to_mesh(hair.data)
    bm.free()
    hair.data.update()
    new_vertex_count = len(hair.data.vertices)
    # Existing garment/rig workflow has authored 'head' skin weighting;
    # reuse it, rather than adding noncanonical bones or modifiers.
    head_group.add(list(range(original_vertices, new_vertex_count)), 1.0, "REPLACE")
    hair["sway_braided_study"] = "2026-10-23; long individual plaits; owner-reference based; UNAPPROVED"
    hair["sway_reference"] = "Two owner-supplied Oct 23 image collages; inspiration only"
    hair["sway_physical_accepted"] = False
    assert len(hair.data.polygons) > original_faces
    bpy.ops.wm.save_as_mainfile(filepath=str(out), check_existing=False)
    print("SWAY_BRAIDS_CANDIDATE",
          "roots", len(roots), "oldVertices", original_vertices,
          "newVertices", new_vertex_count, "oldFaces", original_faces,
          "newFaces", len(hair.data.polygons),
          "output", out, "UNAPPROVED")


if __name__ == "__main__":
    main()
