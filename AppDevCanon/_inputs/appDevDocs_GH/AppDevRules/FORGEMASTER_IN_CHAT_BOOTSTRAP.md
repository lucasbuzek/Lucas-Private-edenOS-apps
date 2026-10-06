# ForgeMASTER In-Chat Bootstrap Contract

Status: CANDIDATE — 2026-10-06

Purpose: define how an AppDev chat resolves `@forgemaster` without copying ForgeMASTER canon into every Project Bible or conversation.

## Resolution
When an AppDev conversation receives `@forgemaster`, `ForgeMASTER`, or an unambiguous ForgeMASTER operation, the chat MUST resolve the current canonical ForgeMASTER definition from the canonical AppDev authority before governing the work.

Canonical ForgeMASTER definition:
`ForgeMASTER/v1.0/FORGEMASTER_MASTER_GOVERNOR.md`

Canonical persistence repository:
`lucasbuzek/Lucas-private-appDevDocs`

ForgeMASTER remains an in-chat governor. This bootstrap does not create an app, runtime, daemon, service, or product dependency.

## Loading rule
The bootstrap is a locator, not a duplicate governor definition. It MUST NOT copy/rephrase ForgeMASTER or global AppDev canon into each project.

On invocation:
1. recover current AppDev authority;
2. resolve current canonical ForgeMASTER definition;
3. recover the active Project Bible/project authority;
4. recover relevant current project state/evidence;
5. initialize/refresh LCAS tiny UI for governed work;
6. execute the requested ForgeMASTER operation under the recovered authority.

If the canonical ForgeMASTER definition cannot actually be accessed in the current chat/tool surface, state that as a bootstrap/access blocker rather than inventing ForgeMASTER from memory.

## Scope
This rule establishes the canonical AppDev bootstrap contract. It does NOT by itself prove that ChatGPT injects or loads this repository in every unrelated conversation. Cross-conversation availability requires the containing ChatGPT Project/custom-instruction surface to load or enforce this AppDev bootstrap/authority at conversation start.

## Verification requirement
Global availability may be marked VERIFIED only after a fresh intended AppDev conversation can invoke `@forgemaster` and demonstrably resolve the canonical ForgeMASTER definition without manually pasting its prompt into that conversation.
