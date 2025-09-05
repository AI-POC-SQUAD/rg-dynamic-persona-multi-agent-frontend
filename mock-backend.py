# mock-backend.py
# Simple mock backend for testing the Dynamic Persona Frontend
# This creates a basic HTTP server that responds to chat messages

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import time
from urllib.parse import urlparse, parse_qs

class MockBackendHandler(BaseHTTPRequestHandler):
    def do_OPTIONS(self):
        """Handle CORS preflight requests"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()

    def do_GET(self):
        """Handle GET requests"""
        parsed_path = urlparse(self.path)
        
        # Health check endpoint
        if parsed_path.path == '/api/health':
            self.send_json_response({'status': 'ok', 'service': 'mock-backend'})
        else:
            self.send_json_response({'error': 'Not found'}, 404)

    def do_POST(self):
        """Handle POST requests"""
        parsed_path = urlparse(self.path)
        
        # Chat endpoint
        if parsed_path.path == '/api/chat':
            try:
                # Read request body
                content_length = int(self.headers['Content-Length'])
                post_data = self.rfile.read(content_length)
                request_data = json.loads(post_data.decode('utf-8'))
                
                # Extract message
                user_message = request_data.get('message', '')
                
                # Generate mock response based on message
                if 'hello' in user_message.lower():
                    response_text = "Hello! I'm a mock backend. Your frontend is working correctly!"
                elif 'test' in user_message.lower():
                    response_text = f"Test successful! I received: '{user_message}'"
                elif 'auth' in user_message.lower():
                    auth_header = self.headers.get('Authorization', 'None')
                    response_text = f"Authentication header: {auth_header}"
                else:
                    response_text = f"Mock response to: '{user_message}'. This is just a test backend!"
                
                # Send response
                self.send_json_response({
                    'response': response_text,
                    'timestamp': int(time.time()),
                    'mock': True
                })
                
            except Exception as e:
                self.send_json_response({'error': f'Error processing request: {str(e)}'}, 500)
        else:
            self.send_json_response({'error': 'Endpoint not found'}, 404)

    def send_json_response(self, data, status_code=200):
        """Send JSON response with CORS headers"""
        response_json = json.dumps(data, indent=2)
        
        self.send_response(status_code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()
        
        self.wfile.write(response_json.encode('utf-8'))

    def log_message(self, format, *args):
        """Custom log format"""
        print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] {format % args}")

if __name__ == '__main__':
    server_address = ('', 3000)
    httpd = HTTPServer(server_address, MockBackendHandler)
    
    print("=" * 60)
    print("🚀 Mock Backend Server Starting")
    print("=" * 60)
    print(f"📍 Server running on: http://localhost:3000")
    print(f"🔗 Health check: http://localhost:3000/api/health")
    print(f"💬 Chat endpoint: http://localhost:3000/api/chat")
    print()
    print("📝 Test messages you can try:")
    print("   - 'hello' -> Get a greeting")
    print("   - 'test' -> Echo back your message")
    print("   - 'auth' -> Check authentication headers")
    print()
    print("🛑 Press Ctrl+C to stop the server")
    print("=" * 60)
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 Server stopped")
        httpd.server_close()
