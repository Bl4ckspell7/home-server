# Network Configuration

DNS and reverse proxy setup for the homeserver.

## DNS Flow

```
host (resolv.conf)  → 127.0.0.54:53        ─┐
Docker containers   → 172.21.255.254:53    ─┴─→ Pi-hole (caching, filtering, .lan)
                                                  ↓
                                            172.21.0.1:5354 → dnscrypt-proxy
                                                  ↓
                                            DNSCrypt / DoH → quad9 via anonymized relays
                                                            (anon-cs-de, -dus, -berlin)
```

## dnscrypt-proxy

**Config:** `/etc/dnscrypt-proxy/dnscrypt-proxy.toml` (deployed by `roles/server/dns/`)

Native (apt) install — no official Docker image for the client. Replaces systemd-resolved as the host's encrypted DNS layer.

Binds to the svr1-network bridge gateway on a **non-privileged port** (`172.21.0.1:5354`) so the daemon (which runs as `_dnscrypt-proxy`, non-root) can `bind()` directly — no systemd socket activation needed. Anonymized DNSCrypt routes hide the client IP from the upstream resolver.

```toml
listen_addresses = ['172.21.0.1:5354']
server_names = ['quad9-dnscrypt-ip4-filter-pri']
dnscrypt_servers = true
require_nolog = true
require_dnssec = false
ipv4_servers = true
ipv6_servers = false
block_ipv6 = true
cache = true
cache_size = 8192
cache_min_ttl = 3600
cache_max_ttl = 259200
cache_neg_min_ttl = 60
cache_neg_max_ttl = 600
bootstrap_resolvers = ['9.9.9.9:53', '1.1.1.1:53']
ignore_system_dns = true

[anonymized_dns]
routes = [
  { server_name = 'quad9-dnscrypt-ip4-filter-pri', via = ['anon-cs-de', 'anon-cs-dus', 'anon-cs-berlin'] }
]
```

Debian trixie ships dnscrypt-proxy `2.1.8`. HTTP/3 and the `[monitoring_ui]` block require ≥ 2.1.10 / 2.1.13 respectively, so they're omitted here. Available again if the package is updated (e.g. via backports / forky pin).

Binding `172.21.0.1` before docker brings the bridge up is enabled by `net.ipv4.ip_nonlocal_bind = 1` (see `roles/server/sysctl/tasks/main.yml`). Resolver + relay lists auto-refreshed from `DNSCrypt/dnscrypt-resolvers`.

systemd-resolved is stopped, disabled and masked. `/etc/resolv.conf` is a static file pointing at **`127.0.0.54`** (pi-hole), so the host itself goes through the same filtering + encrypted-upstream chain as containers.

UFW must allow `53/udp` and `53/tcp` from `172.21.0.0/16` to the host (see `roles/server/ufw/tasks/main.yml`).

## Pi-hole

Provides ad-blocking, caching, and local `.lan` domain resolution. Upstream points to dnscrypt-proxy at `172.21.0.1#5354`. Two listen surfaces:

- `127.0.0.54:53` — the host itself (via `/etc/resolv.conf`)
- `172.21.255.254:53` — Docker containers on `svr1-network`

Pi-hole serves as the DNS server for:

- **Docker containers** (via [Docker's embedded DNS](https://docs.docker.com/engine/network/#dns-services))
- **Local network devices** (phones, laptops, etc. - set DNS to `192.168.178.117`)

**Key config:**

```yaml
FTLCONF_dns_upstreams: |
  172.21.0.1
FTLCONF_dns_hosts: |
  172.21.255.254 pihole.lan
  172.21.255.253 authentik.lan
  # ... other services
```

**Note:** `.lan` domains resolve to container IPs (172.21.255.x), which only work for container-to-container communication. For external access from phones/laptops, use Caddy with public domains.

## Caddy

**Container IP:** `172.21.255.238`  
**Ports:** `443/tcp`, `443/udp` (host-bound), `8080` (exposed internally for Anubis backend routing)

Handles reverse proxy and automatic SSL termination (via Let's Encrypt) for services. External traffic hits Caddy on port 443, which routes through Anubis for PoW protection, then to the backend service via `.lan` DNS.

Example: `https://immich.bl4ckspell.freeddns.org` → Caddy (:443) → Anubis → Caddy (:8080) → `http://immich.lan:2283`
