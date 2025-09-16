# syntax=docker/dockerfile:1

FROM alpine:3.19 AS builder

ARG optimize_build
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
RUN mise trust && mise unuse bun && mise install
# Copy the project files excluding mise.toml
COPY --exclude=mise.toml . .
# Build the project itself in release mode.
RUN mkdir -p target/output  && \
    mise run build-server-release && \
    cp ./target/release/lumina-server ./target/output/;


# --- Final runtime image ---
FROM alpine:3.19
RUN apk add --no-cache ca-certificates
WORKDIR /app
COPY --from=builder /build/target/output/lumina-server /app/lumina-server
EXPOSE 8085
CMD ["/app/lumina-server"]

