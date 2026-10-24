# SWAYcore recovery package (R2)

Recovered, evidence-first continuation of SWAYcore + SWAYcore Dance & Fitness from `SWAYcore_CLAUDE_CURATED_HANDOFF_2026-10-04.zip`.

Start with `Docs/UNRESOLVED_ITEMS.md` (what is NOT done) and `Docs/IMPLEMENTATION_REPORT.md` (what changed and why), then `Docs/BUILD_AND_RUN_INSTRUCTIONS.md`.

| Path | Contents |
|---|---|
| `App/` | The received Build 153-line candidate with targeted repairs (project.yml is generation authority). |
| `Packages/SWAYcoreEngine/` | New reusable Foundation-only engine: calibration state machine, match truth, timeline math, SWAYHumanoid-v1 contract + Vision mapper. |
| `AssetFactory/` | Blender 5.2.x pipeline: convert legal base -> contract rig, bake coach clips from the app's own movement truth, validate, export; provenance gate; unit tests. |
| `Authority/`, `Reference/` | Project authority as received; the original handoff zip (LKG), stale xcodeproj, evidence. |
| `Tools/`, `Scripts/` | Portable verifier, regression tests, Swift lexer, factory library, DeviceSupport guard. |
| `*.command` | `VERIFY_ALL`, `BUILD_SWAYCORE_ENGINE`, `BUILD_DANCE_FITNESS`, `BUILD_ASSETS`, `BUILD_ALL`. |

State of the world: see `Docs/STATE_OF_EVIDENCE.md`. Swift was never compiled and Blender never run by the author of this package.
