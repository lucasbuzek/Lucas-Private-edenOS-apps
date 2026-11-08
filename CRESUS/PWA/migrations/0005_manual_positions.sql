-- User-scoped manual position snapshots; no brokerage transactions or quotes are inferred.
-- All quantity and cost values stay decimal strings, never floating-point SQL REAL.
CREATE TABLE IF NOT EXISTS portfolio_positions (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  account_label TEXT NOT NULL DEFAULT 'Manual',
  ticker TEXT NOT NULL,
  mic TEXT NOT NULL DEFAULT '',
  currency TEXT NOT NULL DEFAULT '',
  name TEXT NOT NULL DEFAULT '',
  quantity TEXT NOT NULL,
  unit_cost TEXT NOT NULL DEFAULT '',
  notes TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(email,account_label,ticker,mic)
);
CREATE INDEX IF NOT EXISTS idx_portfolio_email_account ON portfolio_positions(email,account_label,ticker);
