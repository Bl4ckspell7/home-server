# Dawarich

Port: `:3000` (exposed, no host binding)

- https://dawarich.app/docs/intro
- https://github.com/Freika/dawarich

Email/password login and registration are disabled. Authentik OIDC is the only
interactive login method, with automatic registration for authorized users.

`secrets.yml`:

```yaml
dawarich_postgres_password: ""
authentik_client_id: ""
authentik_client_secret: ""
```

**Reverse Geocoding:**

-> Disable DNS Rate-limiting
