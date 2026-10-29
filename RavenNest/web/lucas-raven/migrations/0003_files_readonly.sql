-- Additive RAVENsNEST Online Storage Manager schema, no existing table changes.
-- Provider access tokens and OAuth secrets live in Cloudflare secrets, not D1.
CREATE TABLE IF NOT EXISTS raven_file_sources (
  id TEXT PRIMARY KEY CHECK(length(id) BETWEEN 2 AND 49),
  label TEXT NOT NULL,
  provider TEXT NOT NULL CHECK(provider IN ('dropbox','google_drive')),
  tenant_id TEXT NOT NULL,
  owner_user_id TEXT NOT NULL REFERENCES users(id),
  root_ref TEXT NOT NULL,
  credential_ref TEXT NOT NULL,
  enabled INTEGER NOT NULL DEFAULT 0 CHECK(enabled IN (0,1)),
  created_at INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS raven_file_grants (
  user_id TEXT NOT NULL REFERENCES users(id),
  source_id TEXT NOT NULL REFERENCES raven_file_sources(id),
  can_list INTEGER NOT NULL DEFAULT 0 CHECK(can_list IN (0,1)),
  can_download INTEGER NOT NULL DEFAULT 0 CHECK(can_download IN (0,1)),
  revoked_at INTEGER,
  PRIMARY KEY(user_id,source_id)
);
CREATE INDEX IF NOT EXISTS raven_file_grants_active ON raven_file_grants(user_id,revoked_at,source_id);
