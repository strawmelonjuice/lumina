Rationale: [[Backend > Timeline carries most]]
# Lumina Data Storage Architecture

This document outlines the data storage architecture of the Lumina social platform, based on the existing implementation
and design principles.



## Core Philosophy: "Timeline-carries-most"

Lumina's storage is designed around a central principle referred to as "Timeline-carries-most". The core idea is that
the `timelines` table, which is expected to be the most frequently accessed table, should be as minimal and efficient as
possible.

- It acts as an index, containing only a timeline ID (`tlid`), an item ID (`item_id`), and a `timestamp`.
- It does not store any content itself, only the relationship between a timeline and an item.


## Database System

Lumina supports two SQL database backends:

- **PostgreSQL**: The recommended database for production environments.
- **SQLite**: Supported for testing and development purposes.

The choice of a database is configured via the `LUMINA_DB_TYPE` environment variable.

## Item and Content Storage

Content in Lumina is stored in a flexible, multi-table system that allows for various types of items to be added to
timelines.

### 1. The Item Lookup Table (`itemtypelookupdb`)

This table acts as a central directory or "forwarding table". Its purpose is to map a generic `item_id` to its specific
content type.

- It contains an `item_id` and an `itemtype` string.
- The `itemtype` string directly corresponds to the name of the database table where the item's specific data is
  stored (e.g., `post_text`, `post_article`).

### 2. Specific Content Tables

Each type of content has its own dedicated table. This design allows for adding new content types without altering the
core timeline logic. The initial three content tables are:

- `post_text`: For short, microblog-style text posts.
- `post_media`: For media-focused posts (e.g., images, videos). The table stores a reference to a **MinIO object ID**,
  not the media file itself.
- `post_article`: For long-form content with a title and body.

For direct messages among others, there will be more variants of these.

### 3. Handling Foreign Content (Federation)

The content tables are designed to accommodate posts from other federated instances. Each content table includes the
following nullable fields:

- `foreign_instance_id`: Stores the identifier of the instance where the post originated.
- `foreign_post_id`: Stores the post's original ID from its home instance.

This allows a local copy of the content to exist while preserving a reference to its original source.

## Caching Layer

- **Redis** is used as a caching and performance-optimization layer.
- It is used for timeline caching and for ephemeral data structures like Bloom filters to quickly check for the
  existence of usernames and emails.
- Redis does not store any persistent, canonical data.
