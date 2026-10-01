# Modern Generals — Project State

Updated: 2026-10-01
Authority model: project implementation/state repository. Canon/governance: lucasbuzek/Lucas-private-appDevDocs / Project Bibles/MODERN_GENERALS.md.

## Active milestone
Dragon Full Roster / large-WDC convergence testing.

Current conversation candidate:
- artifact: Modern_Generals_Dragon_LKG_CONVERGENCE_R1_TEST.rwmod
- SHA-256: 034fa55075b5d2d233550bb89d86ceb4ec71b4c8c48bfc610c2fbf28594df601
- reported static evidence: 165 files / 67 INIs / 81 PNGs / zero missing graphics refs / zero blank PNGs / ZIP integrity PASS
- runtime/device status: PENDING / UNKNOWN until physical Rusted Warfare test evidence is recorded

The artifact itself is not asserted persisted in this GitHub repository by this state record. Persistence of this text record is not evidence of artifact upload or runtime functionality.

## Recovered implementation lineage
- v0.4.x: early engine-facing/basic graphics contracts and device-visible core assets.
- CT02-R2: Engineer construction/production, HQ replacement Engineer, Barracks, Vehicle Works, Rifle Squad x4, native AI integration.
- A1/A1-R1: Full Dragon architecture, economy/progression and roster expansion.
- A2: expanded visual/physical integration, building silhouettes, Engineer/dozer, air/naval art, footprints, roads/crossings/coastal water.
- A3-COMPLETE: complete roster integration evidence and distinct-building evidence; not automatically device-verified.
- C2/C3: 512x512 WDC convergence and physical evidence for major construction/AI/economy/Rifle/minimap capabilities.
- later recovered: Construction Crew variants and Power Grid progression.

Aggregate Alpha 5–9 visual branches are not visual LKGs. Do not derive a new candidate by simply patching the newest failed Alpha.

## Full Dragon contract
15 buildings / 6 infantry / 15 ground / 8 air-UAV / 6 naval.
Architecture: TECH/TIER -> CHASSIS/PLATFORM -> SPECIALIZATION -> MISSION PACKAGE -> VALID CONFIGURATION -> UPGRADES -> GENERAL/DOCTRINE.

## Immediate physical gates for R1
1. Rifle Squad produces x4 and remains visually readable at normal gameplay scale.
2. Base Engineer construction works.
3. Recovered Construction Crew variants are present/functional where intended.
4. Building footprints/clearances prevent invalid overlap.
5. Building graphics are semantically correct and distinct.
6. Full production graph remains available.
7. Power Grid progression works.
8. Native Rusted Warfare AI independently constructs, produces and attacks.
9. WDC land/water/bridge/Naval Yard behavior works.
10. Victory/defeat flow works.

## Failure policy
On failure, preserve passing capability LKGs. Trace only the failed capability to its strongest recovered implementation and repair without rewriting Rusted Warfare or unrelated working systems.

## Persistence / offline policy
Maintain reconstructable local working copies for poor-connectivity operation. GitHub is authoritative working persistence after migration; Mac copies are backup/recovery copies and local execution environments, not routine conversational memory.

No secrets belong in this repository.