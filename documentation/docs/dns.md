# DNS (public domain)

Public DNS for `bl4ckspell.de` is managed with Terraform in `terraform/dns/`
(Hetzner `hcloud` provider). Internal resolution is a separate thing — see
[Network](./network.md).

The zone is deliberately tiny:

| Name     | Type | Value                               |
| -------- | ---- | ----------------------------------- |
| `@`      | A    | VPS front-door IP                   |
| `*`      | A    | VPS front-door IP                   |
| `@`      | MX   | `0 .` — receives no mail (RFC 7505) |
| `@`      | TXT  | `v=spf1 -all` — sends no mail       |
| `_dmarc` | TXT  | `v=DMARC1; p=reject; …`             |

**The wildcard means adding a service never touches DNS.** Everything reaches the
same VPS front-door, and Caddy's on-demand TLS mints a cert per hostname on first
request (restricted to this domain by the `:9000` ask-guard in `caddy-vps`).

`NS` and `SOA` are managed by Hetzner and are deliberately not in Terraform.

## Applying changes

```bash
scripts/tf-dns.sh init     # once
scripts/tf-dns.sh plan
scripts/tf-dns.sh apply
```

The wrapper decrypts the sops state, runs Terraform, re-encrypts it and shreds the
plaintext — from a trap, so it re-encrypts even when Terraform fails.

## Where things live

- **State**: `terraform/dns/terraform.tfstate.enc.json`, sops/age encrypted and
  committed. The plaintext `terraform.tfstate` is gitignored and must never be
  committed. There is **no state locking** — never run two applies at once.
- **API token**: `terraform/dns/secrets.yml` (sops), key `hcloud_token`. Declared
  `ephemeral` in Terraform, so it is never written to state.
- **VPS IP**: never committed. `scripts/vps-ip.sh` reads it from the `ionos-vps`
  entry in `~/.ssh/config` — the same source `inventory.yml` uses — and Terraform
  pulls it in through an `external` data source. If the IP ever changes, edit
  `~/.ssh/config` and re-apply; that is the only edit either tool needs.

## Adding a record

Add an `hcloud_zone_rrset` to `terraform/dns/main.tf` and apply. Note the zone
itself is adopted via the `import` block in `import.tf`, never created.
