from flask import Flask, request, jsonify, Response
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
BACKEND_URL = os.environ.get('BACKEND_URL', 'https://corpus-explorer-api-1036279278510.europe-west4.run.app')
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

def add_cors_headers(response):
    """Add CORS headers to response"""
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type, Authorization')
    response.headers.add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
    return response

@app.route('/run_sse', methods=['POST', 'OPTIONS'])
def proxy_run_sse():
    """Proxy SSE streaming requests to the ADK backend"""
    
    # Handle CORS preflight
    if request.method == 'OPTIONS':
        response = jsonify({'status': 'ok'})
        return add_cors_headers(response)
    
    try:
        logger.info(f"Proxying SSE request to {BACKEND_URL}/run_sse")
        
        # Get identity token for backend authentication
        token = get_identity_token()
        
        # Prepare headers for backend request
        headers = {
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json',
            'Accept': 'text/event-stream'
        }
        
        # Get request data
        request_data = request.get_data()
        logger.info(f"SSE Request data: {request_data.decode('utf-8')[:200]}")
        
        # Forward request to backend with streaming
        backend_response = requests.post(
            f'{BACKEND_URL}/run_sse',
            data=request_data,
            headers=headers,
            stream=True,
            timeout=300  # 5 minute timeout for SSE
        )
        
        logger.info(f"Backend SSE response status: {backend_response.status_code}")
        
        if backend_response.status_code != 200:
            logger.error(f"Backend SSE error: {backend_response.status_code} - {backend_response.text}")
            response = jsonify({
                'error': f'Backend error: {backend_response.status_code}',
                'details': backend_response.text[:500]
            })
            response.status_code = backend_response.status_code
            return add_cors_headers(response)
        
        # Stream the response back to client
        def generate():
            for chunk in backend_response.iter_content(chunk_size=None):
                if chunk:
                    yield chunk
        
        response = Response(
            generate(),
            mimetype='text/event-stream',
            headers={
                'Cache-Control': 'no-cache',
                'Connection': 'keep-alive',
                'X-Accel-Buffering': 'no'
            }
        )
        return add_cors_headers(response)
        
    except Exception as e:
        logger.error(f"SSE proxy error: {str(e)}")
        response = jsonify({'error': f'SSE proxy error: {str(e)}'})
        response.status_code = 500
        return add_cors_headers(response)

@app.route('/apps/<path:subpath>', methods=['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'])
def proxy_apps(subpath):
    """Proxy all /apps/* requests to the ADK backend"""
    
    # Handle CORS preflight
    if request.method == 'OPTIONS':
        response = jsonify({'status': 'ok'})
        return add_cors_headers(response)
    
    try:
        target_url = f'{BACKEND_URL}/apps/{subpath}'
        logger.info(f"Proxying {request.method} request to {target_url}")
        
        # Get identity token for backend authentication
        token = get_identity_token()
        
        # Prepare headers for backend request
        headers = {
            'Authorization': f'Bearer {token}',
            'Content-Type': request.content_type or 'application/json'
        }
        
        # Get request data
        request_data = request.get_data() if request.method in ['POST', 'PUT'] else None
        
        # Forward request to backend
        response = requests.request(
            method=request.method,
            url=target_url,
            data=request_data,
            headers=headers,
            timeout=30
        )
        
        logger.info(f"Backend response status: {response.status_code}")
        
        # Prepare response with CORS headers
        if response.status_code == 200:
            try:
                response_data = response.json()
                result = jsonify(response_data)
            except:
                result = Response(response.text, mimetype='text/plain')
        else:
            logger.error(f"Backend error: {response.status_code} - {response.text}")
            result = jsonify({
                'error': f'Backend error: {response.status_code}',
                'details': response.text[:500]
            })
            result.status_code = response.status_code
        
        return add_cors_headers(result)
        
    except Exception as e:
        logger.error(f"Proxy error: {str(e)}")
        response = jsonify({'error': f'Proxy error: {str(e)}'})
        response.status_code = 500
        return add_cors_headers(response)

@app.route('/list-apps', methods=['GET', 'OPTIONS'])
def proxy_list_apps():
    """Proxy list-apps request to the ADK backend"""
    
    # Handle CORS preflight
    if request.method == 'OPTIONS':
        response = jsonify({'status': 'ok'})
        return add_cors_headers(response)
    
    try:
        target_url = f'{BACKEND_URL}/list-apps'
        logger.info(f"Proxying list-apps request to {target_url}")
        
        # Get identity token for backend authentication
        token = get_identity_token()
        
        headers = {
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json'
        }
        
        response = requests.get(target_url, headers=headers, timeout=30)
        
        logger.info(f"Backend response status: {response.status_code}")
        
        if response.status_code == 200:
            result = jsonify(response.json())
        else:
            result = jsonify({
                'error': f'Backend error: {response.status_code}',
                'details': response.text[:500]
            })
            result.status_code = response.status_code
        
        return add_cors_headers(result)
        
    except Exception as e:
        logger.error(f"List apps error: {str(e)}")
        response = jsonify({'error': f'Proxy error: {str(e)}'})
        response.status_code = 500
        return add_cors_headers(response)

@app.route('/chat', methods=['POST', 'OPTIONS'])
def proxy_chat():
    """Proxy chat requests to the protected backend with IAM authentication"""
    
    # Handle CORS preflight
    if request.method == 'OPTIONS':
        response = jsonify({'status': 'ok'})
        return add_cors_headers(response)
    
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
        
        return add_cors_headers(result)
        
    except requests.exceptions.Timeout:
        logger.error("Request to backend timed out")
        response = jsonify({'error': 'Backend request timed out'})
        response.status_code = 504
        return add_cors_headers(response)
    except requests.exceptions.RequestException as e:
        logger.error(f"Request error: {str(e)}")
        response = jsonify({'error': f'Network error: {str(e)}'})
        response.status_code = 502
        return add_cors_headers(response)
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        response = jsonify({'error': f'Internal server error: {str(e)}'})
        response.status_code = 500
        return add_cors_headers(response)

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
