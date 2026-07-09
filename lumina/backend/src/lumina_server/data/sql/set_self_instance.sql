-- Sets the instance name and creates the id for the local instance, this is required for a lot of things and shouldn't
-- change afterwards! After this, a first (admin) user should be created!
INSERT
	INTO instances (id, name)
	VALUES (uuid_nil(), $1);
