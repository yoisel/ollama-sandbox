#!/bin/bash

# run it with:
# chmod +x start.sh
# ./start.sh

if [[ "$*" == *"--gpu"* ]]; then
  export DOCKER_COMPOSE_GPU_REQUEST="device=all"
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
