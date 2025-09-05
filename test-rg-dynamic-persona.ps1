# test-rg-dynamic-persona.ps1
# Test script for the specific RG Dynamic Persona Cloud Run backend

param(
    [Parameter(Mandatory=$false)]
    [string]$BearerToken
)

Write-Host "Testing RG Dynamic Persona Frontend" -ForegroundColor Cyan
Write-Host "Backend: https://rg-dynamic-persona-1036279278510.europe-west9.run.app" -ForegroundColor Gray
Write-Host

# Check if Docker is available
try {
    $null = Get-Command docker -ErrorAction Stop
} catch {
    Write-Host "Error: Docker is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Prompt for bearer token if not provided
if (-not $BearerToken) {
    Write-Host "You need a bearer token for IAM authentication." -ForegroundColor Yellow
    Write-Host "You can get one with: gcloud auth print-identity-token --audiences=https://rg-dynamic-persona-1036279278510.europe-west9.run.app" -ForegroundColor Gray
    Write-Host
    $BearerToken = Read-Host "Enter your bearer token"
}

if (-not $BearerToken) {
    Write-Host "Error: Bearer token is required for IAM authentication" -ForegroundColor Red
    exit 1
}

Write-Host "Starting frontend with RG Dynamic Persona backend..." -ForegroundColor Yellow

# Stop any existing container
try {
    docker stop rg-persona-frontend 2>$null
    docker rm rg-persona-frontend 2>$null
} catch {
    # Ignore errors if container does not exist
}

# Start the container with your specific configuration
try {
    docker run -d `
        --name rg-persona-frontend `
        -p 8080:8080 `
        -e AUTH_MODE=bearer `
        -e "BACKEND_BASE_URL=https://rg-dynamic-persona-1036279278510.europe-west9.run.app" `
        -e "BEARER_TOKEN=$BearerToken" `
        -e IAP_MODE=false `
        rg-dynamic-persona-frontend

    Write-Host "Container started successfully!" -ForegroundColor Green
} catch {
    Write-Host "Error starting container: $_" -ForegroundColor Red
    exit 1
}

Write-Host
Write-Host "=== RG Dynamic Persona Frontend Ready ===" -ForegroundColor Green
Write-Host "Frontend URL: http://localhost:8080" -ForegroundColor Cyan
Write-Host "Backend URL:  https://rg-dynamic-persona-1036279278510.europe-west9.run.app" -ForegroundColor Cyan
Write-Host "Chat endpoint: /chat" -ForegroundColor Gray
Write-Host "Authentication: Bearer token (IAM)" -ForegroundColor Gray
Write-Host
Write-Host "Test your setup:" -ForegroundColor Yellow
Write-Host "1. Open http://localhost:8080 in your browser" -ForegroundColor White
Write-Host "2. Try sending a GraphQL natural language question" -ForegroundColor White
Write-Host "3. Example: 'What should I wear today in Ushuaia?'" -ForegroundColor White
Write-Host "4. Check browser console (F12) for any errors" -ForegroundColor White
Write-Host
Write-Host "API Details:" -ForegroundColor Yellow
Write-Host "- Request format: Plain text (GraphQL natural language)" -ForegroundColor White
Write-Host "- Response format: JSON with 'answer' field" -ForegroundColor White
Write-Host "- Content-Type: text/plain" -ForegroundColor White
Write-Host "- Authorization: Bearer token" -ForegroundColor White
Write-Host
Write-Host "Troubleshooting:" -ForegroundColor Yellow
Write-Host "- Container logs: docker logs rg-persona-frontend" -ForegroundColor White
Write-Host "- Stop container: docker stop rg-persona-frontend" -ForegroundColor White
Write-Host "- Token expires in ~1 hour, re-run script to refresh" -ForegroundColor White

# Wait a moment for the container to start
Start-Sleep -Seconds 2

# Check if container is running
$containerStatus = docker ps --filter name=rg-persona-frontend --format "{{.Names}}"
if ($containerStatus -eq "rg-persona-frontend") {
    Write-Host
    Write-Host "Container is running successfully!" -ForegroundColor Green
    Write-Host "Ready to test at: http://localhost:8080" -ForegroundColor Cyan
} else {
    Write-Host
    Write-Host "Container failed to start. Check logs with:" -ForegroundColor Red
    Write-Host "docker logs rg-persona-frontend" -ForegroundColor White
    exit 1
}
