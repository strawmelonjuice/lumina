# syntax=docker/dockerfile:1

FROM alpine:3.19

ENV MISE_DATA_DIR="/mise"
ENV MISE_CONFIG_DIR="/mise"
ENV MISE_CACHE_DIR="/mise/cache"
ENV MISE_INSTALL_PATH="/usr/local/bin/mise"
ENV BUN_INSTALL="/usr/local/bin/bun"
ENV PATH="/usr/local/bin/bun/bin:/mise/shims:$PATH"

RUN apk add --no-cache curl git unzip build-base bash

# Install bun outside of mise because Alpine uses musl libc which the mise bun package does not support
RUN curl -fsSL https://bun.sh/install | bash
RUN curl https://mise.run | sh

WORKDIR /build
# Copy and install the mise.toml file first to leverage Docker cache
COPY mise.toml ./mise.toml
COPY mise/ ./mise/
RUN mise trust && mise unuse bun && mise install

# ------- Prefetch Rust dependencies -------

# Copy the manifests cargo needs to prefetch dependencies
COPY Cargo.toml Cargo.lock ./
RUN mkdir server
COPY server/Cargo.toml ./server/
# Prefetch dependencies
RUN cargo fetch --locked

# ------- Prefetch Bun dependencies -------

RUN mkdir client
COPY client/package.json client/bun.lock ./client/
RUN mise run bun-install --locked

# ------- Prefetch Gleam dependencies -------

COPY client/gleam.toml client/manifest.toml ./client/
RUN mise run prefetch-gleam-deps