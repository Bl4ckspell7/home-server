# Jellyfin

Port: `:8096` (exposed, no host binding)

- https://jellyfin.org/docs/
- https://github.com/jellyfin/jellyfin

`jellyfin-watch.service` hands every new file or folder in the media directories to `jellyfin:jellyfin`, since uploads arrive root-owned and Jellyfin saves metadata, subtitles and trickplay next to the media. It fixes only the new path, never the whole tree, and changes ownership only (no chmod, never through a symlink). `jellyfin-permissions.timer` sweeps the tree daily for paths the watcher missed; `sudo jellyfin-set-permissions.sh` runs the same sweep by hand.
