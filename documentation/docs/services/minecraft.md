# Minecraft

Port: `10.10.0.2:25565` (tunnel address only)

- https://docker-minecraft-server.readthedocs.io/
- https://minecraft.wiki/w/Server.properties

Vanilla Java server at `mc.bl4ckspell.de`. The `*` A record points at the VPS, which listens on `30299/tcp` and forwards over WireGuard to svr1's `25565` (`roles/vps/minecraft-vps`); the home router stays closed. Bots sweep 25565, few scan `30299`. The SRV record `_minecraft._tcp.mc` (`terraform/dns`) hands the port to the client, so players type just the name. The port lives in `minecraft_public_port` (Ansible) and `minecraft_port` (Terraform); change both together. Online mode with an enforced whitelist. The container sits alone in the `svr1-game` zone, with Pi-hole for DNS and no Caddy, and may only reach the internet (see [Network → Docker networks](../network.md#docker-networks-zones)).

`30299/tcp` must also be open in the IONOS cloud firewall policy. That is set by hand in the IONOS panel, not by Terraform or Ansible; without it, every deploy reports OK but players time out.

`secrets.yml`:

```yaml
minecraft_whitelist:
  # PlayerName
  - 00000000-0000-0000-0000-000000000000
minecraft_ops:
  # PlayerName
  - 00000000-0000-0000-0000-000000000000
```

Use UUIDs: names are looked up at Mojang on every start, and a failed lookup (stale ProtonVPN tunnel, Mojang outage) keeps the server from starting. Get one with `curl -s https://api.mojang.com/users/profiles/minecraft/<name>` (the `id` without dashes works as well).

These lists are the whole truth (`SYNCHRONIZE`): a name removed here loses access on the next deploy. Ops join even when not whitelisted, so revoking access means removing the name from both lists.

## Console

```bash
docker exec -i minecraft rcon-cli
```

RCON (`25575`) is not published: only the host and the `svr1-game` zone reach it. The password is generated at each start and kept in `data/.rcon-cli.env`, which is why `data/` is `0750`. In a browser: Dockge or Dockhand, `minecraft` stack, for logs, and a container terminal for `rcon-cli`.

## Worlds

One world runs at a time: the folder that `level-name` in `data/server.properties` names. The compose file sets no `LEVEL`, so the image leaves that key alone and switching needs no deploy. Whitelist, ops and bans are shared. Game rules belong to each world (26.x names: `advance_time`, `advance_weather`).

Switch, or create a world under a new name (on svr1, in `/opt/stacks/minecraft`):

```bash
ls data/*/level.dat                       # existing worlds
sed -i 's/^level-name=.*/level-name=<name>/' data/server.properties
docker restart minecraft
```

For a new world, first set `level-seed=` (empty means random) and, if wanted, `level-type=` (e.g. `minecraft\:large_biomes`) in the same file. Both only apply when the folder is created. Delete a world by removing its folder while another one is active; there are no backups.

## Player IPs

The VPS masquerades the forward, so the server logs every player as `10.10.0.1`. The VPS kernel log has the real address of each new connection:

```bash
journalctl -k -g 'minecraft: '
```

Server list pings show up there too, so match a join to `docker logs minecraft` by its time. Each address gets 20 new connections a minute; the VPS drops the rest.

Ban an address at the VPS. The ban lasts until `minecraft-forward.service` restarts, and the nightly unattended-upgrades reboot (03:00) does that, so it is a stopgap:

```bash
nft add element ip minecraft ban '{ 192.0.2.1 timeout 7d }'
```

Permanent bans go by name: `ban <name>` in the console, or remove the player from the whitelist.

## Updates

Renovate bumps the image only. The game version is `VERSION` in the compose file and is raised by hand; players need the matching client version.
