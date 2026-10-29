

## Online research runner — 2026-10-11
- [x] Added a public-source discovery/capture prototype for GDELT, Google News RSS and configured RSS/Atom feeds.
- [x] Added deduplication, publication metadata, public URL checks, source text capture, provenance and explicit NOT_VERIFIED status.
- [x] Added source configuration template, usage documentation and unit tests.
- [ ] Verify a live Mac network run and inspect its output/errors.
- [ ] Expand source coverage with persona-relevant official sources and research indexes; no generic crawler can cover the entire internet.
- [ ] Implement model-backed source synthesis, claim ledger/counterevidence search, persona-aware writing and channel variants.
- [ ] Implement full automatic preparation pipeline and review queue; keep external submission and scheduling gated by exact human approval.


## Automatic preparation orchestrator — 2026-10-11
- [x] Added `10_RUNTIME/auto_pipeline.py`: discovery orchestration, a counterevidence/context search pass, per-topic research packages, optional Responses API model adapter, and local-only schedule proposals.
- [x] Model adapter reads `OPENAI_API_KEY` and `OPENAI_MODEL` from process environment only; source content is explicitly treated as untrusted data; model outputs are drafts, never approvals.
- [x] Publishing and remote scheduling remain absent/disabled. Missing model configuration blocks drafting rather than fabricating a fallback.
- [x] Improved discovery runner TLS trust handling, reduced request timeouts, skipped futile Google News aggregator article fetches, and stopped repeated queries to a provider after HTTP 429.
- [ ] Verify final live run after timeout/aggregator adjustments and inspect captured output.
- [ ] Build a user-facing Persona Studio / guided persona editor and validated persona versioning.
- [ ] Add claim-by-claim source verification, reliable direct-publisher resolution, source-independence analysis and risk/rights gates to the executable pipeline.
- [ ] Add calendar cadence/timezone configuration, queue UI, and account/provider adapters only after explicit platform selection.
- [ ] Validate the optional model adapter against the selected model/account and set cost limits before use.


## Persona Studio and pipeline gates — 2026-10-11
- [x] Added interactive `persona_studio.py` create/edit/validate/activate/list workflow under `03_PERSONAS/Profiles/`.
- [x] New and edited personas remain `CONFIGURED_PENDING_REVIEW`; explicit activation requires a valid profile and reviewer. Profile updates preserve revision snapshots and append an audit event.
- [x] Automatic pipeline now requires an explicitly ACTIVE persona for persona-led runs; schedule proposals reject past times and remain local-only.
- [x] Added persona-studio and pipeline tests; no account secrets or publish permissions are exposed by the wizard.
- [ ] Run an interactive persona setup using Lucas's chosen real account(s), topic scope, platforms, audience, language and cadence.


## PRIVATE / silentChatGPT / ELYSIUM integration — 2026-10-19
- [x] Recovered verified physical master in Software Development; Projects symlink resolves correctly, no duplicate source created.
- [x] Repaired expired-date test and reran local suite; 41 unit tests PASS after adding workspace authorization, ChatGPT JSON boundary and on-device model integration.
- [x] Apple Silicon macOS 27/Xcode 27: FoundationModels import, model availability and synthetic JSON generation confirmed; local executable is internal, not installed.
- [x] Added optional local Swift model adapter and explicit per-persona+CLI permission gate for external cloud drafting. No paid API requests or social-platform side effects performed.
- [x] Recovered ELYSIUM Personal/Business private plugin skill boundaries; no spouse/household data copied.
- [ ] Verify actual BIFROSTcore authenticated actor/consent contract and connector invocation; local gateway is not network-accessible.
- [ ] Build full claim-level verification, primary-source/counterevidence capture, persona-specific drafts, red-team QA, platform policy checks, review UI and complete calendar with exact human approvals.
- [ ] Finish functional acceptance BEFORE creating/installing first private ChatGPT plugin through connected Plugin Creator. Registered project plugin was not found in the owned personal-plugin inventory.
- [ ] Then optional opt-in macOS background service, then native SwiftUI/macOS app; web/PWA representation only after consent and workspace authorization tests.
- [ ] Apply current WORKinCODEX Cloud transport only with verified environment/branch/project scope. Do not clone into a parallel master or apply/push unattended.


## FAMA two-specialist split — 2026-10-20
- [x] Recorded FAMA as preferred name of independent adversarial Social Media Intelligence; retained one physical source master.
- [x] Separately established reusable shared Social Media Manager & Publisher for CURATOR, KUROSAWA, CASPER, COMPOSER and authorized other apps; historical SOCIAL name is unverified placeholder.
- [x] Preserved ARTEMIS asset production, PUBLISHER formal release distribution, DRAPER agency, BIFROST connectivity and ELYSIUM permissions.
- [ ] Recover historical shared-social formal identity and plugin/source before naming or creating.
- [ ] Design/test cross-app social delivery interface and separate permission-scoped in-chat specialist without copying FAMA source or accounts.

