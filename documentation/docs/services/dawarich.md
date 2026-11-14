# Dawarich

Port: `:3000` (exposed, no host binding)

- https://dawarich.app/docs/intro
- https://github.com/Freika/dawarich

Email/password login and registration are disabled. Authentik OIDC is the only
interactive login method, with automatic registration for authorized users.

A fresh install seeds `demo@dawarich.app` as admin. The role links it to the
Authentik account (`files/link_admin.rb`), so the first SSO login lands in it.

`secrets.yml`:

```yaml
dawarich_postgres_password: ""
dawarich_secret_key_base: ""
```

OIDC credentials: shared `vars/oidc_secrets.yml` ([Authentik](authentik.md#oidc-client-credentials)).

**Reverse Geocoding:**

-> Disable DNS Rate-limiting

## Service user

The app runs as the `dawarich` system user (911:911) via `PUID`/`PGID`: its
entrypoint starts as root, chowns `public`, `storage`, `tmp`, `db` and `log`, then
drops to that ID. Postgres and valkey stay on their image defaults.
