MONETA v1.6 CROSS-PLATFORM EXPERIMENTAL

EXECUTABLE NOW
- Web/PWA on modern desktop/mobile browsers.
- Node local server on macOS, Windows and Linux.
- Same shared Core registry/routing/resource-profile logic.

PREPARED, NOT BUILD-VERIFIED
- Tauri 2 desktop shell source for macOS/Windows/Linux.
  Rust/Cargo is unavailable in the current build environment, so native binaries are
  NOT claimed and the native build is NOT_RUN.

RUN
cd 90_CROSS_PLATFORM
npm test
npm start
Open http://127.0.0.1:8790

ARCHITECTURE
ONE CANONICAL CORE → WEB/PWA + NATIVE SHELLS/ADAPTERS
SCALE BY COMPOSITION, NOT BY FORKING.
