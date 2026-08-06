# ddns-updater

- https://github.com/qdm12/ddns-updater

Runs on the **VPS** (`roles/vps/ddns-updater-vps`, podman Quadlet), not at home. It detects the VPS public IP and keeps the `bl4ckspell.freeddns.org` A record (provider `dynu`) pointed at it — this is what points the domain at the front-door. See [VPS front-door](./vps.md).

Web UI disabled (`SERVER_ENABLED=false`); no public route.

Config lives in `roles/vps/ddns-updater-vps/files/data/config.json` — edit, then `sops encrypt --in-place` it.
