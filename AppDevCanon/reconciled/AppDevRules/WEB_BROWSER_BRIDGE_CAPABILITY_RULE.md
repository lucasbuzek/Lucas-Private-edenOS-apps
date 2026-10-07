# WEB / BROWSER BRIDGE - SHARED CAPABILITY RULE (AppDevRule, Mac-only canon)

<!-- RECONCILED 2026-10-07: extracted verbatim from the tail of Mac file `appDev main/AppDevRules_Web_Browser_Bridge_Canon_v1.1.txt` (24228 B), whose first 460 lines are a copy of the appDev MASTER reconciliation handoff. Source sha256 2789ed918466885952094b82c591a60807719f5b8fa7fa9b3cac48184dfed392. Status: Mac-only canon, not yet in GitHub. -->

APPDEVRULE
— WEB / BROWSER BRIDGE SHARED CAPABILITY
============================================================

WEB / BROWSER BRIDGE — SHARED CAPABILITY RULE

The Web / Browser Bridge is a first-class independently consumable
shared EDEN capability. It is not owned exclusively by WEAVER, HERMES,
BIFROST, or another consuming App.

ARCHITECTURE EDEN WEB CAPABILITY / BROWSER BRIDGE CORE → Safari native /
WebExtension adapter — first-class for the Apple-centric Private build →
Chromium WebExtension adapter → Firefox WebExtension adapter →
default-browser / URL / Share fallback where richer integration is
unavailable

Apps consume the shared Web capability directly through a stable common
contract where technically practical.

BIFROST may discover, register, permission, expose, coordinate,
synchronize and enhance the Web capability, but BIFROST must not become
a mandatory runtime gateway or single point of failure.

WEAVER owns website design/development/optimization/SEO, not the generic
Browser Bridge. HERMES may use rich browser/page/form capabilities for
opportunity and application workflows, but does not own the generic
Browser Bridge. Other compatible Apps may consume the same capability
directly.

COMMON CAPABILITY SURFACE The shared contract may expose, where
supported and authorized: web.open web.fetch web.search web.download
web.capture active-page URL/title/metadata page/rendered-content
extraction current user selection page-to-App handoff
permission-controlled browser actions

Adapters normalize browser/platform differences behind the shared
contract. Capability/status semantics must truthfully expose what each
adapter can and cannot do.

INTERACTION PIPELINE For rich browser interaction, use: READ → EXTRACT →
UNDERSTAND → PREPARE → PREVIEW → AUTHORIZED ACTION → VERIFY

Reading/extraction and external actions remain permission-aware.
Consequential actions such as submissions, purchases, commitments,
messages, account changes or irreversible external actions require the
appropriate authorization and must follow: REQUEST → VALIDATE → SAFETY
CHECK → EXECUTE → CONFIRM

The Browser Bridge must not silently submit, purchase, commit, publish
or perform another consequential external action merely because it can
inspect or prepare the page.

APPLE PRIVATE BUILD Safari receives first-class native optimization and
integration for the Private Apple-centric environment where materially
useful. The shared core remains portable and must not become Safari-only
or Apple-only.

CROSS-PLATFORM Chromium and Firefox use compatible WebExtension/platform
adapters where practical. Unsupported browser functionality must degrade
gracefully to available capabilities rather than breaking unrelated EDEN
operation.

NO EDEN BROWSER REQUIREMENT Do not create a separate EDEN browser merely
to provide this capability when mature browser-extension/native
integration can satisfy the requirement. Integrate/adapt existing
browser platforms first.

LOCAL / PROVIDER INDEPENDENCE Browser integration is an adapter/provider
layer, not the owner of user data or domain logic. Loss of a browser
adapter must not invalidate EDEN-owned data, canonical state or
unrelated capabilities.

VERIFICATION Architecture/design status and implementation status are
separate. A Browser Bridge or adapter is not considered implemented,
installed, functional or verified until the relevant build,
installation, permissions and target-browser behavior have been tested
with evidence.
