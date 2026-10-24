# Research and adoption report

Evidence basis: the supplied handoff (read in full), the received candidate source, and targeted web lookups made during this session (Apple developer documentation pages, vendor pages). Search snippets are not quoted; where a decision rests on something I could not verify, it says so. Nothing external was downloaded or incorporated: the authoring sandbox had no network access to download hosts, so every ADOPT/ADAPT below is a **decision for the Mac builder**, not an accomplished integration.

Decision key: ADOPT (use as is) / ADAPT (use with SWAY modification) / REFERENCE (learn from, no dependency) / REJECT.

## 1. Pose acquisition (Vision)
| Item | Detail |
|---|---|
| Problem | Camera to body joints, mapped into the SWAYHumanoid-v1 23-joint contract. |
| Candidate | Apple Vision `VNDetectHumanBodyPoseRequest` (2D, already in Build 147) and `VNDetectHumanBodyPose3DRequest` (3D, camera-relative). |
| Source / version | Apple developer documentation (Vision: "Detecting human body poses in 3D"). Version depends on the Xcode/OS SDK installed; not pinned here. |
| Licence | Platform SDK; no redistribution. |
| Evidence | Apple documents the 3D request as returning a different joint set than the 2D detector. Build 147 physical evidence exists only for the 2D path. |
| Advantages | 3D would give depth for foreshortened moves (side lunge, knee lift). |
| Disadvantages | Different joint set; more compute; no physical-device evidence for SWAY; requires its own calibration/coordinate work. |
| Decision | **2D = ADOPT (kept, protected). 3D = REFERENCE** for a later phase behind a capability flag. |
| Implementation result | New `SwayPoseMapper` maps canonical Vision names into SWAYHumanoid-v1; Apple joints never redefine the contract. Toes are omitted, not invented. Unit-tested in the engine package (Swift tests written, not yet executed). |

## 2. Character runtime (RealityKit)
| Item | Detail |
|---|---|
| Problem | Articulated COACH/YOU runtime. |
| Candidate | Current RealityKit skeletal-pose/skeleton APIs, including IK and retargeting facilities described in Apple's "character skeletons" documentation. |
| Evidence | Build 153 already loads per-clip USDC through RealityKit on device. I did not verify the newer API surface against the minimum deployment target in this session. |
| Decision | **Keep the Build 153 USDC + clip approach (ADOPT, proven). RealityKit IK/retargeting = REFERENCE**; evaluate after the first production character exists, against measured frame time. |
| Implementation result | Asset factory exports in the Build 153 convention (base USDC + one USDC per clip) so the existing loader keeps working. |

## 3. Movement recognition (Create ML action classification)
| Decision | **REFERENCE.** Apple's live action recognition shows multi-frame pose windows feeding a classifier. SWAY's deterministic movement/timing/scoring contract stays authoritative; an ML classifier would add a second, non-deterministic notion of "what move is this". Not adopted. |

## 4. Character base geometry
| Candidate | Licence (as shown by vendor) | Decision | Reason |
|---|---|---|---|
| Quaternius Universal Base Characters | CC0 per vendor page | **REFERENCE, promote to ADAPT only through `register_source.py`** | Vendor page describes a rigged humanoid base. I could not download it or inspect real bone names/topology/materials here, so suitability is **unverified**. The retarget map assumes UE-mannequin-style names and the converter FAILS (never guesses) if any contract joint is missing. |
| Quaternius Universal Animation Library | CC0 per vendor page | **REFERENCE** | Possible source of extra clips through the same retarget map. Not needed for the 20 authored moves, which are baked from SWAY's own movement truth. |
| Ready Player Me | proprietary service | **REJECT** | Third-party generator look (violates the "must not look unmodified third-party" rule); service-continuity risk. I saw search results suggesting the service is being wound down but did not confirm the details; the rejection does not depend on it. |
| Mixamo | Adobe terms | **REFERENCE (naming only)** | No content incorporated; redistribution terms not verified as compatible. |
| VRoid / MakeHuman | not evaluated | **NOT EVALUATED** | No licence/topology evidence gathered. Unknown licensing means do not incorporate. |
| Procedural-from-primitives (Build 153 and my earlier reconstruction) | n/a | **REJECT** | Authority-rejected look. |

Honest consequence: **no production character was created.** The factory is built and unit-tested where possible; the base-model acquisition is a human-confirmed licensing step (`Docs/UNRESOLVED_ITEMS.md` U-01).

## 5. Animation source
| Decision | **ADOPT SWAY's own movement truth.** Clips are baked from `SwayCoachPoseEngine` (pinned by sha256 in `coach_pose_port.py`), so COACH animation, expected YOU pose and matching share one definition. 20 authored moves + a synthetic idle = 21 clips (the 10 proof names preserved). Retarget maths (aim-based, with Blender basis conversion) is unit-tested including a forward-kinematics round trip. External libraries remain optional (section 4). |

## 6. Musical timeline
| Decision | **ADOPT the existing `SwayTimelineEngine` model** (time-derived, grid-aware) and extract its mapping into `SwayTimelineMath` (pure, tested). Found and fixed a tempo-floor defect (40 BPM clamp vs 20 BPM Learn contract). ShazamKit stays an anchor, never the clock (already encoded in the candidate). No beat-tracking library adopted; none was evaluated in depth, so this is "kept existing", not "researched and rejected". |

## 7. Match/score state machine
| Decision | **ADAPT the candidate matcher.** Reference projects I looked at (open-source camera→pose→smoothing→joint-angle→state-machine fitness apps) confirm the architecture; the candidate already has it. Defect fixed: no credit without sufficient joint coverage. Repository not copied. |

## 8. Xcode device-preparation / DeviceSupport incident
| Item | Detail |
|---|---|
| Root cause | **UNKNOWN. Not reproduced.** Web results showed reports of Xcode device preparation consuming disk and of interrupted DeviceSupport copies; I could not tie any to Xcode 27 specifically. |
| Decision | Do not guess a fix. **Guard instead:** `devicesupport_guard.sh` checks free disk, `.copying_lock`, incomplete entries (no Symbols), size sanity and growth rate; it stops safely and **never deletes**. 12 behavioural tests pass against a fake tree. |

## 9. Blender
| Decision | **Blender 5.2.x LTS target; version not verified in this session** (could not run it). Scripts feature-detect operator arguments and layered-action f-curves because those APIs changed across 4.x/5.x. The builder reports the installed version and notes when it differs from the tested line. |

## 10. UI/UX reference products
Apple Fitness+, Just Dance, STEEZY, Dance Reality, Nike Training Club, Peloton: **interaction research only; not examined in depth this session and nothing copied.** The candidate's existing SWAY UI is preserved; no UI redesign was attempted without the ability to run it.
