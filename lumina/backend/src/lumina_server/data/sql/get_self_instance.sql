-- Returns the instances' own entry in the instances table. This is usually a check: It's there to make sure the entry
-- exists, before we can create users based on it.
--
-- Once this returns an instance name, none will be written to the database again, even after it changing in the
-- configuration.
SELECT name
	FROM instances
	WHERE id = '00000000-0000-0000-0000-000000000000'
	LIMIT 1;
