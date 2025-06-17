[← Back to README](../README.md)  

---

# Services

## Authentik

- https://goauthentik.io/
- https://github.com/goauthentik/authentik

### Setup

- create `secrets.yml`:

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
