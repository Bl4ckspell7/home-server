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

Gate a service behind Authentik login. Adding one takes two edits, no UI work:

1. Append an entry to `authentik_proxy_apps` in
   `roles/services/authentik/defaults/main.yml`:

   ```yaml
   - slug: myservice
     name: My Service
     description: What it does
   ```

   `host`, `group` and `icon` are derived from the slug and can be overridden
   per entry.

2. Import the `(authentik)` snippet in the service's Caddy route (see below).

The role renders `templates/proxy-apps.yaml.j2` to
`/opt/stacks/authentik/blueprints/proxy-apps.yaml` and restarts the worker.
Authentik instantiates the blueprint, creating the proxy provider and
application and attaching the provider to the embedded outpost.

The outpost's provider list is replaced on every apply, so every forward-auth
provider must come from that one template — do not add providers by hand or via
a second blueprint, or the ones not listed will be detached.

Manual UI setup, if you ever need it as a fallback:

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
