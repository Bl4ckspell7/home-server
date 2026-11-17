# Anubis

Port: `:3000`

- https://anubis.techaro.lol/docs/
- https://github.com/TecharoHQ/anubis

Anubis sits between Caddy and your backend services to filter out AI scrapers and other malicious traffic using a proof-of-work challenge.

Every public request takes the same path: Caddy `:443` → Anubis → Caddy `:8080` (`TARGET`), which routes by host to the backend. `:8080` accepts only Anubis's IP, so no other container in a zone with Caddy can skip the challenge, and Caddy trusts `X-Forwarded-*` only from Anubis, so backends and Authentik see the real client.
