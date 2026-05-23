-- migrate:up

CREATE TABLE IF NOT EXISTS logs (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	level TEXT CHECK(level IN ('INFO', 'WARN', 'ERROR', 'DEBUG')),
	namespace TEXT,
	message TEXT NOT NULL,
	variables TEXT,
	timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Users: Storing UUIDs as TEXT, but we'll remove the dashes to make it minecraft-like UUIDS, this saves a little space :3
CREATE TABLE IF NOT EXISTS users (
    id                  TEXT PRIMARY KEY NOT NULL CHECK(length(id) = 32),
    foreign_instance_id TEXT,
    foreign_user_id     TEXT,
    email               TEXT NOT NULL UNIQUE,
    username            TEXT NOT NULL UNIQUE,
    password            TEXT NOT NULL
);

-- Items: On the Postgres equevalent, this was a split task between the ultimate source
-- of all posts (timelines) and the types table. In this variant I had an opportunity to create some order.
-- The timelines table is still the table we look up most posts in... BUT: the items table now carries the items themselves.
CREATE TABLE IF NOT EXISTS items (
    id          TEXT PRIMARY KEY NOT NULL CHECK(length(id) = 32),
    item_type   TEXT CHECK(item_type IN ('text', 'media', 'article')), -- DM's and such will be added later, I don't have reference types for those yet.
    author_id   TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Timelines:
CREATE TABLE IF NOT EXISTS timelines (
    tlid      TEXT NOT NULL CHECK(length(tlid) = 32),
    item_id   TEXT NOT NULL REFERENCES items (id) ON DELETE CASCADE,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (tlid, item_id)
);

-- Sessions:
CREATE TABLE IF NOT EXISTS sessions (
    id          TEXT PRIMARY KEY NOT NULL CHECK(length(id) = 32),
    user_id     TEXT NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    session_key TEXT NOT NULL UNIQUE,
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Item Content
CREATE TABLE IF NOT EXISTS post_text (
    id                  TEXT PRIMARY KEY REFERENCES items (id) ON DELETE CASCADE,
    content             TEXT NOT NULL,
    foreign_instance_id TEXT,
    foreign_post_id     TEXT
);

CREATE TABLE IF NOT EXISTS post_media (
    id                  TEXT PRIMARY KEY REFERENCES items (id) ON DELETE CASCADE,
    upload_id           TEXT NOT NULL,
    caption             TEXT,
    foreign_instance_id TEXT,
    foreign_post_id     TEXT
);

CREATE TABLE IF NOT EXISTS post_article (
    id                  TEXT PRIMARY KEY REFERENCES items (id) ON DELETE CASCADE,
    title               TEXT NOT NULL,
    content             TEXT NOT NULL,
    foreign_instance_id TEXT,
    foreign_post_id     TEXT
);

-- Indices for performance
CREATE INDEX IF NOT EXISTS idx_items_author ON items(author_id);
CREATE INDEX IF NOT EXISTS idx_timelines_ts ON timelines(timestamp);

-- migrate:down

DROP INDEX IF EXISTS idx_timelines_ts;
DROP INDEX IF EXISTS idx_items_author;
DROP TABLE IF EXISTS post_article;
DROP TABLE IF EXISTS post_media;
DROP TABLE IF EXISTS post_text;
DROP TABLE IF EXISTS sessions;
DROP TABLE IF EXISTS timelines;
DROP TABLE IF EXISTS items;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS logs;
