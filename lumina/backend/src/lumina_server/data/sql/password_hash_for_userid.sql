-- Gets a local user's password hash from the database for their id (publickey).

SELECT password
	FROM users
	WHERE instance_id = '00000000-0000-0000-0000-000000000000'
	AND id = $1
	LIMIT 1;
