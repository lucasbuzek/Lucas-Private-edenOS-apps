# BIFROST variant — LiteLLM provider gateway adapter

Status: isolated read-only adapter and mock tests implemented; upstream NOT installed or connected; Mac build and physical acceptance UNKNOWN.
Base: bifrost/native-consolidated-20261010.
Upstream candidate: https://github.com/BerriAI/litellm

## Hypothesis
Evaluate LiteLLM only for the provider API-routing gap, if BIFROST/RavenNest cannot already provide the required provider adapters and policy controls. It does not execute Mac builds or coding CLI sessions by itself.

## Scope boundary
Optional provider gateway behind a BIFROST adapter. It must not become a new authority for task status, user identity, Mac worker authorization or artifact verification. Provider routing and coding-agent execution remain distinct capabilities.

## Proposed boundary
- Normalize only provider operations supported by the selected, pinned version.
- Per-provider capability declarations: chat/inference, streaming, tool calling, embeddings or other operations only when verified.
- Credentials remain server-side and are scoped per provider; never return tokens to the iPhone or worker.
- Fail closed on unknown models, missing credentials, disallowed provider, budget/rate limit and upstream errors.
- Avoid adding a gateway if the existing adapters already satisfy the project contract.

## Investigation before implementation
1. Verify current release, license, dependency footprint and current security advisories/CVEs.
2. Review authentication, virtual keys, logging/redaction, SSRF controls, model allowlists and tenant boundaries.
3. Compare with existing RavenNest provider routing to identify a demonstrated gap.
4. Pin an approved version and define rollback before any deployment.

## Required tests
- Invalid/missing credentials, unapproved model/provider and upstream outage.
- Secret redaction in errors/logs and no credential disclosure to clients.
- Rate-limit, timeout, retry and duplicate-call behavior.
- Provider capability mismatch is explicit, not silently emulated.
- No claim that provider text response equals successful worker execution.
- Existing BIFROST tests remain green.

## Gate
Do not install or deploy based on feature breadth alone. Adopt only if the existing provider layer is insufficient and a current security review passes.

## Verified source and implementation — 2026-10-16
- Upstream root `LICENSE`: MIT outside `enterprise/` (separately licensed). Source supports OpenAI-compatible model enumeration and broader proxy routing, but BIFROST/RavenNest already owns an AI provider path; no verified need for an additional gateway yet.
- **Security gate:** LiteLLM reported compromised PyPI versions `1.82.7` and `1.82.8` (2026-03-24) and subsequent authenticated SSRF / provider-key exfiltration fixes (see `https://github.com/advisories/GHSA-3cv6-jpf6-8222`). Any install requires an independently assessed pinned version, artifact verification and tenant isolation; no library import or install was performed.
- `adapter.py` only reduces caller-supplied OpenAI-compatible `GET /models` data to bounded safe model IDs. It never connects, calls inference, reads credentials, infers model pricing, or grants provider access.
- `test_adapter.py`: five mock regressions executed in isolated Python unittest with exact Git blob read-back.
- **Next gate:** demonstrate a concrete missing RavenNest provider feature and a safe pinned upstream version before introducing a proxy.
