# EU TED public-source adapter · TENDERS candidate
- Official source https://docs.ted.europa.eu/api/latest/search.html .
- Anonymous TED Search API POST https://api.ted.europa.eu/v3/notices/search ; query syntax documented at https://ted.europa.eu/en/help/search-browse .
- Same-origin Netlify endpoint /api/official/eu-ted?country=SVK — GET only. Fixed upstream hostname and bounded allowlisted country scopes. No arbitrary browser URL proxy.
- Default Slovakia (SVK), scope ACTIVE, 30 results, no provider account, token or bidding authority.
- Multilingual Slovak and English title support, source published date/number, direct official notice link, no invented eligibility.
- Scope ACTIVE can include planning and result notices, so each result is DISCOVERED pending current official verification and deadline/award checks; source itself is not exhaustive.
- Existing PWA generic discovery/parser imports public results with source URL and evidence as unverified DISCOVERED.
- No provider live HTTP or hosted Netlify tests yet. Mocked unit tests + candidate CI must pass prior to deployment review.
