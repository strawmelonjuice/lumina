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

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN curl https://mise.run | sh

WORKDIR /app
COPY . .
RUN curl -fsSL https://bun.sh/install | bash
RUN mise trust && mise unuse bun && mise install
RUN mkdir -p target/output  && \
    if [ "$optimize_build" = "true" ]; then \
        mise run build-server-release && \
        cp ./target/release/lumina-server ./target/output/; \
    else \
        mise run build-server && \
        cp ./target/debug/lumina-server ./target/output/; \
    fi


# --- Final runtime image ---
FROM alpine:3.19
RUN apk add --no-cache ca-certificates
WORKDIR /app
COPY --from=builder /app/target/output/lumina-server /app/lumina-server
EXPOSE 8085
CMD ["/app/lumina-server"]
