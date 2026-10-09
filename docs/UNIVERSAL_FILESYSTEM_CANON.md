# EDEN universal filesystem canon

Audit date: 2026-10-05. Scope: repository evidence plus the authority update supplied for this milestone.

## Authoritative layout

- EDEN software Apps: `~/edenOS/Projects/EDEN Apps/<APP>/`.
- Assistants/helpers/specialists/governors: reconstructible, versioned backups at `~/edenOS/Projects/#app-assistants/<NAME>/`.
- Independent and combined hardware/software projects: `~/edenOS/Projects/<PROJECT>/`.
- Durable backup payloads: `~/edenOS/Backups/`; `Projects/Backups` is prohibited.
- Disposable cache/build/staging/scratch only: `~/edenOS/Temporary/`; it is never authoritative.

UNKNOWN does not authorize a move. References alone do not classify a named capability or project.

## Classification ledger

| Entity | Canonical class/path | Evidence state |
|---|---|---|
| BIFROST, CURATOR, JANITOR, KUROSAWA, NOSTOS, PENELOPE, SKALD | `Projects/EDEN Apps/<APP>/` | Repository content plus supplied corrected canon/Mac evidence |
| APELLES, CRESUS | `Projects/EDEN Apps/<APP>/` on the Mac | Classification supplied; repository bodies unavailable |
| HESPERA | `Projects/EDEN Apps/HESPERA/` when recovered | Classification supplied; presence/content UNKNOWN |
| edenOS Embedded | `Projects/edenOS Embedded/` | HW/SW project evidence; direct project |
| HESTIA/gardenOS | `Projects/<PROJECT>/` when recovered | HW/SW classification supplied; repository body unavailable |
| SWAYcore | `Projects/SWAYcore/` | Explicitly non-EDEN; direct project |
| Modern Generals Native/mods | `Projects/ModernGenerals/` family | Explicitly non-EDEN; independent family/direct project |
| Lucas AI Journey TOME | `Projects/Lucas-AI-Journey-TOME/` | Existing independent archive; no EDEN-App promotion evidence |
| ARGOS, ARTEMIS, IRIS, CASPER, MIRROR, READ, DÜRER | `Projects/#app-assistants/<NAME>/` evidence backup only | Referenced specialist/capability classification beyond backup is UNKNOWN |

The repository does not manufacture absent application directories for APELLES, CRESUS, HESPERA, or HESTIA. Their recovery requests preserve that gap explicitly.
