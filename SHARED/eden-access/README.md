# EDEN Access v0.1

Shared access contract for EDEN Apps.

## Canon
- Local execution: no account, password, or login required.
- Sign-in is optional locally and personalizes/connects the local profile.
- Protected Internet-facing operations require verified authentication.
- Reuse existing identity providers; EDEN does not operate a password database.
- Cloudflare Access may be an outer gate but is not an identity dependency.
- Standalone Apps retain the minimum adapter; BIFROST may assume shared identity/provider duties when available.

## Provider baseline
Apple, Google and Microsoft first. WebAuthn/passkeys and GitHub are extension adapters.

## Security boundary
Browser code never asserts its own verified identity. The server/gateway adapter must cryptographically verify provider credentials, then pass a normalized provider + subject into EDEN authorization.

The included Worker auth module deliberately does NOT implement raw OIDC token verification yet: issuer/client IDs, callback URLs, key rotation and deployment domains are environment-specific. Treat its X-EDEN-Verified-* headers as trusted-infrastructure-only and strip them at the public edge.

## Integration
Use localProfile() immediately for local mode. Protect /api, /sync and /files at the network boundary. After provider verification, map (provider, provider_subject) to an eden_users.id using schema.sql. Do not merge users solely by email.

## Stage
IMPLEMENTED scaffold / STATIC UNVERIFIED. Environment and physical verification are required before promotion.
