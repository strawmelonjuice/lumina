# Lumina Social Platform

Lumina is a modern, privacy-conscious social platform designed for real-time communication and content sharing. Built
with Rust on the backend and Gleam/Lustre on the client, Lumina aims to provide a secure, flexible, and user-friendly
experience for individuals and communities.

## Key Features

- **User Registration & Authentication:** Secure account creation, login, and session management with support for both
  SQLite and Postgres databases.
- **Real-Time Communication:** WebSocket-based messaging for instant updates and interactions.
- **Content Sharing:** Support for articles, media, and text posts
- **Semi-decentralised:** Instances (servers) can communicate over websockets with allowlisted other instances to blend
  certain aspects of their respective timelines, the identification relies on the already in place DNS system and SSH
  keys.
- **Bubbles vs timelines:** While Lumina has a global timeline and one for following and mutuals, it also has 'bubbles',
  semi-isolated timelines you can be a member of, that sort of operate as communities for specific subjects.
- **Post modes:** Posts and DM's switch modes depending on what you want to put in them. _Want to post a short text?
  Sure! An article post? Okay. A gram post? Great!_ In DM's this is slightly different, but following the same
  principle!

## Vision

Lumina is intended to be a welcoming, open-source alternative to mainstream social networks, prioritizing user control,
transparency, and extensibility. The project is in active development, and contributions are encouraged!

## Getting Involved

If you're interested in contributing, please read this file and the codebase to understand the current architecture and
goals. Feel free to open issues, suggest features, or submit pull requests.

---

_For more details, see the README.MD and WHY.md files._
