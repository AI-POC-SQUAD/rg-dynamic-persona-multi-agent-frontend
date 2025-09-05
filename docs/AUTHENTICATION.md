# Authentication Configuration

This document explains how to configure authentication for the Dynamic Persona Frontend when connecting to backends with different authentication requirements.

## Authentication Modes

The application supports three authentication modes:

### 1. No Authentication (`AUTH_MODE=none`)
- Default mode
- No authentication headers are sent
- Suitable for development backends without authentication

### 2. Bearer Token Authentication (`AUTH_MODE=bearer`)
- Uses bearer tokens in the Authorization header
- **Recommended for Cloud Run with IAM authentication**
- Requires a valid bearer token

### 3. Google Cloud IAP (`IAP_MODE=true`)
- Uses Google Cloud Identity-Aware Proxy
- Relies on browser session cookies
- No explicit Authorization header needed

## Cloud Run IAM Authentication Setup

For Cloud Run services with IAM authentication enabled:

### Step 1: Generate a Bearer Token

Use Google Cloud CLI to generate an identity token:

```bash
# Get an identity token for your Cloud Run service
gcloud auth print-identity-token --audiences=https://your-cloud-run-service-url
```

### Step 2: Configure Environment Variables

Set the following environment variables when running the container:

```bash
# Set authentication mode to bearer
AUTH_MODE=bearer

# Set your Cloud Run service URL
BACKEND_BASE_URL=https://your-cloud-run-service-url

# Set the identity token from step 1
BEARER_TOKEN=eyJhbGciOiJSUzI1NiIs...

# Optional: Disable IAP mode if previously enabled
IAP_MODE=false
```

### Step 3: Run the Container

```bash
docker run -p 8080:8080 \
  -e AUTH_MODE=bearer \
  -e BACKEND_BASE_URL=https://your-cloud-run-service-url \
  -e BEARER_TOKEN=your-identity-token \
  -e IAP_MODE=false \
  rg-dynamic-persona-frontend
```

## Local Development Setup

For local development against a Cloud Run backend:

### Option 1: Using Environment Variables

Create a `.env` file (not committed to git):

```env
AUTH_MODE=bearer
BACKEND_BASE_URL=https://your-cloud-run-service-url
BEARER_TOKEN=your-identity-token
IAP_MODE=false
```

### Option 2: Using Docker Compose

Create a `docker-compose.override.yml`:

```yaml
version: '3.8'
services:
  frontend:
    environment:
      - AUTH_MODE=bearer
      - BACKEND_BASE_URL=https://your-cloud-run-service-url
      - BEARER_TOKEN=your-identity-token
      - IAP_MODE=false
```

## Token Refresh

Identity tokens have a limited lifetime (typically 1 hour). For longer development sessions:

### Manual Refresh
```bash
# Get a new token
NEW_TOKEN=$(gcloud auth print-identity-token --audiences=https://your-cloud-run-service-url)

# Update the container environment or restart with new token
```

### Automatic Refresh Script
```bash
#!/bin/bash
# refresh-token.sh
while true; do
    echo "Refreshing identity token..."
    NEW_TOKEN=$(gcloud auth print-identity-token --audiences=https://your-cloud-run-service-url)
    
    # Update your container or development environment with NEW_TOKEN
    # This depends on your setup (Docker environment, etc.)
    
    # Wait 50 minutes before next refresh
    sleep 3000
done
```

## Troubleshooting

### 401 Authentication Failed
- Check that your bearer token is valid and not expired
- Verify the audience URL matches your Cloud Run service
- Ensure you have the correct permissions to invoke the service

### 403 Access Forbidden
- Your token is valid but you don't have permission to invoke the service
- Check IAM permissions on the Cloud Run service
- Ensure your user/service account has the `Cloud Run Invoker` role

### CORS Errors
- Cloud Run services need CORS configuration for browser requests
- Ensure your backend allows requests from your frontend domain
- For local development, the backend should allow `http://localhost:8080`

### Token Format Issues
- Tokens should start with `eyJ` for JWT format
- Don't include "Bearer " prefix in the BEARER_TOKEN environment variable
- The application automatically adds "Bearer " to the Authorization header

## Security Considerations

### For Production
- Never commit tokens to version control
- Use secure secret management (Google Secret Manager, etc.)
- Consider using workload identity for service-to-service communication
- Rotate tokens regularly

### For Development
- Keep tokens in local `.env` files that are gitignored
- Don't share tokens in chat/email
- Use short-lived tokens when possible
- Consider using gcloud auth application-default login for local development

## Example: Complete Local Setup

1. **Authenticate with Google Cloud:**
   ```bash
   gcloud auth login
   gcloud config set project your-project-id
   ```

2. **Get an identity token:**
   ```bash
   TOKEN=$(gcloud auth print-identity-token --audiences=https://your-service-abc123-uc.a.run.app)
   echo $TOKEN
   ```

3. **Run the frontend container:**
   ```bash
   docker run -p 8080:8080 \
     -e AUTH_MODE=bearer \
     -e BACKEND_BASE_URL=https://your-service-abc123-uc.a.run.app \
     -e BEARER_TOKEN=$TOKEN \
     rg-dynamic-persona-frontend
   ```

4. **Test the connection:**
   - Open http://localhost:8080
   - Send a test message in the chat
   - Check browser console for any authentication errors

The application will now authenticate with your Cloud Run backend using IAM authentication.
