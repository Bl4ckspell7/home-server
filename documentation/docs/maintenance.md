---
sidebar_position: 6
---

# Maintenance

## Initial setup (one-time)

Renovate runs as a GitHub Action authenticated with a fine-grained PAT stored as the `RENOVATE_TOKEN` secret. The auto-provided `GITHUB_TOKEN` cannot be used: GitHub refuses pushes that modify `.github/workflows/*` from it (no `workflows` permission), so updates to Actions and the Renovate image would never get branches. PRs opened with `GITHUB_TOKEN` would also not trigger `compose-validate` / `ansible-validate`.

### 1. Create the fine-grained PAT

GitHub → **Settings** → **Developer settings** → **Personal access tokens** → **Fine-grained tokens** → **Generate new token**:

- Resource owner: `Bl4ckspell7`; Repository access: **Only select repositories** → `home-server`
- Expiration: at most 1 year
- Repository permissions, **Read and write**: Contents, Pull requests, Issues, Workflows, Commit statuses
- Repository permissions, **Read-only**: Dependabot alerts (Metadata read is added automatically)

### 2. Store it as a secret

Repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret** → name `RENOVATE_TOKEN`.

The workflow's own `GITHUB_TOKEN` only checks out the repo (`contents: read`), so **Allow GitHub Actions to create and approve pull requests** under **Settings** → **Actions** → **General** can stay disabled.

### 3. Verify

Repo → **Actions** → **renovate** workflow → **Run workflow** → set `dryRun: full`, `logLevel: debug`. Inspect logs; expect no `401 Unauthorized` or `Bad credentials` errors, no `refusing to allow a GitHub App to create or update workflow`, and a "Found N dependencies" summary.

### Token rotation

When the PAT expires, Renovate runs fail with `401 Unauthorized` / `Bad credentials`. Regenerate the token (same permissions) and update the `RENOVATE_TOKEN` secret.

## Host OS updates (unattended-upgrades)

Both hosts patch themselves. `roles/server/unattended-upgrades` installs
`unattended-upgrades` + `needrestart` and is wired into `server.yml` and
`vps.yml` with different reboot policies.

Two update tracks, opposite priorities: Renovate patches **containers** with a
2-day soak, unattended-upgrades patches the **host OS** with no soak.

### What installs automatically

Debian security origins only:

```
origin=Debian,codename=${distro_codename}-security,label=Debian-Security
```

`needrestart` runs in automatic mode (`$nrconf{restart} = 'a'`), so daemons
linking against a patched library are restarted in place. Container runtimes are
excluded from that (`docker`/`containerd` on svr1, `caddy` on the VPS):
container processes use libraries from their image, not from the host, so
restarting them patches nothing.

### Reboot policy

| Host | Upgrade window                   | Reboot                                                                                                                                                                                                                                                      |
| ---- | -------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| svr1 | 04:00, with catch-up after boot | No scheduled reboot. The nightly power-off applies the new kernel. `unattended-reboot.timer` fires at 05:00 **only if the host is still running** (`Persistent=false`, no catch-up) — the vacation case. 5-minute wall warning, `sudo shutdown -c` cancels. |
| VPS  | 02:30                            | `Automatic-Reboot` at 03:00, users or not.                                                                                                                                                                                                                  |

Only kernel upgrades request a reboot: the marker `/run/reboot-required` is
written by `/etc/kernel/postinst.d/unattended-upgrades`. Everything else is
covered by the needrestart daemon restart.

### Checking

```bash
systemctl list-timers apt-daily.timer apt-daily-upgrade.timer unattended-reboot.timer
sudo unattended-upgrade --dry-run --debug | tail -30
journalctl -u apt-daily-upgrade.service --since -7d
cat /run/reboot-required.pkgs 2>/dev/null   # why a reboot is pending
sudo needrestart -b -r l                    # what still needs a restart
```

The Ansible role runs the dry-run and the needrestart parse check itself, so a
config that fails to parse fails the play rather than silently skipping the next
upgrade run.

## Updates (Renovate)

Renovate opens PRs for Docker image updates daily (04:00 UTC).
Every update sits 2 days before a PR appears (`minimumReleaseAge`).

- **Digest / patch**: review CI, merge.
- **Minor**: review CI + skim upstream release notes, merge.
- **Major**: queued on the [Dependency Dashboard](https://github.com/Bl4ckspell7/home-server/issues?q=is%3Aissue+%22Dependency+Dashboard%22).
  Click approve → PR opens → use checklist below.
- **DB majors** (postgres, mariadb, mysql): disabled. Bump manually with a real upgrade plan.
- **Private registry** (`forgejo.bl4ckspell.de`): disabled. Bump tag manually after pushing a new image.

## Major PR checklist

Before merging a major version PR:

- [ ] Read upstream release notes (Renovate links them in PR body)
- [ ] Diff our `docker-compose.yml` against upstream's reference compose
- [ ] Check for new required env vars → update `vars/secrets.yml` + `.env.j2`
- [ ] Check for new/removed services in the stack
- [ ] Check for volume path or schema changes (data migration?)
- [ ] Run `ansible-playbook services.yml --tags <service> --check` first
- [ ] Have a rollback plan: previous tag + volume backup

## Update intervals

| Type          | Cooldown | Auto-PR            | Merge              |
| ------------- | -------- | ------------------ | ------------------ |
| Digest re-tag | 2 days   | yes                | manual             |
| Patch         | 2 days   | yes                | manual             |
| Minor         | 2 days   | yes                | manual             |
| Major         | 2 days   | dashboard approval | manual + checklist |
| DB major      | —        | disabled           | manual             |
| CVE fix       | none     | yes                | manual (priority)  |
