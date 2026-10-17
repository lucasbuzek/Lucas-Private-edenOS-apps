# VAULT — personal financial control centre

Status: recovered requirements contract for a NEW implementation candidate. User decisions take precedence. Companion Privacy Spaces app is a separate product. This is NOT the MONETA.VAULT treasury specialist.

## Product
One user-controlled financial home for personal bank shortcuts, optional secure bank web access, own files, records, and selectively shared resources. Do not replace actual banks, Apple Passwords, Wallet, Files, or operating-system security. No bank integration exists until implemented and verified.

## Security and privacy
- App owner explicitly chooses item/collection, recipient, access and revocation. Relationships convey no access.
- Local encrypted real storage and independently encrypted optional decoy storage, inactive by default until deliberately enrolled.
- Normal PIN opens private dataset; optional alternate PIN opens an independent synthetic dataset with indistinguishable app chrome. Never show a visible decoy badge inside the active decoy route.
- Optional Apple Face ID authenticates identity; only a subsequent separate ARKit facial movement/expression may select a route; do not claim ARKit verifies identity. Fallback to user-controlled PINs. Requires physical false-trigger, camera permission, timing and accessibility testing.
- Avoid reliance on silent texts/calls or covert device capabilities unavailable to third-party applications. Emergency action is independently opt-in and explicitly limited to verified possible mechanisms. Never promise duress safety.
- Optional screenshot-assisted visual personalization: user-selected bank screenshot references; local Photos Picker + Vision analysis and redaction by default, user review, produce an original VAULT template populated with synthetic data. Avoid third-party branding/counterfeit documents, and delete source screenshots after extraction where requested. Raw bank imagery and secrets are never silently uploaded.
- Audit privacy, logging, background snapshots, data at rest, account-discovery leaks, timing and backup restores.

## Apple and portability
- Apple-native iOS/iPadOS and applicable macOS primary. Independent Web/PWA considered only if its encryption, local-data and authorization threat model meets requirements; Android/Windows/Linux optional justified targets, not automatic ports.
- Native Apple Keychain/LocalAuthentication, Secure Enclave, Files, Photos Picker, Vision, CryptoKit, native sharing are first options. Platform adapters must not invent unsupported capabilities.
- Account launch: installed official bank app via verified universal link where supported, accessible bank web fallback, or vault-only. Never assume arbitrary app enumeration.
- Distinct classification for encrypted app-owned, plain local, user-selected external file references, and synced/shared data.
- All app-owned information exportable as encrypted portable rebuild-capable backup, or readable export when explicitly selected; manifest exposes exclusions and dependencies such as passkeys, external files, bank applications, third-party accounts and Apple Passwords. Data is never hostage.
- Offline core use, graceful intermittent network handling; native OS backup/transfers optional not sole exit.

## Access and sharing
- No spouse/partner/family/accountant access by default.
- CloudKit record-sharing semantics must reflect actual permissions (including destructive write where applicable); never assert granular native permissions without evidence.
- Keep real/decoy crypto boundaries and product identities distinct from companion Privacy Spaces app.

## Candidate and release evidence
2026-10-17: no earlier VAULT application LKG/source was demonstrated after inspection of the local canonical root and connected repositories. A new SwiftUI engineering candidate is being developed at this path. It is not release-ready. The MONETA subordinate cannot be reclassified or deleted. No production data should be added before secure recovery, hardware-bound access, audited export and physical verification.

## Required gates
Reference -> baseline -> implement -> static/build verify -> regression -> rebuild-capable backup and restore smoke-test -> physical Face ID/ARKit/camera test -> qualified release. Preserve each LKG and keep all unverified items UNKNOWN.