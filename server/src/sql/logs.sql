
-- name: NewEvent :exec
INSERT INTO logs (level, namespace, message, variables) VALUES (?, ?, ?, ?);

