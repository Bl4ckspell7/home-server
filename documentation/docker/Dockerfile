FROM docker.io/oven/bun:1.4.5@sha256:3aa040e5445efa09d75bb428a64ba50db13e2b3ac9b6b0c7f145615f62b2ee18 AS build
WORKDIR /app
COPY package.json bun.lock ./
RUN bun install --frozen-lockfile
COPY . .
RUN bun run build

FROM docker.io/library/caddy:2.11.9-alpine@sha256:fc9cbc100585871d18d4e451cca7021785c90a7006087427ae5ceb3e4efe6424
COPY docker/Caddyfile /etc/caddy/Caddyfile
COPY --from=build /app/build /srv
EXPOSE 8349
