FROM ghcr.io/gleam-lang/gleam:v1.15.2-erlang-alpine AS build-client
COPY ./client/ /app/
RUN cd /app/ && gleam build --target javascript
RUN mkdir -p "/app/build/dev/javascript/lumina_client/dist" && find ./src/ -type f -print0 | xargs -0 sha256sum | sha256sum | awk '{print $1}' > "/app/build/dev/javascript/lumina_client/dist/lumina_client_rev.hash"

FROM docker.io/oven/bun:latest AS package-client
COPY --from=build-client /app/build/dev/javascript/ /build
WORKDIR /build
RUN echo 'import { main } from "./lumina_client.mjs";document.addEventListener("DOMContentLoaded", main())' > "/build/lumina_client/entry.mjs"
RUN bun build --target=browser --minify /build/lumina_client/entry.mjs  --outfile /build/dist/lumina_client.min.js
RUN bun build --target=browser /build/lumina_client/entry.mjs  --outfile /build/dist/lumina_client.js

FROM ghcr.io/gleam-lang/gleam:v1.15.2-erlang-alpine AS package-server
COPY ./server/ /app/
RUN apk add build-base
COPY --from=package-client /build/dist /app/priv/static
RUN cd /app/ && gleam export erlang-shipment

FROM docker.io/library/erlang:28.4.2.0-alpine
COPY --from=package-server /app/build/erlang-shipment /app
ENTRYPOINT ["/app/entrypoint.sh", "run"]
