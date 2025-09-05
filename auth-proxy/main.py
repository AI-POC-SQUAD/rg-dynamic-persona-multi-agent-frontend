from flask import Flask, request, jsonify
from google.auth.transport.requests import Request
from google.auth import compute_engine
import requests
import os
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Configuration
BACKEND_URL = os.environ.get('BACKEND_URL', 'https://rg-dynamic-persona-1036279278510.europe-west9.run.app')
TARGET_AUDIENCE = BACKEND_URL

def get_identity_token():
    """Generate identity token for the backend service using default service account"""
    try:
        request_obj = Request()
        
        # Use Compute Engine default service account to create ID token
        credentials = compute_engine.IDTokenCredentials(
            request=request_obj,
            target_audience=TARGET_AUDIENCE
        )
        
        credentials.refresh(request_obj)
        logger.info(f"Successfully generated identity token for audience: {TARGET_AUDIENCE}")
        return credentials.token
        
    except Exception as e:
        logger.error(f"Failed to generate identity token: {str(e)}")
        raise

@app.route('/chat', methods=['POST', 'OPTIONS'])
def proxy_chat():
    """Proxy chat requests to the protected backend with IAM authentication"""
    
    # Handle CORS preflight
    if request.method == 'OPTIONS':
        response = jsonify({'status': 'ok'})
        response.headers.add('Access-Control-Allow-Origin', '*')
        response.headers.add('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS')
        return response
    
    try:
        logger.info(f"Proxying chat request to {BACKEND_URL}/chat")
        
        # Get identity token for backend authentication
        token = get_identity_token()
        
        # Prepare headers for backend request
        headers = {
            'Authorization': f'Bearer {token}',
            'Content-Type': request.content_type or 'text/plain'
        }
        
        # Get request data
        request_data = request.get_data()
        logger.info(f"Request data length: {len(request_data)} bytes")
        
        # Forward request to protected backend
        response = requests.post(
            f'{BACKEND_URL}/chat',
            data=request_data,
            headers=headers,
            timeout=30
        )
        
        logger.info(f"Backend response status: {response.status_code}")
        
        # Prepare response with CORS headers
        if response.status_code == 200:
            response_data = response.json()
            result = jsonify(response_data)
        else:
            logger.error(f"Backend error: {response.status_code} - {response.text}")
            result = jsonify({
                'error': f'Backend error: {response.status_code}',
                'details': response.text[:200]  # Limit error message length
            })
            result.status_code = response.status_code
        
        # Add CORS headers
        result.headers.add('Access-Control-Allow-Origin', '*')
        result.headers.add('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        result.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS')
        
        return result
        
    except requests.exceptions.Timeout:
        logger.error("Request to backend timed out")
        response = jsonify({'error': 'Backend request timed out'})
        response.status_code = 504
    except requests.exceptions.RequestException as e:
        logger.error(f"Request error: {str(e)}")
        response = jsonify({'error': f'Network error: {str(e)}'})
        response.status_code = 502
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        response = jsonify({'error': f'Internal server error: {str(e)}'})
        response.status_code = 500
    
    # Add CORS headers to error responses
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type, Authorization')
    response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS')
    
    return response

@app.route('/health')
def health():
    """Health check endpoint"""
    return jsonify({
        'status': 'ok', 
        'service': 'auth-proxy',
        'backend_url': BACKEND_URL,
        'target_audience': TARGET_AUDIENCE
    })

@app.route('/')
def index():
    """Root endpoint with service information"""
    return jsonify({
        'service': 'RG Dynamic Persona Auth Proxy',
        'description': 'Proxy service for IAM-authenticated Cloud Run backend',
        'endpoints': {
            '/chat': 'POST - Proxy chat requests to backend',
            '/health': 'GET - Health check'
        },
        'backend_url': BACKEND_URL
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    logger.info(f"Starting auth proxy server on port {port}")
    logger.info(f"Backend URL: {BACKEND_URL}")
    logger.info(f"Target audience: {TARGET_AUDIENCE}")
    
    app.run(host='0.0.0.0', port=port, debug=False)
