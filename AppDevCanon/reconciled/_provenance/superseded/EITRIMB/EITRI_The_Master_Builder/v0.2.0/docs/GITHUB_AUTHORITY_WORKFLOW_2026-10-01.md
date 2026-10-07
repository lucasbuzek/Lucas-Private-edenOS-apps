# EITRI / EITRIMB GitHub Authority & Workflow — 2026-10-01

Status: AUTHORITATIVE WORKFLOW
Scope: AppDev governance and existing project conversations

## Authority split

AppDev docs/Bibles/EITRI family:
- lucasbuzek/Lucas-private-appDevDocs
- stores AppDev Bible material, Project Bibles, EITRI/EITRIMB/EitriFactory definitions, helper master prompts, governance/reference docs and Codex bootstrap/handoff guidance.

Project/app implementation:
- lucasbuzek/Lucas-Private-edenOS-apps by default;
- an explicitly established separate project repository remains authoritative for that project.

Do not mix project implementation into DevDocs simply because governance refers to it.

## Mac role

Mac copies are backup/recovery copies after GitHub authority is established.
Do not use the Mac as routine project memory, history discovery, broad filesystem census or status storage.

Before Remote Desktop Commander:
DOES THE NEXT REQUIRED EXECUTABLE ACTION ACTUALLY REQUIRE THE MAC?

If NO:
use GitHub / active context / available tools.

If YES:
use Remote Desktop Commander only for the bounded Mac-local action, such as compile, Xcode/toolchain, local build/test, physical-device verification, rendering/processing or one-time migration.

## Existing-chat recovery

For each active project conversation:
1. preserve the ACTIVE PROJECT;
2. recover only that project's established canon from the active conversation/project evidence;
3. reconcile with any existing Project Bible and project GitHub data;
4. do not import another project's canon;
5. create/update the Project Bible in Lucas-private-appDevDocs;
6. create/update implementation/state in Lucas-Private-edenOS-apps or the established separate project repo;
7. preserve Mac backup when materially required;
8. mark unresolved facts UNKNOWN rather than inventing them.

Migration is incomplete while material project canon remains chat-only.

## EITRI family separation

EITRI:
Master Builder engineering authority/capability.

EITRIMB:
thin in-chat Master Builder governor; inherits AppDev authority rather than duplicating the full Bible.

EitriFactory:
separate standalone product. Do not merge it into EITRIMB.

Their working definitions/Bibles belong in Lucas-private-appDevDocs.

## Normal workflow

GitHub DevDocs authority
→ ACTIVE PROJECT Bible
→ project/app authoritative GitHub repo
→ compact active context
→ EITRIMB routing/execution
→ specialists/plugins/tools
→ evidence
→ update authoritative GitHub state
→ Mac backup only when materially required.

## Codex handoff

Codex reads:
1. AppDev authority in Lucas-private-appDevDocs;
2. applicable Project Bible in Lucas-private-appDevDocs;
3. project source/state from the project's authoritative repo;
4. project-root HANDOFF.md;
5. optional small AGENTS.md bootstrap.

HANDOFF.md contains volatile execution continuity only and answers:
WHAT SHOULD CODEX EXECUTE NEXT?

Do not duplicate the AppDev Bible into HANDOFF.md or AGENTS.md.

## Evidence

GENERATED != IMPLEMENTED
IMPLEMENTED != BUILT
BUILT != TESTED
TESTED != VERIFIED
VERIFIED != RELEASED
UNKNOWN != PASS

GitHub persistence proves persistence/recovery only, not functionality.
