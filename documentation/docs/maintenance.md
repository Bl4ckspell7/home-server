---
sidebar_position: 6
---

# Maintenance

## Initial setup (one-time)

Renovate runs as a GitHub Action using the auto-provided `GITHUB_TOKEN` — no PAT or secret to create.

### 1. Allow Actions to write + create PRs

Repo → **Settings** → **Actions** → **General** → **Workflow permissions**:

- Select **Read and write permissions**
- Check **Allow GitHub Actions to create and approve pull requests**

### 2. Verify

Repo → **Actions** → **renovate** workflow → **Run workflow** → set `dryRun: full`, `logLevel: debug`. Inspect logs; expect no `401 Unauthorized` or `Bad credentials` errors and a "Found N dependencies" summary.

### Caveat: CI does not auto-run on Renovate PRs

PRs opened by `GITHUB_TOKEN` do not trigger other workflows (GitHub anti-loop). `compose-validate` shows no checks on Renovate PRs by default.

Before merging a Renovate PR, re-run validate manually: Repo → **Actions** → **compose-validate** → **Run workflow** → pick the Renovate branch.

If this manual step becomes tedious, switch to a classic PAT with `repo` + `workflow` scopes stored as `RENOVATE_TOKEN`, then change the workflow's `token:` value.

## Updates (Renovate)

Renovate opens PRs for Docker image updates daily (04:00 UTC).
Every update sits 2 days before a PR appears (`minimumReleaseAge`).

- **Digest / patch**: review CI, merge.
- **Minor**: review CI + skim upstream release notes, merge.
- **Major**: queued on the [Dependency Dashboard](https://github.com/Bl4ckspell7/home-server/issues?q=is%3Aissue+%22Dependency+Dashboard%22).
  Click approve → PR opens → use checklist below.
- **DB majors** (postgres, mariadb, mysql): disabled. Bump manually with a real upgrade plan.
- **Private registry** (`forgejo.bl4ckspell.freeddns.org`): disabled. Bump tag manually after pushing a new image.

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
