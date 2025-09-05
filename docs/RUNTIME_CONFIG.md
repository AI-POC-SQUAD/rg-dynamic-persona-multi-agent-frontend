# Runtime Configuration Guide

## Overview

The Dynamic Persona Frontend uses runtime configuration injection to avoid rebuilding containers when environment settings change. This approach provides flexibility for different deployment environments while maintaining the same container image.

## How Runtime Configuration Works

### Configuration Injection Process

1. **Container Start**: When the container starts, `entrypoint.sh` runs
2. **Environment Reading**: Script reads environment variables
3. **JavaScript Generation**: Creates `/config/runtime-env.js` with configuration
4. **Browser Loading**: Flutter web app loads configuration via script tag
5. **Application Use**: Dart code accesses configuration through `window.__RUNTIME_CONFIG__`

### File Structure
```
/usr/share/nginx/html/
├── index.html                    # Includes runtime-env.js script
├── config/
│   └── runtime-env.js           # Generated at container start
└── [other Flutter web assets]
```

## Configuration Variables

### Core Environment Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `APP_PUBLIC_PATH` | string | `"/"` | Base path if app isn't served from domain root |
| `BACKEND_BASE_URL` | string | `"/api"` | Backend API base URL (absolute or relative) |
| `IAP_MODE` | boolean | `false` | Enable IAP cookie-based authentication |
| `IAP_AUDIENCE` | string | `""` | IAP audience for JWT validation (usually not needed in browser) |

### Environment Variable Details

#### APP_PUBLIC_PATH
```bash
# Root domain deployment
APP_PUBLIC_PATH="/"

# Subdirectory deployment
APP_PUBLIC_PATH="/chat/"

# Subdomain with path
APP_PUBLIC_PATH="/apps/chat/"
```

#### BACKEND_BASE_URL
```bash
# Same-origin (recommended for IAP)
BACKEND_BASE_URL="/api"

# Cross-origin absolute URL
BACKEND_BASE_URL="https://api.example.com"

# Local development
BACKEND_BASE_URL="http://localhost:5001"
```

#### IAP_MODE
```bash
# Production with IAP
IAP_MODE=true

# Development without IAP
IAP_MODE=false
```

## Generated Configuration File

### Example runtime-env.js
```javascript
// Runtime configuration injected at container start
window.__RUNTIME_CONFIG__ = {
  APP_PUBLIC_PATH: "/",
  BACKEND_BASE_URL: "/api",
  IAP_MODE: true,
  IAP_AUDIENCE: ""
};

// Console log for debugging (remove in production if needed)
console.log('Runtime config loaded:', window.__RUNTIME_CONFIG__);
```

### HTML Integration
```html
<!-- In web/index.html -->
<script src="/config/runtime-env.js"></script>
```

## Dart/Flutter Integration

### Accessing Configuration in Flutter
```dart
import 'dart:html' as html;

class ConfigService {
  static Map<String, dynamic>? _config;
  
  static Map<String, dynamic>? getConfig() {
    if (_config != null) return _config;
    
    try {
      final config = html.window.context['__RUNTIME_CONFIG__'];
      if (config != null) {
        _config = {
          'APP_PUBLIC_PATH': config['APP_PUBLIC_PATH'] ?? '/',
          'BACKEND_BASE_URL': config['BACKEND_BASE_URL'] ?? '/api',
          'IAP_MODE': config['IAP_MODE'] ?? false,
          'IAP_AUDIENCE': config['IAP_AUDIENCE'] ?? '',
        };
      }
    } catch (e) {
      print('Error loading runtime config: $e');
    }
    
    return _config;
  }
  
  static String get backendUrl {
    final config = getConfig();
    return config?['BACKEND_BASE_URL'] ?? '/api';
  }
  
  static bool get isIapMode {
    final config = getConfig();
    return config?['IAP_MODE'] == true;
  }
}
```

### Using Configuration in API Calls
```dart
// In your API client
class ApiClient {
  String get baseUrl => ConfigService.backendUrl;
  bool get useIap => ConfigService.isIapMode;
  
  Future<http.Response> post(String endpoint, Map<String, dynamic> data) {
    final url = '$baseUrl$endpoint';
    
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    // When IAP_MODE=true, rely on cookies (no Authorization header needed)
    // When IAP_MODE=false, you might add custom authentication
    
    return http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(data),
    );
  }
}
```

## Environment-Specific Configuration

### Development
```bash
# .env.development
APP_PUBLIC_PATH=/
BACKEND_BASE_URL=http://localhost:5001
IAP_MODE=false
IAP_AUDIENCE=
```

### Staging
```bash
# Cloud Run environment variables
APP_PUBLIC_PATH=/
BACKEND_BASE_URL=/api
IAP_MODE=true
IAP_AUDIENCE=projects/123456789/global/backendServices/my-backend
```

### Production
```bash
# Cloud Run environment variables
APP_PUBLIC_PATH=/
BACKEND_BASE_URL=/api
IAP_MODE=true
IAP_AUDIENCE=projects/987654321/global/backendServices/prod-backend
```

## Deployment Behavior

### Environment Variable Changes

| Environment | Change Method | Restart Required | Rebuild Required |
|-------------|---------------|------------------|------------------|
| Local Docker | `docker run -e VAR=value` | Yes | No |
| Cloud Run | `gcloud run services update --set-env-vars` | Yes | No |
| Cloud Build | Update substitution variables | Yes | No |

### Cache Behavior

#### Static Assets (Cacheable)
- Long cache headers (`max-age=31536000, immutable`)
- Hashed filenames for cache busting
- Example: `main.dart.js.1234567890.js`

#### Runtime Config (Non-Cacheable)
- No-store cache headers (`no-store, no-cache, must-revalidate`)
- Always fetched fresh from server
- File: `/config/runtime-env.js`

## Best Practices

### Adding New Configuration Variables

1. **Add to Environment Variables**:
   ```bash
   # In Dockerfile
   ENV NEW_CONFIG_VAR="default_value"
   ```

2. **Update entrypoint.sh**:
   ```bash
   NEW_CONFIG_VAR=${NEW_CONFIG_VAR:-"default_value"}
   
   cat > /usr/share/nginx/html/config/runtime-env.js << EOF
   window.__RUNTIME_CONFIG__ = {
     // ... existing vars
     NEW_CONFIG_VAR: "${NEW_CONFIG_VAR}"
   };
   EOF
   ```

3. **Update Flutter Code**:
   ```dart
   static String get newConfigVar {
     final config = getConfig();
     return config?['NEW_CONFIG_VAR'] ?? 'default_value';
   }
   ```

4. **Update Documentation**:
   - Add to environment variable table
   - Update example configurations
   - Document usage in Dart code

### Security Considerations

1. **No Secrets**: Never put sensitive data in runtime config (visible to browser)
2. **Validation**: Validate configuration values in Dart code
3. **Defaults**: Always provide sensible defaults
4. **Type Safety**: Convert string environment variables to appropriate types

### Testing Configuration

#### Local Testing
```bash
# Test different backend URLs
docker run -p 8080:8080 -e BACKEND_BASE_URL=https://staging-api.example.com app

# Test IAP mode
docker run -p 8080:8080 -e IAP_MODE=true -e BACKEND_BASE_URL=/api app

# Test custom path
docker run -p 8080:8080 -e APP_PUBLIC_PATH=/chat/ app
```

#### Verification Steps
1. **Check Generated File**: Visit `/config/runtime-env.js` in browser
2. **Console Inspection**: Check browser console for config logging
3. **API Calls**: Verify correct backend URL in network tab
4. **Deep Links**: Test that routing works with custom paths

## Troubleshooting

### Common Issues

#### Configuration Not Loading
```javascript
// Check if script loaded
console.log(window.__RUNTIME_CONFIG__);

// Check network tab for /config/runtime-env.js request
// Verify no 404 or cache issues
```

#### Wrong Backend URL
```bash
# Check container environment
docker exec -it container_name env | grep BACKEND

# Check generated config file
docker exec -it container_name cat /usr/share/nginx/html/config/runtime-env.js
```

#### Cache Issues
```bash
# Force refresh in browser (Ctrl+F5)
# Check response headers for runtime-env.js
# Verify no-cache headers are present
```

### Debug Commands

```bash
# Check environment variables in running container
docker exec -it container_name env

# View generated configuration
docker exec -it container_name cat /usr/share/nginx/html/config/runtime-env.js

# Check entrypoint script logs
docker logs container_name

# Test configuration endpoint
curl http://localhost:8080/config/runtime-env.js
```

## Migration Guide

### From Build-Time to Runtime Configuration

1. **Remove Build-Time Variables**:
   ```dart
   // OLD: Build-time configuration
   const String apiUrl = String.fromEnvironment('API_URL', defaultValue: '/api');
   
   // NEW: Runtime configuration
   String get apiUrl => ConfigService.backendUrl;
   ```

2. **Update Build Commands**:
   ```bash
   # OLD: Build with environment
   flutter build web --dart-define=API_URL=https://api.example.com
   
   # NEW: Build without environment (runtime injection)
   flutter build web --release
   ```

3. **Update Deployment**:
   ```bash
   # OLD: Different images per environment
   docker build --build-arg API_URL=https://staging.api.com -t app:staging
   
   # NEW: Same image, different runtime config
   docker run -e BACKEND_BASE_URL=https://staging.api.com app:latest
   ```
