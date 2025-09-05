# Production Deployment Guide

## Prerequisites

1. **Google Cloud Setup**:
   ```bash
   # Enable required APIs
   gcloud services enable cloudbuild.googleapis.com
   gcloud services enable run.googleapis.com
   gcloud services enable artifactregistry.googleapis.com
   
   # Create Artifact Registry repository
   gcloud artifacts repositories create dynamic-persona-frontend \
     --repository-format=docker \
     --location=us-central1
   ```

2. **GitHub Repository**: Push code to GitHub with Cloud Build integration

## Deployment Options

### Option 1: Automatic Deployment (GitHub Integration)

1. **Connect Cloud Build to GitHub**:
   - Go to Cloud Build in Google Cloud Console
   - Connect to your GitHub repository
   - Create trigger for the `develop` branch

2. **Configure Build Triggers**:
   ```yaml
   # Trigger configuration (auto-generated in Cloud Console)
   name: 'deploy-dynamic-persona-frontend'
   github:
     owner: 'AI-POC-SQUAD'
     name: 'rg-dynamic-persona-frontend'
     push:
       branch: 'develop'
   filename: 'cloudbuild.yaml'
   ```

3. **Set Substitution Variables** in the trigger:
   ```
   _REGION: europe-west9
   _SERVICE: rg-dynamic-persona-frontend
   _BACKEND_BASE_URL: https://rg-dynamic-persona-1036279278510.europe-west9.run.app
   _AUTH_MODE: bearer
   _BEARER_TOKEN: ${SECRET_BEARER_TOKEN}  # Use Secret Manager
   ```

### Option 2: Manual Deployment

```bash
# Build and deploy manually
gcloud builds submit --config cloudbuild.yaml \
  --substitutions=_REGION=europe-west9,_SERVICE=rg-dynamic-persona-frontend,_BACKEND_BASE_URL=https://rg-dynamic-persona-1036279278510.europe-west9.run.app,_AUTH_MODE=bearer
```

## Security Best Practices

### 1. Secret Management

**Never commit bearer tokens to Git!** Use Google Secret Manager:

```bash
# Store bearer token in Secret Manager
echo "your-bearer-token" | gcloud secrets create bearer-token --data-file=-

# Reference in Cloud Build
_BEARER_TOKEN: ${SECRET_BEARER_TOKEN}
```

### 2. IAM Configuration

The Cloud Run service should have these IAM permissions:
- `Cloud Run Invoker` for the frontend service account
- `Secret Manager Secret Accessor` for accessing secrets

### 3. Environment Variables

For production deployment, configure these variables:

```yaml
# Production environment variables
APP_PUBLIC_PATH: "/"
BACKEND_BASE_URL: "https://rg-dynamic-persona-1036279278510.europe-west9.run.app"
AUTH_MODE: "bearer"
BEARER_TOKEN: "${SECRET_BEARER_TOKEN}"  # From Secret Manager
IAP_MODE: "false"
```

## Cloud Run Configuration

### Service Settings
- **Region**: `europe-west9` (same as your backend)
- **Memory**: `512Mi`
- **CPU**: `1`
- **Timeout**: `300s`
- **Max Instances**: `10`
- **Min Instances**: `0` (scale to zero)

### Authentication
- **Allow unauthenticated** invocations (frontend is public)
- Backend authentication handled via bearer tokens

### Custom Domain (Optional)
```bash
# Map custom domain
gcloud run domain-mappings create \
  --service rg-dynamic-persona-frontend \
  --domain your-domain.com \
  --region europe-west9
```

## Monitoring and Logs

### Cloud Logging
```bash
# View application logs
gcloud logs read "resource.type=cloud_run_revision" \
  --filter="resource.labels.service_name=rg-dynamic-persona-frontend"
```

### Health Checks
The service includes a health endpoint at `/health` for monitoring.

## Troubleshooting

### Build Failures
1. Check Cloud Build logs in Google Cloud Console
2. Verify Docker build locally: `docker build -t test .`
3. Check Flutter dependencies and versions

### Runtime Issues
1. Check Cloud Run logs for errors
2. Verify environment variables are set correctly
3. Test backend connectivity with curl:
   ```bash
   curl -H "Authorization: Bearer YOUR_TOKEN" \
        -H "Content-Type: text/plain" \
        -d "test message" \
        https://rg-dynamic-persona-1036279278510.europe-west9.run.app/chat
   ```

### Authentication Issues
1. Verify bearer token is valid and not expired
2. Check IAM permissions on the backend service
3. Ensure CORS is configured on the backend

## Cost Optimization

- **Scale to Zero**: Configure min instances to 0
- **Right-sizing**: Start with 512Mi memory and 1 CPU
- **Request-based Billing**: You only pay for actual requests
- **Regional Selection**: Use same region as backend (europe-west9)

## CI/CD Pipeline

The repository includes a complete CI/CD setup:
1. **Code Push** → GitHub
2. **Automatic Build** → Cloud Build
3. **Container Build** → Artifact Registry
4. **Deploy** → Cloud Run
5. **Health Check** → Service ready

## Repository Status

✅ **Ready for deployment:**
- Dockerfile optimized for production
- Multi-stage build (Flutter + NGINX)
- Runtime configuration injection
- Health check endpoints
- Comprehensive documentation
- Security best practices implemented
