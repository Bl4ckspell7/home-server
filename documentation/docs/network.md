# Network Configuration

Internal DNS and reverse proxy setup for the homeserver. The public zone for
`bl4ckspell.de` is managed separately with Terraform — see [DNS](./dns.md).

## DNS Flow

```
host (resolv.conf)  → 127.0.0.54:53        ─┐
Docker containers   → 172.28.<zone>.254:53 ─┴─→ Pi-hole (caching, filtering, mDNS .lan)
                                                  ↓
                                            172.28.1.1:5354 → dnscrypt-proxy
                                                  ↓
                                            DNSCrypt / DoH → quad9 via anonymized relays
                                                            (anon-cs-de, -dus, -berlin)
```

## dnscrypt-proxy

**Config:** `/etc/dnscrypt-proxy/dnscrypt-proxy.toml` (deployed by `roles/server/dns/`)

Native (apt) install — no official Docker image for the client. Replaces systemd-resolved as the host's encrypted DNS layer.

Binds to the `svr1-edge` bridge gateway on a **non-privileged port** (`172.28.1.1:5354`) so the daemon (which runs as `_dnscrypt-proxy`, non-root) can `bind()` directly — no systemd socket activation needed. Anonymized DNSCrypt routes hide the client IP from the upstream resolver.

```toml
listen_addresses = ['172.28.1.1:5354']
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

Binding `172.28.1.1` before docker brings the bridge up is enabled by `net.ipv4.ip_nonlocal_bind = 1` (see `roles/server/sysctl/tasks/main.yml`). Resolver + relay lists auto-refreshed from `DNSCrypt/dnscrypt-resolvers`.

systemd-resolved is stopped, disabled and masked. `/etc/resolv.conf` is a static file pointing at **`127.0.0.54`** (pi-hole), so the host itself goes through the same filtering + encrypted-upstream chain as containers.

UFW allows `5354/udp` and `5354/tcp` to the host from Pi-hole (`172.28.1.254`) only; every other container asks Pi-hole (see `roles/server/ufw/tasks/main.yml`).

## Pi-hole

Provides ad-blocking, caching, and `.lan` names for LAN hosts. Upstream points to dnscrypt-proxy at `172.28.1.1#5354`. Two listen surfaces:

- `127.0.0.54:53` — the host itself (via `/etc/resolv.conf`)
- `172.28.<zone>.254:53` — Docker containers; Pi-hole joins every zone, and each container's `dns:` is the `.254` of its zone

Pi-hole serves as the DNS server for:

- **Docker containers** (via [Docker's embedded DNS](https://docs.docker.com/engine/network/#dns-services))
- **Local network devices** (phones, laptops, etc. - set DNS to `192.168.178.117`)

**Key config:**

```yaml
FTLCONF_dns_upstreams: |
  172.28.1.1#5354
# explicit: pihole.toml keeps an old list once the variable is gone
FTLCONF_dns_hosts: ""
```

**Note:** container `.lan` names are Docker network aliases, not Pi-hole entries (see [Docker networks](#docker-networks-zones)). Docker's embedded DNS answers them only inside the zone, so they don't resolve on the host or the LAN: test with `docker exec <container> nslookup immich.lan`. Pi-hole only serves the LAN hosts mirrored from mDNS as `.lan` (see [mDNS names for containers](#mdns-names-for-containers)). For access from phones/laptops, use Caddy with public domains.

## Docker networks (zones)

Containers only reach each other inside a shared zone network; Docker isolates the zones from each other. Created by `roles/server/docker/` (`docker_zones`), each a /24 whose lower half Docker assigns dynamically, so fixed IPs go in the upper half.

| Network | Subnet | Members |
| --- | --- | --- |
| `svr1-edge` | 172.28.1.0/24 | caddy, anubis, authentik |
| `svr1-apps` | 172.28.2.0/24 | homepage, immich, jellyfin, paperless, vaultwarden, radicale, docs, dawarich, photon |
| `svr1-admin` | 172.28.3.0/24 | dockge, dockhand, backrest (root-equivalent) |
| `svr1-llm` | 172.28.4.0/24 | llamacpp, openwebui, searxng, linkwarden |
| `svr1-ci` | 172.28.5.0/24 | forgejo, forgejo-runner, its dind |

- **Caddy and Pi-hole join every zone:** Caddy proxies to all services, Pi-hole answers DNS at `.254` in each.
- **Names:** each service sets the alias `<name>.lan` on its zone network; Caddy has `caddy.lan` in every zone, Pi-hole `pihole.lan` in `svr1-admin`.
- **Fixed IPs**, only where something checks the address: Pi-hole `.254` (`dns:`), Anubis `172.28.1.236` and Homepage `172.28.2.246` (Caddy's listener guards).
- **Stack-internal networks** (databases, caches, workers) stay per stack.
- **New service:** pick the zone by who must reach it, then join that network with an alias, `dns: [172.28.<zone>.254]` and `dns_search: ["."]`.

## mDNS (svr1.local)

The server's LAN address changes with the router's DHCP, so `inventory.yml` and `~/.ssh/config` use `svr1.local` instead of an IP. avahi publishes that name over mDNS (`roles/server/avahi/`):

- **Interface:** `allow-interfaces` limits avahi to `lan_interface` (`lan0`) and `wifi_interface` (`wlp4s0`), both set in `server.yml`, so it stays off the Docker bridges.
- **Stable NIC name:** `roles/server/nic/` writes `/etc/systemd/network/10-nic.link`, which names the LAN card `lan0` by its permanent MAC (read from the one physical ethernet card, not the default route, which on the hotspot is the wifi card). The name sits outside udev's predictable names (`enp5s0` stays as an altname), so PCI bus renumbering, a BIOS update, a new udev naming scheme or another card can't take it — any of these would break both avahi and Wake-on-LAN. A changed name applies on the next boot. Check with `udevadm info /sys/class/net/lan0 | grep ID_NET_LINK_FILE`.
- **Firewall:** UFW allows UDP 5353 to `224.0.0.251` (see `roles/server/ufw/tasks/main.yml`). IPv4 only, since IPv6 is off (see below).
- **Clients:** the workstation resolves `.local` through `nss-mdns` (`mdns4_minimal` in `/etc/nsswitch.conf`). Test with `avahi-resolve -n4 svr1.local`.

If another host on the LAN also announces `svr1`, avahi renames this one to `svr1-2.local` and Ansible loses it; check `journalctl -u avahi-daemon`.

### mDNS names for containers

Containers can't resolve `.local`, and Pi-hole (dnsmasq) can't do mDNS either. `pihole-mdns-hosts.timer` (`roles/services/pi-hole/`) runs every 30 s, resolves each name in the sops list `pihole_mdns_hosts` through the host's avahi, and writes `<ip> <host>.lan` to `/opt/stacks/pi-hole/mdns-hosts/mdns.hosts`. Pi-hole loads that file via `addn-hosts`. On a change the updater runs `pihole reloaddns`, so a `.lan` name trails a new address by at most ~30 s. A failed lookup (host off, wifi dropout) keeps the last known address for up to 10 min, then the name is dropped. These names share the `.lan` namespace with the container names, so pick no host whose name matches a container. This works on any network the host's avahi listens on; Pi-hole no longer forwards to the FritzBox, whose `fritz.box` names and single-label lookups failed whenever it was not the router.

Pi-hole answers `.local` itself (`local=/local/`), so those queries never leave the host. This also matters for the host: nss-mdns asks unicast DNS for the `local.` SOA before every mDNS lookup, and a slow answer there delays every `.local` name.

Check: `cat /opt/stacks/pi-hole/mdns-hosts/mdns.hosts`, `systemctl list-timers pihole-mdns-hosts.timer`, `journalctl -u pihole-mdns-hosts.service` (logs only changes and failures).

## Wifi

On the phone hotspot the server runs on wifi (`wlp4s0`), often with a weak signal. With power save on, the card dozes, misses frames and the server drops off the network for minutes. So `roles/server/wifi/` turns it off: `/etc/NetworkManager/conf.d/wifi-powersave.conf` (`wifi.powersave=2`) covers every wifi profile left at `802-11-wireless.powersave=default` from its next activation, and `iw` switches the running device off right away. Check with `iw dev wlp4s0 get power_save`.

## IPv6

IPv6 is off on the server, in two layers:

- **sysctl** (`roles/server/sysctl/`): `/etc/sysctl.d/99-disable-ipv6.conf` sets `disable_ipv6 = 1` for `all`, `default` and `lo`. This covers every interface NetworkManager doesn't configure: `lo`, `docker0`, the Docker bridges and `wg0` (all shown as "connected (externally)" in `nmcli device`).
- **NetworkManager** (`roles/server/nic/`, `roles/server/wifi/`): NetworkManager re-enables IPv6 on interfaces it configures, which would override the sysctl, and `NetworkManager.conf` has no global default for `ipv6.method`. So the LAN NIC's connection profile and every wifi profile are set to `ipv6.method=disabled`. The LAN profile is only handled while the cable is connected, so a run on the hotspot skips it; the next run on the LAN applies it.

Docker runs with `enable_ipv6: false`, dnscrypt-proxy with `block_ipv6 = true`, avahi with `use-ipv6=no`, and the WireGuard endpoint is IPv4. The kernel option `ipv6.disable=1` is deliberately not used: it removes IPv6 sockets entirely, so services that only listen on `::` (Dawarich's `-b ::`) would fail to start.

Check: `sysctl net.ipv6.conf.lan0.disable_ipv6` should be `1` and `ip -6 addr` empty.

## ProtonVPN (outbound)

All outbound traffic of the host and of every container leaves through ProtonVPN (`proton0`, `roles/server/protonvpn/`), so the home IP stays hidden for outbound traffic too. `wg-quick` only adds a default route in its own table, so anything with a more specific route stays off the tunnel: the LAN (SSH, pi-hole clients, mDNS), the Docker bridges and the front-door tunnel `wg0`. `wg0` carries the same firewall mark as `proton0`, which makes it reach the VPS directly.

MTU is 1280 so the tunnel fits through any uplink; forwarded container TCP gets its MSS clamped to match. The Proton config's `DNS` line is left out: DNS stays pi-hole → dnscrypt-proxy, and those upstream queries exit through the tunnel.

There is no killswitch. While `proton0` is up, a dead Proton server blocks outbound traffic rather than leaking; with the unit stopped the server uses the normal uplink.

Five German servers rank equal (`protonvpn_peers`, all sharing one key). Each tunnel start picks one at random (`PostUp` → `/usr/local/sbin/protonvpn-peer pick`); `protonvpn-peer switch` hops to another by hand. The `[Peer]` in `proton0.conf` is only a placeholder for wg-quick's routing: a bare `wg syncconf` from that file removes the server and stops all egress, so use `systemctl reload wg-quick@proton0`, which puts a server back.

Watchdog: `protonvpn-watchdog.timer` checks the handshake every minute. When it is older than 180 s (rekey is every 120 s), the watchdog first changes the source port, then switches to a random untried server each minute until one answers. It uses only `wg set`, because a unit restart would briefly leak egress via the uplink. It idles while the unit is stopped or a role run is verifying a restart.

Check: `curl -4 ifconfig.io` on the host and `docker exec caddy wget -qO- ifconfig.io` both show a Proton IP; `wg show proton0` shows a recent handshake; `journalctl -t protonvpn-peer -t protonvpn-watchdog` shows the server in use and any healing.

### Break-glass

Each of these turns the VPN off and leaves the config in place:

1. On the LAN: `ssh server systemctl disable --now wg-quick@proton0`
2. Off the LAN, through the VPS: `ssh -J ionos-vps root@10.10.0.2 systemctl disable --now wg-quick@proton0`
3. Ansible: `ansible-playbook -i inventory.yml server.yml --tags protonvpn -e '{"protonvpn_enabled": false}'`
4. No network at all: the same command on the console, or add `systemd.mask=wg-quick@proton0.service` to the kernel line in GRUB.

Back on: `systemctl enable --now wg-quick@proton0`, or run the role. A role run that (re)starts the tunnel arms a 5-minute timer that turns it off again (stopped and disabled) unless the run confirms the server is still reachable and the tunnel has a handshake.

ufw limits SSH to 6 new connections per 30 s and refuses the rest, so don't retry in quick succession.

Change servers: edit `protonvpn_peers` in `roles/server/protonvpn/vars/secrets.yml` (`sops edit`), run the role; it moves off a server that left the list. Name, public key and entry IP (endpoint `<ip>:51820`) come from the Proton CLI's cache on svr1, `/var/cache/Proton/VPN/serverlist.json` (after `protonvpn signin`, `protonvpn cities list DE` refreshes it). Take the entry whose `EntryCountry` is `DE`: the same node also appears behind Secure Core with a foreign entry IP. Private key and address stay; only a new key needs a dashboard WireGuard config.

## Caddy

**Networks:** every zone, as `caddy.lan`  
**Ports:** `443/tcp`, `443/udp` (host-bound), `8080` (internal, Anubis only, routes to the backends), `8081` (internal, Homepage only, status checks)

Homepage's tiles ask `http://caddy.lan:8081/status/<name>`, since Homepage itself only sits in `svr1-apps`. Caddy requests the service's health path and answers with its status code only, never its body.

Reverse proxy for all services. Home Caddy no longer faces the internet directly — it sits behind the [VPS front-door](./services/vps.md) and is reached only over the WireGuard tunnel. It terminates TLS with a **self-signed internal cert** (`tls internal`); public Let's Encrypt certs are issued on the VPS instead, since home accepts no inbound WAN traffic and can't answer ACME challenges.

External traffic flow:

```
internet
  → VPS Caddy (:443, Let's Encrypt)
  → WireGuard (10.10.0.1 → 10.10.0.2)
  → home Caddy (:443, tls internal)
  → Anubis (PoW protection)
  → home Caddy (:8080)
  → http://immich.lan:2283
```

The FritzBox has **no port-forwards** — the residential IP is off DNS entirely, and public DNS resolves to the VPS. See [VPS front-door](./services/vps.md) for the tunnel + landing-page setup.
