# deploy-auth-proxy-simple.ps1
# Simple deployment of auth proxy using gcloud run deploy

param(
    [Parameter(Mandatory=$false)]
    [string]$ProjectId,
    [Parameter(Mandatory=$false)]
    [string]$Region = "europe-west9",
    [Parameter(Mandatory=$false)]
    [string]$ServiceName = "rg-dynamic-persona-auth-proxy"
)

Write-Host "Deploying RG Dynamic Persona Auth Proxy (Simple Method)" -ForegroundColor Cyan
Write-Host

# Check if gcloud is available
try {
    $null = Get-Command gcloud -ErrorAction Stop
} catch {
    Write-Host "Error: gcloud CLI is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Get project ID if not provided
if (-not $ProjectId) {
    try {
        $ProjectId = gcloud config get-value project 2>$null
        if (-not $ProjectId) {
            throw "No project set"
        }
    } catch {
        Write-Host "Error: No Google Cloud project set. Please run:" -ForegroundColor Red
        Write-Host "gcloud config set project YOUR_PROJECT_ID" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host "Project ID: $ProjectId" -ForegroundColor Gray
Write-Host "Region: $Region" -ForegroundColor Gray
Write-Host "Service Name: $ServiceName" -ForegroundColor Gray
Write-Host

# Enable required APIs
Write-Host "Enabling required APIs..." -ForegroundColor Yellow
gcloud services enable run.googleapis.com --project=$ProjectId

# Deploy directly from source (no Cloud Build needed)
Write-Host "Deploying auth proxy from source..." -ForegroundColor Yellow

try {
    # Change to auth-proxy directory and deploy
    Push-Location .\auth-proxy
    
    gcloud run deploy $ServiceName `
        --source . `
        --platform managed `
        --region $Region `
        --allow-unauthenticated `
        --port 8080 `
        --memory 256Mi `
        --cpu 1 `
        --timeout 60 `
        --max-instances 5 `
        --min-instances 0 `
        --set-env-vars "BACKEND_URL=https://rg-dynamic-persona-1036279278510.europe-west9.run.app" `
        --project $ProjectId

    Pop-Location
    Write-Host "Auth proxy deployed successfully!" -ForegroundColor Green
} catch {
    Pop-Location
    Write-Host "Deployment failed: $_" -ForegroundColor Red
    exit 1
}

# Get the service URL
Write-Host "Getting service URL..." -ForegroundColor Yellow
$serviceUrl = gcloud run services describe $ServiceName `
    --region=$Region `
    --project=$ProjectId `
    --format="value(status.url)" 2>$null

if ($serviceUrl) {
    Write-Host
    Write-Host "=== Deployment Complete ===" -ForegroundColor Green
    Write-Host "Auth Proxy URL: $serviceUrl" -ForegroundColor Cyan
    Write-Host "Health Check: $serviceUrl/health" -ForegroundColor Gray
    Write-Host
    
    # Test the health endpoint
    Write-Host "Testing auth proxy..." -ForegroundColor Yellow
    try {
        $healthResponse = Invoke-RestMethod -Uri "$serviceUrl/health" -Method GET -TimeoutSec 10
        Write-Host "Health check successful!" -ForegroundColor Green
        Write-Host "Service: $($healthResponse.service)" -ForegroundColor Gray
        Write-Host "Backend URL: $($healthResponse.backend_url)" -ForegroundColor Gray
    } catch {
        Write-Host "Warning: Health check failed (service may still be starting): $_" -ForegroundColor Yellow
    }
    
    Write-Host
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Test the proxy manually:" -ForegroundColor White
    Write-Host "   curl $serviceUrl/health" -ForegroundColor Gray
    Write-Host
    Write-Host "2. Update your frontend to use the proxy:" -ForegroundColor White
    Write-Host "   .\test-with-auth-proxy.ps1 $serviceUrl" -ForegroundColor Gray
    Write-Host
    Write-Host "3. Or run frontend manually:" -ForegroundColor White
    Write-Host "   docker run -p 8080:8080 \" -ForegroundColor Gray
    Write-Host "     -e AUTH_MODE=none \" -ForegroundColor Gray
    Write-Host "     -e `"BACKEND_BASE_URL=$serviceUrl`" \" -ForegroundColor Gray
    Write-Host "     rg-dynamic-persona-frontend" -ForegroundColor Gray
    
    Write-Host
    Write-Host "Authentication flow:" -ForegroundColor Yellow
    Write-Host "Browser -> Frontend -> Auth Proxy ($serviceUrl) -> Backend (IAM)" -ForegroundColor White
} else {
    Write-Host "Warning: Could not retrieve service URL" -ForegroundColor Yellow
    Write-Host "Check the Cloud Run console for the service URL" -ForegroundColor Gray
}
