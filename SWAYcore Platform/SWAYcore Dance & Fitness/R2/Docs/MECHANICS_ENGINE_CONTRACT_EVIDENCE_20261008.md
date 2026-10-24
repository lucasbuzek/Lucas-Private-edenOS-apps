# M6 engine contract evidence — 2026-10-08

Command: `swift test --scratch-path /tmp/sway-m6-tests` in `Packages/SWAYcoreEngine`.

- Calibration machine: 14 tests, 0 failures.
- `SwayPoseMapper` / SWAYHumanoid-v1 mapping (`HumanoidContractTests`): 5 tests, 0 failures.
- `SwayMatchTruth` MATCH / NOT MATCHED / UNKNOWN (`MatchTruthTests`): 7 tests, 0 failures.
- `SwayTimelineMath`, including the 20 BPM floor (`TimelineMathTests`): 5 tests, 0 failures.
- Entire package: 34 tests, 0 failures.

No production source belonging to these four protected contracts was edited by Task 8.
