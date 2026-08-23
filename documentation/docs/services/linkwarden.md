# Linkwarden

Port: `:3000` (exposed, no host binding)

- https://docs.linkwarden.app/
- https://github.com/linkwarden/linkwarden

`secrets.yml`:

```yaml
linkwarden_nextauth_secret: ""
linkwarden_postgres_password: ""
linkwarden_meili_master_key: ""
linkwarden_authentik_client_id: ""
linkwarden_authentik_client_secret: ""
```

The Authentik issuer is derived from `BASE_DOMAIN` in `docker-compose.yml`.
Public registration and username/password login are disabled; users authorized
by Authentik can still be provisioned on their first SSO login.

## Service user

Linkwarden runs as the `linkwarden` system user (908:908) via `user:`, which
the image supports since
[v2.16.1](https://github.com/linkwarden/linkwarden/releases/tag/v2.16.1)
([non-root guide](https://docs.linkwarden.app/self-hosting/non-root)).

Only the app container gets it — postgres and meilisearch stay on their image
defaults, as in the other multi-container stacks. Upstream sets `user:` on all
three.

## Upgrading Meilisearch

Meilisearch refuses to start when the on-disk database version differs from the engine version. After a Renovate tag bump that crosses a DB format change, the container exits on start:

```
Error: Your database version (1.50.0) is incompatible with your current engine version (1.53.1).
```

- https://www.meilisearch.com/docs/resources/migration/updating

Migrate in place with a dumpless upgrade. It is not atomic and can corrupt the DB on failure, so back up first while the container is stopped:

```bash
docker compose -f /opt/stacks/linkwarden/docker-compose.yml stop linkwarden-meilisearch
cp -a /opt/stacks/linkwarden/meili_data /opt/stacks/linkwarden/meili_data.bak
```

Temporarily add the upgrade flag to the `linkwarden-meilisearch` service in `files/docker-compose.yml`:

```yaml
environment:
  - MEILI_UPGRADE_DB=true
```

Deploy once. Meilisearch runs a one-way `UpgradeDatabase` task on start (begins immediately, can't be cancelled):

```bash
ansible-playbook services.yml --tags linkwarden
docker compose -f /opt/stacks/linkwarden/docker-compose.yml logs -f linkwarden-meilisearch
```

Once the container is healthy and the log shows the upgrade finished, **remove the flag again** and redeploy — otherwise a future bump auto-migrates on restart with no backup:

```bash
ansible-playbook services.yml --tags linkwarden
```

Then drop the backup: `rm -rf /opt/stacks/linkwarden/meili_data.bak`.
