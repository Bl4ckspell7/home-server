# SearXNG

Port: `:8080` (exposed, no host binding)

- https://docs.searxng.org/
- https://github.com/searxng/searxng

Private metasearch engine and Open WebUI's web search backend (JSON API on
`searxng.lan:8080`, internal, no login). The web UI at `searxng.bl4ckspell.de` sits
behind Authentik forward auth, so it is no open proxy.

Searches leave via ProtonVPN like all svr1 egress ([Network](../network.md)). There
is no killswitch: with the tunnel off they use the home IP. Some engines CAPTCHA the
shared VPN IP and get suspended for a while; check which:

```bash
docker exec openwebui curl -s 'http://searxng.lan:8080/search?q=test&format=json' | jq .unresponsive_engines
```

`secrets.yml`:

```yaml
searxng_secret_key: "" # 64 alphanumeric characters
```

Engines and other options: `files/settings.yml` (image defaults apply otherwise).
