-- Lucas Raven edge state. Holds representation/queue state only;
-- BIFROST node and specialist Apps remain the authoritative owners.
CREATE TABLE IF NOT EXISTS node_state (
  node_id    TEXT PRIMARY KEY,
  meta       TEXT NOT NULL,
  state      TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS actions (
  id           TEXT PRIMARY KEY,
  node_id      TEXT NOT NULL,
  capability   TEXT NOT NULL,
  params       TEXT NOT NULL,
  status       TEXT NOT NULL,          -- queued | claimed | succeeded | failed | expired
  origin       TEXT,                   -- provenance: requesting client summary
  created_at   INTEGER NOT NULL,
  claimed_at   INTEGER,
  completed_at INTEGER,
  result       TEXT
);

CREATE INDEX IF NOT EXISTS actions_queue ON actions (node_id, status, created_at);

-- Keep this fresh-install schema in parity with additive migration 0002.
CREATE TABLE IF NOT EXISTS users (id TEXT PRIMARY KEY, subject TEXT UNIQUE NOT NULL, email TEXT UNIQUE NOT NULL, display_name TEXT, role TEXT NOT NULL CHECK(role IN ('owner','member','viewer')), created_at INTEGER NOT NULL, disabled_at INTEGER);
CREATE TABLE IF NOT EXISTS devices (id TEXT PRIMARY KEY, name TEXT NOT NULL, kind TEXT NOT NULL CHECK(kind IN ('device','cloud')), credential_sha256 TEXT UNIQUE, created_by TEXT NOT NULL, created_at INTEGER NOT NULL, revoked_at INTEGER);
CREATE TABLE IF NOT EXISTS device_enrollments (id TEXT PRIMARY KEY, device_id TEXT NOT NULL, token_sha256 TEXT UNIQUE NOT NULL, expires_at INTEGER NOT NULL, used_at INTEGER, created_by TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS grants (id TEXT PRIMARY KEY, user_id TEXT NOT NULL, device_id TEXT NOT NULL, capability TEXT NOT NULL, created_at INTEGER NOT NULL, created_by TEXT NOT NULL, revoked_at INTEGER);
CREATE UNIQUE INDEX IF NOT EXISTS grants_active_unique ON grants(user_id, device_id, capability) WHERE revoked_at IS NULL;
CREATE INDEX IF NOT EXISTS devices_credential ON devices(credential_sha256) WHERE revoked_at IS NULL;
CREATE INDEX IF NOT EXISTS enrollments_token ON device_enrollments(token_sha256);
CREATE INDEX IF NOT EXISTS grants_user ON grants(user_id, revoked_at);
CREATE TABLE IF NOT EXISTS audit (id INTEGER PRIMARY KEY AUTOINCREMENT, ts INTEGER NOT NULL, subject TEXT, node_id TEXT, capability TEXT, action_id TEXT, event TEXT NOT NULL, detail TEXT);
CREATE INDEX IF NOT EXISTS audit_ts ON audit(ts DESC);

-- Keep this fresh-install schema in parity with additive migration 0003.
CREATE TABLE IF NOT EXISTS chat_daily (day INTEGER PRIMARY KEY, count INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS chat_user_minute (subject TEXT NOT NULL, minute INTEGER NOT NULL, count INTEGER NOT NULL, PRIMARY KEY(subject, minute));
CREATE TABLE IF NOT EXISTS chat_audit (id INTEGER PRIMARY KEY AUTOINCREMENT, ts INTEGER NOT NULL, subject TEXT NOT NULL, intent TEXT, topic TEXT, capability TEXT, outcome TEXT NOT NULL, provider TEXT NOT NULL, latency_ms INTEGER NOT NULL, handoff_excerpt TEXT);
CREATE INDEX IF NOT EXISTS chat_audit_ts ON chat_audit(ts DESC);
