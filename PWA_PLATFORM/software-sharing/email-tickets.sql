-- Separate, private D1 database for owner-controlled software sharing.
-- Does not modify HERMES, CRESUS or ELYSIUM application databases.
CREATE TABLE IF NOT EXISTS software_email_tickets (
  token_hash TEXT PRIMARY KEY,
  app_id TEXT NOT NULL,
  release_id TEXT NOT NULL,
  email TEXT NOT NULL,
  issued_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  consumed_at INTEGER,
  revoked_at INTEGER,
  CHECK (expires_at > issued_at)
);
CREATE INDEX IF NOT EXISTS software_email_tickets_subject
  ON software_email_tickets (app_id, email, issued_at DESC);

-- Release binaries stay pinned to reviewed manifests; the owner may enable or
-- disable an accepted release, but may not alter repository/asset/checksum via UI.
CREATE TABLE IF NOT EXISTS software_release_controls (
  app_id TEXT NOT NULL,
  release_id TEXT NOT NULL,
  enabled INTEGER NOT NULL DEFAULT 0 CHECK (enabled IN (0,1)),
  changed_by TEXT NOT NULL,
  changed_at INTEGER NOT NULL,
  PRIMARY KEY (app_id,release_id)
);
