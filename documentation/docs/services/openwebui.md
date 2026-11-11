# Open WebUI

Port: `:3000` (exposed, no host binding)

- https://docs.openwebui.com/
- https://github.com/open-webui/open-webui

Authentik OIDC is the only login. Admin follows `authentik Admins`, anyone else
lands as pending.

## Models

- **llama.cpp on the desktop** (`linux-docker-config` `roles/llamacpp`, GPU) by its
  `.lan` name, which Pi-hole mirrors from mDNS (see
  [Network](../network.md#mdns-names-for-containers)), so it works on any router.
  Listed only while the desktop is on. Both repos hold the same `llamacpp_api_key`
  in sops.
- **llama.cpp** here (CPU, always on), see [llama.cpp](llamacpp.md).

`secrets.yml`:

```yaml
llamacpp_api_key: "" # same value as the desktop's roles/llamacpp/vars/secrets.yml
llamacpp_base_url: "" # http://<desktop>.lan:<port>/v1
openwebui_secret_key: "" # 64 alphanumeric characters
```

OIDC credentials: shared `vars/oidc_secrets.yml` ([Authentik](authentik.md#oidc-client-credentials)).

## Config

Env vars only seed a fresh database (persistent config). After the first start,
change settings in Admin Settings — including a rotated `llamacpp_api_key`, a
changed `llamacpp_base_url` or a new connection (Connections). Otherwise the
desktop models answer 401 or stay unreachable.

Web search uses the internal [SearXNG](searxng.md) (`searxng.lan:8080`, JSON API).
The Web Search toggle must also be on in the chat; new chats start with it on.
