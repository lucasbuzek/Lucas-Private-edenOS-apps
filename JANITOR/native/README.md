# JANITOR (native macOS) — v0.1.1

Justified Analysis, Navigation, Inspection, Tidying, Optimization & Recovery.
Contract: **UNKNOWN != JUNK.** Inspect → classify → review → confirm → act → verify → record.
No daemon, telemetry, scheduler, watcher, server, cloud or AI dependency.

## Capability matrix (this build)
| Area | Status |
|---|---|
| Quick Scan / Full Scan (bounded, per-root deadlines, PARTIAL on timeout) | Implemented |
| Storage Overview, Choose What to Scan | Implemented |
| Maintenance: safe clean, `brew cleanup`, `simctl delete unavailable`, quarantine aging | Implemented |
| Developer Quick, Project Identity/Versions, Build Families (first+latest kept), Build/Dependency Discovery | Implemented |
| Media Inventory + Large Media, Exact Duplicates (CryptoKit, size→partial→full hash), Similar Names, Photos footprint (read-only) | Implemented |
| Processes, Startup/Background (launchd plists), Installed Apps, Support Inventory, Broken Items, Storage Diagnostics + local snapshots | Implemented (read-only) |
| Quarantine: manifest, verified moves, restore (collision-safe), missing-tolerant, delete | Implemented |
| Reports → ~/Library/Logs/JANITOR/ | Implemented |
| File Provider / iCloud-aware actions | DEFERRED — provider roots are detected and never traversed, hashed, moved or copied |
| PhotoKit analysis | DEFERRED — Photos libraries are PROTECTED, footprint only |
| Signing/origin attribution, Quit/Force Quit, SMAppService login items, true orphan attribution | DEFERRED |
| Privacy inspection, Project consolidation actions, Deep scans other than duplicates | NOT YET IMPLEMENTED |

## Status
Compiled and exercised only on the machine that builds it. Nothing here is a PHYSICAL PASS until you run the acceptance list on your target Mac.
