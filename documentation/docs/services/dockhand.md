# Dockhand

Port: `:3000` (exposed, no host binding)

- https://dockhand.pro/manual/
- https://github.com/Finsys/dockhand

OIDC credentials: shared `vars/oidc_secrets.yml` ([Authentik](authentik.md#oidc-client-credentials)).

## Login

Authentik only, and only for `authentik Admins`: every Dockhand user is admin
(free edition), and admin means root on the host via the docker socket. The
Admin role follows the `groups` claim; without it the UI shows you as non-admin.

- Fresh install: the deploy creates your user and the provider through the API
  (open until auth is on), then enables auth; if that fails, it stops Dockhand
  rather than leave it open. The first SSO login takes the user over by username.
- Client secret rotation: change it in Dockhand (Settings → Authentication)
  while logged in, then deploy Authentik. The deploy can't compare it, since
  Dockhand stores it encrypted.
- Repair (SSO broken, e.g. a domain change): `docker exec -it dockhand
  /app/scripts/disable-auth.sh`, then deploy at once: until then Dockhand is
  open to anyone. The deploy rewrites the provider from sops and turns auth on.
- Local login instead: `DISABLE_LOCAL_LOGIN: "false"`, redeploy, set a password
  with `/app/scripts/reset-password.sh`.
