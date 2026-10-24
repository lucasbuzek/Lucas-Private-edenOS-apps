# SWAYcore Dance & Fitness 0.2 — separate workstream register
**Scope:** operational separation inside the existing Dance & Fitness product; no second source tree. Parent authority = `../Authority/PRODUCT_BIBLE.md` and `../../Authority/PROJECT_BIBLE.md`; full requirement/acceptance = `CONTRACT.md`.
**As of 2026-10-22:** contract exists; integration and new 0.2 binary NOT yet implemented. R2 canonical source stays at `../R2/`, R2/VERSION `R2-0.1.0`, product LKG NONE.

| Track | Owner | Existing authoritative inputs | 0.2 work output / next proof | Currently observed status |
| --- | --- | --- | --- | --- |
| DF-01 App UI | ForgeMASTER / ForgeAPPLE / APPLE review | `../R2/App/SWAY/Views/{RootView,HomeView,MoveLibraryView,WorkoutPlayerView,SettingsView,CreateMoveView,ProgressViewScreen}.swift`; established reference mockups | Existing R2 stage with actual ZERO fallback; all 4 tabs and consumer journeys working; visual/touch/rotation tests | Source present; Oct 22 partial creator report; integrated 0.2 UNKNOWN |
| DF-02 Movement/Engine ZERO | ForgeGAME / ForgeAPPLE | `../../SWAYcore Engine/Avatar/ZERO/`; `../R2/Packages/SWAYcoreEngine/`; canonical `StickFigureView.swift` | One movement truth and portable stickman rendering in consumer Learn/Workout; camera and calibration adapter, independent tests | Shared Engine 31/31 PASS, ZERO signed build PASS; iPhone runtime UNKNOWN |
| DF-03 Music/workout | ForgeMASTER / ForgeGAME | `../R2/App/SWAY/Views/WorkoutPlayerView.swift`, `../R2/App/SWAY/Services/NativeCapabilities.swift` | 26 move mapping; 10 modes; beat-clock-generated/local/MusicKit journeys and failure paths | 2026-10-18 source-level regression reports; full physical end-to-end UNKNOWN |
| DF-04 Creator, progress, local share | ForgeMASTER / ForgeAPPLE | `../R2/App/SWAY/Views/CreateMoveView.swift`, `../R2/App/SWAY/Models/ProfileSharing.swift`, `../R2/App/SWAY/Services/SwayStore.swift` | Persist profile; Create/Save/Export/Import .swaypack round-trip; true Results/Health; opt-in recording | Code exists; 0.2 functional round-trip UNKNOWN |
| DF-05 Community/official | WEAVER / ForgeMASTER | `../../SWAY/Community/ONLINE_COMMUNITY_PRODUCT_CONTRACT.md`; `../../SWAY/Sharing/LOCAL_SHARING_AND_SHARED_SESSIONS.md`; `../R2/App/SWAY/Views/SwayComingToSWAYView.swift` | In 0.2 source-backed honest preview only; official backend adapter, publishing, discover/search, profiles/follows, safety, account deletion gates separate | Community requirements RECOVERED; deployed backend UNKNOWN |
| DF-06 Production avatar | DÜRER / ForgeGAME / ForgeAPPLE | `../R2/Build/native3d_convergence_20261018/` and Oct 21/22 evidence; `../R2/App/SWAY/Avatar/` | Lucia and YOUR DANCER approved native 3D; 44/21 validation, visual + device quality, explicit runtime activation | Unapproved isolated candidates; runtimeApproved false; does not block functional 0.2 |
| DF-07 Recovery/QA | ForgeMASTER / CONDUCTOR coordination | `../STATE.txt`, `../Authority/EVIDENCE_LEDGER.md`, `../R2/Build/report/`, original Builds 81–83 and protected historical refs | Reconcile SHA/Git/one backup; source regression & actual physical evidence; preserve working source | Historical functional 81–83 binary UNKNOWN; product LKG NONE |

## Work isolation contract
1. UI/Product features work independently from production avatar graphics; the 0.2 app consumes the existing ZERO Engine interface through a tested adapter rather than editing the Engine's canonical movement definition opportunistically.
2. Official Community may be specified and independently prototyped, but its account/server path never gates offline v0.2 local features or silently publishes personal content. SWAYZ, KIDZ, Studio and other family products are not worked into this app.
3. R2 is NOT retired, renamed or bulk-copied; its existing changes, snapshots and read-only protected references remain available. Version labels and product LKG advance only through exact tested gates.
4. 0.2 files are a subordinate coordination/documentation lane until tested implementation changes are intentionally integrated through ForgeMASTER. No extra independent project root or shadow Project Bible.
5. Requirements triage: PASS only for an observed exact test, PARTIAL for incomplete integrated journeys, FAIL for a reproducible defect, UNKNOWN for no appropriate test; distinguish historical artifacts from current baseline.

## First executable checkpoint
- Identify precise original Build 81–83 (if recoverable), current R2 file/hash/state and ZERO TestHost integration APIs without changing source.
- Diff concrete R2 consumer controls against `CONTRACT.md`; create a requirement-to-source/test matrix, then repair only missing app UI, movement and sharing gaps.
- Verify combined consumer use of ZERO with app-local offline Beats and canonical count timing, first through regression tests then signed/physical gates. Do not uninstall an existing free-profile iPhone app to bypass the 3-slot block.
- Reserve independent official backend implementation for verified provider/security/rights approval; no invented deployed environment.

**No release promotion / no app installation / no runtime approval authorized by this register.**
