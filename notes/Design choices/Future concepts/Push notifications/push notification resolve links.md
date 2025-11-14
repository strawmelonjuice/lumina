I notice on other social media platforms that when an edit or upload has unforseen consequences, this usually results in
broken push notifications.
Notifications that lead to a 404.

When creating a push notification for something we know nothing about, this is what it is. But in Lumina these
notifications lead to a postview using a JSON string after the # in the url (url hash).

That JSON string can just contain a post or notification id, but we generate a preview of a post, and that
preview should be pushed but not saved once again in the database. Instead, we add to the JSON object. Client holds an
absolute reference to the post id, but also requests a post by both id and a part of its preview. Lumina client should
be smart enough to figure out what post this is even when the ID leads to a 404.
