# test-with-auth-proxy.ps1
# Test the frontend with the auth proxy service

param(
    [Parameter(Mandatory=$false)]
    [string]$AuthProxyUrl
)

Write-Host "Testing Dynamic Persona Frontend with Auth Proxy" -ForegroundColor Cyan
Write-Host

# Check if Docker is available
try {
    $null = Get-Command docker -ErrorAction Stop
} catch {
    Write-Host "Error: Docker is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Prompt for auth proxy URL if not provided
if (-not $AuthProxyUrl) {
    Write-Host "The auth proxy handles authentication to your IAM-protected backend." -ForegroundColor Yellow
    Write-Host "Deploy it first with: .\auth-proxy\deploy-auth-proxy.ps1" -ForegroundColor Gray
    Write-Host
    $AuthProxyUrl = Read-Host "Enter your auth proxy URL (e.g., https://rg-dynamic-persona-auth-proxy-hash-ew.a.run.app)"
}

if (-not $AuthProxyUrl) {
    Write-Host "Error: Auth proxy URL is required" -ForegroundColor Red
    exit 1
}

# Remove trailing slash
$AuthProxyUrl = $AuthProxyUrl.TrimEnd('/')

Write-Host "Testing auth proxy connection..." -ForegroundColor Yellow

# Test auth proxy health
try {
    $healthResponse = Invoke-RestMethod -Uri "$AuthProxyUrl/health" -Method GET
    Write-Host "Auth proxy health check: OK" -ForegroundColor Green
    Write-Host "Backend URL: $($healthResponse.backend_url)" -ForegroundColor Gray
} catch {
    Write-Host "Warning: Could not connect to auth proxy: $_" -ForegroundColor Yellow
    Write-Host "Continuing anyway..." -ForegroundColor Gray
}

Write-Host "Starting frontend with auth proxy configuration..." -ForegroundColor Yellow

# Stop any existing container
try {
    docker stop rg-persona-frontend 2>$null
    docker rm rg-persona-frontend 2>$null
} catch {
    # Ignore errors if container does not exist
}

# Start the container with auth proxy configuration
try {
    docker run -d `
        --name rg-persona-frontend `
        -p 8080:8080 `
        -e AUTH_MODE=none `
        -e "BACKEND_BASE_URL=$AuthProxyUrl" `
        -e IAP_MODE=false `
        rg-dynamic-persona-frontend

    Write-Host "Container started successfully!" -ForegroundColor Green
} catch {
    Write-Host "Error starting container: $_" -ForegroundColor Red
    exit 1
}

Write-Host
Write-Host "=== Frontend Ready with Auth Proxy ===" -ForegroundColor Green
Write-Host "Frontend URL: http://localhost:8080" -ForegroundColor Cyan
Write-Host "Auth Proxy URL: $AuthProxyUrl" -ForegroundColor Cyan
Write-Host "Backend URL: https://rg-dynamic-persona-1036279278510.europe-west9.run.app (via proxy)" -ForegroundColor Gray
Write-Host
Write-Host "Authentication Flow:" -ForegroundColor Yellow
Write-Host "Browser -> Frontend -> Auth Proxy -> IAM-Protected Backend" -ForegroundColor White
Write-Host
Write-Host "Test your setup:" -ForegroundColor Yellow
Write-Host "1. Open http://localhost:8080 in your browser" -ForegroundColor White
Write-Host "2. Send a message: 'What should I wear today in Ushuaia?'" -ForegroundColor White
Write-Host "3. The auth proxy will handle Cloud Run IAM authentication" -ForegroundColor White
Write-Host "4. Check browser console (F12) for any errors" -ForegroundColor White
Write-Host
Write-Host "Benefits of this setup:" -ForegroundColor Yellow
Write-Host "- No bearer tokens needed in frontend" -ForegroundColor White
Write-Host "- Automatic Cloud Run authentication" -ForegroundColor White
Write-Host "- Service account handles token generation" -ForegroundColor White
Write-Host "- CORS properly configured" -ForegroundColor White
Write-Host
Write-Host "Troubleshooting:" -ForegroundColor Yellow
Write-Host "- Frontend logs: docker logs rg-persona-frontend" -ForegroundColor White
Write-Host "- Auth proxy logs: gcloud logs read --service=rg-dynamic-persona-auth-proxy" -ForegroundColor White
Write-Host "- Stop container: docker stop rg-persona-frontend" -ForegroundColor White

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
