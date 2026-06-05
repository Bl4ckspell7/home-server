# Backrest

Port: `:9898` (exposed, no host binding)

- https://garethgeorge.github.io/backrest/
- https://github.com/garethgeorge/backrest

Web UI for restic backups. Admin login and restic repo passwords are set in the UI on first run (stored in `/config/config.json`); no ansible secrets needed.

Backup jobs for other services (source mounts, restic repos, pre-backup hooks such as `forgejo dump` / `pg_dump`) are configured later in the UI.
