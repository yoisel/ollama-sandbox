#!/bin/bash

# run it with:
# chmod +x start.sh
# ./start.sh

USE_GPU=false
CLEAN=false
for arg in "$@"; do
  case "$arg" in
    --gpu) USE_GPU=true ;;
    --clean) CLEAN=true ;;
  esac
done

if [ "$USE_GPU" = true ]; then
  export DOCKER_COMPOSE_GPU_REQUEST="device=all"
fi

if [ "$CLEAN" = true ]; then
  echo "Performing clean build: stopping containers, removing images & volumes, pruning builder cache, and rebuilding images..."
  docker compose down --rmi all -v
  docker builder prune --all --force
  if [ "$USE_GPU" = true ]; then
    docker compose -f docker-compose.yml -f docker-compose.gpu.override.yml build --no-cache --pull
  else
    docker compose build --no-cache --pull
  fi
fi

if [ "$USE_GPU" = true ]; then
  echo "Starting Docker Compose with GPU support..."
  docker compose -f docker-compose.yml -f docker-compose.gpu.override.yml up -d
else
  echo "Starting Docker Compose in CPU-Only mode..."
  docker compose up -d
fi

echo "Waiting for all models to be pulled..."

while true; do
    LOGS=$(docker logs ollama-ubuntu-container 2>&1 | tail -n 10)
    echo "$LOGS"
    if echo "$LOGS" | grep -q "All models pulled successfully."; then
        echo "All models pulled successfully!"
        break
    fi
    sleep 10
done

echo "Disconnecting Ollama from external net..."
docker network disconnect external-net ollama-container || echo "Disconnected!"

echo "All done!"
