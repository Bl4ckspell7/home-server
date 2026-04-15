[← Back to README](../README.md)

---

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

| **Service**          | **Host Port** | **Container Port** |
| -------------------- | ------------- | ------------------ |
| **Pi-hole**          | 53            | 53                 |
| **Anubis**           | -             | 3000               |
| **Immich**           | -             | 2283               |
| **Photon**           | -             | 2322               |
| **Homepage**         | -             | 3000               |
| **Uptime Kuma**      | -             | 3001               |
| **Dawarich**         | -             | 3000               |
| **ddns-updater**     | 3003          | 8000               |
| **Dockhand**         | -             | 3000               |
| **Linkwarden**       | -             | 3000               |
| **Dockge**           | 5001          | 5001               |
| **Radicale**         | 5232          | 5232               |
| **Forgejo**          | 3000          | 3000               |
| **Pi-hole**          | 7080          | 80                 |
| **Pi-hole**          | 7443          | 443                |
| **Paperless-ngx**    | -             | 8000               |
| **Cup**              | 8010          | 8000               |
| **Jellyfin**         | -             | 8096               |
| **Authentik**        | -             | 9443               |
| **Ollama**           | -             | 11434              |

## Service Users and Groups

System users and groups created by Ansible for running services:

| **Service**  | **User** | **UID** | **Group** | **GID** |
| ------------ | -------- | ------- | --------- | ------- |
| **Jellyfin** | jellyfin | 900     | jellyfin  | 900     |
| **Immich**   | immich   | 901     | immich    | 901     |
| **Forgejo**  | forgejo  | 902     | forgejo   | 902     |
| **Radicale** | radicale | 903     | radicale  | 903     |

## Anubis

Port: `:3000`

- https://anubis.techaro.lol/docs/
- https://github.com/TecharoHQ/anubis

Anubis sits between Caddy and your backend services to filter out AI scrapers and other malicious traffic using a proof-of-work challenge.

Set `TARGET` in the docker-compose environment to the backend service you want to protect, then point the corresponding Caddyfile entry to Anubis instead of directly to the backend.

## Authentik

Port: `:9443` (exposed, no host binding)

- https://goauthentik.io/
- https://github.com/goauthentik/authentik

### Setup

`secrets.yml`:

```yaml
pg_pass: 80 characters
secret_key: 60 characters
```

(don't use special characters)

- encrypt

```bash
sops encrypt --in-place secrets.yml
```

### Force MFA

Flows and Stages -> Flows:

`default-authentication-mfa-validation` ->

- Not configured action: -> Force..
- Configuration stages: -> `default-authenticator-webauthn-setup` & `default-authenticator-totp-setup`

## Dockge

Ports: `5001:5001`

- https://dockge.kuma.pet/
- https://github.com/louislam/dockge

## Uptime Kuma

Port: `:3001` (exposed, no host binding)

- https://uptime.kuma.pet/
- https://github.com/louislam/uptime-kuma

## Paperless-ngx

Port: `:8000` (exposed, no host binding)

- https://docs.paperless-ngx.com/
- https://github.com/paperless-ngx/paperless-ngx
- https://docs.goauthentik.io/integrations/services/paperless-ngx/

`secrets.yml`:

```yaml
paperless_secret_key: ""
paperless_db_name: ""
paperless_db_user: ""
paperless_db_password: ""
authentik_client_id: ""
authentik_client_secret: ""
```

## Pi-hole

Ports: `53:53`, `7080:80`, `7443:443`

- https://pi-hole.net/
- https://github.com/pi-hole/docker-pi-hole

`secrets.yml`:

```yaml
pihole_web_password: ""
```

## Homepage

Port: `:3000` (exposed, no host binding)

- https://gethomepage.dev/
- https://github.com/gethomepage/homepage

## Linkwarden

Port: `:3000` (exposed, no host binding)

- https://docs.linkwarden.app/
- https://github.com/linkwarden/linkwarden

`secrets.yml`:

```yaml
linkwarden_nextauth_secret: ""
linkwarden_postgres_password: ""
linkwarden_meili_master_key: ""
linkwarden_authentik_issuer: ""
linkwarden_authentik_client_id: ""
linkwarden_authentik_client_secret: ""
```

## Nextcloud

Ports: `6080:8080`

- https://nextcloud.com/home-users/
- https://nextcloud.com/blog/how-to-install-the-nextcloud-all-in-one-on-linux/
- https://github.com/nextcloud/all-in-one

Setup:

- open aio setup on local ip
- domaincheck: forward http to port 11000 of "nextcloud-aio-domaincheck"
- forward to "nextcloud-aio-apache"

## Immich

Port: `:2283` (exposed, no host binding)

- https://immich.app/docs/overview/quick-start
- https://github.com/immich-app/immich

`secrets.yml`:

```yaml
immich_postgres_password: ""
```

## Cup

Ports: `8010:8000`

- https://cup.sergi0g.dev/
- https://github.com/sergi0g/cup
- https://cup.sergi0g.dev/docs/community-resources/homepage-widget

## Ollama

Port: `:11434` (exposed, no host binding)

- https://ollama.com/
- https://github.com/ollama/ollama

```bash
docker exec -it ollama-ollama-1 /bin/bash
```

```bash
ollama pull phi4-mini
ollama pull mistral
```

## Dawarich

Port: `:3000` (exposed, no host binding)

- https://dawarich.app/docs/intro
- https://github.com/Freika/dawarich

Default credentials: `demo@dawarich.app` `password`

`secrets.yml`:

```yaml
dawarich_postgres_password: ""
authentik_client_id: ""
authentik_client_secret: ""
```

**Reverse Geocoding:**

-> Disable DNS Rate-limiting

## Photon

Port: `:2322` (exposed, no host binding)

- https://github.com/rtuszik/photon-docker

## Jellyfin

Port: `:8096` (exposed, no host binding)

- https://jellyfin.org/docs/
- https://github.com/jellyfin/jellyfin

Permissions are automatically enforced on media directories by a dedicated watcher script and corresponding `systemd` service. These ensure correct ownership (`jellyfin:jellyfin`) and access permissions are maintained continuously.

## Forgejo

Ports: `3000:3000`, SSH: `2222` (exposed internally only, no router port forward)

- https://forgejo.org/docs/latest/
- https://codeberg.org/forgejo/forgejo

`secrets.yml`:

```yaml
forgejo_db_password: ""
```

### Backup

Run the backup script as root on the server:

```bash
bash /opt/stacks/forgejo/backup.sh
```

This stops Forgejo, dumps the PostgreSQL database, archives everything (git repos, config, database dump) into a single `.tar.gz`, and restarts Forgejo. Backups are saved to `/opt/stacks/forgejo/backup/`.

To restore from a backup:

```bash
docker compose -f /opt/stacks/forgejo/docker-compose.yml down
tar xzf /opt/stacks/forgejo/backup/forgejo-backup-XXXXXXXX-XXXXXX.tar.gz -C /opt/stacks/forgejo
docker compose -f /opt/stacks/forgejo/docker-compose.yml up -d forgejo-postgres
sleep 3
docker exec forgejo-postgres dropdb -U forgejo forgejo
docker exec forgejo-postgres createdb -U forgejo forgejo
docker exec -i forgejo-postgres psql -U forgejo -d forgejo < /opt/stacks/forgejo/forgejo-db.sql
docker compose -f /opt/stacks/forgejo/docker-compose.yml up -d
```

## Radicale

Ports: `5232:5232`

- https://radicale.org/master.html
- https://github.com/Kozea/Radicale

CalDAV/CardDAV server for self-hosted calendar and contact sync. Exposed directly via Caddy (not through Anubis, as CalDAV clients can't handle PoW challenges). Uses htpasswd authentication with argon2 hashing.

`secrets.yml`:

```yaml
radicale_users_htpasswd: "user:argon2hash"
```

Generate an argon2 htpasswd entry:

```bash
uv run --with passlib --with argon2-cffi python3 -c "
from passlib.hash import argon2
import getpass
user = input('Username: ')
pw = getpass.getpass('Password: ')
print(user + ':' + argon2.using(type='ID').hash(pw))
"
```

Multiple users go on separate lines in the secrets file.

## Dockhand

Port: `:3000` (exposed, no host binding)

- https://dockhand.pro/manual/
- https://github.com/Finsys/dockhand

## ddns-updater

Ports: `3003:8000`

- https://github.com/qdm12/ddns-updater

Fill `data/config.json` with correct data and encrypt with `sops encrypt --in-place data/config.json`.
