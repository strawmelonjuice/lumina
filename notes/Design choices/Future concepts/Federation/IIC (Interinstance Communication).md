The server should a poll-inspired syncing system for Federating posts with other servers (instances). This is a [[High-level requirements#^4c6bf0|must]].

Having established this, a _how_ remains. In an earlier iteration of Lumina/Ephew (`Lumina:Peonies:itr1`), this how was conceptually answered by introducing HTTP requests fetching other instances' post IDs and then letting the client fetch the actual post content. This is a sound strategy in theory, however, you would possibly fetch posts from an instance impersonating the instance you talked to previously. 
To keep this from happening, a choice was made to only accept domain names as instance ID's, this choice is still present in the current iteration, however, DNS is not infallible. 

To solve that, some form of key checking has to be done. Either by sharing a secret token and having an instance store it, or... more sane, by `ed25519`?

Furthermore, these relatively big HTTP requests would be rate-limited on the requesting side, on the serving side, request spammers would be autoremoved from the allowlist. 

That initially created the concept of WebSocket connections, preferably ones that stay open forever (which is a long time). However, more recently, the [polyproto](https://polyproto.org) has been on my mind.

### Polyproto

I have to look into protocol-specific details later, however, each Lumina instance could also be a Polyproto 'homeserver', thereby allowing the instance to communicate to other instances using an instance user e.g., `iic@peonies.xyz`, AND as users on the instance, e.g. `user+comment@peonies.xyz`. Then federating timelines would of course go over the iic username, however things like comments or DM's, that'd require more direct federation, would be sent directly using JSON from `<username>+<reason>@<instance>` to the instance user of another instance. One of the pitfalls of the earlier conceptual implementation, was that due to the rate-limits of HTTP polling, there was at least 30 seconds of delay, this concept seems to resolve that fantastically.
