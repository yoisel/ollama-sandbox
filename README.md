# Ollama Paranoid Sandbox

## How to start this project

### Without GPU support

```bash
./start.sh
```

```powershell
.\start.ps1
```

### With GPU support

```bash
./start.sh --gpu
```

```powershell
.\start.ps1 --gpu
```

Testing that your GPU support is working:

```bash
docker run --gpus all nvidia/cuda:11.8.0-base-ubuntu22.04 nvidia-smi
```

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

To add a new model for testing, use the following command:

```bash
docker compose exec ollama-ubuntu-container ollama pull <model-name>
```

Replace `<model-name>` with the name of the model you want to add.