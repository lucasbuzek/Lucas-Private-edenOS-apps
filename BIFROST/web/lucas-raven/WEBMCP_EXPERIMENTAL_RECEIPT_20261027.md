# Lucas Raven WebMCP — experimental interoperability receipt (2026-10-27)

## Provenance and project boundary
- This is an additive source-only candidate for the EXISTING BIFROST Lucas Raven website at `BIFROST/web/lucas-raven/public/`.
- It is **not ELYSIUM**, **not the separate RAVENsNEST owner portal**, **not AppleRAVEN**, and **not an installed ChatGPT iOS custom MCP**.
- Based on protected source branch `candidate/appleraven-original-pages-20261027`; existing `app.js`, `index.html`, original Node/Cloudflare and accepted LKG were not modified.
- The ELYSIUM existing private plugin and in-chat suite canon remain independent. A future ELYSIUM WebMCP adapter must be integrated against its own verified original source.

## Changed source in this isolated branch
- `public/webmcp-status.js` — optional Chrome document.modelContext tool `raven_web_status`, using SAME-origin `GET /api/state`, reporting ONLY aggregate device counts.
- `public/webmcp.html` — noindex mobile-readable manual status view even without browser WebMCP support.
- `public/webmcp-status.test.cjs` — reproducible Node regression suite.
- EXACT blob readback: JavaScript `c91c0738e8ebb8798001a71cddb2503fe0d6fc8d`, HTML `eb77ee45d5466da1d7b811f5330a0fd6706aa3c9`, tests `9dc3d0943fac5c7590213ccc0cc1abe6706ab5ce` — equal to locally tested file hashes.

## Tests actually executed
- `node --test webmcp-status.test.cjs` with Node v22: **15/15 passed**.
- Tests include WebMCP supported/unsupported browser, tool read-only declaration, session counts without private fields, 401/403 negative permissions, 404/500/503 denial, malformed payload, unexpected MIME, network failure, zero nodes, manual mobile button, denial UI and noindex HTML.
- Headless Chromium mobile viewport (390 × 844), direct HTML/JS with deliberately **mocked API**: three positive/negative UI state checks **3/3 passed** (200, 401, 503).
- Localhost Chromium HTTP test was blocked by execution sandbox (`ERR_BLOCKED_BY_ADMINISTRATOR`), NOT an application test failure.

## Not tested / forbidden claims
- No real browser-origin-trial `document.modelContext` execution, user Cloudflare Access session, live `/api/state` endpoint, Mac operation, provider API read, iOS ChatGPT custom MCP call or deployment.
- No live Portal OAuth, account consolidation, AppleRAVEN owner+M1 device pairing, files, shell/app execution or full ELYSIUM web backend.
- **EXPERIMENTAL SOURCE CANDIDATE ONLY. NOT LKG, PRODUCT, RELEASE or DEPLOYED SERVICE.**
- No deploy or public-site modification is authorized from this receipt.

## Next evidence gate
Recover exact ELYSIUM native/source Bible + runtime/LKG, complete end-to-end auth/ACL tests, then integrate only the missing verified WebMCP adapter in its owner source. Independently test the protected RAVENsNEST portal and AppleRAVEN owner/device pairing on supported clients. Do not conflate WebMCP browser tools with remote HTTPS MCP or ChatGPT iOS support.
