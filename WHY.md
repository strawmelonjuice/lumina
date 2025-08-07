# Why

> This file aims to explain my choices. Not that I need to explain myself
> but hey, we all feel accountable for our stupid actions sometimes.

## The 25 branch

Few days after the Rust 2024 edition release, having new experiences with gleam Lustre and a really messy repository...
Three great reasons for a clean slate.
Git branch 25 is yet another restart for me writing on Lumina. With past experiences and a clear vision, `master` does a good job, so this one will do even better.

### Choices made

- **Gleam** as the main language on frontend.
  Not having multiple language branches about this.
    - **TailwindCSS** as the main CSS framework.
    - **Lustre** for building the UI.
- **Rust** as the main language on backend.
    - More specifically, the `rocket` library instead of `actix-web`.
    - Rust 2024 edition from the start.
- **PostgreSQL** as the main database. **SQLite** for testing.
- **WebSockets** for real-time communication between the client and the server.

## The `gleam` language

I am a big fan of the language. I think it's a great language for
writing maintainable and scalable code. I think it's a great language
for writing maintainable and scalable code. It's simplicity and the
young yet strong community set a good foundation for Lumina.

## Timeline-carries-most
One of the bussiest tables you'll see is the timeline, containing just some ID's and timestamps.

| Kind                                     | timeline ID | item ID | Timestamp          |
|------------------------------------------|-------------|---------|--------------------|
| `'USER'`, `'DIRECT'`, `'TL'`, `'BUBBLE'` | uuidv4      | uuidv4  | Database timestamp |

The `global` timeline, here being `00000000-0000-0000-0000-000000000000` as the only constant-assigned timeline ID. The user-profiles being the same as their user id counterpart.

This is too vague to actually be able to pull a post, which is why the item forward table exists, combining a uuid and a string to forward to the right item.

Now I say `item`, not `post` here. This because you might expect only timelines (global, userprofiles) and bubbles (timelines meant for a specific subject, forming a community within the larger site) in this table, but direct message threads are actually also saved here.

This means this table might become a little overcrowded, and optimisations such as caching, sharding and mirrorring to Redis will be needed to keep it somewhat performant, especially since this is essentially a constant hot path. I am aware.

Which is why we also would need to log every timeline request to be able to identify for example overrequested timelines.