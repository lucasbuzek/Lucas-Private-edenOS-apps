# Mechanics merge log — 2026-10-08

Base inspected: `476a1c0` (the latest repository snapshot supplied as the Task 8 starting point; it contains the latest puppet-rig work at `2b21781`).

## M1 — `swaycore-release-mechanics-20261008`

**BLOCKED — source ref unavailable.** The supplied clone has no remotes configured and no local, remote-tracking, reflog, or unreachable ref/commit named `swaycore-release-mechanics-20261008`. Commands tried: `git branch -a`, `git show-ref`, `git reflog --all`, `git fsck --no-reflogs --unreachable`, and history searches for the Task 2 receipt/API filenames. Consequently there are no accessible Task 2 diff hunks to classify; inventing hunk decisions would violate the evidence contract. Decision for the unavailable branch as a whole: **drop (blocked)** — no object exists to adopt or adapt. Task 8 mechanics are implemented independently in M3–M5 rather than falsely represented as a merge.

## M2 — `swaycore-salvage-downloads-20261008`

The named ref is absent, but its source commit is present as `87d2f56` and is already an ancestor of the supplied base. The following classifies every one of its 48 zero-context diff hunks (hunk numbers are per file):

- **ADOPT** `SWAYcore/R2/App/CAPABILITY_LEDGER.md` hunk 1 (`-44,0 +45,5`) — retain the evidence note identifying salvaged capabilities.
- **ADOPT** `SWAYcore/R2/App/SWAY/Services/NativeCapabilities.swift` hunk 1 (`-108,0 +109`) — retain the local audio/timeline state implementation as the authoritative salvage.
- **ADOPT** `SWAYcore/R2/App/SWAY/Services/NativeCapabilities.swift` hunk 2 (`-111 +112`) — retain the local audio/timeline state implementation as the authoritative salvage.
- **ADOPT** `SWAYcore/R2/App/SWAY/Services/NativeCapabilities.swift` hunk 3 (`-117,0 +119`) — retain the local audio/timeline state implementation as the authoritative salvage.
- **ADOPT** `SWAYcore/R2/App/SWAY/Services/NativeCapabilities.swift` hunk 4 (`-144,0 +147,9`) — retain the local audio/timeline state implementation as the authoritative salvage.
- **ADOPT** `SWAYcore/R2/App/SWAY/Services/NativeCapabilities.swift` hunk 5 (`-151,0 +163`) — retain the local audio/timeline state implementation as the authoritative salvage.
- **ADOPT** `SWAYcore/R2/App/SWAY/Services/NativeCapabilities.swift` hunk 6 (`-159,0 +172`) — retain the local audio/timeline state implementation as the authoritative salvage.
- **ADOPT** `SWAYcore/R2/App/SWAY/Services/NativeCapabilities.swift` hunk 7 (`-177,0 +191`) — retain the local audio/timeline state implementation as the authoritative salvage.
- **ADOPT** `SWAYcore/R2/App/SWAY/Services/NativeCapabilities.swift` hunk 8 (`-184 +198,2`) — retain the local audio/timeline state implementation as the authoritative salvage.
- **ADOPT** `SWAYcore/R2/App/SWAY/Services/NativeCapabilities.swift` hunk 9 (`-195,0 +211,17`) — retain the local audio/timeline state implementation as the authoritative salvage.
- **ADOPT** `SWAYcore/R2/App/SWAY/Services/NativeCapabilities.swift` hunk 10 (`-787,0 +820,29`) — retain the local audio/timeline state implementation as the authoritative salvage.
- **ADOPT** `SWAYcore/R2/App/SWAY/Services/NativeCapabilities.swift` hunk 11 (`-789,0 +851`) — retain the local audio/timeline state implementation as the authoritative salvage.
- **ADOPT** `SWAYcore/R2/App/SWAY/Services/NativeCapabilities.swift` hunk 12 (`-792 +854`) — retain the local audio/timeline state implementation as the authoritative salvage.
- **ADOPT** `SWAYcore/R2/App/SWAY/Services/NativeCapabilities.swift` hunk 13 (`-795 +857,7`) — retain the local audio/timeline state implementation as the authoritative salvage.
- **ADOPT** `SWAYcore/R2/App/SWAY/Services/NativeCapabilities.swift` hunk 14 (`-797 +864,0`) — retain the local audio/timeline state implementation as the authoritative salvage.
- **ADOPT** `SWAYcore/R2/App/SWAY/Services/NativeCapabilities.swift` hunk 15 (`-800,0 +868,2`) — retain the local audio/timeline state implementation as the authoritative salvage.
- **ADOPT** `SWAYcore/R2/App/SWAY/Services/NativeCapabilities.swift` hunk 16 (`-808 +877`) — retain the local audio/timeline state implementation as the authoritative salvage.
- **ADOPT** `SWAYcore/R2/App/SWAY/Services/NativeCapabilities.swift` hunk 17 (`-851,0 +921,3`) — retain the local audio/timeline state implementation as the authoritative salvage.
- **ADOPT** `SWAYcore/R2/App/SWAY/Services/NativeCapabilities.swift` hunk 18 (`-872,7 +944`) — retain the local audio/timeline state implementation as the authoritative salvage.
- **ADOPT** `SWAYcore/R2/App/SWAY/Services/NativeCapabilities.swift` hunk 19 (`-885,0 +952,12`) — retain the local audio/timeline state implementation as the authoritative salvage.
- **ADOPT** `SWAYcore/R2/App/SWAY/Services/NativeCapabilities.swift` hunk 20 (`-923,0 +1002,2`) — retain the local audio/timeline state implementation as the authoritative salvage.
- **ADOPT** `SWAYcore/R2/App/SWAY/Services/NativeCapabilities.swift` hunk 21 (`-925 +1005,7`) — retain the local audio/timeline state implementation as the authoritative salvage.
- **ADOPT** `SWAYcore/R2/App/SWAY/Services/NativeCapabilities.swift` hunk 22 (`-935,2 +1021,2`) — retain the local audio/timeline state implementation as the authoritative salvage.
- **ADOPT** `SWAYcore/R2/App/SWAY/Services/NativeCapabilities.swift` hunk 23 (`-938,3 +1024,3`) — retain the local audio/timeline state implementation as the authoritative salvage.
- **ADOPT** `SWAYcore/R2/App/SWAY/Services/NativeCapabilities.swift` hunk 24 (`-944,0 +1031,2`) — retain the local audio/timeline state implementation as the authoritative salvage.
- **ADOPT** `SWAYcore/R2/App/SWAY/Services/NativeCapabilities.swift` hunk 25 (`-958,0 +1047`) — retain the local audio/timeline state implementation as the authoritative salvage.
- **ADOPT** `SWAYcore/R2/App/SWAY/Services/NativeCapabilities.swift` hunk 26 (`-961,4 +1050,10`) — retain the local audio/timeline state implementation as the authoritative salvage.
- **ADOPT** `SWAYcore/R2/App/SWAY/Services/NativeCapabilities.swift` hunk 27 (`-1281 +1376,10`) — retain the local audio/timeline state implementation as the authoritative salvage.
- **ADOPT** `SWAYcore/R2/App/SWAY/Services/NativeCapabilities.swift` hunk 28 (`-1306 +1410`) — retain the local audio/timeline state implementation as the authoritative salvage.
- **ADOPT** `SWAYcore/R2/App/SWAY/Services/NativeCapabilities.swift` hunk 29 (`-1308 +1412`) — retain the local audio/timeline state implementation as the authoritative salvage.
- **ADOPT** `SWAYcore/R2/App/SWAY/Views/MoveLibraryView.swift` hunk 1 (`-89 +89`) — retain the minimal existing wiring to the salvaged mechanics without restyling.
- **ADOPT** `SWAYcore/R2/App/SWAY/Views/RootView.swift` hunk 1 (`-270 +270`) — retain the minimal existing wiring to the salvaged mechanics without restyling.
- **ADOPT** `SWAYcore/R2/App/SWAY/Views/WorkoutPlayerView.swift` hunk 1 (`-130 +130`) — retain the minimal existing wiring to the salvaged mechanics without restyling.
- **ADOPT** `SWAYcore/R2/App/SWAY/Views/WorkoutPlayerView.swift` hunk 2 (`-163,0 +164,2`) — retain the minimal existing wiring to the salvaged mechanics without restyling.
- **ADOPT** `SWAYcore/R2/App/SWAY/Views/WorkoutPlayerView.swift` hunk 3 (`-349,0 +352,2`) — retain the minimal existing wiring to the salvaged mechanics without restyling.
- **ADAPT** `SWAYcore/R2/App/SWAY/Views/WorkoutPlayerView.swift` hunk 4 (`-361,0 +366`) — retain single-clock phrase/scoring behavior; M3/M4 replace remaining wall-clock/session behavior.
- **ADAPT** `SWAYcore/R2/App/SWAY/Views/WorkoutPlayerView.swift` hunk 5 (`-363 +368`) — retain single-clock phrase/scoring behavior; M3/M4 replace remaining wall-clock/session behavior.
- **ADAPT** `SWAYcore/R2/App/SWAY/Views/WorkoutPlayerView.swift` hunk 6 (`-369,0 +375,3`) — retain single-clock phrase/scoring behavior; M3/M4 replace remaining wall-clock/session behavior.
- **ADAPT** `SWAYcore/R2/App/SWAY/Views/WorkoutPlayerView.swift` hunk 7 (`-371,2 +379,2`) — retain single-clock phrase/scoring behavior; M3/M4 replace remaining wall-clock/session behavior.
- **ADAPT** `SWAYcore/R2/App/SWAY/Views/WorkoutPlayerView.swift` hunk 8 (`-374 +382`) — retain single-clock phrase/scoring behavior; M3/M4 replace remaining wall-clock/session behavior.
- **ADAPT** `SWAYcore/R2/App/SWAY/Views/WorkoutPlayerView.swift` hunk 9 (`-391 +399`) — retain single-clock phrase/scoring behavior; M3/M4 replace remaining wall-clock/session behavior.
- **ADAPT** `SWAYcore/R2/App/SWAY/Views/WorkoutPlayerView.swift` hunk 10 (`-400 +408`) — retain single-clock phrase/scoring behavior; M3/M4 replace remaining wall-clock/session behavior.
- **ADOPT** `SWAYcore/R2/App/Tests/SWAYTests/SWAYSmokeTests.swift` hunk 1 (`-1,0 +2`) — retain deterministic regression coverage supplied by salvage.
- **ADOPT** `SWAYcore/R2/App/Tests/SWAYTests/SWAYSmokeTests.swift` hunk 2 (`-6,0 +8,39`) — retain deterministic regression coverage supplied by salvage.
- **ADOPT** `SWAYcore/R2/App/Tests/SWAYTests/SWAYSmokeTests.swift` hunk 3 (`-29,0 +70,83`) — retain deterministic regression coverage supplied by salvage.
- **ADOPT** `SWAYcore/R2/Tools/regression/run_library_analysis_state.py` hunk 1 (`-0,0 +1,35`) — retain deterministic regression coverage supplied by salvage.
- **ADOPT** `SWAYcore/R2/Tools/regression/run_local_audio_clock_state.py` hunk 1 (`-0,0 +1,37`) — retain deterministic regression coverage supplied by salvage.
- **ADOPT** `SWAYcore/R2/Tools/regression/run_workout_phrase_state.py` hunk 1 (`-0,0 +1,85`) — retain deterministic regression coverage supplied by salvage.

No hunk was silently omitted; `git show --format= --unified=0 87d2f56 -- SWAYcore/R2` produced the 48 entries above.
