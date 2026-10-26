# CRESUS Apple Client

Targets: iOS, iPadOS; macOS follows using the same CRESUS contracts.

Native UI: SwiftUI.
Billing adapter: StoreKit.
Local intelligence adapter: Foundation Models/Core AI when supported; capability-detect at runtime.
Storage: native local repository implementing CRESUS contracts.

Never embed CRESUS cloud-provider secrets in the application.
FULL must remain useful offline after purchase restoration.
