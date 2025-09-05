# test-local.ps1
# Simple script to test the frontend locally without backend authentication

Write-Host "Testing Dynamic Persona Frontend Locally" -ForegroundColor Cyan
Write-Host

# Check if Docker is available
try {
    $null = Get-Command docker -ErrorAction Stop
} catch {
    Write-Host "Error: Docker is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

Write-Host "Starting frontend container in local mode..." -ForegroundColor Yellow

# Stop any existing container
try {
    docker stop rg-persona-frontend 2>$null
    docker rm rg-persona-frontend 2>$null
} catch {
    # Ignore errors if container does not exist
}

# Start the container without authentication (local development mode)
try {
    docker run -d `
        --name rg-persona-frontend `
        -p 8080:8080 `
        -e AUTH_MODE=none `
        -e BACKEND_BASE_URL=http://localhost:3000/api `
        -e IAP_MODE=false `
        rg-dynamic-persona-frontend

    Write-Host "Container started successfully!" -ForegroundColor Green
} catch {
    Write-Host "Error starting container: $_" -ForegroundColor Red
    exit 1
}

Write-Host
Write-Host "Frontend available at: http://localhost:8080" -ForegroundColor Cyan
Write-Host "Backend URL: http://localhost:3000/api (local)" -ForegroundColor Gray
Write-Host "Authentication: None (development mode)" -ForegroundColor Gray
Write-Host
Write-Host "Current setup:" -ForegroundColor Yellow
Write-Host "- Frontend: Running on port 8080" -ForegroundColor White
Write-Host "- Backend: Expected on port 3000 (not running yet)" -ForegroundColor White
Write-Host "- Authentication: Disabled for local development" -ForegroundColor White
Write-Host
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Open http://localhost:8080 to see the frontend" -ForegroundColor White
Write-Host "2. The chat will show errors since there's no backend yet" -ForegroundColor White
Write-Host "3. You can deploy this to Cloud Run when ready" -ForegroundColor White
Write-Host
Write-Host "When you have a Cloud Run backend:" -ForegroundColor Yellow
Write-Host "- Use test-cloud-run-auth-simple.ps1 instead" -ForegroundColor White
Write-Host "- Or manually set environment variables for your service" -ForegroundColor White
Write-Host
Write-Host "To check container logs:" -ForegroundColor Yellow
Write-Host "docker logs rg-persona-frontend" -ForegroundColor White
Write-Host
Write-Host "To stop the container:" -ForegroundColor Yellow
Write-Host "docker stop rg-persona-frontend" -ForegroundColor White

# Wait a moment for the container to start
Start-Sleep -Seconds 2

# Check if container is running
$containerStatus = docker ps --filter name=rg-persona-frontend --format "{{.Names}}"
if ($containerStatus -eq "rg-persona-frontend") {
    Write-Host "Container is running successfully!" -ForegroundColor Green
    Write-Host "Open http://localhost:8080 in your browser" -ForegroundColor Cyan
} else {
    Write-Host "Container failed to start. Check logs with:" -ForegroundColor Red
    Write-Host "docker logs rg-persona-frontend" -ForegroundColor White
    exit 1
}
