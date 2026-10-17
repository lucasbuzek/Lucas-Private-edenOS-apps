# VAULT — Personal Financial Control Centre

Status: INITIAL ENGINEERING CANDIDATE — NOT PHYSICALLY VERIFIED.

## Identity
Independent personal financial-control application, separate from MONETA's treasury specialist also named VAULT. The companion multi-Space Privacy app is a separate product.

## Current implementation
Native SwiftUI iOS/iPadOS app with optional second access PIN, two isolated locally AES-GCM-encrypted records (PBKDF2-HMAC-SHA256 key derivation), same UI for normal and alternate access, offline account records, session lock on background and iOS file data protection. All stored accounts are manually entered local records; alternate initial entries are synthetic. The optional screenshot picker locally extracts text-region GEOMETRY using Apple Vision, stores only that abstract geometry inside the currently unlocked encrypted record, and never persists the original image or OCR strings. Screenshot-based bank-app UI recreation is NOT implemented.

## NOT READY FOR REAL BANKING OR EMERGENCY USE
Experimental prototype only. A human-memorable PIN used as an offline decryption secret can be guessed if ciphertext is stolen. Do not store real credentials, real bank screenshots or sensitive information in this prototype.
No Keychain/Secure Enclave protection, encrypted export/import, verified backup restore, bank APIs/links, official bank-app impersonation, Face ID/ARKit route, screenshot-to-template generation, actual bank transactions, emergency service, recipient sharing or hardened decoy timing protection.
The alternative route is not a bank application and is not a guarantee of safety during coercion.

## Remaining work
1. Secure Enclave/Keychain hardware-bound root and portable high-entropy recovery pathway with threat-model review.
2. Full encrypted app-data backup, restore and migration, with exclusions and dependency manifest.
3. Complete screenshot-assisted personalized layout generation from the now-implemented PhotosPicker/Vision geometry extractor; add synthetic replacement, review and screenshot retention/clipboard auditing. Tested only for invalid-image rejection, not real banking imagery.
4. Face ID -> optional ARKit follow-up intent routing physical timing/false-trigger tests.
5. Optional verified banking app launcher/web access and explicit item-by-item, recipient-by-recipient sharing.
6. Emergency contact workflows and failure-safe design without unverified silent operations.
7. Cross-platform data contracts and offline-compatible companion UIs. Do not dilute Apple-native UX.
8. Localization, accessibility, independent security review, real iOS device tests.

## Build
Run xcodegen generate in this project root, then:
xcodebuild -project VAULT.xcodeproj -scheme VAULT -configuration Debug -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
The build is not a device test. Do not promote to Products or call this a released app.