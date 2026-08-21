# Authentik

Port: `:9443` (exposed, no host binding)

- https://goauthentik.io/
- https://github.com/goauthentik/authentik

## Service user

Both `authentik-server` and `authentik-worker` run as the dedicated
`authentik` system user (906:906) — no root, no docker socket. The image
entrypoint only fixes permissions when it starts as root, so the bind-mounted
`data/`, `certs/` and `custom-templates/` under `/opt/stacks/authentik` must
stay owned by `authentik`; the role enforces that on every run.

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

## User switching

Several accounts can stay signed in in one browser, switchable from the account
menu (Authentik 2026.8+). Off by default — the brand field `flow_user_switch` is
the only knob. `files/brand.yaml` points it at `default-authentication-flow`, so
a switch is a full re-auth; set that attr to `null` to disable it again (dropping
the entry only stops managing the field).

Verify after a deploy — the `default = t` row is the brand serving requests, and
an empty slug means the `!Find` resolved to null:

```bash
ssh server 'docker exec authentik-postgresql psql -U authentik -d authentik -c "select b.domain, b.\"default\", f.slug from authentik_brands_brand b left join authentik_flows_flow f on f.flow_uuid=b.flow_user_switch_id;"'
```

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

The role renders `templates/apps.yaml.j2` to
`/opt/stacks/authentik/blueprints/apps.yaml` and restarts the worker.
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
   - External host: `https://<service>.bl4ckspell.de`
2. **Applications -> Applications -> Create**
   - Name: `<Service>`
   - Slug: `<service>`
   - Provider: `<service>` (just created)
3. **Applications -> Outposts -> embedded outpost -> Edit**
   - Add the new application to the outpost, save (outpost auto-reloads)

Caddyfile side: import the `(authentik)` snippet inside the service's `handle` block in the internal `:8080` listener. Example:

```caddyfile
@service host service.bl4ckspell.de
handle @service {
    import authentik
    reverse_proxy http://service.lan:PORT {
        header_up X-Forwarded-Proto https
    }
}
```
