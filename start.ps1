# run it with:
# powershell -ExecutionPolicy Bypass -File .\start.ps1

$useGpu = $args -contains "--gpu"
$clean = $args -contains "--clean"

if ($useGpu) { $env:DOCKER_COMPOSE_GPU_REQUEST = "device=all" }

if ($clean) {
    Write-Host "Performing clean build: stopping containers, removing images & volumes, pruning builder cache, and rebuilding images..."
    docker compose down --rmi all -v
    docker builder prune --all --force
    if ($useGpu) {
        docker compose -f docker-compose.yml -f docker-compose.gpu.override.yml build --no-cache --pull
    }
    else {
        docker compose build --no-cache --pull
    }
}

if ($useGpu) {
    Write-Host "Starting Docker Compose with GPU support..."
    docker compose -f docker-compose.yml -f docker-compose.gpu.override.yml up -d
}
else {
    Write-Host "Starting Docker Compose in CPU-Only mode..."
    docker compose up -d
}

Write-Host "Waiting for all models to be pulled..."

while ($true) {
    $logs = docker logs ollama-ubuntu-container 2>&1 | Select-Object -Last 10
    $logs | ForEach-Object { Write-Host $_ }

    if ($logs -match "All models pulled successfully.") {
        Write-Host "All models pulled successfully!"
        break
    }
    Start-Sleep -Seconds 10
}

Write-Host "Disconnecting Ollama from external net..."
try {
    docker network disconnect external-net ollama-container
} catch {
    Write-Host "Disconnected!"
}

Write-Host "All done!"
