# Backrest

Port: `:9898` (exposed, no host binding)

- https://garethgeorge.github.io/backrest/
- https://github.com/garethgeorge/backrest

Web UI for restic backups. Behind Authentik forward-auth, then its own login.

`secrets.yml`:

```yaml
backrest_password_bcrypt: "" # base64 of the bcrypt hash, as in config.json
```

A fresh install gets `/config/config.json` seeded with that user, so there is no
setup wizard. After that Backrest owns the file, and Ansible never overwrites it.
Repos, plans and hooks (`forgejo dump`, `pg_dump`, …) are configured in the UI.

After a password change in the UI, refresh the seed so a rebuild keeps it:

```bash
ssh server 'python3 -c "import json; print(json.dumps(json.load(open(\"/opt/stacks/backrest/config/config.json\"))[\"auth\"][\"users\"][0][\"passwordBcrypt\"]))"' \
  | sops set --value-stdin roles/services/backrest/vars/secrets.yml '["backrest_password_bcrypt"]'
```
