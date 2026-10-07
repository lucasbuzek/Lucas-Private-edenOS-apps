# UNIVERSAL APP INTEGRATION & HIERARCHY RULE

Status: AUTHORITATIVE UNIVERSAL APPDEV RULE

Every application is independently complete for its core domain unless its Project Bible explicitly defines it as a subordinate component. Integration is additive, not a hidden runtime dependency.

Universal rules:
- specialist apps own their domain logic, state, deterministic execution and appropriate native UI;
- higher layers may discover, route, call, deep-link, embed or present specialist capabilities without taking domain ownership;
- independence is bidirectional: a specialist does not require HEIMDALL/BIFROST/CONDUCTOR merely to work, and higher layers do not require a particular specialist unless explicitly established;
- HEIMDALL may call CRESUS; BIFROST may discover/route to CRESUS; CONDUCTOR may request CRESUS capabilities; Siri may invoke CRESUS directly; CRESUS remains fully functional without those systems and they remain functional without CRESUS;
- CONDUCTOR interprets/reasons/coordinates; BIFROST resolves/discovers connections/capabilities/representations and may provide shared generic infrastructure; HEIMDALL provides its established user-facing organizing/workspace experience; the specialist app remains the domain owner;
- an integratable app should expose appropriate identity/version, capabilities/actions, typed inputs/outputs, availability, permissions, consequence level, deep links/routes, App Intents/App Shortcuts, API/headless endpoints, representations, health/state, data ownership and provider requirements;
- use the lowest sufficient representation: LINK -> WEB/TAB -> EMBED -> NATIVE BRIDGE -> NATIVE; do not duplicate native clients merely for architectural purity;
- generic hosting may move to an approved shared host such as BIFROST when compatible, but HOSTING IS TRANSFERABLE; DOMAIN OWNERSHIP IS NOT;
- apps may own their own deterministic reasoning, device/native AI, silentChatGPT path, cloud-provider adapters and provider configuration; higher layers may independently own equivalent infrastructure;
- a higher layer may reason itself and call a deterministic specialist capability, call the specialist's intelligent capability, or delegate the specialist task to the app; no universal broker dependency is implied;
- specialist/user data remains owned by the specialist domain/user; higher layers may keep connective/interoperability metadata but must not silently absorb specialist databases into a monolith;
- Siri/direct system invocation and higher-layer invocation are both valid and neither is universally mandatory;
- failure is isolated: if HEIMDALL/BIFROST/CONDUCTOR is unavailable, standalone specialists continue; if a specialist is unavailable, higher layers report that capability unavailable rather than fake it;
- higher-level UI may surface a specialist as a direct app, workspace item, embedded/native representation, invoked capability or background target without erasing specialist identity.

UNIVERSAL INVARIANT:
APPS ARE STANDALONE DOMAIN OWNERS.
HIGHER LAYERS MAY DISCOVER, ROUTE, EMBED OR CALL THEM.
INTEGRATION IS ADDITIVE.
DEPENDENCY MUST BE EXPLICIT.
HOSTING MAY MOVE; OWNERSHIP DOES NOT.
