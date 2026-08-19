-- Gets a local user's data from the database for their id (publickey).

SELECT username, email, displayname
	FROM users
	WHERE id = $1
	LIMIT 1;
