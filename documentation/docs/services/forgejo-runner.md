# Forgejo Runner

Ports: none (outbound only — the runner polls Forgejo, nothing connects to it)

- https://code.forgejo.org/forgejo/runner
- https://forgejo.org/docs/latest/admin/actions/

## Design

- Separate stack from forgejo itself (`/opt/stacks/forgejo-runner`).
- Registered instance-wide as `svr1-runner`; instance URL is `http://forgejo.lan:3000` (direct via svr1-network + Pi-hole DNS, bypasses caddy/anubis).
- Job containers run inside a dedicated Docker-in-Docker daemon (`forgejo-runner-dind`), never on the host Docker socket — a compromised workflow only gets root inside the isolated dind container.
- dind's API is a unix socket on a volume shared with the runner (`--host=unix:///sock/docker.sock --group=904`) — no network listener at all, nothing for other containers to reach. dind still joins svr1-network, but only so job containers can NAT out to `forgejo.lan`.
- One label `docker` → default job image `node` (needed for JS actions like `actions/checkout`). Labels in `config.yml` are the source of truth — they override the registered labels at every daemon start; registration passes none.
- No secrets: the registration token is minted at deploy time via `forgejo actions generate-runner-token` inside the forgejo container.

## Registration

Automatic and idempotent on `/opt/stacks/forgejo-runner/data/.runner` (missing **or empty** → re-register). To force a re-registration:

```bash
rm /opt/stacks/forgejo-runner/data/.runner
```

then rerun the playbook (`--tags forgejo-runner`).

Registered runners: `https://forgejo.bl4ckspell.freeddns.org/admin/actions/runners`

## Using Actions in a repository

The Actions unit is **disabled by default per repository**. Enable it under
`Settings → Units → Overview → Enable Repository Actions` for each repo that
should run workflows (`.forgejo/workflows/*.yml`, `runs-on: docker`).
