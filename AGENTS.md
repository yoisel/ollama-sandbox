# Ollama Sandbox - AI Agent Instructions

## Project Overview
A Docker Compose environment for running Ollama (open-source LLM inference) locally. Three-service architecture: Ollama server, model downloader/optimizer, and Open WebUI frontend. See [README.md](../README.md) for details.

## Architecture & Data Flow

**Three Core Services** (defined in [docker-compose.yml](../docker-compose.yml)):
1. **ollama** - Ollama inference server (port 11434, persistent volume)
2. **ollama-ubuntu** - One-shot container that pulls & optimizes models from `models.txt` (builds from [dockerfile.models](../dockerfile.models))
3. **open-webui** - Web UI frontend (port 3000)

**Model Optimization Pipeline** ([pull_and_reexport.sh](../pull_and_reexport.sh)):
- Reads `models.txt` (comments/blank lines ignored)
- For each model: pulls original → creates Modelfile with custom `num_ctx` (context window)
- Context mappings hardcoded: `ministral=262144`, `mistral/deepseek/llama/gpt=131072`, others=4096
- Renamed with suffix (`-256k`, `-32k`, `-128k`) to avoid conflicts
- Runs inside ollama-ubuntu container with host IPC access to ollama service

**Volume Sharing**: ollama-ubuntu and ollama both mount `/root/.ollama` (named volume) for model persistence.

## Critical Developer Workflows

### Start Services
```bash
./start.sh                  # CPU-only, waits for model pulls
./start.sh --gpu           # GPU support via docker-compose.gpu.override.yml
./start.sh --clean --gpu   # Clean build + GPU (removes images/volumes, rebuilds)
./start.ps1 [--gpu]        # Windows alternative
```

### Add/Update Models
Edit [models.txt](../models.txt), then:
```bash
docker-compose up ollama-ubuntu-container
```
Reruns pull_and_reexport.sh; existing models with suffix are skipped.

### Common Operations
```bash
docker compose stop/start   # Pause/resume
docker compose down -v      # Full cleanup with volumes
http://localhost:3000       # Web UI access after startup
```

### Startup Validation
[start.sh](../start.sh) polls `docker logs ollama-ubuntu-container` for "All models pulled successfully." message until found.

## Project-Specific Patterns

**Model Naming**: Ollama model IDs use format `name:tag`. When reexported, tag is extended (e.g., `deepseek:7b` → `deepseek:7b-128k`). See lines 30-80 of [pull_and_reexport.sh](../pull_and_reexport.sh) for model-to-context-window logic.

**Dependency Ordering**: 
- ollama-ubuntu depends_on ollama (waits for container, not healthcheck)
- open-webui depends_on both ollama and ollama-ubuntu (ensures models ready)
- Use `depends_on.condition: service_healthy` if stricter ordering needed

**GPU Enablement**: 
- `docker-compose.gpu.override.yml` supplements base compose with `device=all` runtime
- Environment variable `DOCKER_COMPOSE_GPU_REQUEST` set in [start.sh](../start.sh)
- Test GPU: `docker run --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi`

## Key Files & Their Responsibilities

- [docker-compose.yml](../docker-compose.yml) - Service definitions, volumes, networking
- [dockerfile.models](../dockerfile.models) - Ubuntu image with ollama + build deps (minimal, curl/vim/python)
- [pull_and_reexport.sh](../pull_and_reexport.sh) - Core model logic; only file modifying ollama state
- [models.txt](../models.txt) - Declarative model list (one per line, comments with `#`)
- [start.sh](../start.sh) - Orchestration & startup polling (see for GPU/clean flags)
- [docker-compose.gpu.override.yml](../docker-compose.gpu.override.yml) - GPU resource overrides

## Integration Points & Troubleshooting

**Ollama Host URL**: ollama-ubuntu uses `OLLAMA_HOST=http://ollama:11434` (internal Docker network). External tools use `http://localhost:11434`.

**Model Pull Failures**: Check `docker logs ollama-ubuntu-container` for pull errors. Common causes: network issues, disk space, model tag not found.

**Reexport Idempotency**: Script checks if reexported model already exists; removes and recreates if Modelfile changes.

**Podman Support**: See [podman-setup.sh](../podman-setup.sh) for Podman alternative; adapt scripts similarly if needed.
