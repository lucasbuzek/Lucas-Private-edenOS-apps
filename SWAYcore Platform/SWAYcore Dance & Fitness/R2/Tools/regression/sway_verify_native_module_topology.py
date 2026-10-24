"""SWAYcore native YOUR DANCER structural topology regression.

Read-only Blender gate for the existing unapproved 44-option candidate.
Distinguish legitimate open clothing boundaries from actual loose edges and
duplicate full-head facial options. PASS is NOT visual/physical approval.

blender -b <candidate.blend> --python sway_verify_native_module_topology.py -- \
  --contract <your_dancer_modules.json> --report <temporary-report.json>
blender -b --factory-startup --python sway_verify_native_module_topology.py -- --self-test
"""
from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import json
import sys
from pathlib import Path
import bpy


FACIAL_FEATURE_PREFIXES = (
    "YD_Eyes_", "YD_Brows_", "YD_Nose_", "YD_Mouth_", "YD_Facial_Hair_"
)
GARMENT_PREFIXES = (
    "YD_Top_", "YD_Bottom_", "YD_Shoes_", "YD_Accessory_"
)


def topology(mesh):
    """Count *face* topology, treating designed garment openings as valid."""
    face_uses = Counter()
    face_vertices = set()
    parent = list(range(len(mesh.vertices)))

    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    def unite(a, b):
        parent[find(a)] = find(b)

    layout = hashlib.sha256()
    for polygon in mesh.polygons:
        vertices = tuple(int(v) for v in polygon.vertices)
        if len(vertices) < 3:
            continue
        face_vertices.update(vertices)
        layout.update((','.join(map(str, vertices)) + ';').encode('ascii'))
        for a, b in zip(vertices, vertices[1:] + vertices[:1]):
            face_uses[tuple(sorted((a, b)))] += 1
            unite(a, b)

    authored_edges = {
        tuple(sorted(tuple(int(v) for v in edge.vertices)))
        for edge in mesh.edges
    }
    boundaries = [edge for edge, n in face_uses.items() if n == 1]
    boundary_degree = Counter(v for edge in boundaries for v in edge)
    components = Counter(find(vertex) for vertex in face_vertices)

    return {
        "vertices": len(mesh.vertices),
        "faces": len(mesh.polygons),
        "wireEdges": len(authored_edges - face_uses.keys()),
        "unreferencedVertices": len(mesh.vertices) - len(face_vertices),
        "nonManifoldEdges": sum(n > 2 for n in face_uses.values()),
        "boundaryEdges": len(boundaries),
        "boundaryBranchVertices": sum(n != 2 for n in boundary_degree.values()),
        "faceComponents": len(components),
        "largestFaceComponents": sorted(components.values(), reverse=True)[:5],
        "faceTopologySHA256": layout.hexdigest(),
    }


def contracted_names(contract):
    required = set()
    for choices in contract["slots"].values():
        for choice in choices.values():
            required.update(choice if isinstance(choice, list) else [choice])
    return required


def audit(contract):
    required = contracted_names(contract)
    objects = {
        obj.name: obj
        for obj in bpy.data.objects
        if obj.type == "MESH" and obj.get("sway_module")
    }
    errors = []
    missing = sorted(required - objects.keys())
    extra = sorted(objects.keys() - required)
    if missing or extra:
        errors.append({"code": "MODULE_SET_MISMATCH", "missing": missing, "extra": extra})

    face = objects.get("YD_Face_Oval")
    face_metrics = topology(face.data) if face else None
    modules = {}
    full_head_duplicates = []
    wire_modules = []
    for name in sorted(required & objects.keys()):
        obj = objects[name]
        stat = topology(obj.data)
        modules[name] = stat
        if stat["faces"] == 0:
            errors.append({"code": "EMPTY_FACES", "module": name})
        if stat["nonManifoldEdges"] > 0:
            errors.append({"code": "NONMANIFOLD_OVERLAP", "module": name,
                           "edges": stat["nonManifoldEdges"]})
        if any(name.startswith(prefix) for prefix in GARMENT_PREFIXES):
            if stat["wireEdges"] or stat["unreferencedVertices"]:
                wire_modules.append(name)
                errors.append({"code": "LOOSE_GARMENT_GEOMETRY", "module": name,
                               "wireEdges": stat["wireEdges"],
                               "unreferencedVertices": stat["unreferencedVertices"]})
        if any(name.startswith(prefix) for prefix in FACIAL_FEATURE_PREFIXES):
            if (face_metrics and
                stat["vertices"] == face_metrics["vertices"] and
                stat["faces"] == face_metrics["faces"] and
                stat["faceTopologySHA256"] == face_metrics["faceTopologySHA256"]):
                full_head_duplicates.append(name)
                errors.append({"code": "FACIAL_FEATURE_REUSES_FULL_HEAD_TOPOLOGY",
                               "module": name, "faces": stat["faces"]})

    return {
        "status": "FAIL" if errors else "PASS",
        "moduleCount": len(objects),
        "requiredCount": len(required),
        "fullHeadFacialFeatureClones": full_head_duplicates,
        "garmentsWithLooseGeometry": wire_modules,
        "issues": errors,
        "modules": modules,
        "interpretation": (
            "Designed collar/hem/cuff boundary loops are allowed; "
            "a topology PASS alone cannot approve appearance, self-intersection, "
            "deformation, RealityKit playback, licensing or physical iOS runtime."
        ),
    }


def self_test():
    def fixture(name, verts, edges, faces):
        mesh = bpy.data.meshes.new(name)
        mesh.from_pydata(verts, edges, faces)
        mesh.update()
        return mesh

    rectangle = fixture("SWAYValidOpenPanel",
                        [(0, 0, 0), (1, 0, 0), (1, 1, 0), (0, 1, 0)],
                        [], [(0, 1, 2, 3)])
    valid = topology(rectangle)
    assert valid["boundaryEdges"] == 4
    assert valid["wireEdges"] == 0
    assert valid["nonManifoldEdges"] == 0
    assert valid["boundaryBranchVertices"] == 0

    loose = fixture("SWAYLooseWire",
                    [(0, 0, 0), (1, 0, 0), (1, 1, 0), (0, 1, 0), (3, 0, 0), (4, 0, 0)],
                    [(4, 5)], [(0, 1, 2, 3)])
    l = topology(loose)
    assert l["wireEdges"] == 1 and l["unreferencedVertices"] == 2

    overlapping = fixture("SWAYNonManifoldEdge",
                          [(0, 0, 0), (1, 0, 0), (0, 1, 0), (0, -1, 0), (0, 0, 1)],
                          [], [(0, 1, 2), (1, 0, 3), (0, 1, 4)])
    m = topology(overlapping)
    assert m["nonManifoldEdges"] == 1
    bpy.data.meshes.remove(rectangle)
    bpy.data.meshes.remove(loose)
    bpy.data.meshes.remove(overlapping)
    print("SWAY_NATIVE_TOPOLOGY_SELF_TEST_PASS", "legalOpenPanel=1",
          "looseWireRejected=1", "nonManifoldRejected=1")


def main():
    if "--" in sys.argv:
        arguments = sys.argv[sys.argv.index("--") + 1:]
    else:
        arguments = []
    parser = argparse.ArgumentParser()
    parser.add_argument("--contract", type=Path)
    parser.add_argument("--report", type=Path)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args(arguments)
    if args.self_test:
        self_test()
        return
    if not args.contract or not args.report:
        parser.error("--contract and --report are required")
    if args.report.is_relative_to(args.contract.parent):
        parser.error("Report must be separate from the authoritative contract folder")
    contract = json.loads(args.contract.read_text())
    result = audit(contract)
    args.report.write_text(json.dumps(result, indent=2) + "\n")
    print("SWAY_NATIVE_TOPOLOGY_GATE", result["status"],
          "modules", result["moduleCount"],
          "headClones", len(result["fullHeadFacialFeatureClones"]),
          "looseGarments", len(result["garmentsWithLooseGeometry"]),
          "issues", len(result["issues"]))
    for issue in result["issues"][:10]:
        print("ISSUE", issue["code"], issue.get("module", ""))
    if result["status"] != "PASS":
        sys.exit(1)


if __name__ == "__main__":
    main()
