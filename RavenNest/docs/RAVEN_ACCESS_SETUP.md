# Raven Access, migration and cloud-node runbook

Status: **IMPLEMENTED and TESTED offline only**. Nothing here has been deployed or verified against Cloudflare, GitHub, an iPhone, or a Mac.

## 1. Protect the human portal
1. Cloudflare Zero Trust → **Access → Applications → Add application → Self-hosted**.
2. Name it `Raven`; enter the Raven Pages hostname and path `/*`; session duration as Lucas requires.
3. Add an **Allow** policy using the existing Admin, Family, Friends and Testers groups. Configure **One-time PIN** as the email identity provider.
4. Add a separate, higher-priority **Bypass** policy whose application path is exactly `/api/node/*`. Do not bypass `/api/*` or the site. Machine requests retain Raven Bearer authentication.
5. Copy the Access application AUD tag and team domain (for example, the configured `<team>.cloudflareaccess.com`; do not guess either value).

## 2. Pages configuration
From `BIFROST/web/lucas-raven` set non-secret configuration in Pages project settings: `ACCESS_TEAM_DOMAIN`, `ACCESS_AUD`, `BOOTSTRAP_OWNER_EMAIL`, `LEGACY_OPERATOR_ENABLED=1`, and `LEGACY_OPERATOR_SENSITIVE=0`. Keep existing hash secrets during migration. Do not paste values into source or shell history. `BOOTSTRAP_OWNER_EMAIL` creates an owner only when no owner exists.

Apply and verify D1 (Lucas runs these; they were **not executed remotely** here):
```sh
npx wrangler d1 execute lucas-raven --local --file=web/lucas-raven/migrations/0002_multiuser.sql
npx wrangler d1 execute lucas-raven --remote --file=web/lucas-raven/migrations/0002_multiuser.sql
npx wrangler d1 execute lucas-raven --remote --command="SELECT name FROM sqlite_master WHERE type='table' AND name IN ('users','devices','device_enrollments','grants','audit') ORDER BY name"
npx wrangler d1 execute lucas-raven --remote --command="SELECT name FROM sqlite_master WHERE type='index' AND name IN ('grants_active_unique','devices_credential','enrollments_token','grants_user','audit_ts') ORDER BY name"
npx wrangler d1 execute lucas-raven --remote --command="PRAGMA table_info(node_state); PRAGMA table_info(actions);"
npx wrangler pages deploy web/lucas-raven/public --project-name lucas-raven
```
Run the local migration command twice; the second run must succeed without changing table/index counts.

## 3. Cloud worker
Create a fine-grained GitHub token limited to selected repositories with read-only **Metadata**, **Contents**, and **Pull requests**. In the worker settings set secret `GITHUB_TOKEN` and variable `GITHUB_REPOS` to a comma-separated `owner/name` list. Never put the token in `wrangler.toml`.
```sh
cd BIFROST/workers/raven-cloud-node
npx wrangler secret put GITHUB_TOKEN
npx wrangler deploy
```
Create/enroll `lucas-cloud` through the owner API/UI before deployment so its device row exists. The cron runs every minute; cloud action latency can be about 60 seconds.

## 4. Enroll the Mac and retire compatibility
As an owner, create device id `lucas-macbook`, kind `device`, copy the enrollment token from the one-time response, and give it to the local RavenNest enrollment command once Task 2 provides that command. Tokens expire after 15 minutes and are body fields, never URLs. Confirm state, claim and result using the new device credential; revoke the old device if rotating.

Compatibility defaults preserve the current iPhone pairing key: `LEGACY_OPERATOR_ENABLED=1`. It cannot request sensitive `codex.cloud.submit`; temporarily setting `LEGACY_OPERATOR_SENSITIVE=1` opts into that risk. After Access and enrolled-device physical verification, set `LEGACY_OPERATOR_ENABLED=0`, remove `OPERATOR_KEY_SHA256`, test that the old key receives 401, then remove `NODE_KEY_SHA256` after the Mac uses its device credential.

## 5. Rollback
Keep the previous Pages deployment available in Cloudflare deployment history. To restore behavior in minutes: roll Pages back to that deployment, keep the additive tables (they do not alter or drop the original tables), set `LEGACY_OPERATOR_ENABLED=1`, retain the two existing hash secrets, and disable—not delete—the Access application if its policy caused the incident. Stop or roll back the cloud Worker independently. Never delete D1 data as rollback.
