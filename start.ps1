# run it with:
# powershell -ExecutionPolicy Bypass -File .\start.ps1

if ($args -contains "--gpu") {
    $env:DOCKER_COMPOSE_GPU_REQUEST = "device=all"
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
