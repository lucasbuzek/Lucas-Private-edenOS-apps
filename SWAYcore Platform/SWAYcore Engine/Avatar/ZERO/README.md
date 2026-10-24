# SWAYcore Engine — Avatar ZERO (NULL / Stick-man)

Purpose: independent, permanent minimum visual representation for movement, timing, tracking, scoring, fallback and diagnostics.

Original existing code reference (do not move): ../../../../SWAYcore Dance & Fitness/R2/App/SWAY/Views/StickFigureView.swift
Historical reference: ../../../../SWAYcore Dance & Fitness/R2/Reference/LKG_Build143_Selected_extracted/SWAY/Views/StickFigureView.swift

ZERO is an Engine-level renderer contract, NOT a separate new app, verified release or promoted LKG. Recover the original overnight functional build before claiming parity. Reuse the existing 23-joint contract where supported, keep tracking optional, and avoid creating another incompatible skeleton definition.

Independent goals: (1) inspect renderer and its dependencies; (2) validate canonical movement input; (3) create a safe Engine adapter only where necessary; (4) test fallback independently; (5) test Dance & Fitness end-to-end with ZERO; (6) preserve working original.

Current status: independent iPhone Engine ZERO test-host source is implemented at iOS TestHost/ (UI, recovered animated COACH pose, on-device Vision camera stage, six-action calibration onboarding and permission/settings fallback). The native signed iPhone Debug build passed under the existing XZ4VRP5S5G team; its bundle ID is com.lucasbuzek.private.swaycore.enginezero. The existing SWAYcoreEngine package passed 31 automated tests, zero failures. Device installation was attempted and rejected because this free developer profile already occupies all three app slots (HEIMDALL iOS, HEIMDALL Probe, Dance & Fitness); no existing app was removed. Therefore the ZERO camera, UI, onboarding and runtime have NOT been physically accepted. The original Build 81–83 executable remains UNKNOWN; do not promote a ZERO or Dance & Fitness LKG. Original R2 and Build 143 reference source were hash-verified unchanged.
