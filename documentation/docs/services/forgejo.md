# Forgejo

Ports: `3000:3000`, SSH: `2222` (exposed internally only, no router port forward)

- https://forgejo.org/docs/latest/
- https://codeberg.org/forgejo/forgejo

`secrets.yml`:

```yaml
forgejo_db_password: ""
```

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
