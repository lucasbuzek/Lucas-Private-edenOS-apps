-- RavenNest source-first online library; additive to existing RavenNest Pages DB.
-- Physical iCloud folders, the 11 historical domains, and the AI Toolkit's 72 groups
-- remain separate authorities. A category string is a label, never a new canon root.
-- Existing users(id) must be present. No content or OAuth secrets in these rows.
CREATE TABLE IF NOT EXISTS raven_library_sources (
  id TEXT PRIMARY KEY,
  owner_user_id TEXT NOT NULL REFERENCES users(id),
  tenant_key TEXT NOT NULL,
  source_url TEXT NOT NULL,
  source_title TEXT NOT NULL,
  source_description TEXT NOT NULL DEFAULT '',
  source_site TEXT NOT NULL DEFAULT '',
  taxonomy_namespace TEXT NOT NULL DEFAULT 'unclassified',
  taxonomy_key TEXT NOT NULL DEFAULT '',
  source_kind TEXT NOT NULL DEFAULT 'website' CHECK(source_kind IN ('website','repository','documentation','dataset','zim','file-reference','other')),
  source_language TEXT NOT NULL DEFAULT '',
  provenance TEXT NOT NULL DEFAULT 'user-supplied',
  content_hash TEXT,
  original_archive_ref TEXT,
  review_status TEXT NOT NULL DEFAULT 'link-only' CHECK(review_status IN ('link-only','review-needed','verified','blocked')),
  visibility TEXT NOT NULL DEFAULT 'private' CHECK(visibility IN ('private','granted')),
  added_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS raven_library_grants (
  source_id TEXT NOT NULL REFERENCES raven_library_sources(id),
  user_id TEXT NOT NULL REFERENCES users(id),
  can_read INTEGER NOT NULL DEFAULT 0 CHECK(can_read IN (0,1)),
  revoked_at INTEGER,
  PRIMARY KEY(source_id,user_id)
);
CREATE INDEX IF NOT EXISTS raven_library_user_recent ON raven_library_sources(owner_user_id,added_at DESC);
CREATE INDEX IF NOT EXISTS raven_library_classification ON raven_library_sources(taxonomy_namespace,taxonomy_key);
CREATE INDEX IF NOT EXISTS raven_library_active_grants ON raven_library_grants(user_id,revoked_at,source_id);
