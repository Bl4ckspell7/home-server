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

- encrypt

```bash
ansible-vault encrypt secrets.yml
```

"Recover after crash" error:

```bash
rm /opt/wallabag/data/tc.log
```
