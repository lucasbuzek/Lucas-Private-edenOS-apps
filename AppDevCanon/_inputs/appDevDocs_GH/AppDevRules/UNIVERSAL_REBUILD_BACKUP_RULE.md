# UNIVERSAL REBUILD BACKUP RULE

Status: AUTHORITATIVE APPDEV RULE
Applies to: ALL AppDev projects, applications, games, assistants, services, websites, mods, asset pipelines, and related deliverables.

## 0. Authority, persistence and access boundary

Use `UNIVERSAL_PROJECT_STORAGE_RULE.md` for canonical Mac paths and classifications. Do not redefine project identity or storage layout here.

Durable remote AppDev authority is persisted in `lucasbuzek/Lucas-private-appDevDocs` and project implementation in each project's established repository (or the established shared project repository when no dedicated repository exists).

Lucas's Mac has NO assumed GitHub connection. Never require or attempt local GitHub access merely because remote persistence is required. ChatGPT reconciles the independent stores using its authenticated GitHub connector for GitHub and Remote Desktop Commander for the Mac. Cloud Codex may use repository access only when its environment demonstrably provides it.

Mac global AppDev authority: `~/edenOS/Projects/#appDev Bible/`.
Mac assistants: `~/edenOS/Projects/#app-assistants/`.
Project locations follow `UNIVERSAL_PROJECT_STORAGE_RULE.md`, including `Projects/EDEN Apps/<APP>/` for EDEN Apps and `Projects/<PROJECT>/` for independent projects.
`~/edenOS/Temporary/` is disposable only. `~/edenOS/Backups/` is durable local backup storage.

GitHub and Mac copies must be explicitly reconciled by ChatGPT; never describe them as automatically synchronized.

## 1. Three distinct artifacts — never conflate them

A. DURABLE PROJECT ARCHIVE / REBUILD BACKUP — exhaustive rebuild-capable preservation. Size is secondary to recoverability.

B. ACTIVE WORKING PROJECT — clean current development candidate plus authority and inputs needed for implementation and verification, at the canonical path defined by the storage rule.

C. LEAN TASK HANDOFF — compact task-specific transfer containing what the receiving executor needs to understand canon/current state, execute the assigned work, verify it, and return cumulative results.

Invariant: ARCHIVE is exhaustive; WORKING PROJECT is clean/current; HANDOFF is lean/task-specific.

## 2. Meaning of backup

When Lucas requests a project backup, complete backup, reconstruction package, archive, save-everything package, or equivalent, BACKUP means a verified rebuild-capable package by default.

A handoff, Project Bible, README, summary, source snapshot, ZIP, Git repository, or conversation transcript by itself is not a complete backup unless it independently satisfies the rebuild acceptance gate.

## 3. Required rebuild-backup contents

Preserve everything reasonably required to reconstruct the project without old chat history, including as applicable: current Project Bible/canon; relevant AppDev authority pointers/snapshot; complete source; platform projects/manifests; contracts/interfaces/schemas; database schemas/migrations; tests/fixtures; UI/UIX/design-system definitions; required editable assets and manifests; build scripts/builders/installers; dependency manifests/lockfiles; environment/preflight requirements; provider/adapter definitions; required AI contracts/prompts/schemas; packaging/signing/deployment instructions excluding secrets; exact repository/ref/commit where applicable; LKG/current-candidate/evidence state; known failures/unverified/physical gates; restore/rebuild instructions; file inventory and integrity verification.

Never place credentials, tokens, private keys, signing certificates or passwords in ordinary backups. Preserve required secret names/setup requirements instead.

## 4. Persistence targets

1. Persist remote global/project canon through ChatGPT's authenticated GitHub connector to the established repository.
2. Persist source/project data to the established remote project repository through an authorized remote mechanism.
3. Maintain the independent Mac/offline copy at the canonical storage-rule location through Remote Desktop Commander or direct local execution.
4. Use `~/edenOS/Temporary/` only for disposable work.
5. Explicit export destinations do not redefine authority.
6. Do not invent replacement locations when an established location exists.
7. Remote persistence does not replace a requested local/offline backup; the local copy does not replace required remote persistence.
8. Reconciliation is an explicit ChatGPT operation across the two access paths, not local Git synchronization.

## 5. Recovery before packaging

If required material is missing in one store, recover from the other authoritative/recovery sources using the access mechanism actually available. Do not create empty scaffolding and call it a backup. Do not substitute explanations for recoverable data. If a genuinely required dependency cannot be recovered after changed-source/method attempts, record the exact blocker and continue packaging everything else safely recoverable.

## 6. Archive structure

Use a clear equivalent structure appropriate to the project, normally including Project Bible, BACKUP_MANIFEST, RESTORE instructions, source, contracts, tests, required assets/asset manifest, build tooling, docs, authority, evidence, repository/history artifact when practical, and SHA-256 integrity manifest. Do not duplicate regenerable caches/build products unless required for reconstruction.

## 7. Lean handoff construction

Determine receiver and exact task first. Include the minimum complete working set: START_HERE/task contract; relevant canon; current evidence/failures; source/contracts/tests/assets required; toolchain/build/run instructions; expected return contract. Exclude unrelated products, redundant archives, caches, DerivedData, regenerable intermediates and archaeology not needed for the assigned task.

## 8. Verification gate

A durable backup is not COMPLETE until verification actually runs. Verify destination, required rebuild-critical files/directories, non-empty source/canon, manifests/dependencies/tests/contracts where applicable, exact state/ref where applicable, archive integrity/checksums, restore instructions and absence of silently omitted required components. Where practical perform a restore smoke test into a temporary location.

For a lean handoff verify self-sufficiency for the stated task.

## 9. Completion language

Only report BACKUP COMPLETE / VERIFIED after the verification gate passes. Otherwise report the bounded factual state. Never equate command/process creation with completion.

## 10. AUTO behavior

Under AUTO/full-auto continue through safe available recovery, packaging, persistence and verification until the requested acceptance gate is reached or a genuine blocker prevents it. Repairable path/auth/source issues, planning, directory creation, or archive creation without verification are not completion.

## 11. Universal invariants

BACKUP = CANON + SOURCE + REBUILD INPUTS + EXACT STATE + RESTORE INSTRUCTIONS + INTEGRITY VERIFICATION.

ARCHIVE = exhaustive durable recovery. WORKING PROJECT = clean current development state. HANDOFF = lean self-contained task transfer.

MAC AND GITHUB ARE INDEPENDENT STORES. CHATGPT RECONCILES THEM THROUGH THEIR RESPECTIVE CONNECTORS. NEVER ASSUME LOCAL GITHUB ACCESS ON LUCAS'S MAC.

Commands authorize work. Evidence proves state.