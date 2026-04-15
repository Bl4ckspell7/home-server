# home-server Documentation

Built with [Docusaurus](https://docusaurus.io/).

## Development

Install dependencies:

```bash
bun install
```

Start dev server:

```bash
bun start
```

Or preview the production build (required for features like search):

```bash
bun run build && bun run serve
```

## Docker

Run the production build served by Caddy on [http://localhost:8349](http://localhost:8349):

```bash
docker compose -f docker/compose.yml up --build
```

## Maintenance

Upgrade dependencies:

```bash
bunx npm-check-updates -u && bun install
```
