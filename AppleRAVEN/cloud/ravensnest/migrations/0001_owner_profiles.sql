-- AppleRAVEN: additive owner-first identity model for separate Cloudflare account.
-- Existing Raven users/devices/enrollments/grants/actions/audit tables are preserved.
-- Cloudflare infrastructure administration is NOT proof of end-user identity.
-- NO owner, profile, token, provider or device is provisioned by this migration.
-- Backend must enforce BOTH verified OAuth actor and profile-scoped grants.
CREATE TABLE IF NOT EXISTS appleraven_profiles (
 id TEXT PRIMARY KEY,
 slug TEXT NOT NULL UNIQUE,
 display_name TEXT NOT NULL,
 kind TEXT NOT NULL CHECK (kind IN ('personal','professional','private','family','organization','custom')),
 instance_id TEXT NOT NULL UNIQUE,
 created_by_user_id TEXT NOT NULL REFERENCES users(id),
 created_at INTEGER NOT NULL,
 disabled_at INTEGER
);
CREATE TABLE IF NOT EXISTS appleraven_profile_memberships (
 profile_id TEXT NOT NULL REFERENCES appleraven_profiles(id),
 user_id TEXT NOT NULL REFERENCES users(id),
 role TEXT NOT NULL CHECK (role IN ('owner','admin','member','viewer')),
 granted_by_user_id TEXT NOT NULL REFERENCES users(id),
 created_at INTEGER NOT NULL,
 revoked_at INTEGER,
 PRIMARY KEY(profile_id,user_id)
);
CREATE INDEX IF NOT EXISTS appleraven_memberships_actor ON appleraven_profile_memberships(user_id,revoked_at);
CREATE TABLE IF NOT EXISTS appleraven_profile_devices (
 profile_id TEXT NOT NULL REFERENCES appleraven_profiles(id),
 device_id TEXT NOT NULL REFERENCES devices(id),
 enrolled_by_user_id TEXT NOT NULL REFERENCES users(id),
 created_at INTEGER NOT NULL,
 revoked_at INTEGER,
 PRIMARY KEY(profile_id,device_id)
);
CREATE TABLE IF NOT EXISTS appleraven_profile_grants (
 id TEXT PRIMARY KEY,
 profile_id TEXT NOT NULL,
 device_id TEXT NOT NULL,
 user_id TEXT NOT NULL REFERENCES users(id),
 capability TEXT NOT NULL,
 granted_by_user_id TEXT NOT NULL REFERENCES users(id),
 created_at INTEGER NOT NULL,
 revoked_at INTEGER,
 FOREIGN KEY(profile_id,device_id) REFERENCES appleraven_profile_devices(profile_id,device_id)
);
CREATE UNIQUE INDEX IF NOT EXISTS appleraven_active_grants ON appleraven_profile_grants(profile_id,device_id,user_id,capability) WHERE revoked_at IS NULL;
CREATE INDEX IF NOT EXISTS appleraven_grants_user ON appleraven_profile_grants(user_id,profile_id,revoked_at);
CREATE TABLE IF NOT EXISTS appleraven_provider_connections (
 id TEXT PRIMARY KEY,
 profile_id TEXT NOT NULL REFERENCES appleraven_profiles(id),
 linked_by_user_id TEXT NOT NULL REFERENCES users(id),
 provider_id TEXT NOT NULL,
 provider_account_hint TEXT,
 status TEXT NOT NULL CHECK(status IN ('pending','connected','disconnected','revoked')),
 -- NEVER store provider access/refresh tokens in this table.
 -- credential_ref is a non-secret reference to a separately encrypted, identity-bound vault.
 credential_ref TEXT,
 scopes_json TEXT NOT NULL DEFAULT '[]' CHECK(json_valid(scopes_json)),
 created_at INTEGER NOT NULL,
 verified_at INTEGER,
 revoked_at INTEGER
);
CREATE INDEX IF NOT EXISTS appleraven_connections_profile ON appleraven_provider_connections(profile_id,status);
CREATE TABLE IF NOT EXISTS appleraven_mcp_client_grants (
 id TEXT PRIMARY KEY,
 profile_id TEXT NOT NULL REFERENCES appleraven_profiles(id),
 client_id TEXT NOT NULL,
 approved_by_user_id TEXT NOT NULL REFERENCES users(id),
 scopes_json TEXT NOT NULL DEFAULT '[]' CHECK(json_valid(scopes_json)),
 created_at INTEGER NOT NULL,
 expires_at INTEGER,
 revoked_at INTEGER
);
CREATE INDEX IF NOT EXISTS appleraven_clients_profile ON appleraven_mcp_client_grants(profile_id,client_id,revoked_at);
