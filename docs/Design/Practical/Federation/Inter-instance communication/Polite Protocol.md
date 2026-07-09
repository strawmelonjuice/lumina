| Conceptual        |
| ----------------- |
| --No issue yet--, |
Lumina instances communicate 'Politely', they contact instances over HTTPS, identifying themselves and others by domain name. A Lumina instance will only ever share data it knows to be true, either by on a user-level verifying the signature ([Users IDs](../Users%20IDs.md) will explain you how), or by requesting it from the source instance.
## Levels of federation
### Explorative

Upon first 'explorative'-level federation (which is the default behaviour until an admin either approves full federation or maybe disables federation with this instance forever), only shallow data is allowed to be shared: post contents, user lookups, but not much more. This way an instance is a *polite* guest, asking for resources upon demand.

Explorative is the default, but may also be set explicitly, if admins decide an instance is fine to federate with, but do not per se want to more intensely exchange with this instance.

### Full

Only when admins on either side set an instance to 'requesting full federation', the instance may request of admins on the other side to do the same, when both have done so, a *trusted federationship* is created. 
This means timelines and bigger dumps of data can now be exchanged, _and_ a shared HMAC-SHA-512 secret is created to do so securely and with certainty of forever seeing this same instance again. 
This may also be done over a constant and autoreconnecting websocket connection.

On fully-federating instances, a *polite request* (always pulling) can be complimented with a *welcomed gift*, which is a push-based exchange, this can help timelines sync up faster.
### Blocked

When trust is broken, which is what happens when the federationship secret is violated with  forged (or rather, unverifiable) data, an instance will, to protect itself, set the instance to blocked.

A federation-blocked instance does not exchange data, and does not even politely request data.

The instance on the other side will get a simple message upon sending it's trusted requests or upon trying to establish the websocket based exchange, it will in that case follow and automatically return the block - if it doesn't, this would break interaction, as one instance will be able to see posts on the other, but responses to those posts will never be received by their author.

When an admin lifts a block, this will send a request to the unblocked instance, if the reason set for the blockage there is an automated `return blocking` reason, the opposing instance will automatically also lift the block. This means unblocking an instance with a different reason will likely not work, unless there is direct contact between two instance admins, to lift the blocks simultaneously.