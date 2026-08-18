-- Writes a new user account, does not check for invites, does not create a session.
--
-- This query has a lot of parameters! So here's a short list:
-- 1. The new user's generated ID (public key)
-- 2. The new user's email
-- 3. The new user's displayname
-- 4. The new user's username
-- 5. The new user's password
-- 6. The new user's generated private key

INSERT
	INTO users
		(id, private_key, instance_id, email, displayname, username, password)
	VALUES
		($1, $6, uuid_nil(), $2, $3, $4, $5)
	ON CONFLICT DO NOTHING;
