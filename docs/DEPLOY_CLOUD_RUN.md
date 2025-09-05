# Cloud Run Deployment Guide

This guide covers manual deployment steps for the Dynamic Persona Frontend to Google Cloud Run. Use this for one-off deployments or debugging deployment issues.

## Prerequisites

### Required APIs
Enable the following Google Cloud APIs in your project:

```bash
gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable iap.googleapis.com  # If using Load Balancer with IAP
```

### Authentication
Ensure you're authenticated and have the correct project set:

```bash
# Authenticate with Google Cloud
gcloud auth login

# Set your project
gcloud config set project YOUR_PROJECT_ID

# Verify configuration
gcloud config list
```

### Required Permissions
Your account needs these IAM roles:
- `Cloud Run Admin`
- `Artifact Registry Admin` (if using Artifact Registry)
- `Cloud Build Editor` (if using Cloud Build)
- `Compute Network Admin` (if setting up Load Balancer)

## Deployment Methods

### Method 1: Direct Deploy from Source (Recommended)

This method builds and deploys directly from your source code:

```bash
# Deploy with basic configuration
gcloud run deploy dynamic-persona-frontend \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 8080 \
  --memory 512Mi \
  --cpu 1 \
  --max-instances 10 \
  --set-env-vars BACKEND_BASE_URL=/api,IAP_MODE=false

# Deploy with IAP configuration
gcloud run deploy dynamic-persona-frontend \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 8080 \
  --memory 512Mi \
  --cpu 1 \
  --max-instances 10 \
  --set-env-vars BACKEND_BASE_URL=/api,IAP_MODE=true,IAP_AUDIENCE=projects/PROJECT_NUMBER/global/backendServices/BACKEND_SERVICE_ID
```

### Method 2: Build and Push to Artifact Registry

#### Step 1: Create Artifact Registry Repository
```bash
# Create repository for Docker images
gcloud artifacts repositories create dynamic-persona-frontend \
  --repository-format=docker \
  --location=us-central1 \
  --description="Dynamic Persona Frontend container images"
```

#### Step 2: Configure Docker Authentication
```bash
# Configure Docker to use gcloud as credential helper
gcloud auth configure-docker us-central1-docker.pkg.dev
```

#### Step 3: Build and Push Image
```bash
# Build the Docker image
docker build -t us-central1-docker.pkg.dev/YOUR_PROJECT_ID/dynamic-persona-frontend/app:latest .

# Push to Artifact Registry
docker push us-central1-docker.pkg.dev/YOUR_PROJECT_ID/dynamic-persona-frontend/app:latest
```

#### Step 4: Deploy from Artifact Registry
```bash
gcloud run deploy dynamic-persona-frontend \
  --image us-central1-docker.pkg.dev/YOUR_PROJECT_ID/dynamic-persona-frontend/app:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 8080 \
  --memory 512Mi \
  --cpu 1 \
  --max-instances 10 \
  --set-env-vars BACKEND_BASE_URL=/api,IAP_MODE=false
```

## Environment Configuration

### Development Environment
```bash
gcloud run deploy dynamic-persona-frontend-dev \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 8080 \
  --memory 512Mi \
  --cpu 1 \
  --max-instances 5 \
  --set-env-vars APP_PUBLIC_PATH=/,BACKEND_BASE_URL=https://dev-api.example.com,IAP_MODE=false,IAP_AUDIENCE= \
  --tag dev
```

### Staging Environment
```bash
gcloud run deploy dynamic-persona-frontend-staging \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 8080 \
  --memory 512Mi \
  --cpu 1 \
  --max-instances 8 \
  --set-env-vars APP_PUBLIC_PATH=/,BACKEND_BASE_URL=/api,IAP_MODE=true,IAP_AUDIENCE=projects/PROJECT_NUMBER/global/backendServices/staging-backend \
  --tag staging
```

### Production Environment
```bash
gcloud run deploy dynamic-persona-frontend \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 8080 \
  --memory 1Gi \
  --cpu 2 \
  --max-instances 20 \
  --min-instances 1 \
  --set-env-vars APP_PUBLIC_PATH=/,BACKEND_BASE_URL=/api,IAP_MODE=true,IAP_AUDIENCE=projects/PROJECT_NUMBER/global/backendServices/prod-backend \
  --tag production
```

## Updating Environment Variables

You can update environment variables without rebuilding:

```bash
# Update backend URL
gcloud run services update dynamic-persona-frontend \
  --region us-central1 \
  --update-env-vars BACKEND_BASE_URL=https://new-api.example.com

# Update multiple variables
gcloud run services update dynamic-persona-frontend \
  --region us-central1 \
  --update-env-vars BACKEND_BASE_URL=/api,IAP_MODE=true

# Remove environment variable
gcloud run services update dynamic-persona-frontend \
  --region us-central1 \
  --remove-env-vars IAP_AUDIENCE
```

## Custom Domain Setup

### Step 1: Verify Domain Ownership
```bash
# Add domain to Cloud Run
gcloud run domain-mappings create \
  --service dynamic-persona-frontend \
  --domain app.example.com \
  --region us-central1
```

### Step 2: Configure DNS
Add the provided CNAME record to your DNS provider:
```
app.example.com CNAME ghs.googlehosted.com
```

### Step 3: SSL Certificate
Cloud Run automatically provisions SSL certificates for custom domains.

## Traffic Management

### Blue-Green Deployment
```bash
# Deploy new revision with tag
gcloud run deploy dynamic-persona-frontend \
  --source . \
  --region us-central1 \
  --tag blue \
  --no-traffic

# Test the new revision
curl https://blue---dynamic-persona-frontend-xxxx.a.run.app

# Switch traffic to new revision
gcloud run services update-traffic dynamic-persona-frontend \
  --region us-central1 \
  --to-tags blue=100
```

### Gradual Traffic Migration
```bash
# Split traffic between revisions
gcloud run services update-traffic dynamic-persona-frontend \
  --region us-central1 \
  --to-revisions previous-revision=80,latest=20

# Gradually increase traffic to new revision
gcloud run services update-traffic dynamic-persona-frontend \
  --region us-central1 \
  --to-revisions previous-revision=50,latest=50

# Complete migration
gcloud run services update-traffic dynamic-persona-frontend \
  --region us-central1 \
  --to-latest
```

## Monitoring and Logging

### View Logs
```bash
# Real-time logs
gcloud run services logs tail dynamic-persona-frontend \
  --region us-central1 \
  --follow

# Historical logs
gcloud run services logs read dynamic-persona-frontend \
  --region us-central1 \
  --limit 100
```

### Service Information
```bash
# Get service details
gcloud run services describe dynamic-persona-frontend \
  --region us-central1

# List all revisions
gcloud run revisions list \
  --service dynamic-persona-frontend \
  --region us-central1

# Get revision details
gcloud run revisions describe REVISION_NAME \
  --region us-central1
```

### Health Checks
```bash
# Test health endpoint
curl https://YOUR_SERVICE_URL/health

# Expected response: "healthy"
```

## Troubleshooting

### Common Issues

#### Build Failures
```bash
# Check build logs
gcloud logging read "resource.type=build" --limit 50

# Check for Flutter/Dart issues
gcloud run deploy dynamic-persona-frontend --source . --verbosity=debug
```

#### Container Startup Issues
```bash
# Check container logs
gcloud run services logs read dynamic-persona-frontend --region us-central1

# Common issues:
# - Port 8080 not exposed
# - entrypoint.sh permissions
# - Missing nginx configuration
```

#### Runtime Configuration Issues
```bash
# Test configuration endpoint
curl https://YOUR_SERVICE_URL/config/runtime-env.js

# Check environment variables
gcloud run services describe dynamic-persona-frontend \
  --region us-central1 \
  --format="value(spec.template.spec.template.spec.containers[0].env[].name,spec.template.spec.template.spec.containers[0].env[].value)"
```

#### IAP Integration Issues
```bash
# Verify IAP is configured
gcloud iap web get-iam-policy

# Test IAP-protected endpoint
curl -i https://YOUR_LOAD_BALANCER_URL/api/health
# Should redirect to Google OAuth if not authenticated
```

### Performance Optimization

#### Resource Allocation
```bash
# Monitor resource usage
gcloud run services describe dynamic-persona-frontend \
  --region us-central1 \
  --format="value(status.conditions)"

# Adjust CPU and memory based on metrics
gcloud run services update dynamic-persona-frontend \
  --region us-central1 \
  --memory 1Gi \
  --cpu 2
```

#### Cold Start Optimization
```bash
# Set minimum instances to avoid cold starts
gcloud run services update dynamic-persona-frontend \
  --region us-central1 \
  --min-instances 1

# Optimize for startup time
gcloud run services update dynamic-persona-frontend \
  --region us-central1 \
  --cpu-boost
```

## Rollback Procedures

### Quick Rollback
```bash
# List recent revisions
gcloud run revisions list \
  --service dynamic-persona-frontend \
  --region us-central1

# Rollback to previous revision
gcloud run services update-traffic dynamic-persona-frontend \
  --region us-central1 \
  --to-revisions PREVIOUS_REVISION_NAME=100
```

### Emergency Rollback
```bash
# Immediate rollback to last known good revision
gcloud run services replace-traffic dynamic-persona-frontend \
  --region us-central1 \
  --to-revisions KNOWN_GOOD_REVISION=100
```

## Multi-Region Deployment

### Deploy to Multiple Regions
```bash
# Primary region
gcloud run deploy dynamic-persona-frontend \
  --source . \
  --region us-central1 \
  --allow-unauthenticated

# Secondary region
gcloud run deploy dynamic-persona-frontend \
  --source . \
  --region europe-west1 \
  --allow-unauthenticated

# Asia region
gcloud run deploy dynamic-persona-frontend \
  --source . \
  --region asia-northeast1 \
  --allow-unauthenticated
```

### Global Load Balancer Setup
(This requires Load Balancer configuration - see IAP_SETUP.md for details)

## Cost Optimization

### Resource Limits
```bash
# Set conservative limits for cost control
gcloud run services update dynamic-persona-frontend \
  --region us-central1 \
  --memory 512Mi \
  --cpu 1 \
  --max-instances 10 \
  --concurrency 80
```

### Pricing Monitoring
```bash
# Monitor Cloud Run usage
gcloud logging read "resource.type=cloud_run_revision" --limit 100

# Use Cloud Monitoring for cost alerts
```

## Security Best Practices

### Service Account
```bash
# Create dedicated service account
gcloud iam service-accounts create dynamic-persona-frontend \
  --display-name "Dynamic Persona Frontend"

# Assign minimal permissions
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member serviceAccount:dynamic-persona-frontend@YOUR_PROJECT_ID.iam.gserviceaccount.com \
  --role roles/run.invoker

# Deploy with custom service account
gcloud run deploy dynamic-persona-frontend \
  --source . \
  --region us-central1 \
  --service-account dynamic-persona-frontend@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

### VPC Integration (Optional)
```bash
# Deploy with VPC connector for internal services
gcloud run deploy dynamic-persona-frontend \
  --source . \
  --region us-central1 \
  --vpc-connector YOUR_VPC_CONNECTOR \
  --vpc-egress private-ranges-only
```

## Automation Scripts

### Deployment Script
```bash
#!/bin/bash
# deploy.sh

set -e

PROJECT_ID=${1:-your-default-project}
REGION=${2:-us-central1}
ENV=${3:-development}

echo "Deploying to $ENV environment in $PROJECT_ID"

case $ENV in
  development)
    BACKEND_URL="https://dev-api.example.com"
    IAP_MODE="false"
    MAX_INSTANCES="5"
    ;;
  staging)
    BACKEND_URL="/api"
    IAP_MODE="true"
    MAX_INSTANCES="8"
    ;;
  production)
    BACKEND_URL="/api"
    IAP_MODE="true"
    MAX_INSTANCES="20"
    ;;
esac

gcloud run deploy dynamic-persona-frontend-$ENV \
  --source . \
  --platform managed \
  --region $REGION \
  --project $PROJECT_ID \
  --allow-unauthenticated \
  --port 8080 \
  --max-instances $MAX_INSTANCES \
  --set-env-vars BACKEND_BASE_URL=$BACKEND_URL,IAP_MODE=$IAP_MODE

echo "Deployment completed: https://dynamic-persona-frontend-$ENV-xxxx.a.run.app"
```

Usage:
```bash
chmod +x deploy.sh
./deploy.sh your-project-id us-central1 production
```
