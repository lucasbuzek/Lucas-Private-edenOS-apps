# CRESUS private web agent — setup

Free stack: Cloudflare Workers (app) + Workers AI (model, 10,000 neurons/day) +
D1 (chats) + Cloudflare Access (login, free up to 50 users).

Canon source: `CRESUS_InChat_FULL_2026-10-06.zip` (15 modules), bundled into `src/prompt.js`.
Design authority: `#appDev Bible/DESIGN_MANTRA.txt`, CRESUS Project Bible (UI/UIX),
`01_CRESUS_CANON.md` (CRESUS THE KING), `02_OPERATING_MODES.md`, `11_OUTPUT_CONTRACTS.md`.

Already done: D1 database `cresus-agent` created, schema + migration 0002 applied
(id `deafac98-8efa-414b-9561-30904ac1f9b9`, set in `wrangler.toml`).

## 1. Deploy from GitHub (standing default — nothing installed locally)

Cloudflare builds and deploys straight from the repo on every push. The deploy tool
runs on Cloudflare's build machines, so your laptop never needs `node_modules`.

1. Push this folder to GitHub (the repo is the working copy; the Mac is the cold mirror).
   `canon/` holds the 15 canonical CRESUS modules; `npm run build` turns them into
   `src/prompt.js`, so the canon is versioned with the app.
2. Cloudflare dashboard → **Workers & Pages → Create application → Import a repository**
   → pick the repo (if it is a monorepo, set **Root directory** to this app's folder).
3. Build settings:
   - **Build command:** `npm run build`
   - **Deploy command:** `npx wrangler deploy` (the default)
   - Worker name must stay `cresus-agent` (it must match `name` in `wrangler.toml`).
4. **Save and Deploy.** Every later `git push` to the production branch redeploys.

Changing the canon = edit files in `canon/`, push. Changing the app = edit, push.
`wrangler.toml` `[vars]` are the runtime settings (they are not secrets). Real secrets
(`GEMINI_API_KEY`, `ANTHROPIC_API_KEY`, `CF_API_TOKEN`) go in the Worker's
**Settings → Variables & Secrets**, never in the repo. Do not use `[build]` in
`wrangler.toml`: Workers Builds ignores it, so use the dashboard build command.

Until step 2 below is finished the app exposes no data: every API call is refused.

### Fallback: deploy from a computer (only if GitHub deploy is unavailable)

```bash
npm install && npm run build && npm test
npx wrangler login && npx wrangler deploy
```

This installs about 200 MB of tooling (`node_modules`). It is safe to delete afterwards.

## 2. Turn on login (Cloudflare dashboard, ~10 min)

1. **Zero Trust** → choose a team name → **Free plan**.
2. **Integrations → Identity providers → Add**:
   - **Google** (free Google Cloud OAuth client; the side panel walks through it).
   - **One-time PIN** — a code emailed to any address, including **@icloud.com**.
3. **Access controls → Groups → Add** `CRESUS users` → Include → Emails → you + your wife.
4. **Access controls → Applications → Add → Self-hosted**: your `cresus-agent.<you>.workers.dev`
   hostname, login methods Google + One-time PIN, policy **Allow** group `CRESUS users`.
   Copy the **Application Audience (AUD) tag**.
5. Put `ACCESS_TEAM_DOMAIN` and `ACCESS_AUD` in `wrangler.toml`, then commit and push. Cloudflare redeploys automatically. (Both values are identifiers, not secrets.)

## 3. Install on phones

Open the URL → sign in → Safari **Share → Add to Home Screen** (Android: **⋮ → Install app**).

## Managing access

Menu → **Manage access** (admins): seats 1–50, messages per person per day, add/remove
people as member or admin. Removing someone keeps their chats. To manage the Access
sign-in list from the same screen, set `CF_API_TOKEN`, `CF_ACCOUNT_ID`, `ACCESS_GROUP_ID`
as secrets (token permission: *Access: Organizations, Identity Providers, and Groups — Edit*).

## Sign in with Apple

Not used. Cloudflare Access has no built-in Apple option, Sign in with Apple for a website
needs an Apple Developer Program membership, and Apple's client secret is a signed token
that expires within 6 months, which Access's generic OIDC can't renew. The free equivalent
for iPhone users is the emailed one-time code to their iCloud address.

## Device capabilities as a Home Screen web app

| Capability | Web app on iPhone | In this build |
|---|---|---|
| Home Screen icon, full screen | Yes | Yes |
| Save/share files (Files, Notes, Mail) | Yes, share sheet | Yes — *Export my chats* |
| Photos & camera | Yes, via picker | Not yet — needs a vision model |
| Documents (PDF etc.) | Yes, via picker | Not yet |
| Notifications | Yes, iOS 16.4+ | Not yet |
| Add to Calendar | Yes, via .ics | Not yet — fits ZACCHAEUS dates |
| Reminders, Contacts, Health | **No** web access | Only via an Apple Shortcut link |

## Model options

| `PROVIDER`   | Cost | Notes |
|--------------|------|-------|
| `workers-ai` | Free (10k neurons/day) | Default. Data stays on Cloudflare, not used for training. ~30 messages/day with the 6k-token canon. |
| `gemini`     | Free tier | Stronger; Google may use free-tier prompts — avoid real financial details. |
| `anthropic`  | Paid per use | Best quality. |

## Provider-choice migration (PR #5 candidate — do not deploy before migration)

The existing Cloudflare Access sign-in and D1 chats remain authoritative. PR #5 adds per-user intelligence preferences, a first-login chooser and an Intelligence settings dialog. Existing accounts continue using the deployment's prior PROVIDER setting until explicitly changed; skipping selection disables AI only for that user. Providers are available only when configured server-side. Codex Cloud remains disabled pending verified supported account-based dispatch.

**Required order:** apply `migrations/0003_intelligence_preferences.sql` to the existing D1 database **before** deploying the new Worker. For the existing Cloudflare-managed build pipeline, add a pre-deploy migration step under the app's root directory:

```sh
npx wrangler d1 execute cresus-agent --remote --file=migrations/0003_intelligence_preferences.sql
```

This uses the existing D1 database and does not erase chats. Run once; CREATE TABLE IF NOT EXISTS is repeat-safe. Do not automatically deploy this candidate to the live production branch until Cloudflare Access identifiers, migration, and end-to-end checks are verified.

The original `PROVIDER` environment variable remains a backward-compatible default for users who have not saved their selection. Provider keys remain server-side secrets. A successful test against a fake AI provider is not evidence of live provider billing, account entitlements, or real-time research data.
