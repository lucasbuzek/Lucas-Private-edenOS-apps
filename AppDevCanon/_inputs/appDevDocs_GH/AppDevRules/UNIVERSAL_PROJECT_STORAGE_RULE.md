# UNIVERSAL PROJECT STORAGE RULE

Status: CANONICAL GLOBAL APPDEV RULE
Authority: AppDevRules; applies to all current and future AppDev work.

## Canonical layout
- `~/edenOS/Projects/EDEN Apps/<APP>/` — EDEN software applications only.
- `~/edenOS/Projects/<PROJECT>/` — independent products/projects and hardware/software projects.
- `~/edenOS/Projects/#app-assistants/` — reconstructible backups/definitions of in-chat helpers, assistants, specialists and governors.
- `~/edenOS/Projects/#appDev Bible/` — global AppDev authority, rules and Project Bibles.
- `~/edenOS/Projects/#handoffs/` — active handoff material.
- `~/edenOS/Backups/` — durable backup/recovery packages. Never store durable backups under `Projects/Backups`.
- `~/edenOS/Temporary/` — disposable cache/build/staging/scratch only. It is never authoritative or durable storage.
- `~/edenOS/Recovery/` — recovery evidence/state where applicable.
- `~/edenOS/Releases/` — verified release artifacts.

## Classification
1. EDEN App -> `Projects/EDEN Apps/<APP>/`.
2. Independent product/project -> `Projects/<PROJECT>/`; AppDev development does not make a product an EDEN App.
3. Hardware/engineering/infrastructure/HW+SW project -> `Projects/<PROJECT>/`.
4. In-chat helper/assistant/specialist/governor -> `Projects/#app-assistants/` with reconstructible authoritative backup.
5. Canon determines identity; never classify from name or current filesystem location alone.
6. UNKNOWN remains UNKNOWN until classified; do not silently move ambiguous material.
7. No duplicate authoritative copies. Backup/recovery duplicates must be explicitly identified as such.
8. A move is incomplete until path/reference migration and verification pass.

## Established classifications
- HESPERA: EDEN App.
- HESTIA / gardenOS: independent HW/SW project; stays directly under Projects.
- SWAYcore: independent project; NOT EDEN.
- Modern Generals Native and Modern Generals mods: independent project family; NOT EDEN.

## Migration safety
Preserve Git/source relationships, LKG, recovery evidence and unique history. Audit before moving. Do not delete uncertain material. Evidence determines state; UNKNOWN != PASS.