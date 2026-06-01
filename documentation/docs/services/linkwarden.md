# Linkwarden

Port: `:3000` (exposed, no host binding)

- https://docs.linkwarden.app/
- https://github.com/linkwarden/linkwarden

`secrets.yml`:

```yaml
linkwarden_nextauth_secret: ""
linkwarden_postgres_password: ""
linkwarden_meili_master_key: ""
linkwarden_authentik_issuer: ""
linkwarden_authentik_client_id: ""
linkwarden_authentik_client_secret: ""
```

## Upgrading Meilisearch

Meilisearch refuses to start when the on-disk database version differs from the engine version. After a Renovate tag bump that crosses a DB format change, the container exits on start:

```
Error: Your database version (1.12.8) is incompatible with your current engine version (1.45.1).
```

- https://www.meilisearch.com/docs/resources/migration/updating

Migrate in place with a dumpless upgrade (supported from v1.12 → v1.13+, no dump/restore). It is experimental and can corrupt the DB on failure, so back up first while the container is stopped:

```bash
docker compose -f /opt/stacks/linkwarden/docker-compose.yml stop linkwarden-meilisearch
cp -a /opt/stacks/linkwarden/meili_data /opt/stacks/linkwarden/meili_data.bak
```

Temporarily add the experimental flag to the `linkwarden-meilisearch` service in `files/docker-compose.yml`:

```yaml
environment:
  - MEILI_EXPERIMENTAL_DUMPLESS_UPGRADE=true
```

Deploy once. Meilisearch runs a one-way `UpgradeDatabase` task on start (begins immediately, can't be cancelled):

```bash
ansible-playbook services.yml --tags linkwarden
docker compose -f /opt/stacks/linkwarden/docker-compose.yml logs -f linkwarden-meilisearch
```

Wait until the container is healthy and the log shows the upgrade finished. Then **remove the flag again** (so it doesn't migrate on a future restart) and redeploy:

```bash
ansible-playbook services.yml --tags linkwarden
```

Once search works, drop the backup: `rm -rf /opt/stacks/linkwarden/meili_data.bak`.
