# Paperless-ngx

Port: `:8000` (exposed, no host binding)

- https://docs.paperless-ngx.com/
- https://github.com/paperless-ngx/paperless-ngx
- https://docs.goauthentik.io/integrations/services/paperless-ngx/

`secrets.yml`:

```yaml
paperless_secret_key: ""
paperless_db_name: ""
paperless_db_user: ""
paperless_db_password: ""
paperless_admin_password: ""
```

OIDC credentials: shared `vars/oidc_secrets.yml` ([Authentik](authentik.md#oidc-client-credentials)).

## Login

Login is Authentik-only. Superuser status follows `authentik Admins` on each login.

**Break-glass:** the local superuser `admin` can log in at `/admin/`. From the
internet `/admin/` sits behind Authentik forward-auth (admins only), so with
Authentik down use the `manage.py` shell below instead. `admin` is only created
while no superuser exists, so set an existing user's password by hand:

```bash
ssh server 'docker exec -i paperless python3 manage.py shell' <<'PY'
from django.contrib.auth.models import User
import os
u = User.objects.get(username="admin"); u.set_password(os.environ["PAPERLESS_ADMIN_PASSWORD"]); u.save()
PY
```

## Service user

Paperless runs as the `paperless-ngx` system user (912:912) via
`USERMAP_UID`/`USERMAP_GID`: the image remaps its `paperless` user at start. The
`export` and `consume` dirs belong to that user, so files dropped into `consume`
must be readable by it.
