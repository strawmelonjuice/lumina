# Timeline-carries-most
[['Timeline carries most' and the database]]

One of the busiest tables you'll see is the timeline, containing just some ID's and timestamps.

| Kind                                     | timeline ID | item ID | Timestamp          |
| ---------------------------------------- | ----------- | ------- | ------------------ |
| `'USER'`, `'DIRECT'`, `'TL'`, `'BUBBLE'` | uuidv4      | uuidv4  | Database timestamp |

The `global` timeline, here being `00000000-0000-0000-0000-000000000000` as the only constant-assigned timeline ID. The
user-profiles being the same as their user id counterpart.

This is too vague to actually be able to pull a post, which is why the item forward table exists, combining a UUID and a
string to forward to the right item.

Now I say `item`, not `post` here. This because you might expect only timelines (global, userprofiles) and bubbles (
timelines meant for a specific subject, forming a community within the larger site) in this table, but direct message
threads are actually also saved here.

This means this table might become a little overcrowded, and optimizations such as caching, sharding and mirrorring to
Redis will be needed to keep it somewhat performant, especially since this is essentially a constant hot path. I am
aware.

Which is why we also would need to log every timeline request to be able to identify for example over-requested
timelines.