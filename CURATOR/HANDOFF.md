# CURATOR — Execution Handoff

## WHAT SHOULD CODEX EXECUTE NEXT?

Work against the existing local checkout corresponding to `lucasbuzek/Lucas-Private-edenOS-apps`. Do not recreate the repository through GitHub APIs.

1. Read current AppDev/EITRIMB authority from `lucasbuzek/Lucas-private-appDevDocs` and `Project Bibles/CURATOR.md`.
2. Use the authoritative v1.3.5 candidate represented by `CURATOR/backups/v1.3.5/`; reconstructed archive SHA-256 must be `496dc92e30087c56cf652c2c67a829aae8149b7c317290cb09c56d3188859edd`.
3. The immediate gate is genuinely Mac-local: install/build/run CURATOR natively on Lucas's M1 MacBook. The Mac was reached and Apple Swift 6.4 targeting arm64 macOS 27 was demonstrated. At that check, no CURATOR installer/package was present in `~/Downloads`, so installation was not attempted.
4. Once the package is locally available, execute the packaged installer, capture the exact native build result, launch CURATOR, and exercise the smallest real native workflow proving startup/runtime viability.
5. On failure, diagnose the demonstrated failure, implement the narrowest correct repair in the local workspace, rerun the failed gate, then rerun the portable regression suite.
6. Once native build/runtime passes, continue to a real configured professional-provider round trip while preserving provider boundaries and CURATOR standalone domain ownership.
7. Commit/push verified changes and update this file only with new volatile continuation state.

## Current bounded evidence
PASS: portable Swift regression 40/40; macOS Swift syntax parse; installer shell syntax; installer executable permissions; package ZIP integrity; GitHub backup reconstruction integrity; target Mac reachable; Swift 6.4/arm64 toolchain detected.

UNKNOWN: native CURATOR build/runtime; M1 CURATOR physical verification; real professional-provider round trips.

NOT ATTEMPTED: CURATOR installation on target Mac because the install package was not locally present when checked.

No native LKG and no production/public release are currently claimed.

## Continuity rule
GitHub persistence is not functionality evidence. Mac access is reserved for this bounded native build/runtime gate and other genuinely Mac-local work.