-- If invite code is valid, use it, assigning it to a new user id and invalidating it.
--
-- This query has a lot of parameters! So here's a short list:
-- 1. The new user's generated ID (public key)
-- 2. The used invite code
-- 3. The new user's email
-- 4. The new user's displayname
-- 5. The new user's username
-- 6. The new user's password
-- 7. The new user's generated private key
-- 8. The session ID to log in to this new account
-- 9. Newly assigned usersession id.

WITH data(user_id, invite_code, email, displayname, username, password, private_key, session_id, usersession_id) AS (
	VALUES
	($1::bytea, $2, $3, $4, $5, $6, $7::bytea, $8::uuid, $9::bytea)
), check_invite AS (
	SELECT invite_code
		FROM invites
		WHERE valid = TRUE
		AND invite_code = (SELECT invite_code FROM data)
),      user_insert AS (
         INSERT
             INTO users (id, private_key, instance_id, email, displayname, username, password)

                 VALUES (
					(SELECT user_id FROM data), -- id (pubkey)
                         (SELECT private_key FROM data), -- private key
                         uuid_nil(), -- instance id
                    	(SELECT email FROM data), -- email
                         (SELECT displayname FROM data), -- displayname
                         (SELECT username FROM data), -- username
                    	(SELECT password FROM data) -- password
                        )
                 RETURNING id, username, email),
invite_consume AS (
    UPDATE invites
        SET valid = FALSE,
            used_by = (SELECT user_id FROM data)
        WHERE invite_code = (SELECT invite_code FROM check_invite)
	),

     session_insert AS (
         INSERT
             INTO usersessions (id, user_id, session_key)
                 VALUES ((SELECT session_id FROM data), -- Session ID
                         (SELECT user_id FROM data), -- User ID
                         (SELECT usersession_id FROM data) -- Usersession key
                        )
                 RETURNING 1)

SELECT username, email
	FROM user_insert
	WHERE EXISTS (SELECT 1 FROM session_insert)
LIMIT 1;
