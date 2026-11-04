# Open WebUI

Port: `:3000` (exposed, no host binding)

- https://docs.openwebui.com/
- https://github.com/open-webui/open-webui

Authentik OIDC is the only login. Admin follows `authentik Admins`, anyone else
lands as pending.

## Models

- **llama.cpp on the desktop** (`linux-docker-config` `roles/llamacpp`, GPU) by its
  `fritz.box` name, which Pi-hole resolves via the FritzBox. Listed only while the
  desktop is on. Both repos hold the same `llamacpp_api_key` in sops.
- **llama.cpp** here (CPU, always on), see [llama.cpp](llamacpp.md).

`secrets.yml`:

```yaml
llamacpp_api_key: "" # same value as the desktop's roles/llamacpp/vars/secrets.yml
llamacpp_base_url: "" # http://<desktop>.fritz.box:<port>/v1
openwebui_secret_key: "" # 64 alphanumeric characters
```

OIDC credentials: shared `vars/oidc_secrets.yml` ([Authentik](authentik.md#oidc-client-credentials)).

## Config

Env vars only seed a fresh database (persistent config). After the first start,
change settings in Admin Settings — including a rotated `llamacpp_api_key` or a
new connection (Connections), or the desktop models answer 401.

Web search uses DuckDuckGo for now. Once SearXNG runs here behind a VPN, switch it
in Admin Settings → Web Search. The Web Search toggle must also be on in the chat.
