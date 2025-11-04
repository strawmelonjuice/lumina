/*
 This file is also auto-included by server/src/database.rs, which uses it to create the database on first launch.
 */

-- Create logs table
CREATE TABLE IF NOT EXISTS logs
(
	type      VARCHAR   NOT NULL,
	message   TEXT      NOT NULL,
	timestamp TIMESTAMP NOT NULL
);

--  Create users table
CREATE TABLE IF NOT EXISTS users
(
	id                  UUID DEFAULT gen_random_uuid() UNIQUE PRIMARY KEY,
	foreign_instance_id VARCHAR,
	foreign_user_id     UUID,
	email               VARCHAR NOT NULL UNIQUE,
	username            VARCHAR NOT NULL UNIQUE,
	password            VARCHAR NOT NULL
);

-- Create timelines table
CREATE TABLE IF NOT EXISTS timelines
(
	tlid      UUID                     NOT NULL,
	item_id   UUID                     NOT NULL,
	timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
	PRIMARY KEY (tlid, item_id)
);

-- Create item type lookup table
CREATE TABLE IF NOT EXISTS itemtypelookupdb
(
	itemtype VARCHAR NOT NULL,
	item_id  UUID    NOT NULL PRIMARY KEY
);

-- Create sesions table
CREATE TABLE IF NOT EXISTS sessions
(
	id          UUID                              DEFAULT gen_random_uuid() PRIMARY KEY,
	user_id     UUID                     NOT NULL REFERENCES users (id) ON DELETE CASCADE,
	session_key VARCHAR                  NOT NULL UNIQUE,
	created_at  TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Create table for posts in text type
CREATE TABLE IF NOT EXISTS post_text
(
	id                  UUID PRIMARY KEY                  DEFAULT gen_random_uuid(),
	author_id           UUID REFERENCES users (id),
	content             TEXT                     NOT NULL,
	created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
	foreign_instance_id VARCHAR,
	foreign_post_id     VARCHAR
);

-- Create table for posts of media type
CREATE TABLE IF NOT EXISTS post_media
(
	id                  UUID PRIMARY KEY                  DEFAULT gen_random_uuid(),
	author_id           UUID REFERENCES users (id),
	minio_object_id     VARCHAR                  NOT NULL,
	caption             TEXT,
	created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
	foreign_instance_id VARCHAR,
	foreign_post_id     VARCHAR
);

-- Create table for posts of article type
CREATE TABLE IF NOT EXISTS post_article
(
	id                  UUID PRIMARY KEY                  DEFAULT gen_random_uuid(),
	author_id           UUID REFERENCES users (id),
	title               VARCHAR                  NOT NULL,
	content             TEXT                     NOT NULL,
	created_at          TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
	foreign_instance_id VARCHAR,
	foreign_post_id     VARCHAR
);
