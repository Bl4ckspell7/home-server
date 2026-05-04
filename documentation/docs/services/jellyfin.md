# Jellyfin

Port: `:8096` (exposed, no host binding)

- https://jellyfin.org/docs/
- https://github.com/jellyfin/jellyfin

Permissions are automatically enforced on media directories by a dedicated watcher script and corresponding `systemd` service. These ensure correct ownership (`jellyfin:jellyfin`) and access permissions are maintained continuously.
