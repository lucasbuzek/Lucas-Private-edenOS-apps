CREATE TABLE IF NOT EXISTS eden_users (
  id TEXT PRIMARY KEY,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS eden_identities (
  user_id TEXT NOT NULL,
  provider TEXT NOT NULL,
  provider_subject TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(provider, provider_subject),
  FOREIGN KEY(user_id) REFERENCES eden_users(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_eden_identity_user ON eden_identities(user_id);
