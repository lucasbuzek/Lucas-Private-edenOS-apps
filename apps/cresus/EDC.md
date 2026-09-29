# EITRI Deliverable Contract — CRESUS CROSS-PLATFORM v0.2

State: IMPLEMENTING

## Goal
Establish a native-app-first CRESUS foundation for iOS/iPadOS and Android while preserving architectural compatibility with macOS and Windows.

## Required
- canonical product/capability entitlements
- portable research/domain contracts
- strict dividend-state separation
- point-in-time evidence timestamps
- stable security/listing identity
- platform adapter boundaries for storage, billing, device AI and cloud intelligence
- fixture/test vectors consumable by every platform
- no PWA dependency

## Commercial invariants
FREE demonstrates a bounded product.
FULL is a permanent on-device capability unlock.
INTELLIGENCE supplies recurring online research/compute.
Accuracy and ownership of local user data are never intentionally degraded to force subscription.

## Platform gates
iOS/iPadOS: SwiftUI + StoreKit adapter + Apple device-intelligence adapter.
Android: Compose + Play Billing adapter + Android device-intelligence adapter.
macOS/Windows: later clients consume the same contracts.

## Evidence gate
A capability is VERIFIED only after its platform implementation passes shared contract fixtures plus platform-specific tests.
