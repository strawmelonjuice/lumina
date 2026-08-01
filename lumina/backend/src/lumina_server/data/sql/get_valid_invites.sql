-- Gets the list of instance invite codes for which `valid` is `True`.

SELECT invite_code
	FROM invites
	WHERE valid = TRUE;
