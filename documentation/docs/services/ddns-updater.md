# ddns-updater

Port: `:8000` (exposed, no host binding)

- https://github.com/qdm12/ddns-updater

Fill `data/config.json` with correct data and encrypt with `sops encrypt --in-place data/config.json`.

Public route protected by Anubis + Authentik forward auth (no native auth). See [Authentik forward auth setup](./authentik.md#forward-auth-per-app).
