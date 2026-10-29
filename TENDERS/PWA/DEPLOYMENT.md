# TENDERS PWA — Build and Deployment

## Current implementation boundary
This starter is a deployable static PWA for local opportunity records, profile, search, status history, JSON backup/restore and user-supplied public RSS/Atom/JSON/OCDS feed discovery. Provider-specific live-source adapters, multi-device sync, backend authentication, real-account Google OAuth/API verification, bid document assembly and external tender submission remain incomplete. Do not represent those capabilities as available until their separate verification gates pass.

## Build
Requirements: Node.js compatible with Vite 7 and npm.

```sh
npm ci
npm test
npm run build
npm run preview
```

The production output is `dist/`. The committed lockfile supports reproducible dependency installation. Do not deploy the source directory as if it were the production output.

## Static deployment
Deploy the contents of `dist/` to a static HTTPS host such as Cloudflare Pages, Netlify or another compatible host. Configure the publish directory as `dist`; use the project root `PWA/` for the build root, `npm ci` for install and `npm run build` for build. The included `_redirects` provides an SPA fallback for hosts supporting that format. Verify the final paths on the actual provider.

A static deployment runs without the Mac remaining online. Records are stored in that browser's localStorage and are not automatically synchronised across devices. Export backups before changing browser, device or site origin. The current build does not contain a backend or Google credentials.

## Install
Open the deployed HTTPS URL in a supported browser. Desktop Chromium browsers may offer an install action. On iPhone/iPad, use Safari's Share menu and Add to Home Screen where available. Physical Safari/iPhone and Android install tests remain UNKNOWN until performed.

## Security and limits
- Do not add secrets to Vite client environment variables; client bundle values are public.
- Google OAuth/API work requires a separate secure configuration and server-side components where needed.
- Offline behaviour provides a cached shell and previously loaded same-origin resources; it is not a promise that live discovery, cloud sync or Google services work offline.
- Confirm deployment with a live URL smoke test before claiming that the app is publicly deployed.

