# BIFROST isolated variant experiments

Status: branch index/scaffold only. No variant has been integrated, installed, built or tested.
Canonical source baseline: `bifrost/native-consolidated-20261010`.
LKG `7b28cac` remains authoritative until reconciled; no candidate is promoted by these experiments.

## Separate experiment branches

| Variant | Branch | Intended seam | Primary gate |
|---|---|---|---|
| MobileCLI | `bifrost/variant-mobilecli-control` | iPhone-to-coding-agent control | Prove control reuse and result receipts |
| iphone-use | `bifrost/variant-iphone-use-device` | Physical iPhone automation/acceptance | Device identity, permissions, traceable test actions |
| iMessage coding | `bifrost/variant-imessage-approval` | Optional notifications/approval relay | Authenticated user, one-time action-bound approvals |
| OpenHands | `bifrost/variant-openhands-executor` | Optional sandboxed agent execution | Runtime/security/resource fit; actual artifact verification |
| LiteLLM | `bifrost/variant-litellm-provider` | Optional multi-provider API routing | Security/version review and demonstrated provider gap |

## Decision rules

- Preserve existing BIFROST and RavenNest contracts; reuse, integrate, repair, extend, create last.
- Keep each experiment isolated. Do not merge one candidate's changes into another branch.
- Confirm upstream source, license, version, security posture and data handling before code integration.
- Treat each candidate as a hypothesis, not an approved dependency.
- Provider inference, coding-agent sessions, task queue handoff, local execution, and physical device automation are different capabilities.
- No candidate may start services, enroll devices, access secrets, write user project files, deploy, or perform destructive actions without explicit authorization.
- Tests must use mocks for provider/remote behavior until explicit live acceptance is approved.
- Each variant needs its own test suite, regression evidence, artifact/postcondition receipt and rollback notes.
- Do not promote over LKG without package verification and physical acceptance where applicable.

## Current status

- Branches created from `bifrost/native-consolidated-20261010`.
- Each variant has a scope, non-goals, investigation checklist and acceptance gates.
- Implementation code, dependency installation, builds and tests are NOT yet done.
- The Mac-local destination `~/edenOS/Software Development/Online Plugins & Connectors/` has not been updated because the remote desktop session hit its monthly tool allowance. Do not claim local folder creation or retry that tool until its allowance resets.
