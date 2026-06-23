# Docusaurus

Port: `:8349` (exposed, no host binding)

- https://docusaurus.io/
- https://github.com/facebook/docusaurus

Documentation site for this project, built with Docusaurus and served by Caddy.

## Build and push

Use the helper from the repository root. It derives the next image tag from
`roles/services/docusaurus/files/docker-compose.yml`, builds and pushes the
image, updates the compose tag, commits the bump, and deploys Docusaurus:

```bash
scripts/publish-docs.sh patch
```

Use `minor` or `major` instead of `patch` when needed.
