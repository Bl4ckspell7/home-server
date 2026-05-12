# Cup

Ports: `8010:8000`

- https://cup.sergi0g.dev/
- https://github.com/sergi0g/cup
- https://cup.sergi0g.dev/docs/community-resources/homepage-widget

Public route protected by Anubis + Authentik forward auth (Cup has no native auth). See [Authentik forward auth setup](./authentik.md#forward-auth-per-app).

## Setup

Forgejo registry auth (avoids slow scan + WARN spam):

1. Forgejo -> Settings -> Applications -> Generate New Token (scope: `read:package`)
2. Base64 encode `user:token`:
   ```bash
   printf 'bl4ckspell:TOKEN' | base64 -w0
   ```
3. `roles/services/cup/vars/secrets.yml`:
   ```yaml
   forgejo_registry_auth: <base64>
   ```
4. Encrypt:
   ```bash
   sops encrypt --in-place roles/services/cup/vars/secrets.yml
   ```
