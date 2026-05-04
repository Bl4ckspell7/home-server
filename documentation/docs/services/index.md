# Services

## Setup new service

### Docker

- create compose, .env, secrets and ansible task
- encrypt secrets with sops: `sops encrypt --in-place secrets.yml`

### Network

- Pihole new IP entry (`xxx.xxx.xxx.xxx service.lan`) in the shared docker subnet

- Caddy:
  - Add reverse proxy entry in Caddyfile:
    ```
    service.DDNS.ORG {
        reverse_proxy http://service.lan:DOCKER_CONTAINER_PORT
    }
    ```
  - SSL certificates are automatically managed

## Ports

Services behind Caddy use `expose` (no host port binding). Only services requiring direct LAN access retain host port mappings.

| **Service**       | **Host Port** | **Container Port** |
| ----------------- | ------------- | ------------------ |
| **Pi-hole**       | 53            | 53                 |
| **Anubis**        | -             | 3000               |
| **Immich**        | -             | 2283               |
| **Photon**        | -             | 2322               |
| **Homepage**      | -             | 3000               |
| **Uptime Kuma**   | -             | 3001               |
| **Dawarich**      | -             | 3000               |
| **ddns-updater**  | 3003          | 8000               |
| **Docusaurus**    | -             | 8349               |
| **Dockhand**      | -             | 3000               |
| **Linkwarden**    | -             | 3000               |
| **Dockge**        | 5001          | 5001               |
| **Radicale**      | 5232          | 5232               |
| **Forgejo**       | 3000          | 3000               |
| **Pi-hole**       | 7080          | 80                 |
| **Pi-hole**       | 7443          | 443                |
| **Paperless-ngx** | -             | 8000               |
| **Cup**           | 8010          | 8000               |
| **Jellyfin**      | -             | 8096               |
| **Authentik**     | -             | 9443               |
| **Ollama**        | -             | 11434              |

## Service Users and Groups

System users and groups created by Ansible for running services:

| **Service**  | **User** | **UID** | **Group** | **GID** |
| ------------ | -------- | ------- | --------- | ------- |
| **Jellyfin** | jellyfin | 900     | jellyfin  | 900     |
| **Immich**   | immich   | 901     | immich    | 901     |
| **Forgejo**  | forgejo  | 902     | forgejo   | 902     |
| **Radicale** | radicale | 903     | radicale  | 903     |
