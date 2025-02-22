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
    - More specifically, the `axum` library instead of `actix-web`.
    - Rust 2024 edition from the start.
- **PostgreSQL** as the main database. **SQLite** for testing.
- **WebSockets** for real-time communication between the client and the server.

## The `gleam` language

I am a big fan of the language. I think it's a great language for
writing maintainable and scalable code. I think it's a great language
for writing maintainable and scalable code. It's simplicity and the
young yet strong community set a good foundation for Lumina.
