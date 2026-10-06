# CURATOR Project Bible

Status: CURRENT PROJECT AUTHORITY
Project: CURATOR — Creative Understanding, Review, Asset Tagging, Organization & Retrieval

## Product identity
CURATOR is a professional creative-media application for acquiring/discovering, understanding, organizing, reviewing, managing, processing/coordinating, delivering/publishing and preserving photography, video and related creative work.

CURATOR integrates mature professional creative applications rather than recreating their editing engines.

## Current requested milestone
Continue the existing CURATOR implementation from the current v1.3.5 experimental candidate toward a genuinely functional native macOS/M1 application and verify the real product path rather than treating portable tests, compilation, persistence, or packaging as product acceptance.

Immediate acceptance gate: restore/use the authoritative v1.3.5 source, perform native macOS build/runtime verification on the target Mac, repair any failures found, and continue into target-provider verification when native execution is demonstrated.

## Authoritative implementation
Default project/app repository:
`lucasbuzek/Lucas-Private-edenOS-apps`

Current persisted implementation/recovery material:
`CURATOR/`

Current full backup:
`CURATOR/backups/v1.3.5/`

## Current evidence baseline
Candidate: v1.3.5 goal/pipeline audit + repair experimental.
Source revision: `curator-private-lucas-v1.3.5-goal-pipeline-audit-repair`.

Demonstrated:
- Portable Swift regression: PASS — 40/40, 0 failures.
- macOS Swift source syntax parse: PASS.
- Installer shell syntax: PASS.
- Installer executable permissions: PASS (0755).
- Package ZIP integrity: PASS.
- GitHub backup reconstruction SHA-256 matches the source backup archive.

Unverified / UNKNOWN:
- macOS native build/runtime.
- M1 physical verification.
- Real professional-provider round trips.

LKG: no native macOS LKG is currently claimed.
Release: no production/public release is claimed.

## Remaining product gaps
- richer photo/video review and playback/comparison;
- richer EXIF/IPTC editing;
- deeper Projects/Collections;
- native Activity integration with persistent job ledger;
- fuller archive/backup workflows;
- direct provider-backed publishing;
- provider return/reconciliation;
- native macOS build/runtime and target-provider verification.

## Constraints
Preserve user creative data separately from replaceable software. BIFROST remains optional; CURATOR retains standalone capability and domain ownership.

## Development authority
Use the current AppDev/EITRI/EITRIMB authority in this repository. Do not duplicate the global AppDev rulebook into this Project Bible. Evidence determines state; UNKNOWN is not PASS.
