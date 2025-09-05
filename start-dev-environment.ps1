# start-dev-environment.ps1
# Start both frontend and mock backend for local development

Write-Host "Starting Development Environment" -ForegroundColor Cyan
Write-Host

# Check if required tools are available
try {
    $null = Get-Command docker -ErrorAction Stop
} catch {
    Write-Host "Error: Docker is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

try {
    $null = Get-Command python -ErrorAction Stop
} catch {
    Write-Host "Error: Python is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Python 3.x or use 'py' command instead" -ForegroundColor Yellow
    exit 1
}

Write-Host "Step 1: Starting mock backend server..." -ForegroundColor Yellow

# Start the mock backend in the background
$backendJob = Start-Job -ScriptBlock {
    Set-Location $using:PWD
    python mock-backend.py
}

Write-Host "Mock backend started (Job ID: $($backendJob.Id))" -ForegroundColor Green

# Wait a moment for the backend to start
Start-Sleep -Seconds 3

Write-Host "Step 2: Starting frontend container..." -ForegroundColor Yellow

# Stop any existing frontend container
try {
    docker stop rg-persona-frontend 2>$null
    docker rm rg-persona-frontend 2>$null
} catch {
    # Ignore errors if container does not exist
}

# Start the frontend container
try {
    docker run -d `
        --name rg-persona-frontend `
        -p 8080:8080 `
        -e AUTH_MODE=none `
        -e BACKEND_BASE_URL=http://host.docker.internal:3000/api `
        -e IAP_MODE=false `
        rg-dynamic-persona-frontend

    Write-Host "Frontend container started successfully!" -ForegroundColor Green
} catch {
    Write-Host "Error starting frontend container: $_" -ForegroundColor Red
    Stop-Job $backendJob
    Remove-Job $backendJob
    exit 1
}

Write-Host
Write-Host "Development Environment Ready!" -ForegroundColor Green
Write-Host "=" * 50
Write-Host "Frontend: http://localhost:8080" -ForegroundColor Cyan
Write-Host "Backend:  http://localhost:3000" -ForegroundColor Cyan
Write-Host "Health:   http://localhost:3000/api/health" -ForegroundColor Gray
Write-Host
Write-Host "What you can do now:" -ForegroundColor Yellow
Write-Host "1. Open http://localhost:8080 in your browser" -ForegroundColor White
Write-Host "2. Try sending messages in the chat" -ForegroundColor White
Write-Host "3. Test messages: 'hello', 'test', 'auth'" -ForegroundColor White
Write-Host
Write-Host "To stop everything:" -ForegroundColor Yellow
Write-Host "1. Press Ctrl+C" -ForegroundColor White
Write-Host "2. Run: docker stop rg-persona-frontend" -ForegroundColor White
Write-Host
Write-Host "Monitoring services... (Press Ctrl+C to stop)" -ForegroundColor Yellow

# Wait for the backend job and monitor
try {
    # Keep the script running and monitor the backend
    while ($backendJob.State -eq "Running") {
        Start-Sleep -Seconds 5
        
        # Check if frontend container is still running
        $containerStatus = docker ps --filter name=rg-persona-frontend --format "{{.Names}}"
        if ($containerStatus -ne "rg-persona-frontend") {
            Write-Host "Frontend container stopped unexpectedly!" -ForegroundColor Red
            break
        }
    }
} catch {
    Write-Host "Stopping services..." -ForegroundColor Yellow
} finally {
    # Cleanup
    Write-Host "Cleaning up..." -ForegroundColor Yellow
    
    # Stop backend
    Stop-Job $backendJob -ErrorAction SilentlyContinue
    Remove-Job $backendJob -ErrorAction SilentlyContinue
    
    # Stop frontend
    docker stop rg-persona-frontend 2>$null
    docker rm rg-persona-frontend 2>$null
    
    Write-Host "Development environment stopped." -ForegroundColor Green
}
