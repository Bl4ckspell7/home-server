# llama.cpp

Port: `:8080` (exposed, no host binding)

- https://github.com/ggml-org/llama.cpp

CPU-only LLM server in router mode, used by Linkwarden (AI tagging) and Open WebUI.
No API key: it is only reachable on `svr1-network`.

## Models

`defaults/main.yml` lists the GGUF files (downloaded with sha256 check),
`files/models.ini` the presets. The section name is the model ID that clients
request, e.g. Linkwarden's `OPENAI_MODEL`.

- `gemma4-26b-a4b-iq2m`: Gemma4-26B-A4B (MoE, 4B active), HauhauCS "Balanced"
  uncensor. ~12 t/s, ~16 GB RAM while loaded. Thinking off.

One model is loaded at a time, on the first request, and unloaded after 15 min idle.

```bash
docker exec llamacpp curl -s http://127.0.0.1:8080/models
```
