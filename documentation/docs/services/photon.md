# Photon

Port: `:2322` (exposed, no host binding)

- https://github.com/rtuszik/photon-docker

Geocoding backend for [Dawarich](dawarich.md), which reaches it at
`photon.lan:2322`. Nothing else consumes it.

## Service user

Photon runs as the `photon` system user (907:907), set through `PUID`/`PGID`
rather than the `user:` directive the other stacks use. The image builds its own
`photon` user at 9011 and leaves `/photon` at mode 0750, so any other UID cannot
traverse it — a container started with `user: "907:907"` cannot even read its
own entrypoint. With `PUID`/`PGID` the entrypoint starts as root, remaps its
internal user to 907, fixes ownership, then drops privileges via `gosu`. Only
that startup shim is root; the Python supervisor and the Photon JVM run as 907.
