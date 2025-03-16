# run it with:
# powershell -ExecutionPolicy Bypass -File .\start.ps1

Write-Output "Starting Docker Compose..."

$env:DOCKER_COMPOSE_GPU_REQUEST="device=all"

Write-Output "Starting Docker Compose with GPU support..."
docker compose up -d

Write-Output "Waiting for all models to be pulled..."
$models = @("deepseek-r1:1.5b", "deepscaler:1.5b", "deepseek-coder:1.3b", "deepseek-coder:6.7b", "moondream", "llama3.2-vision:11b", "llama2-uncensored")

do {
    Start-Sleep -Seconds 5
    $logs = docker logs ollama-ubuntu-container -n 50
    $allPulled = $true

    foreach ($model in $models) {
        if ($logs -notmatch $model) {
            $allPulled = $false
            break
        }
    }
} while (-not $allPulled)

Write-Output "All models pulled successfully!"

Write-Output "Disconnecting Ollama from external-net..."
docker network disconnect external-net ollama

Write-Output "All done!"
