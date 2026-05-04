# Anubis

Port: `:3000`

- https://anubis.techaro.lol/docs/
- https://github.com/TecharoHQ/anubis

Anubis sits between Caddy and your backend services to filter out AI scrapers and other malicious traffic using a proof-of-work challenge.

Set `TARGET` in the docker-compose environment to the backend service you want to protect, then point the corresponding Caddyfile entry to Anubis instead of directly to the backend.
