# BIFROST runtime delegation contract

**Status: required architecture; adapter details pending project authority and
implementation.** This document records the architecture explicitly supplied
for BIFROST. It does not claim that existing code implements the contract.

## Ownership

- An App owns its product identity, domain logic, user data, and standalone
  headless runtime.
- BIFROST may host generic runtime responsibilities only after the App and
  BIFROST establish compatibility and transfer runtime ownership explicitly.
- Delegation never transfers App domain or data ownership to BIFROST.
- BIFROST is optional. Standalone operation remains a first-class mode.

## Required handoff behavior

1. Identify the App and its declared runtime contract/version.
2. Validate compatibility and the App's existing data/state in place. Adoption
   must not require uninstall/reinstall or reset/migrate data destructively.
3. Ask the App to quiesce its standalone service and confirm it released its
   listeners/resources before BIFROST starts a hosted instance.
4. Keep one authoritative runtime owner per App service. Do not start the hosted
   instance while the standalone owner is still active.
5. Report host state and failure truthfully. A process launch alone is not
   readiness; readiness requires the App's contract-defined health confirmation.
6. On explicit standalone selection, BIFROST removal/unavailability, or
   incompatibility, release host ownership and let the App reactivate its
   standalone runtime using the same user state.
7. If safe handoff or recovery cannot be confirmed, keep the current owner
   running and report delegation unavailable. Never force-stop an unverified
   process or claim a successful handoff.

## Contract details not recovered

The project authority available in this recovery does not define the wire
protocol, compatibility/version policy, discovery mechanism, consent flow,
health checks, ownership lease format, crash recovery, or per-App adapters.
Those details require recovery from BIFROST project authority or explicit
engineering decisions. They must not be represented as historical decisions.

## Existing candidate assessment

The current source has app discovery and independent JANITOR controls, but no
runtime declaration, handoff, adoption, exclusive ownership, lease, or
standalone reactivation implementation. Its Remote Desktop Commander wrapper is
a separate optional provider and does not satisfy the App runtime contract.
