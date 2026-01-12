# ollama-sandbox

A Docker Compose setup to run Ollama on a local workstation. 

This project leverages Docker containers to create a stand-alone environment for running Ollama, ideal for running open source LLM models (example: Deepseek, qwen2, llama).

The setup includes multiple services defined in the `docker-compose.yml` file:

- **ollama**: This service runs the main Ollama container. It uses the `ollama/ollama` image and exposes port `11434` for communication.

- **ollama-ubuntu**: This service builds a custom Docker image from the `dockerfile.models` . It installs necessary dependencies and the Ollama tool. The service is responsible for pulling the machine learning models listed in `models.txt` and storing them in a shared volume. It depends on the `ollama` service and runs a command to pull the models upon startup.

- **open-webui**: This service runs the Open WebUI container, which provides a web interface for interacting with Ollama. It uses the `ghcr.io/open-webui/open-webui:main` image and exposes port `3000` for accessing the web UI.

## How to start this project

### Using Docker

Download and install Docker:
https://www.docker.com/

(On Windows, use Docker with WSL)

### Start without GPU support

Linux / Mac OS X

```bash
./start.sh
```

Windows 

```powershell
.\start.ps1
```

### Start with GPU support

Linux / Mac OS X

```bash
./start.sh --gpu
```

Windows 

```powershell
.\start.ps1 --gpu
```

Testing that your GPU support is working:

```bash
docker run --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```

## How to use it

Open your web browser with this address:

http://localhost:3000

## How to pause it

```bash
docker compose stop
```

## How to resume it

```bash
docker compose start
```

## How to wipe this whole project out

```bash
docker compose down -v
```

## Forced clean all of your containers (all of them, not just this project)

```bash
docker rm -f $(docker ps -aq)
```

## How to add a new model on the fly for testing

To add a new model while ollama is running, edit models.txt then run

```bash
docker-compose up ollama-ubuntu-container
```

## Podman (Alternative)

For Linux users who prefer Podman, a setup script is included:

```bash
sudo ./podman-setup.sh
```

This installs Podman, docker-compose, and starts containers in the background. After setup, use standard Docker commands. Containers persist across reboots.

### Notes
- Podman socket is at `/run/user/$(id -u)/docker.sock` (user-level, not system-level)
- Containers run as your user instead of root
- If the service stops after reboot, re-run the setup script
