# BIFROST isolated variant experiments

Status: five isolated, disabled read-only adapters and mock test suites implemented; 51/51 Python mock regressions executed in an isolated container against source matching GitHub blob SHAs. No upstream integration, Mac build, deployment or physical test.
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
- Each variant contains `boundary.py`, `adapter.py`, `test_boundary.py`, `test_adapter.py` and an updated `VARIANT.md`; exact committed code matches executed mock test source.
- Mock regression: MobileCLI 11/11, iphone-use 10/10, iMessage 10/10, OpenHands 10/10, LiteLLM 10/10; all passed using `python3 -B -m unittest discover -p 'test_*.py' -q` in each isolated directory.
- Upstream corrected: `MobileCLI/mobilecli` (MIT; distinct from `mobile-next/mobilecli`), `OpenHands/OpenHands` (MIT). iphone-use is PolyForm Shield 1.0 (not OSI); original `prbe-ai/imessage-coding` (MIT) is decommissioned; LiteLLM is MIT outside restricted `enterprise/` content and has supply-chain/SSRF security concerns.
- No daemon, device adapter, provider proxy, messaging service or code-execution runtime was installed or connected. All capabilities remain disabled. Mac native and real-provider tests remain UNKNOWN.
- The Mac-local destination `~/edenOS/Software Development/Online Plugins & Connectors/` has not been updated because the remote desktop session hit its monthly tool allowance. Do not claim local folder creation or retry that tool until its allowance resets.
