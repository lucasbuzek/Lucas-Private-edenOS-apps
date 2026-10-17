# VAULT — Existing capability / open-source reuse decision (2026-10-17)

Native-first rule: use OS services before third-party dependencies. Avoid duplicating Apple Passwords, bank apps or Files.

| Existing capability | Proven relevance | Integration decision |
|---|---|---|
| Apple CryptoKit, Keychain, LocalAuthentication, Data Protection | Authenticated encryption, secret storage, system biometric approval | USE Apple-native security primitives; native biometric-to-key protection remains unimplemented and physically unverified |
| Apple Photos Picker + Vision | User-granted reference screenshots, local recognized text/geometry | USE for opt-in template extraction after privacy gate; never upload banking screenshots by default |
| ARKit face tracking | User-configured intentional facial route selection separate from Face ID | POC ONLY; requires hardware compatibility, explicit camera access and false-trigger tests |
| Cryptomator (https://cryptomator.org and https://docs.cryptomator.org) | Encrypted cross-platform Files documents | INTEGRATE through user-controlled external file references where installed; cannot substitute for financial permissions/route isolation |
| KeePassXC (https://keepassxc.org, GPL-2/3) | Cross-platform encrypted credential database; useful portability reference | OPTIONAL external user-managed password store; do not bundle GPL source into VAULT casually |
| KeePassium/Strongbox/KeePassDX | iOS/Android KDBX clients compatible with password databases | OPTIONAL interoperability, not a financial controller |
| Bitwarden (https://github.com/bitwarden/server/blob/main/LICENSE_FAQ.md) | Credential/password manager, organization sharing | REFER/INTEGRATE through explicit supported APIs; clients GPL-3; server AGPL-3 and separately licensed modules; not drop-in code |
| SQLCipher (https://github.com/sqlcipher/sqlcipher) | Authenticated encrypted database at scale | EVALUATE for larger record sets after performance, mobile builds and exact licensing review; don't replace working small Core |
| Apple CloudKit Sharing | Selective record sharing | Only use with verified actual grant/revoke semantics; apparent read/write may have broader deletion rights |
| Official bank apps / deep links | User-preferred login/payment channel | Validate exact universal links per institution; never claim a generic URL scheme works |

Platform decisions: iPhone/iPad and relevant Mac first. Portable encrypted data envelope and documentation allow future Android/Windows/Linux/web integration; do not promise platform parity before testing. A browser PWA must not pretend to access Apple Face ID, Secure Enclave keys, or private native banking apps the same way.

Security omissions: offline weak-PIN guessing; key rotation and secure erase; export/recovery; confidentiality of decoy existence and failure timing; screenshot remnants; clipboard/screen-recording; rollback/replay; secure data sharing and revocation; malicious documents; accessibility; trusted emergency notifications; app review; iCloud provider and bank-app external dependencies. These remain UNKNOWN, not PASS.

Apple's App Review 4.1 copycat/impersonation rule: https://developer.apple.com/help/app-review/guideline-reference/4-1-prevent-copycat-rejection/ . VAULT will not ship copied official bank logos or exportable counterfeit statements.