# Pi-hole

Ports: `53:53`, `7080:80`, `7443:443`

- https://pi-hole.net/
- https://github.com/pi-hole/docker-pi-hole

`secrets.yml`:

```yaml
pihole_web_password: ""
pihole_mdns_hosts: [] # <host> names served as <host>.lan, see Network → mDNS names for containers
```
