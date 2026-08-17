# VPS (front-door)

IONOS VPS as a WireGuard + Caddy front-door: public DNS points at the VPS, not the home IP. Caddy terminates TLS and reverse-proxies to the home box over WireGuard, falling back to a landing page when home is unreachable.

Managed by the `vps` inventory group via `vps.yml` (roles under `roles/vps/`):

- `apt-vps` — podman, wireguard, nftables (Debian repos, no docker repo)
- `wireguard-vps` — native `wg0` (`10.10.0.1/24`) + `ip_forward` + NAT masquerade
- `caddy-vps` — podman Quadlet front-door, on-demand TLS, landing fallback
- `landing` — static "be right back" page → `/srv/landing`
- reuses [`ssh`](../ssh.md) from `roles/server`

The A record is a static Terraform-managed record — see [DNS](../dns.md). There is
no DDNS client: the VPS IP does not change.

The **home side** connects as an inbound-only WireGuard peer (`10.10.0.2/24`, `AllowedIPs=10.10.0.1/32`, keepalive) via `roles/server/wireguard` — default route untouched. Home Caddy sits behind this tunnel and serves a self-signed cert (`tls internal`); the VPS proxies to it with `tls_insecure_skip_verify`. See [Network](../network.md).

## Deploy

```bash
ansible-playbook -i inventory.yml vps.yml
```

## Secrets

Generate the WireGuard keys — one keypair per side plus a shared preshared key:

```bash
wg genkey | tee vps.key | wg pubkey    # VPS  private -> public
wg genkey | tee home.key | wg pubkey   # home private -> public
wg genpsk                              # preshared key
```

Put the VPS private key, the home public key and the PSK into
`roles/vps/wireguard-vps/vars/secrets.yml`, then encrypt:

```yaml
wg_vps_private_key: <vps.key>
wg_home_public_key: <home pubkey>
wg_preshared_key: <psk>
```

```bash
sops encrypt --in-place roles/vps/wireguard-vps/vars/secrets.yml
```

The home peer's `roles/server/wireguard/vars/secrets.yml` holds the mirror set (home private key, VPS public key, PSK, endpoint).

## Notes

- Container runtime: podman; Quadlet unit lives in `/etc/containers/systemd/`.
- No `ufw` — filtered at the IONOS firewall (`22`, `80`, `443`, `51820/udp`).
- On-demand TLS issues certs per host once DNS points at the VPS; until then Caddy serves `landing`.
