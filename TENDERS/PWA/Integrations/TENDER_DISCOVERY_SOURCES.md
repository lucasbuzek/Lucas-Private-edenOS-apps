# TENDERS — Discovery Source Research and Readiness

Reviewed: 2026-10-15. This is source research, not a claim that the listed live providers are connected.

## Implemented generic adapter

The PWA supports user-supplied public RSS, Atom, JSON and OCDS-shaped JSON feeds. It records fetch time, HTTP status, source feed URL, source item identifier and (where Web Crypto is available) SHA-256 of the fetched feed body. Imports remain DISCOVERED; they do not claim eligibility, live tender status or independent verification. The browser must be able to reach the feed and the host must permit cross-origin access (CORS). Authenticated portals and feeds blocked by CORS need a provider adapter or authorised backend proxy.

## Official source candidates and verification gates

### South Africa — National Treasury eTender Transparency Portal
- Official portal: https://data.etenders.gov.za/
- Official OpenAPI/Swagger UI: https://ocds-api.etenders.gov.za/swagger/index.html
- Official portal says versioned procurement data is available through an OCDS-compatible JSON REST API, and monthly data is available as CSV/JSON/Excel under CC BY 4.0. It warns the portal includes only a subset of public procurement data captured on eTender.
- Official portal page inspected through public web search on 2026-10-15. Direct host-side TLS-verified requests to both portal and Swagger UI failed with CERTIFICATE_VERIFY_FAILED (unable to get local issuer certificate). No TLS bypass was used.
- Exact OpenAPI document, operation paths/parameters, sample response, auth requirements at endpoint level, browser CORS headers and live tender coverage remain UNKNOWN. No TENDERS-specific adapter implemented until these are verifiable.

### European Union — Tenders Electronic Daily (TED) Search API
- Official API documentation: https://ted.europa.eu/api/documentation/index.html
- Official public API Swagger UI: https://api.ted.europa.eu/swagger-ui/index.html
- Official primary search endpoint: https://api.ted.europa.eu/v3/notices/search
- Official secondary search endpoint: https://tedweb.api.ted.europa.eu/v3/notices/search
- The Publications Office's 14 May 2025 reusers workshop Q&A identifies these official docs/endpoints and notes fair-use/API limits. It also warns the API is notice-based and may not map individual lots cleanly.
- Official search docs are JavaScript/anti-bot gated in the available browser extraction. Direct host-side TLS-verified requests to docs and endpoint (GET and OPTIONS preflight) failed with CERTIFICATE_VERIFY_FAILED (unable to get local issuer certificate). No TLS bypass was used.
- Published examples from the official workshop establish POST search endpoint use, but the exact current OpenAPI schema, field names/response model, anonymous permissions, rate limits and browser CORS response headers were not directly verified in this run. No TENDERS-specific adapter implemented until these gates are satisfied.

### Slovakia and other jurisdictions
No Slovakia-specific endpoint has been adopted as a default. Discover and verify the official portal/API, exact schema, permissions, data-use terms and CORS before implementing a country-specific adapter.

## Verification record — 2026-10-15
- Official-source web research: PASS for source identity and documented API entry points; PARTIAL for exact schema.
- Direct TLS-verified host requests: BLOCKED by local certificate validation failure for ZA portal, ZA Swagger UI, TED docs and TED API endpoint. This is an environment trust-chain failure, not proof the provider is down.
- CORS/OPTIONS result: UNKNOWN because TLS verification failed before an HTTP response was received.
- Endpoint permissions/auth: PARTIAL from official published docs; endpoint-specific live behaviour not tested.
- Provider-specific TENDERS adapters: NOT IMPLEMENTED, correctly gated pending schema, permissions and CORS evidence.
- Do not bypass TLS validation, invent fields, treat browser search snippets as a machine-readable schema, or mark a source connected.

## Source trust and status rules
A successful HTTP response means only that a source was fetched. A parsed result means only that a notice-shaped record was extracted. Imported records remain DISCOVERED until current official notice, deadline, amendments/cancellations and eligibility are checked. Preserve the original notice URL and feed URL; keep fetch timestamp, source item identifier, publication date and content hash where available. Never infer that a deadline is still open when the source lacks a trustworthy closing time/time zone. Do not scrape authenticated pages, bypass access controls, or misrepresent an inaccessible source as verified.

