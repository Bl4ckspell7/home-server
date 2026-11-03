# Immich

Port: `:2283` (exposed, no host binding)

- https://immich.app/docs/overview/quick-start
- https://github.com/immich-app/immich

`secrets.yml`:

```yaml
immich_postgres_password: ""
```

OIDC credentials: shared `vars/oidc_secrets.yml` ([Authentik](authentik.md#oidc-client-credentials)).

## Settings and login

- Settings live in `templates/immich.json.j2` (`IMMICH_CONFIG_FILE`), and the
  settings UI is read-only.
- Login is Authentik-only. For the login page, open `/auth/login?autoLaunch=0`.
- Admin rights come from the `immich_role` claim (`authentik Admins`).
