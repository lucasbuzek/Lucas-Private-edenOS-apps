# SWAYcore Community / Connect / Official Backend
**Recovered required official-release scope. Engineering state: REQUIREMENT RECOVERED; DEPLOYMENT AND IMPLEMENTATION NOT VERIFIED.**

## Release-stage boundary
- Alpha/current offline-first consumer must function without accounts or a network. Local creation, Move library, rhythmic Beats, locally available workouts, avatar preferences, .swaypack export/import and Share Sheet remain independent.
- **Official release requires a web/backend component** for community functions, official packs/updates and public publishing. This is an additional component of the SWAYcore ecosystem, not a competing movement engine or an excuse to lock local features behind login.
- Studio Management is separate business-domain source; SWAYZ is professional creator; Kids requires independent safeguarding rules.

## Required interoperable objects/workflows (recovered, exact storage implementation UNKNOWN)
1. **Identity:** optional accounts and cross-device data, verified member identity where needed, public display as pseudonymous handle; email and identifying data remain private. Do not reveal email as a social identifier.
2. **Profiles/social context:** user-controlled public/private profile details, follows/friends where enabled, favorites/bookmarks, discoverability controls; public posting always intentional.
3. **Content publishing:** validate Move/Variation/Combination/Routine/Program versions and official packs using the SAME canonical .swaypack movement definition; author/source/licence/version/provenance; preview/reference, metadata and consent; ability to unpublish and manage ownership/rights.
4. **Discovery:** browse/search/filter authored moves/routines/challenges/styles and official pack catalog; explicit content safety classifications, robust references and versioned downloads; cached local offline use after download.
5. **Challenges and groups:** optional community challenges, group/partner participation and professional studio/class links without expanding two-person CONSUMER Shared Sessions into unlimited live sessions. Exact live-session service design remains to be proven.
6. **Official updates:** versioned provider-endpoint catalogs/manifests, compatibility checks and content updates, not remote code execution. Never overwrite local creations without backups or migration.
7. **Trust/safety:** moderation, content reporting/blocking, abuse workflow, intellectual-property complaints and takedown, publication restrictions and transparent rules before opening public uploads. No unwarranted public camera footage, precise location, phone number or private choreography.
8. **Privacy/deletion:** local processing as default; minimize server data, ask before publishing, support revocation, exports and deletion, no silent telemetry. Health data, tracking recordings and camera frames stay on device unless a user explicitly selects a supported share action. Device state/consent syncing is optional and transparent.
9. **Child protection:** Kids is NOT connected automatically to adult public discovery/chat/follows. Age bands, parental identity/consent, content moderation and policy detail are not fully recovered. Treat public-child interaction as **UNSUPPORTED until independently designed and physically/security tested**.

## Backend integration contract
- Make official backend an **adapter**, not an authoritative second movement model. All published content passes canonical schema and source/licence validation, pack-signature/checksum verification, version negotiation and offline caching.
- Support accountless local export/import and native Share Sheet regardless of backend availability.
- Server endpoints, provider choices, cloud costs, account vendor, deployment and production security review are UNKNOWN. Do not create paid cloud resources, register users, upload personal data or claim deployment until separately specified and verified.
- Source currently available in R2: `App/SWAY/Models/ProfileSharing.swift` and related pack/service contracts, which are NOT evidence of deployed server. Original family package includes `Packages/SWAYcoreKit/Sources/SWAYcoreKit/SwayPack.swift`.
- Minimum acceptance before official release: publish consent -> validated pack -> moderation -> searchable discovery -> download -> offline use -> version update -> remove/report/block -> profile privacy -> account state deletion. Run adversarial/abuse and user data leakage tests as well as functional tests.

## Evidence boundary
Historical user decisions of 2026-09-27 require web backend for official community/updates/content; 2026-09-22 current Alpha excludes a finished portal and uses lightweight/private profiles. Treat both as **different release gates**, not conflicting feature definitions.
