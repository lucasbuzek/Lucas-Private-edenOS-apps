# State and evidence (truthful)

Scale: REQUESTED → PLANNED → IMPLEMENTED → STATIC PASS → BUILD PASS → ENVIRONMENT PASS → PHYSICAL PASS → REGRESSION PASS → RELEASE CANDIDATE → RELEASED. Later states are never inferred from earlier ones.

## What was produced in the authoring sandbox (Linux; no Swift, Xcode, Blender, Homebrew; network off)
| Area | State | Evidence |
|---|---|---|
| All Swift source (Core, AppKit, Studio, 4 apps, tests) | IMPLEMENTED | files exist |
| Repository static verification | STATIC PASS (when `verify_static.py` reports PASS) | run in sandbox; report in `Build/report/static.json` |
| Python validators + cross-check of core algorithms | PASS (Python only) | `Tests/Python/*` run in sandbox |
| Shell syntax of builders | STATIC PASS | `bash -n` |
| Swift compile / `swift test` | **UNKNOWN** | never executed here; first real run is your builder |
| Blender generation/validation | **UNKNOWN** | never executed here |
| Character visual quality | **UNKNOWN** | needs human review; manifests say UNREVIEWED |
| Xcode build/package | **UNKNOWN** | |
| Simulator / physical device | **UNKNOWN** | |

## Honest scope limits (not claimed as done)
Windows/Linux Studio (ND-014); Record Me/Photos/Share only coded, unverified; MusicKit/ShazamKit/HealthKit need entitlements, signing and a device; Dance & Fitness workouts/challenges/programs beyond Quick Dance + Practice are limited to the model layer (hierarchy types exist; UI for programs/challenges is not built); Kid Dancers uses SF Symbol tiles in its library grid (the performing character is the production rig); SWAYZ formations/lighting/notation are metadata fields only. Expect compile errors on first Mac run: the builder logs them under `Build/logs/` and a repair pass is needed — this code has never met a Swift compiler.
