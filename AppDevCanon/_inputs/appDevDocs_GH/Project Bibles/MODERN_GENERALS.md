# MODERN GENERALS — MASTER PROJECT BIBLE

Status: AUTHORITATIVE RECOVERED CANON — reconciled 2026-10-03
Governance: EITRI v0.2.0 / EITRIMB thin governor / LCAS FULL.

## NON-DRIFT CANON LOCK — READ BEFORE ANY MODERN GENERALS RESPONSE
Modern Generals already has established game canon. Recover and preserve it before proposing changes.

The recent 36-General work is a SCOPE-DOWN / CONSOLIDATION of the already-established larger game, NOT a redesign, restart, vertical-slice strategy, new asset architecture, or new mechanics exercise.

Canonical interpretation:
EXISTING MODERN GENERALS GAME + EXISTING DATABASES + EXISTING MECHANICS + EXISTING ASSETS/CONTENT
→ scale/consolidate breadth to the locked v1 36-General release
→ preserve applicable established mechanics/content/assets
→ finish the full game.

Do not reinterpret temporary Dragon, USA/China/GLA, M56, Alpha, C-series or other test packages as final product scope. They are test/recovery/donor evidence only.

Do not claim that an exact historical final 36-name list must be recovered before work can continue. The larger established General pool is the source pool; final v1 selection/consolidation may be scenario-appropriate/random within the established allocation and game scenario. Omitted/merged Generals donate useful established doctrines, assets, technologies and abilities to surviving Generals where appropriate.

## Product identity
Modern Generals is the active modern RTS game lineage, a spiritual successor to the classic Westwood-era Command & Conquer / Generals design lineage.

Product thesis:
- Modernize the technology. Preserve the soul.
- The Mod proves the game. Native realizes it.
- One game, one canon, two implementations during development.

Rusted Warfare Modern Generals is the Mod/LAB implementation and gameplay laboratory. Rusted Warfare is its engine: do not rebuild native/proven Rusted Warfare systems for the mod. Native iPadOS/macOS/iOS is the definitive independent implementation using the shared Modern Generals canon.

Rogues Gallery is an optional Modern Generals mod/add-on/meme-generator/satirical layer, not the canonical roster.

## Governing final-release scope
The target is the FULL FINAL v1 GAME, not a Dragon vertical slice, not a three-faction product, and not a sequence of test builds treated as product architecture.

- v1: exactly 36 playable doctrine-distinct Generals.
- v2: 75 total playable Generals = retained 36 + 39 additional.
- v1 includes independent EDEN Initiative for Skirmish/WDC; in Story it is AI-only in approximately the final 2–3 missions.
- civilians/rogue actors/NPC factions are independent Story actors, not canonical playable-General slots.
- all complete game systems/economy/mechanics are release scope.

Recovered 36-slot allocation from the scope-down decision:
- USA 5
- China 5
- Russia 4
- Europe 7
- Indo-Pacific / South Asia 4
- Middle East 3
- Africa 5
- Americas 1
- Irregular / Non-state 2
TOTAL 36.

The consolidation rule is to remove overlapping Generals based on production priorities, specialist assets, abilities and battlefield behavior while retaining useful established doctrines/assets/abilities from omitted/merged Generals. Selection can be scenario-appropriate/random to fit the game scenario; it is not a recovery blocker.

## EXISTING ASSET DATABASE — AUTHORITY LOCK
Modern Generals already has an established asset/database lineage. DO NOT propose creating a new asset/equipment database from scratch.

Recovered lineage:
- original master database: 1,039 gameplay/design asset records across the earlier larger General/faction structure;
- expanded platform-family database: 2,108 records while preserving the permanent asset IDs and adding platform-family/variant relationships;
- later Asset Production Work / complete production database: 2,352 records;
- additional EDEN material brought the production queue to approximately 2,394 records in later pre-flight work.

Recovered canonical database locations/names include:
- `DATABASE/master_asset_database.json`
- `DATABASE/master_asset_database.csv`
- `DATABASE/master_asset_database.md`
- supporting `generals.json`, `factions.json`, `alliances.json`, `technologies.json`, `asset_families.json`
- per-General manifests/specifications and Asset Production Work material.

Recovered schema/relationship concepts include permanent asset IDs, faction, General, object/type, mechanics/consumer IDs, graphics consumers, production/integration/verification state, provenance, real-world inspiration, manufacturer/classification where applicable, platform-family relationships, `PLATFORM_FAMILY_ID`, `PARENT_ASSET_ID`, `VARIANT_OF`, shared components, technology generation and alliance/capture unlock relationships.

Asset categories already encompass units, infantry, buildings, defenses, aircraft, helicopters, drones/UAVs, naval/amphibious, support/logistics, construction, resources/economy, technologies, upgrades, abilities, superweapons, projectiles, effects, icons/UI, portraits and shared/platform-family components.

The current operation is:
RECOVER EXISTING DATABASE FILES → reconcile/filter/consolidate them to the 36-General v1 scenario → retain unused records as donor/reference material → enrich/adapt for Native 3D where required.

It is NOT:
INVENT NEW EQUIPMENT MATRIX → INVENT NEW ASSET DATABASE.

Historical M56 implementation evidence (405 INIs, 493 PNG paths, 57 TMX maps) is an implementation/recovery lineage, not the master asset database. Duplicate development art in M56 does not invalidate the authoritative database.

## Campaign / modes
Recovered authoritative goals:
- era approximately 2000–2035+.
- v1 Story architecture retains the established ceiling of up to 150 unique canonical missions, with a short shared Grand Campaign approximately 25–35 missions plus deeper faction campaigns and alternative victories.
- MG-CAM-141–150 convergence and MG-CAM-150 full story-valid alliance roster via production were established targets.
- later v2 expansion target is approximately 150–200 missions with additional/alternative Generals/perspectives; do not overwrite the v1 ceiling with the v2 target.
- Story Pipeline v2.0 remains canonical.
- MAPGEN remains canonical/locality-aware.
- authored Story Campaign and dynamic World Domination Campaign are separate ways to play. They share systems/assets but never progression/state.
- no predetermined campaign winner; campaign state/alliance consequences retained.

WDC = World Domination Campaign. Strategic WDC architecture and individual tactical-map implementation are distinct layers; do not conflate a 512x512 tactical/map implementation with the entire strategic WDC structure. Recovered WDC work includes large strategic-region/theater concepts plus reusable operational maps/variants. Preserve exact recovered data when available rather than inventing replacements.

## Core gameplay architecture
WORLD/BLOC/NATION/FACTION
→ GENERAL
→ DOCTRINE
→ TECH/TIER
→ CHASSIS/PLATFORM ACCESS
→ BUILDING SPECIALIZATION
→ MISSION PACKAGE
→ VALID CONFIGURATION
→ EQUIPMENT UPGRADES
→ GENERAL/DOCTRINE MODIFIERS.

NO EMPTY BUILDINGS:
BUILD → PRODUCE/SUPPORT → SPECIALIZE → OPERATE → ADAPT.

Retained domains:
economy, resources, power, construction, production, combat, native/proven AI, technology, chassis/platforms, building specialization, mission packages/configurations, equipment upgrades, doctrines, logistics, repair/recovery, radar/ISR, EW/counter-UAS, air defence, artillery/fires, infantry, ground, air/UAV, naval, strategic systems, objectives, fog, victory/defeat, save/reload/replay and campaign/WDC integration.

Technology goals include T1 Legacy → T2 Current → T3 Advanced/Prototype → T4 Experimental/Strategic. Earlier work also established higher-tier construction/building progression and advanced-builder concepts; recover rather than redesign.

Veterancy is locked:
Regular → Veteran → Elite.
Veteran = modest automatic improvements. Only Elite may add one appropriate capability. No Heroic tier.

Real-world reference rule:
canon → real-world reference → gameplay abstraction → proven engine/native capability.

## Roster source pool and consolidation
Authoritative release counts:
- v1 = 36
- v2 = 75 total

Recovered pre-consolidation source structure included a larger 45-General/national-command pool: USA 6; China 6; Russia 5; Europe including Germany, France, UK, Poland, Sweden, Italy, Finland and Türkiye; Japan; South Korea; India; Pakistan; Australia; Israel; Saudi Arabia; Iran; South Africa; Egypt; Morocco; Nigeria; Kenya; Ethiopia; Algeria; Canada; Brazil; plus three irregular-network specializations.

Historical recovered named evidence includes USA/Vanguard; China/Dragon; Russia/Hammer; UK/Lancer; France/Chevalier; Germany/Panzer; Poland/Hussar; Ukraine/Trident; Türkiye/Anatolia; India/Rajput; Pakistan/Falcon; Japan/Shogun; Korea/Tiger; Israel/Merkava; Iran/Zagros; Saudi Arabia/Desert Falcon; Egypt/Nile; South Africa/Springbok; Nigeria/Eagle; Brazil/Jaguar; Mexico/Aztec; Australia/Wallaby; Indonesia/Garuda Nusantara; GLA/Nomad; EDEN/Warden.

These historical names are source-pool/recovery evidence, not a requirement to reconstruct one lost sacred final-36 list. Use established scenario/allocation/consolidation rules and existing databases.

Recovered doctrine lineage includes USA Air Force → USA Air & Space Command; China Tank → China Heavy Armor; China Infantry → China Mechanized Infantry; China Nuclear → China Rocket Force; Stealth/Demolition → irregular-network doctrines; Laser/Superweapon concepts redistributed into modern technologies/doctrines. Preserve exact database definitions where recovered.

EDEN conceptual identities recovered in project history include Architect, Gardener, Shepherd, Voyager, Guardian, Falconer and Tinkerer, with cycle SEED → GENERATE → FABRICATE → ADAPT → RECLAIM → EXPAND → RELOCATE. These Generations are doctrinal/conceptual evolutions, not technology tiers. Exact historical sequence/order remains unresolved.

## Dragon donor/test contract
Dragon / China Combined Arms is a mature mechanics/content donor and regression/reference lineage, not the final-game scope.

Recovered Dragon content target:
- 15 buildings including Naval Yard extension
- 6 infantry
- 15 ground roles
- 5 chassis families
- 8 air/UAV
- 6 naval
- Vehicle Factory specializations: Mechanized / Armor / Fires / Air Defense / Support

Established infantry roles include Rifle, AT, MANPADS, Engineer, Recon/Scout and Special Forces.

Power Plant progression:
Core Grid / Basic Power → Grid Expansion → Hardened Grid → High-Output Grid → Strategic Grid.

Technology Center T1/T2/T3/T4 state progression exists in the Mod lineage. Unsafe global cross-unit tier hiding/gating was deliberately deferred where safe team-state behavior was not proven.

Recovered alpha economy implementation, not final balance:
HQ +4/60; Power Plant +2/60; Supply Network I +8/40; Supply Network II +14/40; Supply Network III +22/40; FOB +5/50; Strategic Center +6/60; Supply vehicle = logistics/repair support.

## Rusted Warfare Mod/LAB recovery
Recover capability-by-capability; newest package is not automatically LKG.

Recovered lineage includes v0.1.x/v0.4.x engine-facing contracts; Vanguard/Dragon/Nomad test foundation; CT02-R2; A1/A1-R1; A2/A3; M56 donor/recovery; C2/C3; Construction Crew; Power Grid recovery.

Known visual/regression evidence includes HQ consumer failures, effectively invisible builder, tiny infantry readability problems, wrong/temporary building graphics, duplicate-hash donors, Supply Depot/AA infantry placeholders and rejected aggregate visual regressions.

Preserve device/runtime evidence over filename recency. Failed/partial builds remain evidence donors.

## Assets / full 36-General production
Asset production targets the complete 36-General v1 game by using the existing asset database and donor pool.

Modern Generals models recognizable real-world-inspired equipment. Existing 3D model examples should be used as reference/production inputs so Blender/DÜRER does not infer complex real-world equipment from prose alone.

Pipeline:
recover existing asset database + established equipment canon → filter/consolidate to selected 36 while retaining donor records → identify real-world inspiration → collect photos/technical references/existing 3D examples → DÜRER/Blender master/adaptation as legally appropriate → preserve recognizable proportions/silhouette/role → optimize for large-army RTS use → derive established variants/modules/configurations → integrate → runtime/physical verify.

Do not invent arbitrary polygon budgets, LOD counts, unit-count targets, equipment mappings or General content. Large-army play means excessive showcase detail is unnecessary; recognizable identity and gameplay readability are the priority.

Availability of model examples removes the previous asset-production reason to serialize all work behind Dragon. Full-roster asset/reference production may proceed in dependency-aware parallel work.

## Native Apple implementation
Platform hierarchy:
iPadOS PRIMARY → macOS EXPANDED → iOS PORTABLE.
“One Modern Generals”: shared simulation/canon/campaign/save model with device-appropriate UI.

Primary architecture:
Swift + SwiftUI; RealityKit presentation; Reality Composer Pro where useful; GameplayKit/custom deterministic logic; Metal/MetalFX only when justified; renderer-independent simulation.

Modules:
MGCore, MGContent, MGWorld, MGRenderer, MGAI, MGCampaign, MGSaveReplay, MGInterface, platform adapters, shared assets.

RealityKit consumes authoritative battle state; presentation does not own gameplay truth.
MGNavigation has a GameplayKit grid baseline; Recast Navigation + Detour remain intended large-RTS production navigation backend.

Presentation baseline is fixed/isometric RTS. free3D and arWarTable remain later presentation capabilities; architecture stays 3D-capable/presentation-agnostic.

Recovered UI direction: TINY / low-clutter. Do not invent unrecovered final visual styling.

## Evidence/governance
GENERATED != SAVED != IMPLEMENTED != BUILT != TESTED != VERIFIED != RELEASED.
NEWEST != LKG.
UNKNOWN != PASS.
TEMPORARY TEST SCOPE != PRODUCT SCOPE.
SCOPE-DOWN != REDESIGN.

Authority order:
1. explicit current user-locked canon
2. authoritative recovered Project Bible/conversation canon
3. recovered existing databases/manifests
4. device/runtime evidence
5. audited implementation evidence
6. production manifests/test contracts
7. older recovery/conversation evidence
8. external research only for genuine gaps

AUTO continues safe available work until the requested final-game deliverable is complete or a genuine unavailable dependency blocks remaining safe work. Retry must change something.

## Offline/local-first
Connectivity is unreliable. Ordinary development after provisioning should remain local/offline-capable where practical. GitHub/cloud/plugins are accelerators and persistence/coordination layers, not mandatory runtime/build dependencies when adequate local capability exists.

## GitHub authority
AppDev/EITRI governance + Project Bibles: lucasbuzek/Lucas-private-appDevDocs.
Native source/state: lucasbuzek/Modern-Generals-native-iOS-macOS-.
Rusted Warfare Mod/LAB source/recovery: lucasbuzek/modern-generals-RWMOD.
Mac copies are backup/recovery plus bounded local execution, not routine conversational memory.

## Current recovery/implementation priorities
1. Recover the actual existing master asset database / Asset Production Work files and manifests; do not recreate them from memory.
2. Reconcile the existing larger asset/General pool to the scenario-appropriate 36-General v1 allocation.
3. Preserve omitted records as donor/reference content.
4. Continue full-game mechanics/economy/campaign/WDC implementation from established canon.
5. Adapt existing asset records for Native 3D using real-world/existing-model references.
6. Verify with evidence; do not convert persistence into functionality claims.

## Remaining UNKNOWNs
Only mark genuinely unrecovered details UNKNOWN. Missing historical detail is not permission to redesign established canon.