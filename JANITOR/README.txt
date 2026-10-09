JANITOR-current-physical-test
Version: 0.11.1-terminal-safety-candidate

Double-click JANITOR.command to open the Terminal interface on this Mac.
Choose STANDARD, DEVELOPER, MEDIA, FULL CREW, or QUARANTINE / RECOVERY.
CLI help: ./JANITOR.command --help

Scan -> review -> confirm -> action -> verify -> record.
Quarantine uses verified same-filesystem moves with recovery manifests.
Restore skips missing items and refuses existing/protected destinations.
Cross-filesystem moves and uncertain/cloud provider operations are refused.
Desktop/Documents are always excluded from ordinary recursive scans.
Unknown custom locations, external/network volumes and Photos internals
are protected. Photos footprint uses metadata only; no residency/reclaim.
Size figures are allocated-size estimates, not guaranteed reclaimable bytes.
Close apps/builds before reviewing developer cache cleanup.
Build-number families use filename evidence: review before quarantine/delete.

Physical testing still required: launch/menu, Quick/Full, developer review,
local disposable-file quarantine/restore, media review, and Full Crew.
Use disposable fixtures for actions; do not test deletion on personal projects.
Consolidation readiness is a report; source merging is deferred.
No daemon, telemetry, server, mandatory AI, or Python runtime dependency.
Requires this Mac's Bash and native find/stat/realpath/PlistBuddy utilities.
THIS IS A PHYSICAL-TEST CANDIDATE, NOT PHYSICALLY VERIFIED OR ACCEPTED.
