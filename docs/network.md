# Network Configuration

DNS and reverse proxy setup for the homeserver.

## DNS Flow

```
Phone/Device (192.168.178.x)
    ↓
Server (192.168.178.117:53)
    ↓
Pi-hole (172.21.255.254) ─── Ad-blocking & .lan resolution
    ↓
Docker DNS (127.0.0.11)
    ↓
systemd-resolved ─── DNSSEC validation & caching
    ↓
DNS.SB / Cloudflare ─── DNS-over-TLS (port 853)
```

## systemd-resolved

**Config:** `/etc/systemd/resolved.conf`

```ini
[Resolve]
DNS=185.222.222.222#dot.sb 45.11.45.11#dot.sb
FallbackDNS=1.1.1.1#one.one.one.one 1.0.0.1#one.one.one.one
DNSOverTLS=yes
DNSSEC=yes
Cache=yes
DNSStubListener=yes
ReadEtcHosts=yes
Domains=lan
```

Provides DNS-over-TLS to upstream providers (DNS.SB, Cloudflare) with DNSSEC validation.

## Pi-hole

Provides ad-blocking and local `.lan` domain resolution. Uses Docker's embedded DNS (`127.0.0.11`) as upstream, which forwards to systemd-resolved.

Pi-hole serves as the DNS server for:

-  **Docker containers** (via [Docker's embedded DNS](https://docs.docker.com/engine/network/#dns-services))
- **Local network devices** (phones, laptops, etc. - set DNS to `192.168.178.117`)

**Key config:**

```yaml
FTLCONF_dns_upstreams: |
  127.0.0.11
FTLCONF_dns_hosts: |
  172.21.255.254 pihole.lan
  172.21.255.253 authentik.lan
  # ... other services
```

**Note:** `.lan` domains resolve to container IPs (172.21.255.x), which only work for container-to-container communication. For external access from phones/laptops, use Nginx Proxy Manager with public domains or `server-ip:port`.

## Nginx Proxy Manager

**Container IP:** `172.21.255.249`  
**Access:** `http://192.168.178.117:81`

Handles reverse proxy and SSL termination for services. Routes external traffic to internal container IPs.

Example: `https://immich.example.com` → NPM → `http://172.21.255.243:80`
