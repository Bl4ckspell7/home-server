[← Back to README](../README.md)

---

# Services

## Authentik

Port: `9443`

- https://goauthentik.io/
- https://github.com/goauthentik/authentik

### Setup

- create `secrets.yml`

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

Port: `5001`

- https://dockge.kuma.pet/
- https://github.com/louislam/dockge

## Wallabag

Port: `8090`

- https://wallabag.org/
- https://github.com/wallabag/wallabag

### Setup

- create `secrets.yml`:

```yaml
wallabag_db_user: wallabag
wallabag_db_pass: "super-secure-generated-password"
wallabag_db_root_pass: "another-strong-password"
```

(don't use special characters)

- encrypt

```bash
ansible-vault encrypt secrets.yml
```

## Uptime Kuma

Port: `3001`

- https://uptime.kuma.pet/
- https://github.com/louislam/uptime-kuma

## Paperless-ngx

Port: `8000`

- https://docs.paperless-ngx.com/
- https://github.com/paperless-ngx/paperless-ngx
- https://docs.goauthentik.io/integrations/services/paperless-ngx/

Setup:

create and encrypt `secrets.yml`:

```yaml
paperless_secret_key:
paperless_db_name:
paperless_db_user:
paperless_db_password:
authentik_client_id:
authentik_client_secret:
```

(don't use special characters)
