#!/bin/bash

# run it with:
# chmod +x start.sh
# ./start.sh

echo "Starting Docker Compose..."

export DOCKER_COMPOSE_GPU_REQUEST="device=all"

echo "Starting Docker Compose with GPU support..."
docker compose up -d

echo "Waiting for all models to be pulled..."
MODELS=("deepseek-r1:1.5b" "deepscaler:1.5b" "deepseek-coder:1.3b" "deepseek-coder:6.7b" "moondream" "llama3.2-vision:11b" "llama2-uncensored")

while true; do
    LOGS=$(docker logs ollama-ubuntu-container 2>&1 | tail -n 50)
    COMPLETE=true

    for MODEL in "${MODELS[@]}"; do
        if ! echo "$LOGS" | grep -q "$MODEL"; then
            COMPLETE=false
            break
        fi
    done

    if [ "$COMPLETE" = true ]; then
        echo "All models pulled successfully!"
        break
    fi

    sleep 5  # Check every 5 seconds
done

echo "Disconnecting Ollama from external-net..."
docker network disconnect external-net ollama || echo "Already disconnected."

echo "All done!"
