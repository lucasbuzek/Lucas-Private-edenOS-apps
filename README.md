# Lucas-Private-edenOS-apps

**Purpose:** Lucas's owner-specific EDEN application variants and explicitly private EDEN development workspaces. This repository is not the general EDEN applications repository and is not the authority for every EDEN platform or application.

## Boundaries

- Normal EDEN application sources belong in `lucasbuzek/edenOS-apps`.
- Owner-specific private/custom application variants belong in the designated RAVENsNEST account/repository when their migration destination and source lineage have been verified.
- The EDEN hardware/software platform lineage (GardenOS, coreOS, edenOScore and the embedded/Linux platform work) is not an ordinary app collection. Its own platform repository and Project Bibles govern it; do not move it into an app repository.
- `edenOS Embedded/` is a distinct private Samsung SM-T110 Android embedded-platform project. Its own Project Bible and handoff explicitly designate this repository as its development continuity location and prohibit writing its development artifacts into `lucasbuzek/edenOS` or `lucasbuzek/edenOS-apps`. Preserve that project-specific contract unless Lucas explicitly supersedes it.
- `edenOS` is the separate hardware/software platform repository.
- `edenOS-public` is the separate public release/distribution destination. No release readiness is implied.

## Preservation rules

Keep each project in its own established lineage. Preserve source history, Project Bible, LKG, current candidate, test evidence and provenance. Do not merge similarly named projects, flatten platform and app boundaries, or treat a private variant as a replacement for the normal application.

Before moving a project, inspect its own Project Bible and handoff, verify the destination, copy and verify the complete source first, and only then remove the old copy. Do not delete nonempty project content as a cleanup shortcut.
