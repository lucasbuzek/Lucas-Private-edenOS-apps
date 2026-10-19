-- Private software request queue, not CRESUS/HERMES production D1.
-- Execute on an explicitly provisioned, independent sharing D1 binding ONLY.
CREATE TABLE IF NOT EXISTS pwa_waitlist (
  app_id TEXT NOT NULL,
  email TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','approved','denied')),
  requested_at TEXT NOT NULL DEFAULT (datetime('now')),
  reviewed_at TEXT,
  reviewed_by TEXT,
  PRIMARY KEY(app_id,email)
);
CREATE INDEX IF NOT EXISTS sharing_requests_by_status
  ON pwa_waitlist(app_id,status,requested_at DESC);
CREATE TABLE IF NOT EXISTS share_rate_limits (
  key_hash TEXT NOT NULL,
  bucket INTEGER NOT NULL,
  request_count INTEGER NOT NULL DEFAULT 1 CHECK(request_count > 0),
  PRIMARY KEY(key_hash,bucket)
);
