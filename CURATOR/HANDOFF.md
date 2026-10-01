# CURATOR — Execution Handoff

## WHAT SHOULD CODEX EXECUTE NEXT?

Work against the existing local checkout corresponding to `lucasbuzek/Lucas-Private-edenOS-apps`. Do not recreate the repository through GitHub APIs.

1. Read current AppDev/EITRIMB authority from `lucasbuzek/Lucas-private-appDevDocs` and the current `Project Bibles/CURATOR.md`.
2. Ensure the local CURATOR working tree contains/restores the authoritative v1.3.5 candidate represented by `CURATOR/backups/v1.3.5/`. Verify the reconstructed archive SHA-256 is `496dc92e30087c56cf652c2c67a829aae8149b7c317290cb09c56d3188859edd` before using it.
3. Build CURATOR natively on the target macOS/M1 environment using the project's existing build mechanism. Do not substitute portable Swift tests for this gate.
4. Launch the built application and exercise the smallest real native workflow required to prove startup/runtime viability. Capture exact build/runtime evidence.
5. If build or runtime fails, diagnose the demonstrated failure, implement the narrowest correct repair in the local workspace, rerun the failed gate, then run the existing portable regression suite to detect regressions.
6. Once native build/runtime passes, continue to the next executable product gap: a real configured professional-provider round trip, preserving provider boundaries and CURATOR's standalone domain ownership.
7. Commit and push verified changes and update this HANDOFF.md with only the new volatile continuation state.

## Current bounded evidence
PASS: portable Swift regression 40/40; macOS Swift syntax parse; installer shell syntax; installer executable permissions; package ZIP integrity; GitHub backup reconstruction integrity.

UNKNOWN: native macOS build/runtime; M1 physical verification; real professional-provider round trips.

No native LKG and no production/public release are currently claimed.

## Continuity rule
Repository persistence is not functionality evidence. Build, launch, test and provider results must be recorded only at the state actually demonstrated.
