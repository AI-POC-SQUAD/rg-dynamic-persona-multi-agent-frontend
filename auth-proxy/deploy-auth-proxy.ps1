# deploy-auth-proxy.ps1
# Deploy the auth proxy service to Cloud Run

param(
    [Parameter(Mandatory=$false)]
    [string]$ProjectId,
    [Parameter(Mandatory=$false)]
    [string]$Region = "europe-west9"
)

Write-Host "Deploying RG Dynamic Persona Auth Proxy" -ForegroundColor Cyan
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
Write-Host

# Enable required APIs
Write-Host "Enabling required APIs..." -ForegroundColor Yellow
gcloud services enable cloudbuild.googleapis.com --project=$ProjectId
gcloud services enable run.googleapis.com --project=$ProjectId
gcloud services enable artifactregistry.googleapis.com --project=$ProjectId

# Create Artifact Registry repository if it doesn't exist
Write-Host "Creating Artifact Registry repository..." -ForegroundColor Yellow
try {
    gcloud artifacts repositories create dynamic-persona-frontend `
        --repository-format=docker `
        --location=$Region `
        --project=$ProjectId 2>$null
    Write-Host "Repository created successfully" -ForegroundColor Green
} catch {
    Write-Host "Repository already exists or creation failed" -ForegroundColor Gray
}

# Build and deploy using Cloud Build
Write-Host "Building and deploying auth proxy..." -ForegroundColor Yellow

try {
    gcloud builds submit ./auth-proxy `
        --config=./auth-proxy/cloudbuild.yaml `
        --project=$ProjectId `
        --substitutions=_REGION=$Region

    Write-Host "Auth proxy deployed successfully!" -ForegroundColor Green
} catch {
    Write-Host "Deployment failed: $_" -ForegroundColor Red
    exit 1
}

# Get the service URL
Write-Host "Getting service URL..." -ForegroundColor Yellow
$serviceUrl = gcloud run services describe rg-dynamic-persona-auth-proxy `
    --region=$Region `
    --project=$ProjectId `
    --format="value(status.url)" 2>$null

if ($serviceUrl) {
    Write-Host
    Write-Host "=== Deployment Complete ===" -ForegroundColor Green
    Write-Host "Auth Proxy URL: $serviceUrl" -ForegroundColor Cyan
    Write-Host "Health Check: $serviceUrl/health" -ForegroundColor Gray
    Write-Host
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Test the proxy: curl $serviceUrl/health" -ForegroundColor White
    Write-Host "2. Update your frontend BACKEND_BASE_URL to: $serviceUrl" -ForegroundColor White
    Write-Host "3. Set AUTH_MODE=none in your frontend (proxy handles auth)" -ForegroundColor White
    Write-Host
    Write-Host "Frontend configuration:" -ForegroundColor Yellow
    Write-Host "docker run -p 8080:8080 \" -ForegroundColor White
    Write-Host "  -e AUTH_MODE=none \" -ForegroundColor White
    Write-Host "  -e `"BACKEND_BASE_URL=$serviceUrl`" \" -ForegroundColor White
    Write-Host "  rg-dynamic-persona-frontend" -ForegroundColor White
} else {
    Write-Host "Warning: Could not retrieve service URL" -ForegroundColor Yellow
    Write-Host "Check the Cloud Run console for the service URL" -ForegroundColor Gray
}
