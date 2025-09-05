# CI/CD Setup Guide

This guide covers setting up automated CI/CD pipelines for the Dynamic Persona Frontend. You can choose between Cloud Run's GitHub integration or Cloud Build triggers.

## Deployment Options Overview

| Method | Pros | Cons | Best For |
|--------|------|------|----------|
| **Cloud Run GitHub Integration** | Simple setup, automatic builds, no Cloud Build costs | Limited customization, fewer build steps | Simple deployments, getting started |
| **Cloud Build Triggers** | Full customization, complex pipelines, advanced features | More setup, Cloud Build costs | Production environments, complex workflows |

## Option 1: Cloud Run GitHub Integration (Recommended for Simplicity)

### Prerequisites
- GitHub repository with your code
- Google Cloud project with Cloud Run API enabled
- Proper permissions for Cloud Run service

### Setup Steps

#### 1. Connect GitHub Repository
```bash
# Enable required APIs
gcloud services enable run.googleapis.com
gcloud services enable cloudbuild.googleapis.com

# Connect repository (interactive)
gcloud run deploy dynamic-persona-frontend \
  --source https://github.com/YOUR_USERNAME/YOUR_REPO \
  --region us-central1 \
  --allow-unauthenticated
```

#### 2. Configure Environment Variables
After initial deployment, set environment variables:

```bash
# Development environment
gcloud run services update dynamic-persona-frontend \
  --region us-central1 \
  --update-env-vars BACKEND_BASE_URL=https://dev-api.example.com,IAP_MODE=false

# Production environment
gcloud run services update dynamic-persona-frontend \
  --region us-central1 \
  --update-env-vars BACKEND_BASE_URL=/api,IAP_MODE=true,IAP_AUDIENCE=projects/PROJECT_NUMBER/global/backendServices/prod-backend
```

#### 3. Set Up Automatic Deployments

**Via Google Cloud Console:**
1. Go to Cloud Run → Services → your-service
2. Click "Edit & Deploy New Revision"
3. Go to "Advanced" → "Continuous Deployment"
4. Connect your GitHub repository
5. Configure branch and build settings

**Via gcloud CLI:**
```bash
# Set up continuous deployment from main branch
gcloud run services replace YOUR_SERVICE_NAME \
  --region us-central1 \
  --source https://github.com/YOUR_USERNAME/YOUR_REPO \
  --source-revision main
```

### Branch-Based Environments

#### Development Branch → Dev Environment
```bash
gcloud run deploy dynamic-persona-frontend-dev \
  --source https://github.com/YOUR_USERNAME/YOUR_REPO \
  --source-revision develop \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars BACKEND_BASE_URL=https://dev-api.example.com,IAP_MODE=false
```

#### Main Branch → Production Environment
```bash
gcloud run deploy dynamic-persona-frontend \
  --source https://github.com/YOUR_USERNAME/YOUR_REPO \
  --source-revision main \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars BACKEND_BASE_URL=/api,IAP_MODE=true
```

### Advantages of GitHub Integration
- **Zero Configuration**: Uses your existing Dockerfile
- **Automatic Builds**: Triggers on every push to configured branch
- **Simple Setup**: Minimal configuration required
- **Cost Effective**: No separate Cloud Build charges

### Limitations of GitHub Integration
- **Limited Customization**: Can't add custom build steps
- **Single Dockerfile**: Must use Dockerfile in repository root
- **No Multi-Stage Pipelines**: Can't run tests before deployment
- **Limited Environment Control**: Basic environment variable support

---

## Option 2: Cloud Build Triggers (Recommended for Production)

### Prerequisites
- GitHub repository connected to Cloud Build
- Artifact Registry repository for images
- Cloud Build API enabled

### Setup Steps

#### 1. Enable APIs and Set Up Artifact Registry
```bash
# Enable required APIs
gcloud services enable cloudbuild.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable run.googleapis.com

# Create Artifact Registry repository
gcloud artifacts repositories create dynamic-persona-frontend \
  --repository-format=docker \
  --location=us-central1 \
  --description="Dynamic Persona Frontend images"
```

#### 2. Connect GitHub Repository
```bash
# Connect GitHub repository to Cloud Build
gcloud alpha builds connections create github \
  --region=us-central1 \
  YOUR_CONNECTION_NAME

# Link repository
gcloud alpha builds repositories create \
  --connection=YOUR_CONNECTION_NAME \
  --region=us-central1 \
  --remote-uri=https://github.com/YOUR_USERNAME/YOUR_REPO
```

#### 3. Create Cloud Build Triggers

**Development Environment Trigger:**
```bash
gcloud builds triggers create github \
  --region=us-central1 \
  --repo-name=YOUR_REPO \
  --repo-owner=YOUR_USERNAME \
  --branch-pattern="^develop$" \
  --build-config=cloudbuild.yaml \
  --description="Deploy to development environment" \
  --substitutions=_REGION=us-central1,_REPO=dynamic-persona-frontend,_SERVICE=dynamic-persona-frontend-dev,_BACKEND_BASE_URL=https://dev-api.example.com,_IAP_MODE=false,_IAP_AUDIENCE=,_MAX_INSTANCES=5,_MEMORY=512Mi,_CPU=1
```

**Production Environment Trigger:**
```bash
gcloud builds triggers create github \
  --region=us-central1 \
  --repo-name=YOUR_REPO \
  --repo-owner=YOUR_USERNAME \
  --branch-pattern="^main$" \
  --build-config=cloudbuild.yaml \
  --description="Deploy to production environment" \
  --substitutions=_REGION=us-central1,_REPO=dynamic-persona-frontend,_SERVICE=dynamic-persona-frontend,_BACKEND_BASE_URL=/api,_IAP_MODE=true,_IAP_AUDIENCE=projects/PROJECT_NUMBER/global/backendServices/prod-backend,_MAX_INSTANCES=20,_MEMORY=1Gi,_CPU=2
```

#### 4. Configure Service Account Permissions
```bash
# Get Cloud Build service account
PROJECT_NUMBER=$(gcloud projects describe YOUR_PROJECT_ID --format="value(projectNumber)")
CLOUDBUILD_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"

# Grant permissions for Cloud Run deployment
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member=serviceAccount:${CLOUDBUILD_SA} \
  --role=roles/run.admin

gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member=serviceAccount:${CLOUDBUILD_SA} \
  --role=roles/iam.serviceAccountUser

# Grant permissions for Artifact Registry
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member=serviceAccount:${CLOUDBUILD_SA} \
  --role=roles/artifactregistry.writer
```

### Advanced Cloud Build Configuration

#### Enhanced cloudbuild.yaml with Testing
```yaml
steps:
  # Run tests
  - name: 'cirrusci/flutter:stable'
    entrypoint: 'sh'
    args:
      - '-c'
      - |
        cd app
        flutter pub get
        flutter test
        flutter analyze

  # Build Docker image
  - name: 'gcr.io/cloud-builders/docker'
    args: [
      'build',
      '-t', '${_REGION}-docker.pkg.dev/${PROJECT_ID}/${_REPO}/${_SERVICE}:${COMMIT_SHA}',
      '-t', '${_REGION}-docker.pkg.dev/${PROJECT_ID}/${_REPO}/${_SERVICE}:latest',
      '.'
    ]

  # Push to Artifact Registry
  - name: 'gcr.io/cloud-builders/docker'
    args: [
      'push',
      '--all-tags',
      '${_REGION}-docker.pkg.dev/${PROJECT_ID}/${_REPO}/${_SERVICE}'
    ]

  # Security scan (optional)
  - name: 'gcr.io/cloud-builders/gcloud'
    entrypoint: 'sh'
    args:
      - '-c'
      - |
        gcloud container images scan ${_REGION}-docker.pkg.dev/${PROJECT_ID}/${_REPO}/${_SERVICE}:${COMMIT_SHA} \
          --location=${_REGION} || echo "Scan completed with findings"

  # Deploy to Cloud Run
  - name: 'gcr.io/google.com/cloudsdktool/cloud-sdk'
    entrypoint: 'gcloud'
    args: [
      'run', 'deploy', '${_SERVICE}',
      '--image', '${_REGION}-docker.pkg.dev/${PROJECT_ID}/${_REPO}/${_SERVICE}:${COMMIT_SHA}',
      '--region', '${_REGION}',
      '--platform', 'managed',
      '--port', '8080',
      '--allow-unauthenticated',
      '--set-env-vars', 'APP_PUBLIC_PATH=${_APP_PUBLIC_PATH},BACKEND_BASE_URL=${_BACKEND_BASE_URL},IAP_MODE=${_IAP_MODE},IAP_AUDIENCE=${_IAP_AUDIENCE}',
      '--max-instances', '${_MAX_INSTANCES}',
      '--memory', '${_MEMORY}',
      '--cpu', '${_CPU}',
      '--timeout', '${_TIMEOUT}'
    ]

  # Smoke test
  - name: 'gcr.io/cloud-builders/curl'
    args: ['--fail', '--retry', '3', '--retry-delay', '10', 'https://${_SERVICE}-xxxx.a.run.app/health']

substitutions:
  _REGION: 'us-central1'
  _REPO: 'dynamic-persona-frontend'
  _SERVICE: 'dynamic-persona-frontend'
  _APP_PUBLIC_PATH: '/'
  _BACKEND_BASE_URL: '/api'
  _IAP_MODE: 'false'
  _IAP_AUDIENCE: ''
  _MAX_INSTANCES: '10'
  _MEMORY: '512Mi'
  _CPU: '1'
  _TIMEOUT: '300'

timeout: '1800s'
options:
  machineType: 'E2_HIGHCPU_8'
  logging: CLOUD_LOGGING_ONLY
```

### Multi-Environment Pipeline

#### Environment-Specific Triggers

**Feature Branch Trigger (Preview):**
```bash
gcloud builds triggers create github \
  --region=us-central1 \
  --repo-name=YOUR_REPO \
  --repo-owner=YOUR_USERNAME \
  --branch-pattern="^feature/.*$" \
  --build-config=cloudbuild-preview.yaml \
  --description="Deploy preview environment for feature branches"
```

**cloudbuild-preview.yaml:**
```yaml
steps:
  # Quick validation build (no deployment)
  - name: 'cirrusci/flutter:stable'
    entrypoint: 'sh'
    args:
      - '-c'
      - |
        cd app
        flutter pub get
        flutter analyze
        flutter test

  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'temp-image', '.']

  # Comment on PR with preview URL (if applicable)
  - name: 'gcr.io/cloud-builders/gcloud'
    entrypoint: 'sh'
    args:
      - '-c'
      - |
        echo "Build validation completed for branch ${BRANCH_NAME}"
```

### Pipeline Monitoring

#### Build Notifications
```bash
# Set up Pub/Sub topic for build notifications
gcloud pubsub topics create cloud-build-notifications

# Create subscription
gcloud pubsub subscriptions create build-notifications-email \
  --topic=cloud-build-notifications

# Configure Cloud Build to publish to topic
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member=serviceAccount:${CLOUDBUILD_SA} \
  --role=roles/pubsub.publisher
```

#### Monitoring Dashboard
Create monitoring dashboards for:
- Build success/failure rates
- Deployment frequency
- Build duration
- Service health after deployment

### Rollback Strategies

#### Automatic Rollback on Failure
```yaml
# Add to cloudbuild.yaml
steps:
  # ... previous steps ...
  
  # Health check with rollback
  - name: 'gcr.io/cloud-builders/gcloud'
    entrypoint: 'sh'
    args:
      - '-c'
      - |
        # Wait for deployment to be ready
        gcloud run services wait ${_SERVICE} --region=${_REGION}
        
        # Get service URL
        SERVICE_URL=$(gcloud run services describe ${_SERVICE} --region=${_REGION} --format="value(status.url)")
        
        # Health check
        if ! curl --fail --retry 3 --retry-delay 10 $SERVICE_URL/health; then
          echo "Health check failed, rolling back"
          gcloud run services update-traffic ${_SERVICE} \
            --region=${_REGION} \
            --to-revisions=${_PREVIOUS_REVISION}=100
          exit 1
        fi
```

### Security Best Practices

#### Secure Substitutions
```bash
# Store sensitive values in Secret Manager
gcloud secrets create iap-audience --data-file=iap-audience.txt

# Use in Cloud Build
gcloud builds triggers update TRIGGER_ID \
  --substitutions=_IAP_AUDIENCE_SECRET=projects/YOUR_PROJECT_ID/secrets/iap-audience/versions/latest
```

#### Least Privilege Access
```bash
# Create dedicated service account for Cloud Run
gcloud iam service-accounts create dynamic-persona-frontend-sa

# Grant minimal permissions
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member=serviceAccount:dynamic-persona-frontend-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com \
  --role=roles/run.invoker

# Use in deployment
gcloud run deploy dynamic-persona-frontend \
  --service-account=dynamic-persona-frontend-sa@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

### Cost Optimization

#### Build Optimization
```yaml
# Use shorter timeout for faster feedback
timeout: '600s'

# Use smaller machine type for simple builds
options:
  machineType: 'E2_MEDIUM'

# Cache dependencies
steps:
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '--cache-from', 'gcr.io/$PROJECT_ID/cache:latest', '-t', 'app', '.']
```

#### Conditional Deployments
```yaml
# Only deploy if tests pass
steps:
  - name: 'flutter-test'
    # ... test steps
  
  # Deploy only on main branch
  - name: 'deploy'
    condition: 'branch == "main"'
    # ... deploy steps
```

## Comparison Summary

### Cloud Run GitHub Integration
**Best for:**
- Small teams
- Simple applications
- Getting started quickly
- Cost-sensitive projects

**Use when:**
- You have a simple Dockerfile
- You don't need complex testing pipelines
- You want minimal configuration

### Cloud Build Triggers
**Best for:**
- Production environments
- Complex applications
- Teams requiring advanced CI/CD features
- Applications with multiple environments

**Use when:**
- You need testing before deployment
- You require custom build steps
- You need advanced security scanning
- You want detailed build monitoring

## Migration Path

### From GitHub Integration to Cloud Build
1. **Prepare Cloud Build configuration**: Create `cloudbuild.yaml`
2. **Set up Artifact Registry**: Create image repository
3. **Create triggers**: Configure branch-based triggers
4. **Test in parallel**: Run both systems temporarily
5. **Switch over**: Disable GitHub integration, enable Cloud Build
6. **Clean up**: Remove old configurations

### Best Practices for Both Approaches
- **Environment Separation**: Use different services for dev/staging/prod
- **Monitoring**: Set up alerting for failed deployments
- **Documentation**: Keep deployment procedures documented
- **Testing**: Always include health checks after deployment
- **Rollback Plans**: Have clear rollback procedures ready
