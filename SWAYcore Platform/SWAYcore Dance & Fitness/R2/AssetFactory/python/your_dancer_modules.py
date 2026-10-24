"""Pure-Python resolver for the YOUR DANCER Blender/RealityKit module contract."""
import json

def load_contract(path):
    with open(path) as fh:
        return json.load(fh)

def resolve(contract, profile):
    """Return deterministic visible mesh names and material values. Invalid choices fail closed."""
    visible = []
    for field, choices in contract["slots"].items():
        choice = str(profile[field])
        if choice not in choices:
            raise ValueError("unsupported %s=%s" % (field, choice))
        value = choices[choice]
        visible.extend(value if isinstance(value, list) else [value])
    materials = {}
    for field, material in contract["materialParameters"].items():
        if field in profile:
            materials[material] = profile[field]
    transforms = {node: profile[field] for field, node in contract.get("transformParameters", {}).items() if field in profile}
    return {"visibleMeshes": sorted(visible), "materialValues": materials, "transforms": transforms}

def validate_contract(contract):
    errors = []
    if contract.get("skeletonContract") != "SWAYHumanoid-v1": errors.append("wrong skeleton contract")
    slots = contract.get("slots", {})
    for field in contract.get("requiredProfileFields", []):
        if field not in slots and field not in contract.get("materialParameters", {}) and field not in contract.get("transformParameters", {}) and field not in contract.get("inputOnly", {}): errors.append("unbound field: " + field)
    names = [n for choices in slots.values() for value in choices.values() for n in (value if isinstance(value, list) else [value])]
    if len(names) != len(set(names)): errors.append("mesh names must belong to exactly one option")
    if any(not n.startswith("YD_") for n in names): errors.append("non-namespaced mesh")
    return errors
