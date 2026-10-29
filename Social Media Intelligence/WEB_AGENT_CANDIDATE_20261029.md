# FAMA read-only browser agent — additive candidate
Purpose: real local browser access to the ORIGINAL FAMA research_runner.py via a bounded POST API, plus experimental Chrome WebMCP progressive enhancement.

Start on the actual approved Mac in a temporary/authorized test environment:
1. Use a 32+ character randomly generated owner token from the local macOS secret store; provide as FAMA_WEB_TOKEN in the launching process only. Never paste the token in ChatGPT or commit it.
2. Run python3 10_RUNTIME/web_agent.py from the recovered working project with unchanged original runtime files.
3. Open http://127.0.0.1:8765 in an approved browser; type token into the in-page password field. Token remains in browser tab memory, never localStorage/cookies.
4. Submit a public research topic. Actual runner uses GDELT/Google News feeds. A result is a LEAD, not claim verification. No posting, scheduling, account OAuth, private ELYSIUM reads or file access.

Boundaries: server strictly binds 127.0.0.1, checks bearer with constant-time comparison, exact browser Origin where supplied, request size, search length/range and per-IP rate. No cross-origin headers, no arbitrary URLs or local file operations, no background installation, no permanent daemon. It DOES initiate public network research only on the owner's explicit action. Built-in HTTP is not a production proxy/authentication stack. Do not expose port to the Internet, reverse-proxy without independently verified owner identity, or use a cloud origin with this simple local token.

The Chrome WebMCP tool only exists when supported in that browser. Safari and other browsers retain human controls. There is NO remote Streamable HTTP MCP or host deployment here, and no implied social provider account connection. Later secure cloud mode requires separately tested server-side identity, tenant grants, provider OAuth, audit, encrypted storage and host deployment.

Tests: Python stdlib unittest, including anonymous, wrong bearer, cross-origin, other tenant, unsupported publish, rate limit, and actual runner invocation contract (offline mocked provider results). Physical Mac tests, social provider OAuth and remote MCP full end-to-end remain UNKNOWN.
