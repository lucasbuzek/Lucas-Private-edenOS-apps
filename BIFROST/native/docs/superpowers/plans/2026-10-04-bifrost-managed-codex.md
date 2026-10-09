# BIFROST Managed Codex Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add BIFROST-managed per-specialist Codex execution with persistent session isolation, capability-first local/cloud/hybrid routing, and layman confirmation UX.

**Architecture:** Extend the existing provider pattern rather than replace BIFROST. A persistent session registry and execution router sit behind a Codex provider; specialists submit structured requests and BIFROST resolves/executes infrastructure while specialist/governor authority remains external.

**Tech Stack:** Swift 6, SwiftUI/AppKit/Foundation, Process, JSON persistence, installed Codex CLI/app-server, XCTest.

**Spec:** `docs/superpowers/specs/2026-10-04-bifrost-managed-codex-design.md`

## Global Constraints
- Preserve BIFROST CONNECT · KEEP · RESOLVE and existing functionality.
- No paid API key requirement and no private ChatGPT endpoint/session scraping.
- Credentials/tokens never enter repository persistence.
- Separate persistent Codex identity/session context per specialist; resume before recreate.
- Capability-first: deterministic/native/local before connected escalation when sufficient.
- Cloud availability must be evidenced, never assumed.
- User confirms consequential intent; BIFROST issues technical commands.
- Physical Mac verification required before promotion.

## Review Focus
- Corrupt/missing registry file must recover safely without inventing sessions.
- Unknown specialist/project must not inherit another specialist's session.
- Codex installed but logged out must report authentication required, not ready.
- Cloud command present but unavailable/account-ineligible must not report cloud ready.
- Consequential request without confirmation must not execute.

---

### Task 1: Add test target and persistent specialist session registry
**Files:** Modify `project.yml`; create `Tests/CodexSessionRegistryTests.swift`; create `Sources/CodexSessionRegistry.swift`.
**Interfaces:** Produces `CodexSessionKey`, `CodexSessionRecord`, `CodexSessionRegistry` with lookup/upsert/remove and JSON-backed persistence.
- [ ] Write failing XCTest cases for per-specialist isolation, project separation, persistence/reload, and corrupt-file recovery.
- [ ] Regenerate Xcode project and run focused tests; verify RED because registry types are absent.
- [ ] Implement minimal registry with atomic JSON persistence and no credential fields.
- [ ] Run focused tests and full suite; verify GREEN.
- [ ] Commit registry/test-target change.

### Task 2: Add Codex capability provider
**Files:** Create `Tests/CodexProviderTests.swift`; create `Sources/CodexProvider.swift`.
**Interfaces:** Consumes process execution abstraction; produces `CodexAvailability` and operations to inspect auth/local/cloud readiness and resume/start execution identifiers.
- [ ] Write failing tests for missing CLI, logged-out, local-ready, cloud-unavailable, and command failure states using an injected command runner.
- [ ] Run focused tests; verify RED.
- [ ] Implement minimal provider using supported installed Codex CLI surfaces without reading credentials.
- [ ] Run focused and full tests; verify GREEN.
- [ ] Commit provider.

### Task 3: Add execution request and router
**Files:** Create `Tests/ExecutionRouterTests.swift`; create `Sources/ExecutionRequest.swift`; create `Sources/ExecutionRouter.swift`.
**Interfaces:** Consumes `CodexAvailability`, specialist request constraints, and session registry; produces `ExecutionRoute` (`native`, `localCodex`, `cloudCodex`, `hybrid`, `unavailable`) plus reason/evidence.
- [ ] Write failing tests for native-sufficient, local-only, cloud-allowed, hybrid-required, unavailable, and cross-specialist isolation cases.
- [ ] Run focused tests; verify RED.
- [ ] Implement minimal deterministic router; never infer availability not supplied by evidence.
- [ ] Run focused/full tests; verify GREEN.
- [ ] Commit router.

### Task 4: Add consequential-action confirmation policy
**Files:** Create `Tests/ExecutionConfirmationTests.swift`; create `Sources/ExecutionConfirmation.swift`.
**Interfaces:** Produces human-readable confirmation requirements from execution request/action categories.
- [ ] Write failing tests for install, destructive write, new permission, cloud transfer, spend/publish versus routine/read-only execution.
- [ ] Run focused tests; verify RED.
- [ ] Implement minimal policy and user-facing summary model; keep exact commands as Expert detail only.
- [ ] Run focused/full tests; verify GREEN.
- [ ] Commit confirmation policy.

### Task 5: Integrate provider/router with BifrostSystem and UI
**Files:** Modify `Sources/BifrostSystem.swift`, `Sources/RootView.swift`, `Sources/SecondaryViews.swift`, `Sources/StatusMenu.swift`; create/update integration tests as supported by target.
**Interfaces:** Consumes Tasks 1–4; exposes connection/readiness, specialist sessions, routes and confirmation state through existing Simple/Advanced/Expert disclosure.
- [ ] Write failing model/integration tests for refresh, degraded offline state, session resume and confirmation blocking.
- [ ] Run tests; verify RED.
- [ ] Wire provider/router into BifrostSystem without removing existing discovery/JANITOR/remote/Keep Awake functions.
- [ ] Add Simple connected/degraded status and Advanced/Expert execution/session details; no terminal knowledge required in Simple.
- [ ] Run focused/full tests and macOS build; verify GREEN.
- [ ] Commit integration.

### Task 6: Regression, package evidence, and physical gate
**Files:** Update `RECOVERY_STATUS.md`, `IMPLEMENTATION_INVENTORY.md`; create evidence log/checksum manifest under `docs/evidence/`.
**Interfaces:** Consumes complete candidate; produces evidence only, not automatic LKG promotion.
- [ ] Run complete test suite and clean Debug build; capture commands/results.
- [ ] Verify built app Info.plist and launch/terminate process without claiming GUI functions not inspected.
- [ ] Exercise authenticated Codex availability and two-specialist isolation on the Mac without destructive work.
- [ ] Package candidate, verify archive from clean extraction, record SHA-256.
- [ ] Record remaining UNKNOWN physical/UI/cloud gates truthfully; promote only if established ForgeMASTER gates pass.
- [ ] Commit evidence/documentation.
