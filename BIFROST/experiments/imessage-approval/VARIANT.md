# BIFROST variant — iMessage approval/steering adapter

Status: isolated read-only adapter and mock tests implemented; upstream NOT installed or connected; Mac build and physical acceptance UNKNOWN.
Base: bifrost/native-consolidated-20261010.
Upstream candidate: https://github.com/prbe-ai/imessage-coding

## Hypothesis
Evaluate reusing an existing iMessage relay for remote steering and human approval prompts, without making iMessage the required BIFROST control plane.

## Scope boundary
Optional notification/approval transport only. BIFROST remains the source of task identity, authorization policy, audit history and execution status. No model or relay may grant its own approval.

## Proposed boundary
- Send a minimal task summary and approval request with an unguessable, short-lived reference.
- Bind each decision to the authenticated user, task ID, action digest, expiry and one-time nonce.
- Treat replies as untrusted until identity, expiry, replay and task-state checks pass.
- Never send secrets, full environment variables, provider tokens, private source bundles or unrestricted shell commands through messages.
- If iMessage is unavailable, approval remains pending; do not fall back to auto-approval.

## Investigation before implementation
1. Verify upstream license, platform constraints, data handling, message identity semantics and relay security.
2. Establish whether message sender identity can be authenticated strongly enough for the required approval class.
3. Compare with native BIFROST confirmation UI and existing RavenNest controls.
4. If sender identity is not strong enough, restrict this variant to notifications only.

## Required tests
- Spoofed, expired, replayed and wrong-task approvals are rejected.
- Approval for one action cannot authorize a changed action.
- Missing connectivity never converts pending approval into approval.
- Sensitive fields are redacted.
- Every decision is auditable and linked to the exact task/action digest.
- Existing BIFROST tests remain green.

## Gate
Approval authority and upstream security must be proven before this variant can approve any write, deployment, credential, or destructive operation.

## Verified source and implementation — 2026-10-16
- Original candidate `prbe-ai/imessage-coding` carries an MIT license but its GitHub repository description explicitly says **DECOMMISSIONED 2026-09-29**. It uses Bun/Hono, Neon/Postgres, Sendblue iMessage/SMS, a hosted orchestration plane and a private LiteLLM proxy; unsuitable for unreviewed reuse or the no-paid-API objective.
- Another independent project `dvdsgl/claude-imessage` is MIT but explicitly warns against running its full-permission autonomous daemon. Neither third-party daemon was installed.
- `adapter.py` parses an untrusted challenge echo with length bounds; even a match returns `authorization: none`, with sender identity not assumed trustworthy. No iMessage transport, approval flow or outbound message is connected.
- `test_adapter.py`: five mock regressions executed with exact Git blob read-back.
- **Gate: STOP** for real approval. Continue only as an opt-in notification candidate once a maintained transport and independent verified user/task/action binding are proven.
