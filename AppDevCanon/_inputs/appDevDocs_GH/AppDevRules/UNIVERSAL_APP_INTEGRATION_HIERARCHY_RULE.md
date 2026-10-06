# UNIVERSAL APP INTEGRATION & HIERARCHY RULE

Status: AUTHORITATIVE UNIVERSAL APPDEV RULE
Applies to: ALL AppDev applications, services, assistants, specialist apps, bridges and higher-level orchestration products.

## 1. Standalone-first invariant

Every application is independently complete for its core domain unless its Project Bible explicitly defines it as a subordinate component.

A specialist app must not require HEIMDALL, BIFROST, CONDUCTOR or another EDEN app merely to perform its own core work.

Removing a higher-level EDEN layer must not destroy the specialist app's core standalone functionality.

## 2. Optional integration, not ownership transfer

Higher-level systems may:
- discover an app;
- call its capabilities;
- deep-link into it;
- invoke App Intents / Shortcuts;
- use its API/headless service;
- embed an authorized representation;
- route work to it;
- present it inside a broader workspace.

This does NOT transfer domain ownership.

The specialist app remains authoritative for its domain logic, state and user-facing product behavior.

## 3. Independence is bidirectional

A higher-level app must not depend on one specialist app unless explicitly defined.

A specialist app must not depend on a higher-level app unless explicitly defined.

Example:
- HEIMDALL may call CRESUS.
- BIFROST may discover/route to CRESUS.
- CONDUCTOR may request a CRESUS capability.
- Siri may invoke CRESUS directly.
- CRESUS may run fully without HEIMDALL/BIFROST/CONDUCTOR.
- HEIMDALL/BIFROST/CONDUCTOR may run fully without CRESUS.

## 4. Role hierarchy

Unless a Project Bible defines otherwise:

CONDUCTOR
- interprets, reasons, coordinates and routes complex work;
- does not own specialist domain logic.

BIFROST
- discovers/resolves providers, capabilities, connections and representations;
- may provide shared connective/hosting infrastructure;
- is not the specialist app and is not the AI itself.

HEIMDALL
- provides organizing/understanding/workspace-oriented user experiences where established;
- may surface or invoke specialist capabilities;
- does not absorb specialist domain ownership.

SPECIALIST APPLICATION
- owns its domain;
- executes its own deterministic work;
- owns its own native UI where justified;
- exposes capabilities to other layers;
- remains standalone.

SIRI / APPLE SYSTEM SURFACES
- may invoke an app directly through App Intents/Shortcuts;
- may invoke higher-level EDEN apps;
- may perform their own Apple Intelligence/provider escalation.

## 5. Capability contract

Each integratable app should expose, as applicable:
- identity/version;
- capabilities/actions;
- inputs/outputs;
- availability;
- required permissions;
- local/network characteristics;
- consequence level;
- deep links/routes;
- App Intents / App Shortcuts;
- service/headless/API endpoint;
- representation types;
- health/state;
- data authority/ownership;
- optional shared-host compatibility;
- provider/intelligence requirements.

## 6. Representation progression

Use the lowest sufficient representation:

LINK
-> WEB/TAB
-> EMBED
-> NATIVE BRIDGE
-> NATIVE

Do not create duplicate native clients merely for architectural purity.

Native first does not mean native at all costs.

## 7. Shared hosting

An app may voluntarily allow compatible generic infrastructure to be hosted by BIFROST or another approved shared host.

HOSTING IS TRANSFERABLE.
DOMAIN OWNERSHIP IS NOT.

The app must retain enough standalone capability to recover/reclaim its hosted function where practical.

## 8. Intelligence independence

Apps may own their own:
- deterministic reasoning;
- native/device AI;
- silentChatGPT path;
- cloud provider adapters;
- provider login/configuration.

Higher-level EDEN systems may also own their own independent intelligence/provider stack.

A higher-level system may choose to:
- reason itself and call a deterministic specialist capability;
- call the specialist app's own intelligent capability;
- delegate the entire specialist task to the app.

No universal broker dependency is implied.

## 9. Data ownership

Specialist app data remains owned by the specialist domain/user.

Higher-level systems may store:
- connective metadata;
- capability registry;
- location/connection state;
- representation metadata;
- interoperability metadata;
- references/provenance needed for routing.

They must not silently swallow specialist databases into a monolith.

User data must outlive any optional integration layer.

## 10. Siri / direct system invocation

A standalone app should expose direct system integration where useful.

Canonical examples:
Siri -> CRESUS App Intent -> CRESUS
Siri -> HEIMDALL -> CRESUS
HEIMDALL -> CRESUS
BIFROST -> CRESUS
CONDUCTOR -> CRESUS

All are valid if implemented.

No path is universally mandatory.

## 11. Failure isolation

If BIFROST is unavailable, specialist apps continue standalone.
If HEIMDALL is unavailable, specialist apps continue standalone.
If CONDUCTOR is unavailable, specialist apps continue standalone.
If one specialist app is unavailable, higher-level systems continue and report that capability as unavailable rather than faking it.

Integration failure must not create false feature availability.

## 12. UI / hierarchy

Higher-level UI should not erase specialist identity.

A specialist app may appear:
- as a direct app;
- inside a workspace;
- as an embedded/native representation;
- as an invoked capability;
- as a background execution target.

The product should present the correct owner/context where that matters.

## 13. Universal invariant

APPS ARE STANDALONE DOMAIN OWNERS.
HIGHER LAYERS MAY DISCOVER, ROUTE, EMBED OR CALL THEM.
INTEGRATION IS ADDITIVE.
DEPENDENCY MUST BE EXPLICIT.
HOSTING MAY MOVE; OWNERSHIP DOES NOT.
