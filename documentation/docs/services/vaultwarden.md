# Vaultwarden

Port: `:80` (exposed, no host binding)

- https://github.com/dani-garcia/vaultwarden
- https://github.com/dani-garcia/vaultwarden/wiki

`secrets.yml`:

```yaml
vaultwarden_db_password: ""
vaultwarden_admin_token: ""
```

`vaultwarden_admin_token` must be an argon2id PHC string generated from the
plaintext admin password/token:

```bash
docker run --rm -it docker.io/vaultwarden/server:1.36.0 /vaultwarden hash
```

The generated PHC string is stored in SOPS and rendered into `.env` as
`VAULTWARDEN_ADMIN_TOKEN`. The plaintext password/token is not stored in the
repository.

## Access

Vaultwarden is routed through Anubis like the other public services. If
Bitwarden apps, browser extensions, CLI sync, or WebSocket notifications fail
because of the challenge page, change the Caddy route to bypass Anubis for this
service.

Only the `/admin` panel is gated by Authentik forward auth. The web vault is
zero-knowledge — the vault is encrypted client-side under the master password —
so it keeps its native authentication, as do Bitwarden apps, browser extensions,
CLI sync, and WebSocket notifications.

Authentik is an additional layer on `/admin`, not a replacement: after the
Authentik login you are still prompted for `VAULTWARDEN_ADMIN_TOKEN`.

The Caddy route also gates `/outpost.goauthentik.io/*`, which is where
`forward_auth` redirects unauthenticated browsers. Without it the login would
redirect into Vaultwarden and 404.

The Authentik provider/application/outpost assignment is managed by the
`proxy-apps.yaml` blueprint rendered by the Authentik role.

## Storage and Backup

Vaultwarden stores attachments, sends, icons, keys, and runtime config in the
named Docker volume `vaultwarden_data`. PostgreSQL stores database files in the
named Docker volume `vaultwarden_pgdata`.

For Backrest/restic backups, mount `vaultwarden_data` read-only into a backup
container/job and back up that mount path. For PostgreSQL, prefer a `pg_dump`
backup, or stop the stack before taking a filesystem-level backup of
`vaultwarden_pgdata`.
