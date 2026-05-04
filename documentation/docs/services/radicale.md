# Radicale

Ports: `5232:5232`

- https://radicale.org/master.html
- https://github.com/Kozea/Radicale

CalDAV/CardDAV server for self-hosted calendar and contact sync. Exposed directly via Caddy (not through Anubis, as CalDAV clients can't handle PoW challenges). Uses htpasswd authentication with argon2 hashing.

`secrets.yml`:

```yaml
radicale_users_htpasswd: "user:argon2hash"
```

Generate an argon2 htpasswd entry:

```bash
uv run --with passlib --with argon2-cffi python3 -c "
from passlib.hash import argon2
import getpass
user = input('Username: ')
pw = getpass.getpass('Password: ')
print(user + ':' + argon2.using(type='ID').hash(pw))
"
```

Multiple users go on separate lines in the secrets file.
