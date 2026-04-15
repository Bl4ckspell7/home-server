FROM oven/bun:1.3.12@sha256:8956c7667fa17beb6e3c664115e66bdacfe502da5d99603626e74c197bdef160 AS build
WORKDIR /app
COPY package.json bun.lock ./
RUN bun install --frozen-lockfile
COPY . .
RUN bun run build

FROM caddy:2.11.2-alpine@sha256:a1b7e624f860619cea121bdbc5dec2e112401666298c6507c6793b0a3ee6fc8e
COPY docker/Caddyfile /etc/caddy/Caddyfile
COPY --from=build /app/build /srv
EXPOSE 8349
