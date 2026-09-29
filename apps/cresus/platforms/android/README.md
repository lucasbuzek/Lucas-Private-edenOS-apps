# CRESUS Android Client

Target: Android; Windows follows as a separate desktop client consuming the same contracts.

Native UI: Jetpack Compose.
Billing adapter: Google Play Billing.
Local intelligence adapter: supported Android on-device AI capabilities; capability-detect at runtime.
Storage: native local repository implementing CRESUS contracts.

Never embed CRESUS cloud-provider secrets in the application.
FULL must remain useful offline after purchase restoration.
