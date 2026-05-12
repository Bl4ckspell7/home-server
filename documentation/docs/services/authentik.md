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

## Forward auth (per-app)

Gate a service that has no native auth (e.g. Cup) behind Authentik login. One-time UI setup per service:

1. **Applications -> Providers -> Create**
   - Type: **Proxy Provider**
   - Name: `<service>`
   - Authorization flow: `default-provider-authorization-implicit-consent`
   - Mode: **Forward auth (single application)**
   - External host: `https://<service>.bl4ckspell.freeddns.org`
2. **Applications -> Applications -> Create**
   - Name: `<Service>`
   - Slug: `<service>`
   - Provider: `<service>` (just created)
3. **Applications -> Outposts -> embedded outpost -> Edit**
   - Add the new application to the outpost, save (outpost auto-reloads)

Caddyfile side: import the `(authentik)` snippet inside the service's `handle` block in the internal `:8080` listener. Example:

```caddyfile
@service host service.bl4ckspell.freeddns.org
handle @service {
    import authentik
    reverse_proxy http://service.lan:PORT {
        header_up X-Forwarded-Proto https
    }
}
```
