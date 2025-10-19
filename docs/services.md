[← Back to README](../README.md)

---

# Services

## Setup new service

### Docker

- create compose, .env, secrets and ansible task

### Network

- Pihole new IP entry (`xxx.xxx.xxx.xxx service.lan`) in the shared docker subnet

- NPM:
  - Proxy Host: `service.DDNS.ORG`, `http://service.lan:DOCKER_CONTAINER_PORT`
  - request ssl certificate via "Let's Encrypt" (make sure Port `80` is forwarded in the router)

## Ports

| **Service**          | **Host Port** | **Container Port** |
| -------------------- | ------------- | ------------------ |
| **Pi-hole**          | 53            | 53                 |
| **Nginx Proxy Mgr.** | 80            | 80                 |
| **Nginx Proxy Mgr.** | 81            | 81                 |
| **Nginx Proxy Mgr.** | 443           | 443                |
| **Immich**           | 2283          | 2283               |
| **Photon**           | 2322          | 2322               |
| **Homepage**         | 3000          | 3000               |
| **Uptime Kuma**      | 3001          | 3001               |
| **Dawarich**         | 3002          | 3000               |
| **Linkwarden**       | 3010          | 3000               |
| **Dockge**           | 5001          | 5001               |
| **Pi-hole**          | 7080          | 80                 |
| **Pi-hole**          | 7443          | 443                |
| **Paperless-ngx**    | 8000          | 8000               |
| **Cup**              | 8010          | 8000               |
| **Wallabag**         | 8090          | 80                 |
| **Jellyfin**         | 8096          | 8096               |
| **Authentik**        | 9080          | 9080               |
| **Authentik**        | 9443          | 9443               |
| **Ollama**           | 11434         | 11434              |
| **Seafile**          | –             | –                  |

## Service Users and Groups

System users and groups created by Ansible for running services:

| **Service**  | **User** | **UID** | **Group** | **GID** |
| ------------ | -------- | ------- | --------- | ------- |
| **Jellyfin** | jellyfin | 900     | jellyfin  | 900     |

## Authentik

Port: `9080:9080`, `9443:9443`

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
ansible-vault encrypt secrets.yml
```

- save vault key to file and specify location in `ansible.cfg`

### Force MFA

Flows and Stages -> Flows:

`default-authentication-mfa-validation` ->

- Not configured action: -> Force..
- Configuration stages: -> `default-authenticator-webauthn-setup` & `default-authenticator-totp-setup`

## Dockge

Ports: `5001:5001`

- https://dockge.kuma.pet/
- https://github.com/louislam/dockge

## Wallabag

Ports: `8090:80`

- https://wallabag.org/
- https://github.com/wallabag/wallabag

`secrets.yml`:

```yaml
wallabag_db_user: wallabag
wallabag_db_pass: ""
wallabag_db_root_pass: ""
wallabag_domain_name: ""
```

## Uptime Kuma

Ports: `3001:3001`

- https://uptime.kuma.pet/
- https://github.com/louislam/uptime-kuma

## Paperless-ngx

Ports: `8000:8000`

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

## Nging Proxy Manager

Ports: `80:80`, `443:443`, `81:81`

- https://nginxproxymanager.com/
- https://github.com/NginxProxyManager/nginx-proxy-manager

`secrets.yml`:

```yaml
nginx_db_name: ""
nginx_db_user: ""
nginx_db_password: ""
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

Ports: `3000:3000`

- https://gethomepage.dev/
- https://github.com/gethomepage/homepage

## Linkwarden

Ports: `3010:3000`

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
- domaincheck: NPM: forward http to port 11000 of "nextcloud-aio-domaincheck"
- NPM: forward to "nextcloud-aio-apache"

## Seafile

Ports: ``

- https://manual.seafile.com/latest/
- https://manual.seafile.com/latest/setup/setup_ce_by_docker/
- https://github.com/haiwen/seafile

## Immich

Ports: `2283:2283`

- https://immich.app/docs/overview/quick-start
- https://github.com/immich-app/immich

`secrets.yml`:

```yaml
immich_postgres_password: ""
```

Web UI Error: "Server offline, Version unknown"
-> NPM: Enable Websockets

## Cup

Ports: `8010:8000`

- https://cup.sergi0g.dev/
- https://github.com/sergi0g/cup
- https://cup.sergi0g.dev/docs/community-resources/homepage-widget

## Ollama

Ports: `11434:11434`

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

Ports: `3002:3000`

- https://dawarich.app/docs/intro
- https://github.com/Freika/dawarich

Default credentials: `demo@dawarich.app` `password`

`secrets.yml`:

```yaml
dawarich_postgres_password: ""
```

## Photon

Ports: `2322:2322`

- https://github.com/rtuszik/photon-docker
