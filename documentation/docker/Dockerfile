FROM docker.io/oven/bun:1.4.3@sha256:ec06c3b6cea04192ae6770c434f668ca41d343ad19fa6472216c7b48be39c598 AS build
WORKDIR /app
COPY package.json bun.lock ./
RUN bun install --frozen-lockfile
COPY . .
RUN bun run build

FROM docker.io/library/caddy:2.11.7-alpine@sha256:173b26306d711395accaeba8b67afcaad2a085ccb1e6bf26010bfe8c095a5229
COPY docker/Caddyfile /etc/caddy/Caddyfile
COPY --from=build /app/build /srv
EXPOSE 8349
