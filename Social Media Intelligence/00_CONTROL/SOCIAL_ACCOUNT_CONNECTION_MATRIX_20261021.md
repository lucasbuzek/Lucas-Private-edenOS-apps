# Social Account Connection and Security Matrix
Date: 2026-10-21. Research-backed design only; provider authorization not yet tested. Recheck terms/capabilities when implemented.

| Platform | Proposed account mode | Credential connection | Actions requiring real provider capability |
| --- | --- | --- | --- |
| WhatsApp personal | Personal, guided user handoff | App/share sheet or owner-approved browser workflow | Prepare messages/Status assets locally; neither programmatic personal messaging nor Status posting assumed |
| WhatsApp Business / Cloud API | Authenticated business phone/account | Official business onboarding and token grant | Opt-in messaging, templates, webhooks, delivery/read receipts; Cloud API message status is NOT a WhatsApp Status/Story |
| Facebook personal | Personal account | User login/official OAuth where available | Account settings and posting guided if platform API disallows personal automation |
| Facebook Pages | Page/Business | Official Meta authorized permissions | Pages posts, comments, metrics subject to granted scopes |
| Facebook Marketplace | Personal/business listing | User-confirmed native/browser handoff | Listings, messages and commerce are guided unless verified API |
| Instagram | Personal, Creator, Business | Separate consent and account capabilities | Instagram Graph publishing is for supported professional accounts; personal profiles guided |
| Meta Business Suite | Owned business portfolio | Meta official delegated access | Manage only authorized Pages, professional accounts and business assets |
| TikTok | Personal/Creator/Business | TikTok official authorization | Direct publishing requires app audit and user permissions; otherwise guided/upload-to-inbox |
| YouTube Studio | Channel or Brand Account | Google OAuth | Upload/video scheduling/metadata, comments and analytics within approved scopes |
| Snapchat | Personal/Public/Creator/Business | Approved native account flow | Public content/metrics where supported, otherwise guided native workflow |
| Discord | User, server, bot | OAuth/bot tokens | Bot-based server automation only; no user-account self-bot |
| Threads / LinkedIn / X / others | Personal, organization, publisher | Platform-specific official authorization | Enforce published API rights/limits and platform policy |
| Optional adults-only social sites | Private adult owner's account | Platform-native interactive login | Separate 18+ user-permission partition; provider API unknown, guided only until verified |

Status enum: NOT_REQUESTED, DISCOVERY_OFFERED, OWNER_APPROVED, AUTHENTICATING, CONNECTED_READ_ONLY, CONNECTED_PREPARE, CONNECTED_PUBLISH, EXPIRED, REVOKED, MANUAL_ONLY, UNSUPPORTED, UNKNOWN. A stored username is not proof of connected access.

First-run permission sequence: select FAMA/BRAGI -> authenticate individual owner -> select permitted Personal/Family/Slindokuhle tenant -> choose in-chat assistant (ChatGPT/Claude when actually available) -> explicit opt-in account discovery -> provider-native login -> account scope/rights/permission preview -> assign per-account app privileges -> verify receipt and account identity. Skipping any provider leaves it NOT_CONNECTED.

Credential model: system Keychain/OAuth token references, per-tenant browser data isolation, Touch ID step-up for secret retrieval where supported, never plaintext passwords in app database, source documents or chat. Per-account security and identity screen must show the account's real owner/handle and last confirmed status. Account secret retrieval requires that exact principal and scope and logs an auditable security event without logging the secret.

Source documentation: https://www.postman.com/meta/whatsapp-business-platform/collection/wlk6lh4/whatsapp-cloud-api ; https://www.postman.com/meta/instagram/folder/u4g5a2a/instagram-api-with-facebook-login ; https://support.discord.com/hc/en-us/articles/115002192352-Automated-User-Accounts-Self-Bots ; https://developer.apple.com/documentation/security/using-the-keychain-to-manage-user-secrets . WhatsApp Status API availability was not established; do not claim it.

