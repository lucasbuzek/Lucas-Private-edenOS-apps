-- Manual ZACCHAEUS event log, evidence states never merged, amounts exact decimal text.
-- known_at and observed_at are WHEN CRESUS received the manual entry, not the economic date.
CREATE TABLE IF NOT EXISTS income_events (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  account_label TEXT NOT NULL DEFAULT 'Manual',
  ticker TEXT NOT NULL,
  mic TEXT NOT NULL DEFAULT '',
  currency TEXT NOT NULL,
  amount TEXT NOT NULL,
  status TEXT NOT NULL,
  effective_at TEXT NOT NULL,
  pay_date TEXT NOT NULL DEFAULT '',
  source_published_at TEXT NOT NULL DEFAULT '',
  description TEXT NOT NULL DEFAULT '',
  source_ref TEXT NOT NULL DEFAULT '',
  notes TEXT NOT NULL DEFAULT '',
  known_at TEXT NOT NULL,
  observed_at TEXT NOT NULL,
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  revision INTEGER NOT NULL DEFAULT 1
);
CREATE INDEX IF NOT EXISTS idx_income_email_effective ON income_events(email,effective_at DESC);
