-- Returns the count of users on this local instance.

SELECT
	COUNT(DISTINCT id)
	FROM users
	WHERE instance_id = '00000000-0000-0000-0000-000000000000';
