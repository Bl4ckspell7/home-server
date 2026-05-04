# Docusaurus

Port: `:8349` (exposed, no host binding)

- https://docusaurus.io/
- https://github.com/facebook/docusaurus

Documentation site for this project, built with Docusaurus and served by Caddy.

## Build and push

```bash
cd documentation
podman login forgejo.bl4ckspell.freeddns.org
podman build -f docker/Dockerfile -t forgejo.bl4ckspell.freeddns.org/bl4ckspell/home-server-docs:1.0.0 .
podman push forgejo.bl4ckspell.freeddns.org/bl4ckspell/home-server-docs:1.0.0
```

Update the image tag in `roles/services/docusaurus/files/docker-compose.yml` to match the pushed version.
