import json, os, sys, unittest
AF = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.join(AF, "python"))
from your_dancer_modules import load_contract, resolve, validate_contract

class YourDancerModules(unittest.TestCase):
    @classmethod
    def setUpClass(cls): cls.c = load_contract(os.path.join(AF, "data", "your_dancer_modules.json"))
    def base(self):
        return {"bodyStyle":"Neutral","faceShape":0,"eyeStyle":0,"browStyle":0,"noseStyle":0,"mouthStyle":0,
                "hairStyle":0,"facialHairStyle":0,"outfitStyle":0,"footwearStyle":0,"accessoryStyle":0,
                "skinTone":2,"hairColor":0,"appearancePreset":0,"bodyScale":1.0,"headScale":1.0,"limbScale":1.0,"hairScale":1.0}
    def test_contract_binds_every_required_profile_field(self): self.assertEqual(validate_contract(self.c), [])
    def test_each_choice_changes_visible_mesh_set(self):
        base = self.base()
        for field, choices in self.c["slots"].items():
            outputs = [tuple(resolve(self.c, dict(base, **{field: choice}))["visibleMeshes"]) for choice in choices]
            self.assertEqual(len(outputs), len(set(outputs)), field)
    def test_each_colour_changes_resolved_material_value(self):
        for field in ("skinTone", "hairColor", "appearancePreset"):
            a=self.base(); b=self.base(); b[field]=a[field]+1
            self.assertNotEqual(resolve(self.c,a)["materialValues"], resolve(self.c,b)["materialValues"], field)
    def test_each_scale_changes_resolved_transform_set(self):
        for field in ("bodyScale","headScale","limbScale","hairScale"):
            a=self.base(); b=self.base(); b[field]=1.1
            self.assertNotEqual(resolve(self.c,a)["transforms"],resolve(self.c,b)["transforms"],field)
    def test_portrait_is_explicitly_input_only_not_a_render_texture(self):
        self.assertIn("portraitData",self.c["inputOnly"])
        self.assertNotIn("portraitData",self.c["materialParameters"])
    def test_every_runtime_profile_field_changes_resolved_output(self):
        base=self.base(); baseline=resolve(self.c,base)
        for field in self.c["requiredProfileFields"]:
            if field in self.c["inputOnly"]: continue
            changed=dict(base)
            if field in self.c["slots"]:
                values=list(self.c["slots"][field]); changed[field]=values[1] if str(base[field])==values[0] else values[0]
            elif field in self.c["transformParameters"]: changed[field]=1.1
            else: changed[field]=base[field]+1
            self.assertNotEqual(resolve(self.c,changed),baseline,field)
    def test_unknown_option_fails_closed(self):
        with self.assertRaises(ValueError): resolve(self.c, dict(self.base(), hairStyle="missing"))

if __name__ == "__main__": unittest.main(verbosity=2)
