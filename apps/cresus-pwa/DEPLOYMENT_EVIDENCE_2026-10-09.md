# CRESUS PR #5 — live Cloudflare verification and safe rollout

Evidence date: 2026-10-09. Source candidate: `8ea97005` at start of inspection. No live changes made.

## Verified against connected Mac and Cloudflare account
- Existing authorized Mac workspace: `/Users/lucas/edenOS/Projects/EDEN Apps/CRESUS-PWA`.
- Local Wrangler v4.147.0 successfully authenticated to the intended Cloudflare account.
- Local `wrangler.toml` has non-placeholder Cloudflare Access domain, AUD, D1 database ID, and Workers AI binding; **do not copy local identity values into public repo defaults**.
- `wrangler deployments list --name cresus-agent` returned deployments; latest listed deployment was 2026-10-07 12:10:14 UTC, version `56998568-65a3-4b76-bdfd-6de626eb6bed`. This is a recorded baseline, not proof of successful authenticated browser behavior.
- Remote D1 read-only query succeeded; existing `users`, `conversations`, `messages` tables found. `intelligence_preferences` table **absent**. Database not mutated.
- CI for PR #5 source commit `8ea97005` passed. Real Access browser and real provider responses remain unverified.

## Deployment safety requirements
1. Preserve the existing live Worker and local project. Do not overwrite the Mac's source folder with the GitHub branch.
2. Build candidate in an isolated worktree/directory; reconcile local real `wrangler.toml` values **without committing them**, including exact D1 and Access bindings. Check `wrangler deploy --dry-run` and asset bundle before touching production.
3. Snapshot D1 to a protected location using Wrangler's supported `d1 export` facility, then validate the backup file and record its checksum. Export may include private chats and user data; keep private and encrypted. Do not commit it.
4. Confirm the expected live Worker deployment ID and D1 database binding again. Record recovery instructions for the prior Worker version and the D1 backup.
5. Apply only `migrations/0003_intelligence_preferences.sql` to the existing D1 database, then read-only verify the new table and preexisting data counts. Migration is additive and repeat-safe; rollback of this schema should generally retain the new table to avoid data loss.
6. Deploy the isolated PR #5 candidate only after dry-run and backup gates pass. No auto-merge, no LKG promotion.
7. Test authenticated owner and member sessions: first-login choice, skip, Settings persistence, selected provider execution, retry/idempotency, existing chat retrieval/export, seat permissions, quota and sign-out. Check mobile PWA and offline presentation.
8. If any live gate fails, revert Worker traffic to recorded prior version and retain D1 evidence. Do not blindly restore the entire database (would discard newer chats).

## Outstanding
- OAuth/ChatGPT-plan Codex Cloud task dispatch not verified; Codex option remains fail-closed.
- No live Worker deployment, D1 migration, or physical browser verification performed during this inspection.
- Current remote D1 was read only; Access token was not disclosed or copied.
