# Authentication Strategy for Cloud Run to Cloud Run

## Current Challenge

Your setup has:
- **Frontend**: Public Cloud Run service (browser application)
- **Backend**: IAM-protected Cloud Run service (requires identity tokens)
- **Problem**: Browsers can't generate Google Cloud identity tokens

## Solution: Identity Token Proxy

Create a lightweight proxy service that handles authentication to your protected backend.

### Architecture

```
Browser → Frontend (Public) → Auth Proxy (IAM) → Backend (IAM)
```

## Implementation

### 1. Auth Proxy Service

Create a simple Cloud Run service that:
- Accepts requests from your frontend
- Uses service account to generate identity tokens
- Proxies requests to your protected backend

```python
# auth-proxy/main.py
from flask import Flask, request, jsonify
from google.auth.transport.requests import Request
from google.oauth2 import service_account
import requests
import os

app = Flask(__name__)

# Configuration
BACKEND_URL = os.environ.get('BACKEND_URL', 'https://rg-dynamic-persona-1036279278510.europe-west9.run.app')
TARGET_AUDIENCE = BACKEND_URL

def get_identity_token():
    """Generate identity token for the backend service"""
    # Use the default service account credentials
    request = Request()
    
    # Create ID token
    from google.auth import compute_engine
    credentials = compute_engine.IDTokenCredentials(
        request=request,
        target_audience=TARGET_AUDIENCE
    )
    
    credentials.refresh(request)
    return credentials.token

@app.route('/chat', methods=['POST'])
def proxy_chat():
    """Proxy chat requests to the protected backend"""
    try:
        # Get identity token
        token = get_identity_token()
        
        # Forward request to backend
        headers = {
            'Authorization': f'Bearer {token}',
            'Content-Type': request.content_type or 'text/plain'
        }
        
        response = requests.post(
            f'{BACKEND_URL}/chat',
            data=request.get_data(),
            headers=headers,
            timeout=30
        )
        
        # Return backend response
        return jsonify(response.json()), response.status_code
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/health')
def health():
    return {'status': 'ok', 'service': 'auth-proxy'}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
```

### 2. Deploy Auth Proxy

```bash
# Create auth-proxy directory
mkdir auth-proxy
cd auth-proxy

# Create requirements.txt
echo "flask==2.3.3
google-auth==2.23.0
requests==2.31.0" > requirements.txt

# Create Dockerfile
cat > Dockerfile << EOF
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY main.py .
CMD ["python", "main.py"]
EOF

# Deploy to Cloud Run
gcloud run deploy auth-proxy \
  --source . \
  --platform managed \
  --region europe-west9 \
  --allow-unauthenticated \
  --set-env-vars BACKEND_URL=https://rg-dynamic-persona-1036279278510.europe-west9.run.app
```

### 3. Update Frontend Configuration

Update your frontend to use the auth proxy instead of direct backend access:

```bash
# Set frontend to use auth proxy
docker run -p 8080:8080 \
  -e AUTH_MODE=none \
  -e BACKEND_BASE_URL=https://auth-proxy-[hash]-ew.a.run.app \
  rg-dynamic-persona-frontend
```

## Alternative: Simpler IAP Solution

### Enable IAP on Both Services

1. **Enable IAP on your backend**:
   ```bash
   # Your backend should already have this, but verify:
   gcloud run services update rg-dynamic-persona-backend \
     --region europe-west9 \
     --remove-flags allow-unauthenticated
   ```

2. **Enable IAP on your frontend** and use the same authenticated users:
   ```bash
   gcloud run services update rg-dynamic-persona-frontend \
     --region europe-west9 \
     --remove-flags allow-unauthenticated
   ```

3. **Configure IAP**:
   - Both services under the same IAP-protected load balancer
   - Users authenticate once for both services
   - Frontend can call backend using session cookies

### IAP Load Balancer Setup

```bash
# Create global load balancer with IAP
gcloud compute backend-services create persona-backend \
  --global \
  --load-balancing-scheme=EXTERNAL_MANAGED

# Add Cloud Run NEG
gcloud compute network-endpoint-groups create persona-neg \
  --region=europe-west9 \
  --network-endpoint-type=serverless \
  --cloud-run-service=rg-dynamic-persona-backend

gcloud compute backend-services add-backend persona-backend \
  --global \
  --network-endpoint-group=persona-neg \
  --network-endpoint-group-region=europe-west9

# Configure IAP
gcloud iap web enable --resource-type=backend-services \
  --service=persona-backend
```

## Recommended Approach

For your use case, I recommend the **Auth Proxy** approach because:

✅ **Simple**: One small proxy service  
✅ **Secure**: Uses service account authentication  
✅ **Scalable**: Proxy can handle multiple backends  
✅ **Flexible**: Easy to modify authentication logic  
✅ **Cost-effective**: Minimal additional resources  

Would you like me to:
1. Create the auth proxy service for you?
2. Set up IAP for both services?
3. Or implement a different authentication strategy?
