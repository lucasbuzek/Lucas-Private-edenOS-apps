# TENDERS PWA — Deployment Readiness Checklist

Status at creation: NOT YET VERIFIED; use this checklist against the actual implementation.

## Source and build
- [ ] Authoritative source path/repository and LKG established.
- [ ] Dependencies and licences inspected; lockfile committed.
- [ ] Clean reproducible production build succeeds.
- [ ] Build output inspected; no secrets, debug data or unintended local paths.
- [ ] Version, source revision, build ID and package version recorded.

## PWA requirements
- [ ] Valid manifest, name/short name, start URL, scope, display and theme.
- [ ] Required icon sizes and Apple touch icon exist and load.
- [ ] Service worker registers; cache/version/update logic is verified.
- [ ] Offline shell and offline/stale-data states work as documented.
- [ ] Reconnect, failed sync, retry and conflict paths are tested.
- [ ] Keyboard, screen-reader labels, focus, contrast and reduced-motion checks pass.
- [ ] Desktop and narrow mobile layouts pass.

## Deployment
- [ ] Static host target and exact deployment steps documented.
- [ ] Base path, asset paths, SPA fallback and HTTPS behaviour verified on target host.
- [ ] Optional backend and environment variables documented with a safe example.
- [ ] OAuth redirect URIs, CORS and allowed origins configured without embedding secrets.
- [ ] Clean deploy package generated, extracted to a fresh directory and smoke-tested.
- [ ] Package manifest and SHA-256 checksum recorded.
- [ ] Actual provider deployment confirmed and public URL tested before calling it deployed.

## Google and other providers
- [ ] Gmail/Drive/Calendar remain disconnected until OAuth and end-to-end tests pass.
- [ ] Least-privilege scopes, cancellation and revocation tested.
- [ ] Data isolation, token security and sync errors verified.

## Device gates
- [ ] Desktop browser install/launch verified.
- [ ] iOS Safari installation/launch verified on physical device or explicitly UNKNOWN.
- [ ] Android browser install/launch verified or explicitly UNKNOWN.
- [ ] Offline/reconnect behaviour verified on target devices.

No unchecked item is PASS. Mark genuinely irrelevant items N/A with rationale.

