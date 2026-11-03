# Forgejo

Port: HTTP `3000` (internal only). The web UI offers HTTPS cloning only; SSH is disabled.

- https://forgejo.org/docs/latest/
- https://codeberg.org/forgejo/forgejo

`secrets.yml`:

```yaml
forgejo_db_password: ""
forgejo_secret_key: "" # 64 alphanumeric characters
```

## Secret key

Don't change `forgejo_secret_key`: TOTP, Actions secrets and mirror addresses
become unreadable, with no re-encrypt tool. To rotate anyway, back up, deploy,
then:

- mirrors: `UPDATE mirror SET encrypted_remote_address = NULL;` and sync
  (Forgejo re-reads the address from git config)
- Actions secrets: set them again
- TOTP: `DELETE FROM two_factor WHERE uid = <id>;`

## Backup

Run the backup script as root on the server:

```bash
bash /opt/stacks/forgejo/backup.sh
```

This stops Forgejo, dumps the PostgreSQL database, archives everything (git repos, config, database dump) into a single `.tar.gz`, and restarts Forgejo. Backups are saved to `/opt/stacks/forgejo/backup/`.

To restore from a backup:

```bash
docker compose -f /opt/stacks/forgejo/docker-compose.yml down
tar xzf /opt/stacks/forgejo/backup/forgejo-backup-XXXXXXXX-XXXXXX.tar.gz -C /opt/stacks/forgejo
docker compose -f /opt/stacks/forgejo/docker-compose.yml up -d forgejo-postgres
sleep 3
docker exec forgejo-postgres dropdb -U forgejo forgejo
docker exec forgejo-postgres createdb -U forgejo forgejo
docker exec -i forgejo-postgres psql -U forgejo -d forgejo < /opt/stacks/forgejo/forgejo-db.sql
docker compose -f /opt/stacks/forgejo/docker-compose.yml up -d
```
