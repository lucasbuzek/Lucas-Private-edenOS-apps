-- Scoped CRESUS watchlist. Identity is an explicit ticker + MIC if known;
-- unknown MIC remains blank rather than resolving the wrong exchange.
CREATE TABLE IF NOT EXISTS watchlist_entries (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  ticker TEXT NOT NULL,
  mic TEXT NOT NULL DEFAULT '',
  currency TEXT NOT NULL DEFAULT '',
  isin TEXT NOT NULL DEFAULT '',
  name TEXT NOT NULL DEFAULT '',
  notes TEXT NOT NULL DEFAULT '',
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE(email,ticker,mic)
);
CREATE INDEX IF NOT EXISTS idx_watchlist_email_updated ON watchlist_entries(email,updated_at DESC);
