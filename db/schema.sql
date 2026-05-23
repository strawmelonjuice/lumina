CREATE TABLE IF NOT EXISTS "schema_migrations" (version varchar(128) primary key);
CREATE TABLE logs (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	level TEXT CHECK(level IN ('INFO', 'WARN', 'ERROR', 'DEBUG')),
	namespace TEXT,
	message TEXT NOT NULL,
	variables TEXT,
	timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE users (
    id                  TEXT PRIMARY KEY NOT NULL CHECK(length(id) = 32),
    foreign_instance_id TEXT,
    foreign_user_id     TEXT,
    email               TEXT NOT NULL UNIQUE,
    username            TEXT NOT NULL UNIQUE,
    password            TEXT NOT NULL
);
CREATE TABLE items (
    id          TEXT PRIMARY KEY NOT NULL CHECK(length(id) = 32),
    item_type   TEXT CHECK(item_type IN ('text', 'media', 'article')), -- DM's and such will be added later, I don't have reference types for those yet.
    author_id   TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE timelines (
    tlid      TEXT NOT NULL CHECK(length(tlid) = 32),
    item_id   TEXT NOT NULL REFERENCES items (id) ON DELETE CASCADE,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (tlid, item_id)
);
CREATE TABLE sessions (
    id          TEXT PRIMARY KEY NOT NULL CHECK(length(id) = 32),
    user_id     TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    session_key TEXT NOT NULL UNIQUE,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE post_text (
    id                  TEXT PRIMARY KEY REFERENCES items (id) ON DELETE CASCADE,
    content             TEXT NOT NULL,
    foreign_instance_id TEXT,
    foreign_post_id     TEXT
);
CREATE TABLE post_media (
    id                  TEXT PRIMARY KEY REFERENCES items (id) ON DELETE CASCADE,
    upload_id           TEXT NOT NULL,
    caption             TEXT,
    foreign_instance_id TEXT,
    foreign_post_id     TEXT
);
CREATE TABLE post_article (
    id                  TEXT PRIMARY KEY REFERENCES items (id) ON DELETE CASCADE,
    title               TEXT NOT NULL,
    content             TEXT NOT NULL,
    foreign_instance_id TEXT,
    foreign_post_id     TEXT
);
CREATE INDEX idx_items_author ON items(author_id);
CREATE INDEX idx_timelines_ts ON timelines(timestamp);
-- Dbmate schema migrations
INSERT INTO "schema_migrations" (version) VALUES
  ('20260403165425');
