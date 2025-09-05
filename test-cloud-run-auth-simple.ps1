# test-cloud-run-auth-simple.ps1
# Simple PowerShell script to test the frontend with Cloud Run IAM authentication

param(
    [Parameter(Mandatory=$false)]
    [string]$CloudRunUrl
)

Write-Host "Testing Dynamic Persona Frontend with Cloud Run IAM Authentication" -ForegroundColor Cyan
Write-Host

# Check if required tools are available
try {
    $null = Get-Command gcloud -ErrorAction Stop
} catch {
    Write-Host "Error: gcloud CLI is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install the Google Cloud SDK: https://cloud.google.com/sdk/docs/install" -ForegroundColor Yellow
    exit 1
}

try {
    $null = Get-Command docker -ErrorAction Stop
} catch {
    Write-Host "Error: Docker is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Prompt for Cloud Run service URL if not provided
if (-not $CloudRunUrl) {
    $CloudRunUrl = Read-Host "Enter your Cloud Run service URL (e.g., https://your-service-abc123-uc.a.run.app)"
}

if (-not $CloudRunUrl) {
    Write-Host "Error: Cloud Run URL is required" -ForegroundColor Red
    exit 1
}

Write-Host "Generating identity token for Cloud Run service..." -ForegroundColor Yellow

# Generate identity token
try {
    $Token = gcloud auth print-identity-token --audiences="$CloudRunUrl" 2>$null
    if (-not $Token) {
        throw "Empty token returned"
    }
} catch {
    Write-Host "Error: Failed to generate identity token" -ForegroundColor Red
    Write-Host "Make sure you are authenticated with: gcloud auth login" -ForegroundColor Yellow
    Write-Host "And that you have permission to invoke the Cloud Run service" -ForegroundColor Yellow
    exit 1
}

Write-Host "Identity token generated successfully" -ForegroundColor Green
Write-Host "Token preview: $($Token.Substring(0, [Math]::Min(20, $Token.Length)))..." -ForegroundColor Gray

Write-Host
Write-Host "Starting frontend container with Cloud Run authentication..." -ForegroundColor Yellow

# Stop any existing container
try {
    docker stop rg-persona-frontend 2>$null
    docker rm rg-persona-frontend 2>$null
} catch {
    # Ignore errors if container does not exist
}

# Start the container with authentication
try {
    docker run -d `
        --name rg-persona-frontend `
        -p 8080:8080 `
        -e AUTH_MODE=bearer `
        -e "BACKEND_BASE_URL=$CloudRunUrl" `
        -e "BEARER_TOKEN=$Token" `
        -e IAP_MODE=false `
        rg-dynamic-persona-frontend

    Write-Host "Container started successfully!" -ForegroundColor Green
} catch {
    Write-Host "Error starting container: $_" -ForegroundColor Red
    exit 1
}

Write-Host
Write-Host "Frontend available at: http://localhost:8080" -ForegroundColor Cyan
Write-Host "Backend URL: $CloudRunUrl" -ForegroundColor Gray
Write-Host "Authentication: Bearer token (IAM)" -ForegroundColor Gray
Write-Host
Write-Host "To test:" -ForegroundColor Yellow
Write-Host "1. Open http://localhost:8080 in your browser" -ForegroundColor White
Write-Host "2. Send a test message in the chat" -ForegroundColor White
Write-Host "3. Check the browser console for any errors" -ForegroundColor White
Write-Host
Write-Host "Note: The identity token expires in about 1 hour" -ForegroundColor Yellow
Write-Host "If you get 401 errors, re-run this script to refresh the token" -ForegroundColor Gray
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
} else {
    Write-Host "Container failed to start. Check logs with:" -ForegroundColor Red
    Write-Host "docker logs rg-persona-frontend" -ForegroundColor White
    exit 1
}
