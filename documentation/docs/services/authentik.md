# Authentik

Port: `:9443` (exposed, no host binding)

- https://goauthentik.io/
- https://github.com/goauthentik/authentik

## Setup

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

## Force MFA

Flows and Stages -> Flows:

`default-authentication-mfa-validation` ->

- Not configured action: -> Force..
- Configuration stages: -> `default-authenticator-webauthn-setup` & `default-authenticator-totp-setup`
