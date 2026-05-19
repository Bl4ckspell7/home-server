FROM oven/bun:1.3.14@sha256:e10577f0db68676a7024391c6e5cb4b879ebd17188ab750cf10024a6d700e5c4 AS build
WORKDIR /app
COPY package.json bun.lock ./
RUN bun install --frozen-lockfile
COPY . .
RUN bun run build

FROM caddy:2.11.3-alpine@sha256:3739ea4f0c877259a693d932693cf8f3408e9a9497c004f031b0e830e93e1546
COPY docker/Caddyfile /etc/caddy/Caddyfile
COPY --from=build /app/build /srv
EXPOSE 8349
