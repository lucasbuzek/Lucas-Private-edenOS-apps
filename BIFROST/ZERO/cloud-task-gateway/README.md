# BIFROST ZERO — Cloud Task Gateway (candidate)
Scope: PWA -> authenticated Cloudflare Worker -> GitHub issue queue. No Mac or local bridge required.
**Execution boundary:** This is NOT a Codex Cloud task API integration. It creates traceable tasks but cannot start or monitor Codex executions. Do not represent QUEUED_FOR_EXECUTOR as RUNNING.
## Verified upstream interface
Official `openai/codex-action@v1` executes Codex on GitHub Actions, but requires a provider API key as a repository secret. This conflicts with the current no-paid-API requirement unless an acceptable free credential route is separately proven. No public supported direct Codex Cloud task-creation API has been verified here.
## Deploy
Cloudflare Worker module entrypoint `worker.mjs`; set secrets `GITHUB_TOKEN` (fine-grained, issues read/write only for chosen repo) and `GATEWAY_TOKEN`, vars `GITHUB_OWNER`, `GITHUB_REPO`, `ALLOWED_ORIGIN` (exact PWA origin).
Endpoints: POST /tasks {title,instruction}; GET /tasks/:issue_number. Auth: Authorization: Bearer <gateway token>. Do not embed GATEWAY_TOKEN in public PWA JavaScript: instead use authenticated server-side session/BFF to call gateway. Never grant GitHub token to browser.
## Security gate
Before production, replace shared gateway token with verified user session, per-agent ACL, anti-CSRF protection and rate limits; enforce repo allowlist, instruction sanitization, and approval for code-changing execution. The current origin check is defense-in-depth, not authentication. No execution enabled.
## Acceptance gates
1. Code syntax/test; 2. Auth rejects missing/invalid tokens; 3. Unauthorized origin rejected; 4. Valid task creates one GitHub issue; 5. Status returns queued; 6. No secret leaks; 7. Codex execution remains UNKNOWN until independently wired and tested.
## Non-goals
No local filesystem, Mac, physical device, unverified Codex API, automatic PR merge, or billing bypass.
