# EDEN PWA Cloud, Access & Identity Canon — 2026-09-28

## Canonical access model
- LOCAL FIRST — no account, password, or login is required for local execution.
- Sign-in is optional locally and personalizes/connects the existing local profile.
- Protected Internet-facing access requires authentication.
- Reuse identities users already own; do not create an EDEN password ecosystem.
- Public read-only surfaces may remain unauthenticated where explicitly designed as public.

## Identity
EDEN identity is a shared capability, not a separate App or mandatory hosted identity service.
Baseline external identities: Apple, Google, Microsoft.
Extensions: WebAuthn/passkeys, GitHub, organization OIDC/SAML where appropriate.
Never merge identities solely because email addresses match.
An external identity verifies a person; EDEN maps the verified provider subject to the user's EDEN/local profile.
Authentication and permission to external provider data (Drive, OneDrive, etc.) are separate grants.

## Standalone / BIFROST
Every EDEN App remains independently operable.
A standalone App carries the minimum identity/cloud adapter it requires.
When BIFROST is present, compatible Apps may delegate shared provider, deployment, storage, sync and identity plumbing to BIFROST.
Delegation is reversible; BIFROST is not mandatory.

## Preferred PWA cloud implementation
Cloudflare is the preferred initial low-cost provider, not an architectural dependency:
- Pages: PWA/static deployment
- Access: optional outer private gate
- Workers: protected server/API boundary
- D1: structured cloud data
- R2: object/file storage
Production and private preview deployments must be protected when the profile is Private.
Browser code must never contain permanent provider/admin secrets.

## Cloud storage
Provider abstraction supports R2/S3-compatible storage plus optional Google Drive, OneDrive, Dropbox, WebDAV, NAS and other adapters.
Apps request storage capabilities rather than vendor names.
Sensitive data should be encrypted before remote storage where appropriate.

## EDEN Sync
Shared capability for local↔cloud state.
Apps declare authority semantics appropriate to their domain: local-authoritative, cloud-authoritative, multi-master, or backup-only.
Offline operation is normal for local-first Apps; reconnection triggers controlled reconciliation.

## Security boundary
Local UI may operate without authentication.
Network endpoints exposing private data, writes, synchronization, files, administration or protected capabilities require verified authentication.
Provider credentials/tokens are verified at a trusted server/gateway adapter. Never trust identity asserted by browser-controlled headers.
Cloudflare Access may add perimeter protection but is never the sole EDEN identity authority.

## User experience
Recommended/default setup hides provider implementation details.
User-facing concepts: This Device, EDEN Cloud/Sync, My Cloud Storage, Backup, Archive.
Advanced/Expert may expose provider routing, quotas, sync authority, encryption, retention and recovery.

## Implementation reference
Reusable scaffold lives in:
lucasbuzek/Lucas-Private-edenOS-apps
branch: eitrimb/eden-pwa-access-v1
path: SHARED/eden-access/
draft PR: #2

Implementation currently includes:
- local profile creation without account/login
- optional personalization via verified identity
- protected network-route classification
- Worker trusted-identity boundary scaffold
- D1-compatible user ↔ provider-subject schema
- baseline Apple/Google/Microsoft issuer definitions
- static tests

## Evidence state
Architecture: ACCEPTED / CANONICAL by user direction.
Code scaffold: IMPLEMENTED.
Static/environment/physical authentication verification: pending actual deployment/provider credentials.
Do not promote authentication to VERIFIED until cryptographic provider verification is exercised end-to-end.
