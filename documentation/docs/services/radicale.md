# Radicale

Port: `:5232` (exposed, no host binding)

- https://radicale.org/master.html
- https://github.com/Kozea/Radicale

CalDAV/CardDAV server for self-hosted calendar and contact sync. Reached through Anubis like every service; its default policy only challenges browser user agents, so CalDAV apps pass, but a client sending a browser-like user agent would get the challenge. Uses htpasswd authentication with argon2 hashing.

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
