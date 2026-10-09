# Conflicts, gaps, UNKNOWNs, and blockers

## Corrected conflicts

1. Repository project folders formerly lived at its top level. They now mirror the universal canon under `Projects/EDEN Apps/` or direct `Projects/` without changing project payloads.
2. The CURATOR durable archive formerly lived inside its app as `CURATOR/backups/`. It now lives at root `Backups/EDEN Apps/CURATOR/`; stale handoff references were corrected.
3. BIFROST documentation formerly named `~/edenOS/Projects/BIFROST/`; it now names `~/edenOS/Projects/EDEN Apps/BIFROST/`.
4. PENELOPE's detached Project Bible is consolidated into its app directory.

## Remaining UNKNOWNs

- Original ChatGPT assistant definitions/configurations, exact assistant versions and complete LKG histories for all 12 represented helpers/specialists/governors.
- Full project facts, source/assets and LKGs for APELLES, CRESUS, HESPERA, HESTIA/gardenOS and the referenced specialists.
- Whether names mentioned by relationship evidence correspond to assistant-only capabilities, software projects, or both, except where the authority update classifies them.
- Native/device verification items already marked UNKNOWN in individual projects remain UNKNOWN.

## Demonstrable unavailable dependency

The prior cloud task `task_e_6ac1969c8f208332bfe21b3ace834339` was reported READY (+4223/-0, 162 files), but this checkout exposes no task artifact, remote/ref, commit, dangling Git object, or sibling workspace from which to inspect it. Applying an unavailable or stale patch was not attempted, and `codex cloud apply` was not used. Its recovery request records the exact dependency.
