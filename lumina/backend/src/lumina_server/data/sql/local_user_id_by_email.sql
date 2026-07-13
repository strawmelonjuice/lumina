-- Gets a local user's id (publickey) from the database based on the email they use.

SELECT id
	FROM users
	WHERE instance_id = '00000000-0000-0000-0000-000000000000'
	AND email = $1
	LIMIT 1;
