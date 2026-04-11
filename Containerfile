FROM docker.io/oven/bun:latest AS style-client
COPY ./client/bun.lock ./client/package.json /app/
RUN bun install --cwd=/app/ --production
COPY ./client/ /app/
RUN mkdir -p /app/prepped && bun x @tailwindcss/cli -i /app/app.css -o /app/prepped/lumina_client.css

FROM ghcr.io/gleam-lang/gleam:v1.15.2-erlang-alpine AS build-client
WORKDIR /app
COPY ./client/gleam.toml ./client/manifest.toml ./
RUN gleam deps download
COPY ./client/ ./
COPY --from=style-client /app/prepped/ /app/prepped/
RUN gleam build --target javascript
RUN find ./src/ -type f -print0 | xargs -0 sha256sum | sha256sum | awk '{print $1}' > "/app/prepped/lumina_client_rev.hash"
RUN mkdir -p "build/dev/javascript/dist" && mv prepped/* "build/dev/javascript/dist"


FROM docker.io/oven/bun:latest AS package-client
COPY --from=build-client /app/build/dev/javascript/ /build
WORKDIR /build
RUN echo 'import { main } from "./lumina_client.mjs";document.addEventListener("DOMContentLoaded", main())' > "/build/lumina_client/entry.mjs"
RUN bun build --target=browser --minify /build/lumina_client/entry.mjs  --outfile /build/dist/lumina_client.min.mjs && \
	bun build --target=browser /build/lumina_client/entry.mjs  --outfile /build/dist/lumina_client.mjs

FROM ghcr.io/gleam-lang/gleam:v1.15.2-erlang-alpine AS package-server
RUN apk add build-base
WORKDIR /app
COPY ./server/gleam.toml ./server/manifest.toml ./
RUN gleam deps download
COPY ./server/ /app/
RUN cd /app/ && gleam export erlang-shipment

FROM docker.io/library/erlang:28-alpine
RUN adduser -D lumina
USER lumina
WORKDIR /app
COPY --from=package-server --chown=lumina:lumina /app/build/erlang-shipment /app
COPY --from=package-client --chown=lumina:lumina /build/dist /app/lumina_server/priv/static
VOLUME /data
ENTRYPOINT ["/app/entrypoint.sh", "run"]
