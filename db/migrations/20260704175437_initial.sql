-- migrate:up

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE TYPE log_level AS ENUM ('info', 'warn', 'error', 'debug');
CREATE TYPE item_type_enum AS ENUM ('text', 'media', 'article');
CREATE TYPE federationlevel AS ENUM ('full', 'explorative', 'blocked');

-- Logs (may be used or may not be used; unsure for now.) ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
CREATE TABLE IF NOT EXISTS logs (
    id BIGSERIAL PRIMARY KEY,
    level log_level,
    namespace TEXT,
    message TEXT NOT NULL,
    variables JSONB,
    timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Instances ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
CREATE TABLE IF NOT EXISTS instances (
    -- id by which local instance identifies this instance.
    id uuid PRIMARY KEY,
    -- Domain name by which this instance is known.
    name TEXT NOT NULL,
    -- Secrets are created upon first true federation. An instance may be told about the existence by other instances,
    -- but only when federation occurs (either due to user interactions, or by [global] timeline federation) these are created.
    -- Upon a single infraction of trust (an unverifiable message), means this value is NULLed and exchange is set to
    -- false, leaving an automated reason.
    shared_secret BYTEA,
    -- Unset upon discovery, admin could set this to true (or federate-all or federate-none may be set to automate this
    -- behaviour). Set to true means timeline federation may occur with this instance, NULL means federation may
    -- only occur on user level (default). When set to false, the instance is never allowed to pull timelines, nor
    -- is ever pulled from (also not on user level)
    -- Note that for full federation to occur, both sides should have this set to true.
    exchange federationlevel,
    -- Reason for exchange to be set to false, either typed by an admin or by the instance if trust is broken.
    reason TEXT
);

COMMENT ON TABLE instances IS 'Stores local and federated instance details, tracking trust and timeline exchange states.';
COMMENT ON COLUMN instances.id IS 'Internal UUID used by the local instance to identify this specific instance.';
COMMENT ON COLUMN instances.name IS 'The unique domain name of the federated instance.';
COMMENT ON COLUMN instances.shared_secret IS 'The HMAC symmetric federation secret. Generated on first true federation; NULLed if trust breaks.';
COMMENT ON COLUMN instances.exchange IS 'Federation level is set to one of: full, explorative, or blocked. When NULL, acts like explorative but if the other instance decides to ask for full federation, may prompt an admin to upgrade to full. (if admin dismisses this, it becomes explorative.)';
COMMENT ON COLUMN instances.reason IS 'Administrative or automated explanation for why the exchange state was set to FALSE.';



-- Users ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
CREATE TABLE IF NOT EXISTS users (
    id BYTEA PRIMARY KEY,
    private_key BYTEA,
    instance_id uuid NOT NULL REFERENCES instances (id) ON DELETE CASCADE,
    email TEXT,
    displayname TEXT,
    username TEXT NOT NULL UNIQUE,
    password TEXT,
    CONSTRAINT unique_username_per_instance UNIQUE (username, instance_id)
);
COMMENT ON TABLE users IS 'Stores all users the instance knows about.';
COMMENT ON COLUMN users.id IS 'The public key of this user, combined with the instance_id this means we can lookup a user instantly, but even without, we can verify the users signed messages as it also is a ed25519 public key.';
COMMENT ON COLUMN users.private_key IS 'The ed25519 private key of a local user, used to sign important changes and, if requested, also posts and edits.';
COMMENT ON COLUMN users.instance_id IS 'The instance id of this user.';
COMMENT ON COLUMN users.email IS 'The email address of a local user, for administration purposes.';
COMMENT ON COLUMN users.displayname IS 'The displayed name for a user';
COMMENT ON COLUMN users.username IS 'The user-set and human-readable name for a user. For local users this contains only a username, for non-local users this is to be post-fixed with "@<instance-name>".';
COMMENT ON COLUMN users.password IS 'The password has of a local user, for authentication.';

-- Items ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
CREATE TABLE IF NOT EXISTS items (
    id uuid PRIMARY KEY,
    item_type item_type_enum,
    author_id BYTEA NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

COMMENT ON TABLE items IS 'All items and their types are linked over this table, items are polymorphic which makes this table able to provide proper forwards.';

CREATE TABLE IF NOT EXISTS post_text (
    id uuid PRIMARY KEY REFERENCES items (id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    foreign_post_id uuid
);

CREATE TABLE IF NOT EXISTS post_media (
    id uuid PRIMARY KEY REFERENCES items (id) ON DELETE CASCADE,
    upload_id TEXT NOT NULL,
    caption TEXT,
    foreign_post_id uuid
);

CREATE TABLE IF NOT EXISTS post_article (
    id uuid PRIMARY KEY REFERENCES items (id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    foreign_post_id uuid
);

-- Timelines ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
CREATE TABLE IF NOT EXISTS timelines (
    tlid uuid,
    item_id uuid NOT NULL REFERENCES items (id) ON DELETE CASCADE,
    timestamp TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (tlid, item_id)
);

-- User sessions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

CREATE TABLE IF NOT EXISTS usersessions (
    id uuid PRIMARY KEY,
    user_id BYTEA NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    session_key BYTEA NOT NULL,
    last_touched TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE usersessions IS 'User sessions are not to be confused with the Session Store ETS table, user sessions refer to logged in sessions. However, the "id" used here, refers to the SessionStore entry.';
COMMENT ON COLUMN usersessions.id IS 'Session id as found in the SessionStore ETS table and in browser cookies.';
COMMENT ON COLUMN usersessions.user_id IS 'The user logged in to this session.';
COMMENT ON COLUMN usersessions.session_key IS 'Secret hash that on match allows a session to be revived. Upon successful revival, the id is replaced with the id of the session that revived the user session.';
COMMENT ON COLUMN usersessions.last_touched IS 'Changed on INSERT or UPDATE to allow garbage cleanup of user sessions if they are older than 30 days.';

-- Indices for performance ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
CREATE INDEX IF NOT EXISTS idx_items_author ON items(author_id);
CREATE INDEX IF NOT EXISTS idx_timelines_ts ON timelines(timestamp);
CREATE INDEX IF NOT EXISTS idx_users_instance ON users(instance_id);

-- migrate:down

DROP INDEX IF EXISTS idx_users_foreign_instance;
DROP INDEX IF EXISTS idx_timelines_ts;
DROP INDEX IF EXISTS idx_items_author;
DROP TABLE IF EXISTS post_article;
DROP TABLE IF EXISTS post_media;
DROP TABLE IF EXISTS post_text;
DROP TABLE IF EXISTS usersessions;
DROP TABLE IF EXISTS timelines;
DROP TABLE IF EXISTS items;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS instances;
DROP TABLE IF EXISTS logs;

DROP TYPE IF EXISTS item_type_enum;
DROP TYPE IF EXISTS log_level;
DROP TYPE IF EXISTS federationlevel;
