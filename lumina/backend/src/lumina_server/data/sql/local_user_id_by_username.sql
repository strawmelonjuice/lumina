-- Gets a local user's id (publickey) from the database based on the username they use.

SELECT id
	FROM users
	WHERE instance_id = '00000000-0000-0000-0000-000000000000'
	AND username = $1
	LIMIT 1;
