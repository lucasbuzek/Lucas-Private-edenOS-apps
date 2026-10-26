# AppleRAVEN — owner's personal private identity

**Current user decision, 2026-10-26:** AppleRAVEN is a PERSONAL Apple-specific MCP, with a dark graphite/midnight identity combining the **Apple logo** and a **raven**. It is not an EDEN or edenOS product and must not inherit EDEN application icons or design branding. It can interoperate with those products only by explicit, separate authorized adapters.

## Canonical private theme

- Surface: `#05070E`, raised surface `#111725`
- Text: cool silver `#D7DEEA`; muted `#8E9DB6`
- Accent: moonlight blue `#87ABD7`
- Native Apple mark: `Image(systemName: "apple.logo")`
- Raven motif: private original raven silhouette; `bird.fill` is native SF Symbols fallback
- Brand identity: `AppleRAVEN` (no EDEN wordmark, brand colors or specialist icon)

## Implementation evidence

A newer **conversation-only distributable** `AppleRAVEN-private-dark-v0.3.1.zip` includes SVG, PNG, .icns, brand.json, SwiftUI companion identity source, 15-tool standalone MCP and tests. Local isolated verification on 2026-10-26: 37/37 tests, modern/legacy stdio smoke, 15 tools, no-clobber installation. Package SHA-256: `0453a82dc6abe20e5da8213ce3c2257a58a7d11b98ad34a26b68273b326ab171`.

**This historical GitHub candidate branch is NOT asserted to contain the newer distributable's complete source**. It must be reconciled against the original Mac source/LKG and the exact conversation package before promoting any newer code. No physical Apple install was verified. Apple's logo and SF Symbol should be rendered by the native Apple platform rather than embedding third-party font resources. Private use does not imply Apple affiliation.
