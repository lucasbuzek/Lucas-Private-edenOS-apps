-- Additive independent owner/member Google/Apple OIDC login; Cloudflare Access stays admin-only.
-- Run after verifying backing D1 instance, backup, and existing users/roles.
CREATE TABLE IF NOT EXISTS raven_oauth_attempts (
 state_hash TEXT PRIMARY KEY,
 provider TEXT NOT NULL CHECK(provider IN ('google','apple')),
 code_verifier TEXT NOT NULL,
 nonce TEXT NOT NULL,
 created_at INTEGER NOT NULL,
 expires_at INTEGER NOT NULL,
 consumed_at INTEGER
);
CREATE INDEX IF NOT EXISTS raven_oauth_attempts_expiry ON raven_oauth_attempts(expires_at);
CREATE TABLE IF NOT EXISTS raven_portal_identities (
 provider TEXT NOT NULL CHECK(provider IN ('google','apple')),
 provider_subject TEXT NOT NULL,
 user_id TEXT NOT NULL REFERENCES users(id),
 linked_at INTEGER NOT NULL,
 PRIMARY KEY(provider,provider_subject)
);
CREATE INDEX IF NOT EXISTS raven_portal_identities_user ON raven_portal_identities(user_id);
CREATE TABLE IF NOT EXISTS raven_portal_sessions (
 token_hash TEXT PRIMARY KEY,
 user_id TEXT NOT NULL REFERENCES users(id),
 created_at INTEGER NOT NULL,
 expires_at INTEGER NOT NULL,
 revoked_at INTEGER
);
CREATE INDEX IF NOT EXISTS raven_portal_sessions_user ON raven_portal_sessions(user_id,revoked_at,expires_at);
