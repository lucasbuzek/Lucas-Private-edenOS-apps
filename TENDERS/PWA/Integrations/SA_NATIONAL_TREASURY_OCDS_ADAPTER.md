# TENDERS · South African National Treasury official OCDS source adapter (candidate)
Source contract: https://ocds-api.etenders.gov.za/swagger/v1/swagger.json (OpenAPI v1).
- Official GET /api/OCDSReleases uses PageNumber, PageSize, dateFrom, dateTo; releases[] and links.next.
- Netlify function path /api/official/sa-ocds; this is a same-origin read-only proxy to the pinned official host, not a general URL proxy.
- Date range bounded to 31 days; up to 3 pages of up to 100 releases, output explicitly truncated when more pages may exist.
- Latest revision per ocid kept in each fetch batch. Each result links back to official OCDS release record.
- All results remain DISCOVERED and unverified; this is a subset and may include historical/awarded processes. Do not automatically call them open or eligible.
- Browser PWA still keeps local-only contexts, not secure multi-user tenancy. This proxy holds no OAuth credentials and must not host confidential records.
- New code unit tests use mock HTTP responses. Actual official API and deployment integration test required prior to official adapter acceptance.
- Reuse: existing src/discovery.js parses the resulting JSON and maintains dedupe/evidence recording; no new procurement governor.
