#!/bin/bash

# test-cloud-run-auth.sh
# Example script to test the frontend with Cloud Run IAM authentication

set -e

echo "🔧 Testing Dynamic Persona Frontend with Cloud Run IAM Authentication"
echo

# Check if required tools are available
if ! command -v gcloud &> /dev/null; then
    echo "❌ Error: gcloud CLI is not installed or not in PATH"
    echo "   Please install the Google Cloud SDK: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker is not installed or not in PATH"
    exit 1
fi

# Prompt for Cloud Run service URL
read -p "🌐 Enter your Cloud Run service URL (e.g., https://your-service-abc123-uc.a.run.app): " CLOUD_RUN_URL

if [[ -z "$CLOUD_RUN_URL" ]]; then
    echo "❌ Error: Cloud Run URL is required"
    exit 1
fi

echo "🔑 Generating identity token for Cloud Run service..."

# Generate identity token
TOKEN=$(gcloud auth print-identity-token --audiences="$CLOUD_RUN_URL" 2>/dev/null)

if [[ -z "$TOKEN" ]]; then
    echo "❌ Error: Failed to generate identity token"
    echo "   Make sure you're authenticated with: gcloud auth login"
    echo "   And that you have permission to invoke the Cloud Run service"
    exit 1
fi

echo "✅ Identity token generated successfully"
echo "🔧 Token preview: ${TOKEN:0:20}..."

echo
echo "🚀 Starting frontend container with Cloud Run authentication..."

# Stop any existing container
docker stop rg-persona-frontend 2>/dev/null || true
docker rm rg-persona-frontend 2>/dev/null || true

# Start the container with authentication
docker run -d \
  --name rg-persona-frontend \
  -p 8080:8080 \
  -e AUTH_MODE=bearer \
  -e BACKEND_BASE_URL="$CLOUD_RUN_URL" \
  -e BEARER_TOKEN="$TOKEN" \
  -e IAP_MODE=false \
  rg-dynamic-persona-frontend

echo "✅ Container started successfully!"
echo
echo "🌐 Frontend available at: http://localhost:8080"
echo "🔗 Backend URL: $CLOUD_RUN_URL"
echo "🔑 Authentication: Bearer token (IAM)"
echo
echo "📝 To test:"
echo "   1. Open http://localhost:8080 in your browser"
echo "   2. Send a test message in the chat"
echo "   3. Check the browser console for any errors"
echo
echo "⚠️  Note: The identity token expires in ~1 hour"
echo "   If you get 401 errors, re-run this script to refresh the token"
echo
echo "🛠️  To check container logs:"
echo "   docker logs rg-persona-frontend"
echo
echo "🛑 To stop the container:"
echo "   docker stop rg-persona-frontend"

# Wait a moment for the container to start
sleep 2

# Check if container is running
if docker ps | grep -q rg-persona-frontend; then
    echo "✅ Container is running successfully!"
else
    echo "❌ Container failed to start. Check logs with:"
    echo "   docker logs rg-persona-frontend"
    exit 1
fi
