# UNIVERSAL PROJECT STORAGE, APPDEV SPACE & PACKAGE DELIVERY RULE

Status: CANONICAL GLOBAL APPDEV RULE
Authority: AppDevRules; applies to all current and future AppDev work.
Supersedes conflicting older storage, Finder-tag and Releases/Products wording.

## 1. Central AppDev space
`~/edenOS/AppDev/` is the central AppDev control and governance space.

It contains:
- `#appDev Bible/` — global AppDev authority, rules and Project Bibles.
- `#app-assistants/` — authoritative/reconstructible in-chat helper, assistant, specialist and governor material.
- `#App Backups/` — durable AppDev/application backup and recovery packages.
- `#handoffs/` — active and retained handoff material.
- `Smart Folders/` — saved Finder searches/views for AppDev navigation and status; never engineering authority.

These are control/support collections, not application source workspaces.

## 2. Canonical project storage
- `~/edenOS/Projects/EDEN Apps/<APP>/` — EDEN software applications only.
- `~/edenOS/Projects/<PROJECT>/` — independent products/projects and HW/SW projects.
- `~/edenOS/Temporary/<PROJECT>/` — disposable cache, DerivedData, scratch, transient staging and rebuildable intermediates only.
- `~/edenOS/Quarantine/` — uncertain/misplaced material awaiting reconciliation; quarantine is not deletion.
- No duplicate authoritative copies. Backup/recovery duplicates must be explicitly identified as such.

Established classifications:
- HESPERA: EDEN App.
- HESTIA / gardenOS: independent HW/SW project.
- SWAYcore: independent project; NOT EDEN.
- Modern Generals Native/mods: independent project family; NOT EDEN.

## 3. Per-App workspace
Each EDEN App folder is a neat, self-contained durable workspace for all non-temporary App-specific material. Preserve existing build-system conventions and working repository paths; do not rename merely for cosmetic uniformity.

Each EDEN App workspace exposes the central AppDev space using a single link/reference:
`AppDev -> ~/edenOS/AppDev`

Do not duplicate the AppDev governance tree into every App.

App-specific durable material may include source, tests, resources, configuration, documentation, data, evidence, recovery records, tools and package records as appropriate. Temporary/cache/rebuildable outputs belong under `~/edenOS/Temporary/`.

## 4. Releases — test launchpad
`~/edenOS/Releases/` is the launchpad for intentionally compiled/testable application builds.

A compiled application may be made available there for manual, physical-device or user testing. Presence in Releases does NOT mean evidence state RELEASED, VERIFIED, TESTED or WORKING.

Evidence tags/records must state the demonstrated truth, e.g. `§Built`, `§Test`, `§Unverified`.

Never promote evidence state merely because an artifact exists in Releases.

## 5. Products — qualified functional applications
`~/edenOS/Products/` contains applications that have demonstrated the project's required working/tested/functional gate.

Admission to Products requires evidence appropriate to the project. Compilation alone is insufficient.

Products does not replace source Projects, LKG records, release artifacts, manifests or recovery evidence.

## 6. Package delivery
Evidence-gated flow remains:
REFERENCE -> BASELINE/LKG -> IMPLEMENT -> VERIFY -> REGRESSION -> PACKAGE -> PACKAGE VERIFY -> PHYSICAL GATE -> PROMOTE.

A normal local progression is:
Project workspace -> compiled/testable candidate in Releases -> required testing/verification -> qualified working application in Products.

GENERATED != IMPLEMENTED != BUILT != TESTED != VERIFIED != RELEASED.
UNKNOWN != PASS.
Preserve LKG.

## 7. Finder taxonomy and Smart Folders
Finder metadata is a navigation/classification layer, never engineering authority.

Reserved semantics:
- `@` = identity / implementation type + platform, e.g. `@App macOS`, `@App iOS`, `@App iPadOS`, `@App Windows`, `@App Android`, `@PWA Web`, `@PWA Agent Web`, `@Assistant In-Chat`, `@ChatGPT`.
- `§` = lifecycle/evidence display state, e.g. `§In Development`, `§Built`, `§Test`, `§Alpha`, `§Beta`, `§Working`, `§Verified`, `§Recovery`, `§LKG`, `§Unverified`.
- `#` = structural/organizational collections such as `#appDev Bible`, `#app-assistants`, `#App Backups`, `#handoffs`.

Smart Folders are saved searches/views only. They do not move, copy, promote or determine state.

Canonical AppDev Smart Folder views should include:
APPDEV: All Apps; macOS Apps; iOS Apps; Web / PWA.
STATUS: In Development; AppTest; Alpha; Beta; Working; Recovery; Unverified.

`AppTest` is the compact user-facing attention queue for applications requiring Lucas's manual/physical testing. Its membership is driven by appropriate metadata/evidence; AppTest itself is not an evidence state.

The AppDev Smart Folder collection is stored under:
`~/edenOS/AppDev/Smart Folders/`

The Smart Folders collection is intended for Dock access as a Stack. Finder sidebar remains minimal; AppTest is the primary AppDev attention view.

## 8. Classification and migration safety
1. Canon determines identity; never classify from name or current filesystem location alone.
2. UNKNOWN remains UNKNOWN until classified.
3. Audit before moving; preserve Git/source relationships, LKG, recovery evidence and unique history.
4. A move is incomplete until path/reference migration and verification pass.
5. Existing working functionality and repository conventions outrank cosmetic reorganization.
6. Migration to this layout must be non-destructive and evidence-verified.
