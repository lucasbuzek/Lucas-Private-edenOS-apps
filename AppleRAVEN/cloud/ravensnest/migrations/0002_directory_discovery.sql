-- AppleRAVEN owner-first portal discovery: identities are NOT authenticated users.
-- Directory candidates confer NO profile membership, provider connection, device grant,
-- Apple ID association, invitation, or access rights.
-- Claimed identities require a successful sign-in and verified user binding.
CREATE TABLE IF NOT EXISTS appleraven_directory_candidates (
 id TEXT PRIMARY KEY,
 normalized_email TEXT NOT NULL COLLATE NOCASE UNIQUE,
 display_label TEXT NOT NULL,
 identity_class TEXT NOT NULL CHECK(identity_class IN ('owner_identity','independent_person','organization_account')),
 source_kind TEXT NOT NULL CHECK(source_kind IN ('connected_account','verified_apple_correspondence','historical_reference')),
 verification_status TEXT NOT NULL DEFAULT 'discovered' CHECK(verification_status IN ('discovered','verified','rejected')),
 invited_at INTEGER,
 claimed_user_id TEXT REFERENCES users(id),
 created_at INTEGER NOT NULL DEFAULT (unixepoch())
);
CREATE INDEX IF NOT EXISTS appleraven_discovery_class ON appleraven_directory_candidates(identity_class,verification_status);

CREATE TABLE IF NOT EXISTS appleraven_space_templates (
 slug TEXT PRIMARY KEY,
 display_name TEXT NOT NULL,
 scope_kind TEXT NOT NULL CHECK(scope_kind IN ('personal','private','professional','family','shared','business','organization','research')),
 intended_owner TEXT NOT NULL,
 status TEXT NOT NULL DEFAULT 'planned' CHECK(status IN ('planned','active')),
 created_at INTEGER NOT NULL DEFAULT (unixepoch())
);
