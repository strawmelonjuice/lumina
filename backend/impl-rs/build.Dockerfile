# syntax=docker/dockerfile:1

# --- Build stage ---
FROM lumina-build-environment AS builder

WORKDIR /build

# Copy the project files excluding mise.toml
COPY --exclude=mise.toml . .

# Builds debug version
RUN mkdir -p target/output  && \
    mise run build-server && \
    cp ./target/debug/lumina-server ./target/output/;

# --- Final runtime image ---
FROM alpine:3.19
RUN apk add --no-cache ca-certificates
WORKDIR /app
COPY --from=builder /build/target/output/lumina-server /app/lumina-server
COPY assets /app/assets
EXPOSE 8085
CMD ["/app/lumina-server"]
