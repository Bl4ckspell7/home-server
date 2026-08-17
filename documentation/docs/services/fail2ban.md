# fail2ban (VPS)

- https://github.com/fail2ban/fail2ban

Runs on the **VPS** (`roles/vps/fail2ban-vps`), not at home. The VPS is the internet
edge, so bans drop traffic before it crosses the WireGuard tunnel.

Anubis (at home) is a proof-of-work gate, not a rate limiter — it challenges, but
never stops repetition and never bans. fail2ban covers what it cannot.

## Jails

| Jail | Source | Trigger | Ban |
| --- | --- | --- | --- |
| `sshd` | journald | 4 failures / 10 min | 1h, escalating |
| `caddy-probe` | `/var/log/caddy/access.log` | 2 hits / 1h on `/.env`, `/.git/`, `/wp-`, … | 1h, escalating |
| `caddy-rate` | same log | 1200 requests / 1 min | 10 min, fixed |

Bans escalate (`bantime.increment`, factor 2, capped at 1w) — except `caddy-rate`,
which is a heuristic and stays at a fixed 10 minutes on purpose.

Anubis answers its challenge with **HTTP 200**, so status codes say nothing about
whether a request was blocked. The filters key on path and volume instead.

## The nftables hook matters

Caddy is a podman container with published ports, so netavark DNATs its traffic in
`nat hook prerouting` — it then traverses **forward**, never **input**. fail2ban's
stock nftables action hooks `input`, which would fill the ban set and report bans
while blocking nothing.

The jails therefore override it:

```
banaction = nftables[type=multiport, chain_hook=prerouting, chain_priority=-300, blocktype=drop]
```

`prerouting` at raw priority (-300) runs ahead of dstnat (-100), so one chain
covers both container ports and host services. Verify after any change:

```bash
nft list table inet f2b-table   # must say: hook prerouting priority raw
```

`type=multiport` (not `allports`) is a safety property: an HTTP jail bans only
80/443, so a false positive can never cut SSH and lock you out of the unban
command.

## Operating

```bash
fail2ban-client status                      # jails
fail2ban-client status caddy-probe          # counters + banned IPs
fail2ban-client set caddy-rate unbanip <IP>
fail2ban-client unban --all                 # panic button
```

Test a filter against the live log without waiting for an attack:

```bash
fail2ban-regex /var/log/caddy/access.log /etc/fail2ban/filter.d/caddy-probe.conf
```

## Tuning `caddy-rate`

Every device at home reaches these services through the public domain, so at the
VPS the **whole household is one source IP**. The 1200/min threshold is set well
above a normal burst (Immich sync, media-heavy page). To tighten it, measure first:

```bash
jq -r '.request.remote_ip' /var/log/caddy/access.log | sort | uniq -c | sort -rn | head
```

## Access log

Provided by `roles/vps/caddy-vps` (the `access_log` snippet), written to
`/var/log/caddy/access.log` as JSON with `iso8601` timestamps — fail2ban's
`datepattern` depends on that format. Caddy rolls the files itself (20 MiB × 5), so
there is no logrotate config. `remote_ip` is the true client: the VPS sets no
`trusted_proxies`. See [VPS front-door](./vps.md).
