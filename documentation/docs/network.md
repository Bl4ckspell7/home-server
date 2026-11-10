# Network Configuration

Internal DNS and reverse proxy setup for the homeserver. The public zone for
`bl4ckspell.de` is managed separately with Terraform — see [DNS](./dns.md).

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

**Note:** `.lan` domains resolve to container IPs (172.21.255.x), which only work for container-to-container communication, plus the LAN hosts mirrored from mDNS (see [mDNS names for containers](#mdns-names-for-containers)). For external access from phones/laptops, use Caddy with public domains.

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

Check: `curl -4 ifconfig.io` on the host and `docker exec caddy wget -qO- ifconfig.io` both show a Proton IP; `wg show proton0` shows a recent handshake.

### Break-glass

Each of these turns the VPN off and leaves the config in place:

1. On the LAN: `ssh server systemctl disable --now wg-quick@proton0`
2. Off the LAN, through the VPS: `ssh -J ionos-vps root@10.10.0.2 systemctl disable --now wg-quick@proton0`
3. Ansible: `ansible-playbook -i inventory.yml server.yml --tags protonvpn -e '{"protonvpn_enabled": false}'`
4. No network at all: the same command on the console, or add `systemd.mask=wg-quick@proton0.service` to the kernel line in GRUB.

Back on: `systemctl enable --now wg-quick@proton0`, or run the role. A role run that (re)starts the tunnel arms a 5-minute timer that turns it off again (stopped and disabled) unless the run confirms the server is still reachable and the tunnel has a handshake.

ufw limits SSH to 6 new connections per 30 s and refuses the rest, so don't retry in quick succession.

New Proton server: download its WireGuard config, put key, peer key, endpoint and address into `roles/server/protonvpn/vars/secrets.yml` (`sops edit`), run the role.

## Caddy

**Container IP:** `172.21.255.238`  
**Ports:** `443/tcp`, `443/udp` (host-bound), `8080` (exposed internally for Anubis backend routing)

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
