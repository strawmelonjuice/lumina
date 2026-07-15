-- Creates an authenticated session from a session id, and a user id.



WITH inserted AS (
	INSERT
		INTO usersessions (id, user_id, session_key)
		VALUES ($1, $2, $3)
		RETURNING 1
)
SELECT username,email
	FROM users
	WHERE instance_id = '00000000-0000-0000-0000-000000000000'
	AND id = $2
	AND EXISTS (SELECT 1 FROM inserted)
	LIMIT 1;
