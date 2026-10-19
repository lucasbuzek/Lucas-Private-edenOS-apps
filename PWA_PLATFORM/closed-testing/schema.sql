-- Run on a dedicated D1 database for EACH independently deployed app.
-- No migration or writes to HERMES/CRESUS existing databases.
CREATE TABLE IF NOT EXISTS pwa_waitlist (
  app_id TEXT NOT NULL,
  email TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','denied')),
  requested_at TEXT NOT NULL DEFAULT (datetime('now')),
  reviewed_at TEXT,
  reviewed_by TEXT,
  PRIMARY KEY (app_id, email)
);
CREATE INDEX IF NOT EXISTS idx_pwa_waitlist_status
  ON pwa_waitlist(app_id, status, requested_at DESC);
